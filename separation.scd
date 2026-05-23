// fiveband_engine.sc
(
SynthDef(\fiveband_engine, { |inBus=0, outBus=0, f1=200, f2=800, f3=3000, f4=8000, sr=44100|
    var inSig, left, right;
    var bandsL, bandsR;
    var lp1, hp1, lp2, hp2, lp3, hp3, lp4, hp4;
    var b0, b1, b2, b3, b4;

    // Read stereo input from inBus (assumes stereo pair)
    inSig = In.ar(inBus, 2);
    left = inSig[0];
    right = inSig[1];

    // Helper: 2nd-order Butterworth biquad using RLPF/RHPF is not exact;
    // implement biquad via BPF/LPF/HPF with two cascades for LR behaviour.
    // Use RLPF/RHPF for stability and control of Q when available.

    // Build 4th-order Linkwitz-Riley lowpass at fc: cascade two 2nd-order lowpass
    var lrLow = { |sig, fc|
        var s1 = RLPF.ar(sig, fc, 0.7071);
        var s2 = RLPF.ar(s1, fc, 0.7071);
        s2
    };

    // Build 4th-order Linkwitz-Riley highpass at fc: cascade two 2nd-order highpass
    var lrHigh = { |sig, fc|
        var s1 = RHPF.ar(sig, fc, 0.7071);
        var s2 = RHPF.ar(s1, fc, 0.7071);
        s2
    };

    // Create band outputs by subtracting adjacent LR outputs
    // low band = lowpass(f1)
    b0 = [ lrLow.(left, f1), lrLow.(right, f1) ];

    // band1 = lowpass(f2) - lowpass(f1)
    lp_f2_L = lrLow.(left, f2);
    lp_f2_R = lrLow.(right, f2);
    b1 = [ lp_f2_L - b0[0], lp_f2_R - b0[1] ];

    // band2 = lowpass(f3) - lowpass(f2)
    lp_f3_L = lrLow.(left, f3);
    lp_f3_R = lrLow.(right, f3);
    b2 = [ lp_f3_L - lp_f2_L, lp_f3_R - lp_f2_R ];

    // band3 = lowpass(f4) - lowpass(f3)
    lp_f4_L = lrLow.(left, f4);
    lp_f4_R = lrLow.(right, f4);
    b3 = [ lp_f4_L - lp_f3_L, lp_f4_R - lp_f3_R ];

    // high band = input - lowpass(f4) (equivalently highpass(f4) via LR)
    b4 = [ left - lp_f4_L, right - lp_f4_R ];

    // Output bands to consecutive stereo buses starting at outBus
    // Each band occupies two channels: outBus + (bandIndex*2)
    Out.ar(outBus + 0, b0); // band 0 stereo
    Out.ar(outBus + 2, b1); // band 1 stereo
    Out.ar(outBus + 4, b2); // band 2 stereo
    Out.ar(outBus + 6, b3); // band 3 stereo
    Out.ar(outBus + 8, b4); // band 4 stereo
}).add;
)

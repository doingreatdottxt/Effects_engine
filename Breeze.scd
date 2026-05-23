s.boot;

(
SynthDef(\breeze, {
    arg in=0, out=0, mix=0.5, flutter=0.5, space=0.5;
    var dry, wet, chorused, sig;

    // 1. INPUT
    dry = SoundIn.ar(in);

    // 2. THE DRIFT (Chorus/Vibrato)
    // We use a gently modulating delay line to create a wavering, tape-like drift
    chorused = DelayC.ar(
        in: dry, 
        maxdelaytime: 0.2, 
        delaytime: SinOsc.kr(0.5 + (flutter * 2.0)).range(0.005, 0.01 + (flutter * 0.02))
    );

    // 3. THE AETHER (Airy Reverb)
    // High-pass the wet signal before the reverb so it floats "above" the dry audio
    wet = HPF.ar(chorused, 800 + (flutter * 400));

    // We use FreeVerb here, which translates perfectly to DaisySP's ReverbSc
    wet = FreeVerb.ar(
        in: wet, 
        mix: 1.0, // We handle the master mix later
        room: 0.7 + (space * 0.29), // Huge room size
        damp: 0.1 // Very low high-frequency dampening keeps it bright and airy
    );

    // Slowly pan the reverb back and forth to enhance the "drifting" sensation
    wet = Pan2.ar(wet, SinOsc.kr(0.1 + (flutter * 0.2)));

    // 4. MIX AND ROUTE
    // Copy the mono dry signal to both L and R channels to match the stereo wet signal
    sig = XFade2.ar(dry ! 2, wet, (mix * 2) - 1);
    
    Out.ar(out, sig);

}).add;
)

// Test it:
z = Synth(\breeze);
z.set(\mix, 0.4, \flutter, 0.8, \space, 0.9); // Lots of movement, huge airy space
z.free;

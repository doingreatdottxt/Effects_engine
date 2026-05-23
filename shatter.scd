// Boot the server if needed
s.boot;

(
SynthDef(\shatter, {
    // Macro parameters: mapped conceptually between 0.0 and 1.0
    // We added a 'mix' parameter here as well to balance the dry/wet
    arg in=0, out=0, mix=0.5, density=0.5, chaos=0.0, age=0.0;
    
    var dry, wet, fb, clock, glitchTime, delayTime, sig;
    
    // 1. INPUT
    dry = SoundIn.ar(in);
    
    // 2. FEEDBACK LOOP
    // Capture the output of the delay from the last sample block
    fb = LocalIn.ar(1) + dry;
    
    // 3. THE SHATTER ENGINE
    // Density controls how rapidly the buffer fragments (2Hz up to 20Hz stutter)
    clock = LFNoise0.kr(2 + (density * 18));
    
    // Chaos controls the depth of the fragmentation.
    // At chaos = 0.0, delay is a stable 0.4 seconds.
    // At chaos = 1.0, the delay time jumps wildly between tiny stutters (0.02s) and 0.4s.
    glitchTime = clock.range(0.02, 0.4);
    delayTime = SelectX.kr(chaos, [0.4, glitchTime]);
    
    // The delay line. We use Lag to smooth the time jumps slightly. 
    // This prevents audio clicking and instead produces highly musical pitch-warping artifacts.
    wet = DelayC.ar(fb, 1.0, Lag.kr(delayTime, 0.05));
    
    // 4. THE AGE ENGINE (Degradation)
    // As 'age' increases, we drive the signal harder into a tanh distortion (tape saturation)
    wet = (wet * (1.0 + (age * 4.0))).tanh;
    
    // As 'age' increases, we narrow the EQ band to mimic failing hardware or old tape
    wet = LPF.ar(wet, 10000 - (age * 8000));
    wet = HPF.ar(wet, 40 + (age * 400));
    
    // Send back to the feedback loop. 
    // We increase the feedback amount slightly as chaos goes up to let the glitches ring out.
    LocalOut.ar(wet * (0.6 + (chaos * 0.25)));
    
    // 5. MIX AND ROUTE
    sig = XFade2.ar(dry, wet, (mix * 2) - 1);
    
    // Output as stereo
    Out.ar(out, sig ! 2);
    
}).add;
)

// ==========================================
// TESTING CONTROLS 
// ==========================================

// 1. Start the effect
y = Synth(\shatter);

// 2. Play with the macros! 
y.set(\mix, 0.6, \density, 0.1, \chaos, 0.0, \age, 0.0); // Clean, basic delay
y.set(\mix, 0.7, \density, 0.8, \chaos, 0.8, \age, 0.3); // Glitchy, rhythmic IDM stutters
y.set(\mix, 0.5, \density, 0.5, \chaos, 0.4, \age, 0.9); // Degraded, warbling lo-fi tape

// 3. Stop the effect
y.free;

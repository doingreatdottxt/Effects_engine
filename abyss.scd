// Boot the server if you haven't already
s.boot;

(
SynthDef(\abyss, {
    // Macro parameters: mapped conceptually between 0.0 and 1.0
    arg in=0, out=0, depth=0.5, shimmer=0.0, drift=0.2;
    var dry, wet, shimmerLoop, sig;
    
    // 1. INPUT
    // Capture mono input from hardware
    dry = SoundIn.ar(in);
    
    // 2. THE SHIMMER NETWORK (Feedback Loop)
    // LocalIn reads the audio from the *previous* block's LocalOut
    shimmerLoop = LocalIn.ar(1);
    
    // Sum the dry input with our feedback loop
    shimmerLoop = dry + shimmerLoop;
    
    // Pitch shift exactly one octave up (ratio of 2.0)
    shimmerLoop = PitchShift.ar(shimmerLoop, windowSize: 0.1, pitchRatio: 2.0, pitchDispersion: 0.001, timeDispersion: 0.001);
    
    // Filter the highs to prevent the octave from becoming overly harsh/piercing
    shimmerLoop = LPF.ar(shimmerLoop, 8000);
    
    // Send back into the feedback loop. 
    // We multiply by shimmer (0.0 - 1.0) and cap it at 0.85 to prevent runaway gain blowouts.
    LocalOut.ar(shimmerLoop * (shimmer * 0.85));
    
    // 3. THE REVERB CLOUD (Modulated Cascade)
    // Feed both the dry signal and the shimmer pitch-shift into the reverb
    wet = dry + (shimmerLoop * shimmer);
    
    // Create a lush tail using a cascade of 8 allpass delays
    8.do {
        // AllpassC allows for interpolated delay times, essential for smooth tape-like modulation
        wet = AllpassC.ar(
            in: wet, 
            maxdelaytime: 0.1, 
            // Delay time is modulated by LFNoise2 (smooth random LFO) based on the 'drift' parameter
            delaytime: LFNoise2.kr(0.1 + (drift * 0.5)).range(0.01, 0.05 + (drift * 0.04)), 
            // Decay time scales up with 'depth'
            decaytime: 1.0 + (depth * 5.0) 
        );
    };
    
    // Darken the reverb tail as depth increases for a spacier, distant feel
    wet = LPF.ar(wet, 12000 - (depth * 8000));
    
    // 4. MIX AND ROUTE
    // Crossfade between pure dry and pure wet. (depth * 2) - 1 maps 0.0->1.0 to -1.0->+1.0
    sig = XFade2.ar(dry, wet, (depth * 2) - 1); 
    
    // Output as pseudo-stereo by slightly delaying the right channel to widen the image
    Out.ar(out, [sig, DelayC.ar(sig, 0.02, 0.015)]);
    
}).add;
)

// ==========================================
// TESTING CONTROLS (Run these line by line)
// ==========================================

// 1. Start the effect
x = Synth(\abyss);

// 2. Play with the macros! 
// (Highlight a line and execute it to hear the changes live)
x.set(\depth, 0.8, \shimmer, 0.6, \drift, 0.7); // Lush and angelic
x.set(\depth, 0.4, \shimmer, 0.0, \drift, 0.1); // Small, subtle, dark room
x.set(\depth, 0.9, \shimmer, 0.9, \drift, 0.9); // Full chaos/ambient wash

// 3. Stop the effect
x.free;

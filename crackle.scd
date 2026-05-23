s.boot;

(
SynthDef(\crackle, {
    arg in=0, out=0, mix=0.5, spark=0.5, tension=0.0;
    var dry, wet, rhythm, echo, sig;

    // 1. INPUT
    dry = SoundIn.ar(in);

    // 2. THE ENGINE (Rhythmic Dust)
    // Mix a steady ticking clock (Impulse) with random sputtering (Dust)
    rhythm = Mix([
        Impulse.ar(8 + (spark * 12)), 
        Dust.ar(10 + (spark * 20))
    ]);

    // Shape the clicks into tiny, rapid volume envelopes
    rhythm = Decay2.ar(rhythm, 0.001, 0.03);

    // Multiply the input audio by the rhythm. 
    // This literally grabs microscopic "shards" of whatever you are playing.
    wet = dry * rhythm;

    // 3. THE RESONATOR (Comb Filter Delay)
    // A Comb filter acts like a very short delay with high feedback, causing it to ring out.
    // 'Tension' shortens the delay time, raising the pitch of the ringing metallic overtones.
    echo = CombC.ar(
        in: wet, 
        maxdelaytime: 0.2, 
        delaytime: 0.01 + ((1.0 - tension) * 0.05), 
        decaytime: 0.5 + (tension * 1.5)
    );

    // High-pass the output so it stays light, crispy, and out of the way of the bass
    wet = HPF.ar(echo, 1500);

    // 4. MIX AND ROUTE
    sig = XFade2.ar(dry, wet, (mix * 2) - 1);
    
    Out.ar(out, sig ! 2);

}).add;
)

// Test it:
c = Synth(\crackle);
c.set(\mix, 0.5, \spark, 0.2, \tension, 0.1); // Sparse, woody vinyl clicks
c.set(\mix, 0.6, \spark, 0.8, \tension, 0.9); // Dense, high-pitched metallic rain
c.free;

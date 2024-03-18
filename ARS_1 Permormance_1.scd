// Patches below are taken and altered from various sources indluiding UdK's Genertaive Computation Seminar and various open source online collections.
// The file can be thought of as divided into multiple parts: 1. the startup code, 2. the artificial rain (white noise) controlled via mouse moevements, 3. he individual sound patches, 4. an interactive harmonica to pair with an outside instrument.


// Performance File 0
s.record(duration: 900);

s.boot
//!! I call Ndef.clear with fadeout time
// show all soundmaking Ndefs:
~mixer = NdefMixer(s);
ProxyMeter.addMixer(~mixer);
s.plotTree
Ndef.clear(10)



// Set TempoClock // avoid using this by replacing parameters in "wind" function
/*t = TempoClock.new(80/60).permanent_(true);*/

Ndef(\playthedrum).stop
// // Wind sound
/*Ndef(\n).clock_(t).poll
Ndef(\n).fadeTime_(4)
t.tempo*/
s.reboot


// Inititate digital rain sound
(
Ndef(\n, {
	var sig, f, osc;
	f = 1.3;
	sig = PinkNoise.ar(0.5);
	osc = LFNoise2.kr(rrand(0.5, 1)).range(2, 8);
	sig = Pan2.ar(in: BPF.ar(sig, SinOsc.kr(f/osc).exprange(400, 800), 0.4), pos:MouseX.kr(-1, 1));
});
)

(
Ndef(\m, {
	var sig, f, osc;
	f = 1.3;
	sig = PinkNoise.ar(0.5);
	osc = LFNoise2.kr(rrand(0.5, 1)).range(2, 8);
	sig = Pan2.ar(in: BPF.ar(sig, SinOsc.kr(f/osc).exprange(100, 300), 0.4), pos:MouseY.kr(-1, 1));
});
)
Ndef(\n).play;
Ndef(\m).play;

// Rain #TODO: make brighter
(
Ndef(\rain, {
	var gaus, osc;
	gaus = {WhiteNoise.ar}.dup(10).sum;
	gaus = LPF.ar(BPF.ar(gaus, 50, 1/0.4), 500);

	osc = SinOsc.ar(gaus.linlin(-1, 1, 40, 80)) * gaus.squared * 10;
	osc = (osc - 0.35).max(0);

	2.do {
		osc = HPF.ar(osc, 500);
	};

	osc.dup * 0.7
})
)
Ndef(\rain).play




/////////////////////////
/////////////////////////

//// Load and play audio files
~path = "path" // insert parth to recording
(
~buf1 = Buffer.read(s,~path);
Ndef(\irish, {arg mul = 0.5;
	PlayBuf.ar(2, ~buf1, loop: 0) * mul
});
)
Ndef(\irish).play;



////Harmonic part
//////////////////////////////////////////////////////////////////

// // Cornerstone Example -- combine much of what has been learned thus far
// Long SynthDef
(
SynthDef(\wow, {arg out = 0, freq =  60, amp = 0.1, gate = 1, wowrelease = 3;
	var chorus, source, filtermod, env, snd;
	chorus = Lag.kr(freq, 2) * LFNoise2.kr([0.4, 0.5, 0.7, 1, 2, 5, 10]).range(1 , 1.02);
	source = LFSaw.ar(chorus) * 0.5;
	filtermod = SinOsc.kr(1/16).range(1, 10);
	env = Env.asr(1, amp, wowrelease).kr(2, gate);
	snd = LPF.ar(in: source, freq: freq*2* filtermod, mul: env);
	Out.ar(out, Splay.ar(snd))
}).add;
)

~wow = NPVoicer(Ndef(\wow));     // make an NPVoicer with an Ndef in it
~wow.prime(\wow); // prepare it with the default synthdef


~wow.put(48, [\freq, 48.midicps]);
~wow.put(65, [\freq, 65.midicps]);
~wow.put(71, [\freq, 71.midicps]);
~wow.put(76, [\freq, 76.midicps]);
~wow.put(79, [\freq, 79.midicps]);


~wow.play; // play it
~wow.releaseAll;


~wow.release(76);
~wow.release(65);
~wow.release(79);
~wow.proxy.objects.indices


// How do we call the NdefGUI with freq control?
s.plotTree

    // start a sound with key 48, with its won set of params
g.put(48, [\freq, 48.midicps]);
NPVoicer


//// Semi-textured
// keep mouse center top for nicest sound
(
Ndef(\glassDroplets,
	// sample and hold liquidities
	// mouse x controls clock rate, mouse y controls center frequency
{
	var clockRate, clockTime, clock, centerFreq, freq, panPos, patch;

	/*clockRate = MouseX.kr(1, 200, 'exponential');*/
	clockRate = 100;
	clockTime = clockRate.reciprocal;
	clock = Impulse.kr(clockRate, 0.4);

	centerFreq = MouseY.kr(100, 8000, 'exponential');
	freq = Latch.kr(WhiteNoise.kr(centerFreq * 0.5, centerFreq), clock);
	panPos = Latch.kr(WhiteNoise.kr, clock);
	patch = CombN.ar(
			Pan2.ar(
				SinOsc.ar(
					freq,
					0,
					Decay2.kr(clock, 0.1 * clockTime, 0.9 * clockTime)
				),
				panPos
			),
			0.3, 0.3, 2
		);
});
)
Ndef(\glassDroplets).play;


// Reverberated sine percussion
(
Ndef(\dropsRev, {
var a, c, d, s, z, y;
d = 6; // number of percolators
c = 5; // number of comb delays
a = 4; // number of allpass delays

({
		// sine percolation sound :
	s = Mix.ar(Array.fill(d, { Resonz.ar(Dust.ar(2/d, 50), 200 + 3000.0.rand, 0.003)}) );

		// reverb predelay time :
	z = DelayN.ar(s, 0.048);

		// 7 length modulated comb delays in parallel :
	y = Mix.ar(CombL.ar(z, 0.1, LFNoise1.kr(Array.fill(c,{0.1.rand}), 0.04, 0.05), 15));

		// chain of 4 allpass delays on each of two channels (8 total) :
	a.do({ y = AllpassN.ar(y, 0.050, [0.050.rand,0.050.rand], 1) });
		// add original sound to reverb and play it :
	s+(0.2*y)
})});
)
Ndef(\dropsRev).play



//// Industrial bell
(
Ndef(\industrialBell,
	{
		var root, scale, s;
		// wind chords
		var trig, p, n, exc, x, base, range;
		//root = rrand(3,6);
		root = 15;
		scale = #[0,2,4,5,7,9,11];
		n = 5;
		exc = BrownNoise.ar([0.007,0.007]) * max(0, LFNoise1.kr(exprand(0.125,0.5), 1.25, -0.25));
		s = (Klank.ar(`[Array.fill(n, {(scale.choose + #[36,48,60,72,84].choose + root).midicps}),nil,Array.fill(n, {rrand(0.1,2.0)})], exc) * 0.1).softclip;
}).add;
)
Ndef(\industrialBell)


//// Deep Pulse
(
Ndef(\deepPulse, {
	arg fundamental = 30;
    var harmonics = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    var snd = BPF.ar(
        in: Saw.ar(32, LFPulse.ar(harmonics, width: 0.1)), //this line I don't understand
		freq: harmonics * fundamental,
        rq: 0.01,
        mul: 20);
    Splay.ar(snd);
});
)
Ndef(\deepPulse).play
Ndef(\deepPulse).set(\fundamental, 60);


//// Claxon / cluster generator
(
Ndef(\claxon, {
	Mix.fill(16, {SinOsc.ar(rrand(100, 3000), mul: 0.05)})});
)
Ndef;




// Sirens
(
Ndef(\sirens, {
var n;
n = 2;	// number of sirens
({
	CombL.ar(
		Mix.arFill(n, {
			Pan2.ar(
				SinOsc.ar(
					SinOsc.kr(0.1.rand + 0.02, 2pi.rand, 600.rand, 1000 + 300.rand2),
					0,
					LFNoise2.ar(100 + 20.0.rand2, 0.1)
				),
				1.0.rand2
			)
		})
		+ LFNoise2.ar(LFNoise2.kr([0.4,0.4], 90, 620), LFNoise2.kr([0.3,0.3], 0.15, 0.18)),
		0.3, 0.3, 3)
})
});
)
Ndef(\sirens).play

//// Percussive
// Cymbals
(
Ndef(\cymbals, {
// cymbalismvar
	var p;
		var z, f1, f2;
p = 50;	// number of partials per channel per 'cymbal'.
		f1 = 500 + 2000.0.rand;
		f2 = 8000.0.rand;
		z = Array.fill(2, {
			`[	// sine oscil bank specification :
				y = Array.fill(p, { f1 + f2.rand} ), // frequencies
				nil, 							// amplitudes default to 1.0
				Array.fill(p, { 1.0 + 4.0.rand })	// ring times
			]
		});
		Klank.ar(z, Decay.ar(Impulse.ar(3.0.rand + 0.5), 0.004, WhiteNoise.ar(0.03)));
});
)
Ndef(\cymbals).play


//Scratchy
(Ndef(\scratchy, {
	RHPF.ar(BrownNoise.ar([0.5,0.5], -0.49).max(0) * 20, 5000, 1)
})
)
Ndef(\scratchy).play

// Moto rev
(
Ndef(\moto,
{
	RLPF.ar(LFPulse.ar(SinOsc.kr(0.1, 0, 10, 21), 0.1), 100, 0.1).clip2(0.4)
})
)
Ndef(\moto).play


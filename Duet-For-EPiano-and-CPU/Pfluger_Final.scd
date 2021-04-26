/*
Hi!

Welcome to my SC final for Audio Software Design @ Temple U

Quick notes on "performance":

The "piece" is meant to be conceived of as an improvisational acoustic framework, taking the form of a piece of software. Though I may be the only one to ever use this piece of software, I enjoy the laden potential of a compositional medium that lies somewhere between building an instrument and "composing" piece; a sonorous digital framework...

In liu of a proper gui, I have set up a system of computer keyboard/mouse based interaction that is used to control various aspects of the "piece". These are controls expose parameters that I felt were good candidates for manipulation, in development and improvisation of the piece

In order to safely do this, use the "...key press tracker..." window to "type" in your key commands. This will prevent you from altering the code itself, and provides a nice way to track what you're doing...

Special Interface Command Controls:
q = plays water sample
w = Plays Glass Tone Percussion sample
Mouse Y position = Sample Playback Rate
Mouse X position = Master Delay time (0.1 - 2.5 sec range)
Space = Spectral Freezes (AUDIO INPUT ONLY)
d = allows clean audio input to reach freeze and delay network without exclusively passing through pitch tracker
f = longer fdbck time on delay network
b = bypass audio pitch tracking
g = initialize audible granular processing
r = generate new random pitch shift factor for granular pitch shift
*/
(
s.waitForBoot({ //this takes care of all "load sequencing",

'!Allocating Buffers and Busses!'.postln; //helpful status update in the post window

~bus1 = Bus.audio(s, 2); //bus for fft processing
	s.sync; //waits for previous tasks to finish, then starts on next part...
~pBus = Bus.audio(s, 2); //bus for pitch tracking
	s.sync; //waits for previous tasks to finish, then starts on next part...
~dBus = Bus.audio(s, 2); //bus for delay and reverb
	s.sync;//waits for previous tasks to finish, then starts on next part...
~gBus = Bus.audio(s, 2); //bus for granular pitch shift
	s.sync; //waits for previous tasks to finish, then starts on next part...

~fft_buf = Buffer.alloc(s,2048); // allocates buffer for FFT freeze later on
	s.sync; //waits for previous tasks to finish, then starts on next part...
~b1 = Buffer.read(s, "/Users/jonahpfluger/Documents/SuperColliderFiles/samp/Samples/Water.aif"); // loads sample into a buffer b1
	s.sync; //waits for previous tasks to finish, then starts on next part...
~b2 = Buffer.read(s, "/Users/jonahpfluger/Documents/SuperColliderFiles/samp/Samples/Glass_Tone.aif"); // loads sample into a buffer called b2

s.sync; //waits for previous tasks to finish, then starts on next part...

(
'!Setting up Conveniece GUI!'.postln; //helpful status update in the post window
Window.closeAll;
		w = Window.new("...key press tracker...", Rect(0, 400, 830, 425));
		w.front;
		w.alwaysOnTop = false;
		w.background = Color.new(0.15, 0.6, 0.4, 0.5);
~keyText = TextField(w, Rect(5, 5, 200, 20));
~helpTip = StaticText(w, Rect(250, 75, 150, 25)).string_("key shortcut help --->");
~helpList = StaticText(w, Rect(400, 5, 300, 400)).string_("Special Interface Command Controls:
q = plays water sample \n
w = Plays Glass Tone Percussion sample \n
Mouse Y position = Sample Playback Rate (=pitch) \n
Mouse X position = Master Delay time (0.1 - 2.5 sec range) \n
Space = Spectral Freezes (AUDIO INPUT ONLY) \n
d = allows clean audio input to reach freeze and delay network without exclusively passing through pitch tracker \n
f = longer fdbck time on delay network \n
b = bypass audio pitch tracking \n
g = initialize audible granular processing \n
r = generate new random pitch shift factor for granular pitch shift");
);

s.sync;//waits for previous tasks to finish, then starts on next part...

s.meter;//brings up, my friend, the meter
s.plotTree;//brings up, my friend, the post window

s.sync;//waits for previous tasks to finish, then starts on next part...
(// Defs...
( '!initializing synth defs!'.postln; //helpful status update in the post window
SynthDef.new(\buf_player, {
	arg rate, buf, amp = 0.5, loop = 1, out = 0, trig, trig_copy, key, buf_num, scale = 0.25, chan, atk = 1, slew = 1;
	var sig, env;
	env = XLine.kr(0.01, 0.5, atk);
	rate = MouseY.kr(0.25, 10, 1);
	trig = KeyState.kr(key, -1, 1);
	trig_copy = KeyState.kr(key, 0, 1, slew);
	sig = PlayBuf.ar(2, buf_num, rate, trig, loop: loop);
	sig = sig * env;
	sig = sig * (trig_copy*scale);
	Out. ar(out, sig);
}).add;
);

'buf synth intialized'.postln;//helpful status update in the post window

(
SynthDef(\inout, {
	arg key;
	var inSig, local;
	key = KeyState.kr(2, 0, 1);
	inSig = SoundIn.ar(0)!2; //bring signal in from interface
	Out.ar(~pBus, inSig); //sends input to pitch tracker
	Out.ar(~bus1, inSig*key); //sends input to fft freezer
	Out.ar(~gBus, inSig); //sends input to granular processing
}).add;
);

'audio-in synth intialized'.postln;//helpful status update in the post window

(
SynthDef(\pTrack, {
	arg out = 0;
	var in, amp, freq, hasFreq, sound;
	in = In.ar(~pBus);
	amp = Amplitude.kr(in, 0.05, 0.05);
	# freq, hasFreq = Pitch.kr(in); // the pitch ugen throws 2 outputs, so a literal array is used to "catch" both and seperate into useful params
	//sound = Mix.new(SinOsc.ar(freq.lag(0.10) * 4, mul:amp))!2;
	sound = SinOsc.ar(freq.lag(0.10) * 4, mul:amp)!2;
	sound = sound * KeyState.kr(11, 1, 0);
	Out.ar(~bus1, sound);
	Out.ar(~dBus, sound);
}).add;
);

'pitch track synth initialized'.postln;//helpful status update in the post window

(
SynthDef(\grain_pitch, {
	arg dur, trig, shift;
	var sig, in;
	in = In.ar(~gBus, 2); // takes input in from gBus
	trig = Dust.kr(10); //used as random trig in grainin ugen later on...
	dur = LFNoise0.kr(2).range(0.5, 2);
	shift = TExpRand.kr(1, 4, KeyState.kr(15, -1, 1)); //pressing "r" (KeyState "15", generates a randomly distrbiuted float (w exp distribution) bt 1 and 4)
	sig = PitchShift.ar(in, 0.2, shift);//shift signal up via random value generated by Key press of "r"
	sig = GrainIn.ar(2, trig, dur, sig); //granulator ugen
	sig = sig * KeyState.kr(5, 0, 1.5);
	Out.ar(~bus1, sig*0.7);
}).add;
);

'grain synth initialized'.postln;//helpful status update in the post window

(
SynthDef(\freeze, { //fft freeze processing
	arg trig;
	var in, freqDomain;
	in = In.ar(~bus1, 2); //takes audio in from ~bus1
	freqDomain = FFT(~fft_buf, in);//converts "in" into a freq domain representation, stored in ~fft_buf
	freqDomain = PV_MagFreeze(freqDomain, KeyState.kr(49, 0, 1, 0.01));//spectral freeze ugen, with trig controlled by KeyState of Space bar (49 = space bar)
	Out.ar(~dBus, IFFT(~fft_buf)!2);//sends audio to ~dBus, freq domain rep is converted back into time domain via IFFT ugen
}).add;
);

'fft freeze synth initialized'.postln;//helpful status update in the post window

(
SynthDef(\delay, { // simple delay and verb fx chain
	arg d_tim;
	var sig, in;
	d_tim = MouseX.kr(0.1, 2.5); //sets arg d_tim = Mouse horizontal pos
	in = In.ar(~dBus, 2); //receives audio via ~dBus
	sig = CombC.ar(in, 2.5, d_tim.lag(10), KeyState.kr(3, 10, 35)); //basic comb filt, with Key control for key f (first arg 3 = "hey keystate ugen listen to the f key") to increase feedback by 3.5x
	sig = JPverb.ar(sig, 2, 0.5);//verb... sc3 extentsion downloaded from standard lib
	Out.ar(0, sig); //sounds out array
}).add
);

'delay and verb synth initialized'.postln;//helpful status update in the post window
'all synth defs initialized... ready to go!'.postln;//helpful status update in the post window
);

s.sync;//waits for previous tasks to finish, then starts on next part...

(//synth calls...
'!Calling Synths!'.postln;//helpful status update in the post window
f = Synth(\delay);// creates synth
		s.sync;//waits for previous tasks to finish, then starts on next part...

e = Synth(\freeze);// creates synth
		s.sync;//waits for previous tasks to finish, then starts on next part...

g = Synth(\grain_pitch);// creates synth
		s.sync;//waits for previous tasks to finish, then starts on next part...

d = Synth(\pTrack);// creates synth
		s.sync;//waits for previous tasks to finish, then starts on next part...

c = Synth(\inout);// creates synth
		s.sync;//waits for previous tasks to finish, then starts on next part...

( // glass tone sample synth
b = Synth(\buf_player, [ //below = args to manipulate exposed params of synthdef
	\buf_num, ~b2,
	\scale, 0.5,
	\key, 13,
	\out, ~dBus,
]);
);// creates synth
		s.sync;//waits for previous tasks to finish, then starts on next part...

( // water sample synth
a = Synth(\buf_player, [//below = args to manipulate exposed params of synthdef
	\buf_num, ~b1,
	\atk, 25,
	\scale, 0.35,
	\slew, 5,
	\key,12,
	\out, ~dBus,
]);
);// creates synth
		s.sync;//waits for previous tasks to finish, then starts on next part...

);
s.sync;//waits for previous tasks to finish, then starts on next part...

'ready to play! :)'.postln;//helpful status update in the post window

});
)//end of s. wait
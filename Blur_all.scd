({
	s.waitForBoot({
	'...Allocating Busses...'.postln;
	~bus1 = Bus.audio(s, 2);

	// SYNTHDEFS **********************************************************************************
	'...Declaring Synth Defs...'.postln;
	(
		SynthDef(\system_1, {
			arg freq = 125, amp = 0.5, atk_goal = 1, dkay_goal = 0, atk_time = 1, dkay_time = 1, pos = -1, cf = 500, out = ~bus1;
			var sig, env;
			sig = Saw.ar(freq);
			env = EnvGen.kr(Env(
				[0, atk_goal, dkay_goal],
				[atk_time, dkay_time],
			), doneAction:2);
			sig = LPF.ar(sig, cf);
			sig = sig*env;
			sig = Pan2.ar(sig, LFNoise1.kr(0.5).range(-1, 1));
			Out.ar(out, sig*amp);
		}).add;
	);

	(
		SynthDef.new(\pikachu, {
			arg freq = 261.6, cf = 400, lfo_1, lfo_1_rate = 0.25, atk_tim = 2.5, dkay_tim = 1, max_vol = 0.7, out = 0;
			var sig, env;
			lfo_1 = SinOsc.kr(lfo_1_rate).range(-0.5, 0.5);
			env = EnvGen.kr(Env(
				[0, max_vol, 0],
				[atk_tim, dkay_tim],
				[1, -1]), doneAction: 2);
			freq = Rand(100, 300);

			sig = Saw.ar(freq);
			sig = sig * env;
			sig = LPF.ar(sig, cf);
			sig = Pan2.ar(sig, lfo_1);
			Out.ar(out, sig);
		}).add;
	);

	(
		SynthDef.new(\wind, {
			arg sway = 250, atk_tim = 1, dkay_tim = 1, cf = 440, rq = 1, amp = 1, out = 0, hpf = 750, lpf = 1000;
			var sig, env;
			sig = PinkNoise.ar(1);
			sig = MoogFF.ar(sig, sway, 2);
			env = EnvGen.kr(Env(
				[0, 0.75, 0],
				[atk_tim, dkay_tim],
			), doneAction:2);
			sig = BPF.ar(sig, cf, rq);
			sig = HPF.ar(sig, hpf.lag(1));
			sig = LPF.ar(sig, lpf);
			sig = sig * env;
			sig = sig * amp;
			Out.ar(out, sig);
		}).add
	);

	(
		SynthDef.new(\kick, {
			arg out = 0, freq = 35, amp = 0.5, atk_tim = 0.01, dkay_tim = 0.2;
			var sig, env, pitch_env;
			env = EnvGen.kr(Env.perc(atk_tim,dkay_tim), doneAction: 2);
			pitch_env = EnvGen.kr(
				Env([0.5, 1.5], [0.01]));
			sig = SinOsc.ar(freq * pitch_env)!2;
			sig = sig * env;
			sig = sig * amp;
			Out.ar(out, sig);
		}).add;
	);

	(
		SynthDef.new(\snare_hat, {
			arg cf = 500, out = 0, atk_tim = 0.01, dkay_tim = 1, rq = 0.5, amp = 0.7;
			var sig, env;
			env = EnvGen.kr(Env.perc(atk_tim, dkay_tim), doneAction: 2);
			sig = WhiteNoise.ar(0.01)!2;
			sig = BPF.ar(sig, cf, rq);
			sig = sig * env * amp;
			Out.ar(out, sig);
		}).add;
	);

	(
		SynthDef(\fx, {
			arg del_tim = 2.5, fdback = 10, db = -15;
			var sig, in;
			in = In.ar(~bus1);
			sig = AllpassC.ar(in, 5, del_tim.lag(10), fdback);
			//sig = FreeVerb.ar(sig, 0.75, 0.5, 0.5);
			sig = BPeakEQ.ar(sig, 250, 1.5, db);
			sig = JPverb.ar(sig, damp: 0.75, low: 0, mid: 0.5, lowcut: 1000);
			sig = Pan2.ar(sig, LFNoise1.kr(1.25).range(-0.35, 0.35));
			Out.ar(0, sig);
		}).add;
	);


	s.sync;

	'...Managing GUI...'.postln;

	(
		Window.closeAll;
		w = Window.new("... Blur | Jonah Pfluger ...", Rect(800, 200, 500, 550));
		w.front;
		w.alwaysOnTop = true;
		w.background = Color.new(0.15, 0.6, 0.7, 0.5);

		~hpf_slider = Slider.new(w, Rect(20, 95, 50, 100))
		.action_({
			arg obj;
			var cf;
			cf = obj.value.linexp(0, 1, 500, 750);
			if(
				y.isPlaying,{
					y.set(\hpf, cf)});
			~hpf_numberBox.value_(obj.value.linexp(0, 1, 500, 750));
		});

		~hpf_slider.value_(1); // initialize

		(
			~hpf_numberBox = NumberBox(w, Rect(20, 200, 50, 20))
			.value_(750)
			.clipLo_(500)
			.clipHi_(750)
			.decimals_(2)
			.action_({
				arg obj;
				~hpf_slider.valueAction_(obj.value.expline(500, 750, 0, 1))
			});
		);

		(
			~hpf_text = StaticText.new(w, Rect(10, 225, 100, 25)).string_("W-Support");
		);

		(
			~lpf_text = StaticText.new(w, Rect(110, 225, 100, 25)).string_("W-Sparkle");
		);

		~lpf_slider = Slider.new(w, Rect(115, 95, 50, 100))
		.action_({
			arg obj;
			var cf;
			cf = obj.value.linexp(0, 1, 800, 2500);
			if(
				y.isPlaying,{
					y.set(\lpf, cf)});
			~lpf_numberBox.value_(obj.value.linexp(0, 1, 800, 2500));
		});

		~lpf_slider.value_(0.2); // initialize

		(
			~lpf_numberBox = NumberBox(w, Rect(115, 200, 50, 20))
			.value_(1000)
			.clipLo_(800)
			.clipHi_(2500)
			.decimals_(2)
			.action_({
				arg obj;
				~lpf_slider.valueAction_(obj.value.expline(800, 2500, 0, 1))
			});
		);

		(
			~wind_synth_button = Button(w, Rect(20, 10, 75, 50))
			.states_([["Trig Wind", Color.black]])
			.action_({
				arg obj;
				obj.value;
				if(obj.value == 0,{rrand(1, 5).do{(
					y = Synth.new(
						\wind,
						[
							\sway, rrand(100, 500),
							\atk_tim, rrand(1, 5),
							\dkay_tim, rrand(1, 5),
							\cf, (Scale.lydian.degrees+60).choose.midicps * [0.5, 1, 1.5, 2, 4].choose.postln,
							\rq, 0.001,
							\amp, 100,
							\hpf, ~hpf_slider.value.linexp(0, 1, 500, 750),
							\lpf, ~lpf_slider.value.linexp(0, 1, 800, 2500),
							\out, ~bus1,
						]
					).register;
				)};
				});
			});

		);

		~p_button = Button(w, Rect(175, 10, 75, 50))
		.states_([["L-Sweep", Color.black]])
		.action_({
			arg obj;
			obj.value.postln;
			if(obj.value == 0, {
				rrand(1, 3).do{
					(x = Synth(\pikachu,
						[
							\cf, rrand(100, 400),
							\out, ~bus1,
						]

					).register;
				)};
			});
		});

		(
			~system1_button = Button(w, Rect(300, 10, 75, 50))
			.states_([
				["Patt Saw", Color.black],
				["Patt Saw", Color.black, Color.grey]
			])
			.action_({
				arg obj;
				obj.value.postln;
				if(obj.value == 1,
					/*pressed*/{
						(
							Pdef(\system_1, Pbind(
								\instrument, \system_1,
								\dur, Pexprand(0.5, 3.5, inf),
								//\midinote, Prand(Scale.majorPentatonic.degrees+48-12, inf),
								\midinote, Prand(Scale.majorPentatonic.degrees+60-12, inf),
								//\cf, Pexprand(250, 500, inf),
								\cf, Pdefn(\cutoff),
								\atk_goal, 0.75,
								\dkay_goal, 0,
								\atk_time, Pexprand(1.5, 4, inf),
								\dkay_time, Pexprand(1, 5, inf),
								\out, ~bus1,
							)).play;
						);
					},
					/*pressed off*/{
						(
							Pdef(\system_1, Pbind(
								\instrument, \system_1,
							)).stop;
						);
					}
				);

			});
		);

		(
			~s1_cf_rslider = RangeSlider.new(w, Rect(50, 300, 125, 50))
			.lo_(0.1).hi_(0.5).action_({
				arg obj;
				var lo_cf, hi_cf;
				lo_cf = obj.lo.value.linexp(0.01, 1, 200, 4000).postln;
				hi_cf = obj.hi.value.linexp(0.01, 1, 200, 4000).postln;

				Pdefn(\cutoff, Pexprand(lo_cf, hi_cf, inf));
			});


		);

		~saw_r_text = StaticText(w, Rect(10, 300, 50, 50))
		.string_("P Saw CF");


		(
			~kick_button = Button(w, Rect(400, 10, 75, 50))
			.states_([
				["T Thump", Color.black],
				["T Thump", Color.black, Color.grey]
			])
			.action_({
				arg obj;
				obj.value.postln;
				if(obj.value == 1,
					/*pressed*/{
						(
							Pdef(\kick, Pbind(
								\instrument, \kick,
								\dur, Pdefn(\temp),
								\freq, Prand(Scale.majorPentatonic.degrees+60, inf),
								\amp, Pseq([0.5, 0.2, 0.4, 0.1]*0.75, inf),
							)).play;
						);
					},
					/*pressed off*/{
						(
							Pdef(\kick, Pbind(
								\instrument, \kick,
							)).stop;
						);
					}
				);

			});
		);

		(
			~temp_slider = Slider.new(w, Rect(50, 450, 125, 50))
			.value_(0.8)
			.action_({
				arg obj;
				var t;
				t = obj.value.linlin(0, 1, 2.5, 0.1).postln;


				Pdefn(\temp, t);
			});
		);

		~temp_text = StaticText(w, Rect(10, 450, 50, 50))
		.string_("Kick Temp");

		(
			~s_blips_button = Button(w, Rect(300, 100, 75, 50))
			.states_([
				["Tuned Pings", Color.black],
				["Tuned Pings", Color.black, Color.grey]
			])
			.action_({
				arg obj;
				obj.value.postln;
				if(obj.value == 1,
					/*pressed*/{
						(
							Pdef(\bop_quick, Pbind(
								\instrument, \kick,
								//\dur, Pexprand(2.5, 5, inf),
								\dur, Pdefn(\ping_dur),
								\atk_tim, Pwhite(0.05, 0.5, inf),
								\dkay_tim, Pwhite(0.09, 0.3, inf),
								\freq, Pdefn(\slide_range),
								//\freq, Pexprand(100, 1000, inf),
								\amp, Prand([0.5, 0.2, 0.4, 0.1]*0.1, inf),
								\out, ~bus1,
							)).play;
						);
					},
					/*pressed off*/{
						(
							Pdef(\bop_quick, Pbind(
								\instrument, \kick,
							)).stop;
						);
					}
				);

			});
		);

		(
				~blip_range_slider = Slider.new(w, Rect(300, 300, 125, 50))
					.action_({
						arg obj;
						var range;
					range = obj.value.linlin(0, 1, 48, 72).round(1).postln;

						Pdefn(\slide_range, Prand((Scale.majorPentatonic.degrees+range).midicps, inf));
					});
				);

			(
				~ping_range = StaticText(w, Rect(260, 300, 39, 50))
				.string_("Ping Range");
			);

		(
			~ping_dur_rslider = RangeSlider.new(w, Rect(50, 375, 125, 50))
			.lo_(0.5).hi_(5).action_({
				arg obj;
				var lo_c, hi_c;
				lo_c = obj.lo.value.linlin(0, 1, 0.01, 5).postln;
				hi_c = obj.hi.value.linlin(0, 1, 0.01, 5).postln;


				Pdefn(\ping_dur, Pexprand(lo_c, hi_c, inf));
			});
		);

		~ping_dur_text = StaticText(w, Rect(10, 375, 50, 50))
		.string_("T Ping Dur");

		(
			~l_blips_button = Button(w, Rect(400, 100, 75, 50))
			.states_([
				["Tuned Dro", Color.black],
				["Tuned Dro", Color.black, Color.grey]
			])
			.action_({
				arg obj;
				obj.value.postln;
				if(obj.value == 1,
					/*pressed*/{
						(
							Pdef(\bop_long, Pbind(
								\instrument, \kick,
								\dur, Pwhite(0.5, 2.5, inf),
								\atk_tim, Pwhite(1.5, 4, inf),
								\dkay_tim, Pwhite(1, 5, inf),
								\freq, Prand((Scale.lydian.degrees+48).midicps, inf),
								//\freq, Pexprand(100, 250, inf),
								\amp, Prand([0.5, 0.2, 0.4, 0.1]*0.1, inf),
								\out, ~bus1,
							)).play;
						);
					},
					/*pressed off*/{
						(
							Pdef(\bop_long, Pbind(
								\instrument, \kick,
							)).stop;
						);
					}
				);

			});
		);

		(
			~noise_button = Button(w, Rect(300, 200, 75, 50))
			.states_([
				["Noise Perc", Color.black],
				["Noise Perc", Color.black, Color.grey]
			])
			.action_({
				arg obj;
				obj.value.postln;
				if(obj.value == 1,
					/*pressed*/{
						(
							Pdef(\snare_hat, Pbind(
								\instrument, \snare_hat,
								\dur, 1,
								\amp, 0.5,
								\atk_tim, Pdefn(\a_t),
								\dkay_tim, Pdefn(\d_t),
								\rq, 0.7,
								\out, ~bus1,
							)).play;
						);
					},
					/*pressed off*/{
						(
							Pdef(\snare_hat, Pbind(
								\instrument, \snare_hat,
							)).stop;
						);
					}
				);

			});
		);

				(
			~noise_a_rslider = RangeSlider.new(w, Rect(300, 375, 125, 50))
			.lo_(0.5).hi_(5).action_({
				arg obj;
				var lo_c, hi_c;
				lo_c = obj.lo.value.linlin(0, 1, 0.01, 5).postln;
				hi_c = obj.hi.value.linlin(0, 1, 0.01, 5).postln;


				Pdefn(\a_t, Pwhite(lo_c, hi_c, inf));
			});
		);
			(
				~a_d_text = StaticText(w, Rect(260, 375, 40, 50))
				.string_("Noise A");
			);

				(
			~noise_d_rslider = RangeSlider.new(w, Rect(300, 450, 125, 50))
			.lo_(0.5).hi_(5).action_({
				arg obj;
				var lo_c, hi_c;
				lo_c = obj.lo.value.linlin(0, 1, 0.01, 5).postln;
				hi_c = obj.hi.value.linlin(0, 1, 0.01, 5).postln;


				Pdefn(\d_t, Pwhite(lo_c, hi_c, inf));
			});
		);

			(
				~n_d_text = StaticText(w, Rect(260, 450, 40, 50))
				.string_("Noise D");
			);

		(
			~wiggle_button = Button(w, Rect(400, 200, 75, 50))
			.states_([
				["Wiggle", Color.black]
			])
			.action_({
				arg obj;
				obj.value.postln;
				if(obj.value == 0,
					/*pressed*/{
						f.set(\del_tim, rrand(1.5, 3.5).postln, \fdback, 10)
					},

				);

			});
		);

	);

	'...Calling FX Synth...'.postln;

	f = Synth(\fx, addAction: 'addToTail');

	s.sync;


	'...Calling Meter and Plot Tree...'.postln;
	s.meter;
	s.plotTree;
});
}.fork(AppClock);
)
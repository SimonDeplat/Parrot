(
s.waitForBoot({
	var numLoops = 8;
	var inputChannel = 0;
	var outChannel = 0;
	var maxLoopLength = 20.0;

	var synthPlaying = true;
	var fullScreen = false;

	var folderName = thisProcess.nowExecutingPath.dirname;
	var win = Window(
		"Parrot",
		Rect(
			Window.screenBounds.width * 0.1,
			Window.screenBounds.height * 0.1,
			Window.screenBounds.width * 0.8,
			Window.screenBounds.height * 0.8
		);
	)
	.background_(Color.fromHexString("#2c5aa0ff"));

	var directSynth = SynthDef(\parrotDirect, { |out = 0, in = 0|
		var snd = SoundIn.ar(in);
		Out.ar(out, snd);
	}).play(args: [\out, outChannel, \in, inputChannel]);

	var title = UserView()
	.maxHeight_(200);
	var container = HLayout()
	.margins_(24)
	.spacing_(6);

	var style = GMStyle()
	.mainColor_(Color.fromHexString("#2c5aa0ff"))
	.backColor_(Color.fromHexString("#5485d0ff"))
	.borderColor_(Color.fromHexString("#27508fff"))
	.secondBorderSize_(0)
	.thirdBorderSize_(0)
	.helpersColor_(Color.white);

	var topImage = Image.open(
		folderName
		+/+ "assets/topImg.png"
	);

	var buffers = List(0);

	var addLoop = { |index|
		var view = UserView();
		var helper = GMButton()
		.svg_(folderName +/+ "assets/notPlaying.svg")
		.style_(style);
		var recordButton = GMRecordButton()
		.symbolRatio_(0.6)
		.style_(style);
		var clearButton = GMFeedbackButton()
		.svg_(folderName +/+ "assets/silence.svg")
		.style_(style);
		var amp = 1.0;
		var volumeSlider = GMFaderSlider()
		.value_(amp)
		.displayValue_(false)
		.drawHelpers_(true)
		.helpersStyle_(\dot)
		.helpersRatio_(0.05)
		.helpersNumber_(3)
		.minAlpha_(0.5)
		.style_(style);
		var player = nil;
		var recorder = nil;
		var time;

		var buffer = Buffer.alloc(
			s,
			s.sampleRate * maxLoopLength,
			1,
			{ |buffer|
				buffers.add(buffer);
				1
			}
		);

		var killPlayer = {
			if(player.notNil)
			{ player.set(\gate, 0); };
			helper.svg_(folderName +/+ "assets/notPlaying.svg");
		};

		recordButton.action_({ |isRecording|
			if(isRecording) {
				killPlayer.value;

				recorder = Synth(
					\parrotRecorder,
					[
						\in, inputChannel,
						\buffer, buffer
					]
				);

				time = AppClock.seconds;
			} {
				recorder.set(\gate, 0);
				recorder = nil;

				time = AppClock.seconds - time;

				player = Synth(
					\parrotPlayer,
					[
						\buffer, buffer,
						\duration, time,
						\amp, amp,
					]
				);

				helper.svg_(folderName +/+ "assets/playing.svg");
			};
		});

		volumeSlider.action_({ |value|
			amp = value;
			if(player.notNil)
			{ player.set(\amp, amp); };
		});

		clearButton.action_({ killPlayer.value; });

		view.layout_(
			VLayout()
			.margins_(0)
			.spacing_(12)
			.add(helper, 1)
			.add(recordButton, 1)
			.add(clearButton, 1)
			.add(volumeSlider, 4)
		);

		container.add(view);
	};

	Buffer.freeAll;

	SynthDef(\parrotRecorder, { |in, buffer, gate = 1.0|
		var snd = SoundIn.ar(in);

		// Recording an extra second
		// to avoid clicks
		var killer = EnvGen.kr(
			Env(
				[1, 1, 0],
				[0.01, 1],
				\lin,
				1,
				0
			),
			gate: gate,
			doneAction: Done.freeSelf
		);

		RecordBuf.ar(
			snd,
			bufnum: buffer,
			offset: 0.0,
			recLevel: 1.0,
			preLevel: 0.0,
			run: killer,
			loop: 1.0,
			trigger: 1.0,
			doneAction: 0
		);
	}).add;

	SynthDef(\parrotPlayer, { |out = 0, buffer,
		amp = 1.0, duration = 20.0, gate = 1.0|
		var trigger = Impulse.ar(1 / duration);

		var snd = PlayBuf.ar(
			1,
			buffer,
			1.0,
			trigger: trigger,
			loop: 1.0
		);

		var killer = EnvGen.kr(
			Env(
				[1, 1, 0],
				[0.01, 0.01],
				\lin,
				1,
				0
			),
			gate: gate,
			doneAction: Done.freeSelf
		);

		snd = snd * amp;
		snd = snd * killer;

		Out.ar(out, snd);
	}).add;

	numLoops.do({ addLoop.value; });

	title.drawFunc_({ |view|
		var ratio = 1;

		ratio = min(
			view.bounds.width / 772,
			view.bounds.height / 200
		);

		topImage.free;
		topImage = Image.open(
			folderName +/+ "assets/topImg.png",
		)
		.scalesWhenResized_(true)
		.setSize(
			(772 * ratio).asInteger,
			(200 * ratio).asInteger,
		);

		Pen.drawImage(
			Point(
				(view.bounds.width / 2) - (topImage.width / 2),
				0
			),
			topImage
		);
	});

	win.layout_(
		VLayout()
		.margins_(0)
		.spacing_(0)
		.add(title, 1)
		.add(container, 9)
	);

	win.onClose_({
		if(synthPlaying)
		{ directSynth.free; };
		buffers.do({ |buffer| buffer.free; });
		if(topImage.notNil)
		{ topImage.free; };
	});

	CmdPeriod.doOnce({
		synthPlaying = false;
		win.close;
	});

	View.globalKeyDownAction_({ |view, char, mod, unicode|
		// CTRL + F
		if(unicode == 6) {
			if(fullScreen)
			{ win.endFullScreen; }
			{ win.fullScreen; };
			fullScreen = fullScreen.not;
		};

		// ESC
		if(unicode == 27) { win.close; };
	});

	win.front;
});
)
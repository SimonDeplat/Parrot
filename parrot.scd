(
s.waitForBoot({

	var numLoops = 8;
	var inputChannel = 0;
	var outChannel = 0;
	var maxLoopLength = 20.0;

	// QWERTY layout
	var clearKeys = "qwertyuiop";
	var recordKeys = "asdfghjkl;";
	var muteKeys = "zxcvbnm,./";
	
	// AZERTY layout
	// var clearKeys = "azertyuiop";
	// var recordKeys = "qsdfghjklm";
	// var muteKeys = "wxcvbn,;:!";


	
	////////////////////
	//    SOFTWARE    //
	////////////////////
	var recStates = Array.fill(numLoops, { false });
	var muteStates = Array.fill(numLoops, { 1 });
	var recButtons = Array.fill(numLoops, { nil });
	var muteButtons = Array.fill(numLoops, { nil });
	var clearButtons = Array.fill(numLoops, { nil });
	var times = Array.fill(numLoops, { nil });
	var amps = Array.fill(numLoops, { 1.0 });
	var buffers = Array.fill(numLoops, { nil });
	var players = Array.fill(numLoops, { nil });
	var recorders = Array.fill(numLoops, { nil });

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

	var record = { |index|
		recStates[index] = recStates[index].not;
		
		if(recStates[index]) {
			clear.value(index);
			recorders[index] = Synth(
				\parrotRecorder,
				[
					\in, inputChannel,
					\buffer, buffers[index]
				]
			);
			times[index] = AppClock.seconds;
			recButtons[index].setDisplay(true);
		} {
			recorders[index].set(\gate, 0);
			recorders[index] = nil;
			times[index] = AppClock.seconds - times[index];
			players[index] = Synth(
				\parrotPlayer,
				[
					\buffer, buffers[index],
					\duration, times[index],
					\amp, amps[index],
					\mute, muteStates[index],
				]
			);
			clearButtons[index].svg_(
				folderName +/+ "assets/playing.svg");
			recButtons[index].setDisplay(false);
		};
	};

	var mute = { |index|
 		if(muteStates[index] == 0)
		{ muteStates[index] = 1; }
		{ muteStates[index] = 0; };
		if(players[index].notNil)
		{ players[index].set(\mute, muteStates[index]); };
		muteButtons[index].state_(muteStates[index]);
	};

	var clear = { |index|
		if(players[index].notNil) {
			players[index].set(\gate, 0);
			players[index] = nil;
		};
		clearButtons[index].svg_(
			folderName +/+ "assets/notPlaying.svg");
	};

	var addLoop = { |index|
		var view = UserView();
		var clearButton = GMButton()
		.svg_(folderName +/+ "assets/notPlaying.svg")
		.style_(style)
		.action_({ clear.value(index); });

		var recordButton = GMRecordButton()
		.symbolRatio_(0.6)
		.style_(style)
		.action_({ record.value(index) });
		var muteButton = GMSwitchButton()
		.states_([
			(string: "", color: Color.fromHexString("#5485d0ff"),
				fontColor: Color.black, svg: folderName +/+ "assets/silence.svg"),
			(string: "", color: Color.fromHexString("#5485d0ff"),
				fontColor: Color.black, svg: folderName +/+ "assets/notSilence.svg")
		])
		.state_(1)
		.style_(style)
		.action_({ mute.value(index); });
		var amp = 1.0;
		var volumeSlider = GMFaderSlider()
		.value_(amp)
		.displayValue_(false)
		.displayHelpers_(true)
		.helpersStyle_(\dot)
		.helpersRatio_(0.05)
		.helpersNumber_(3)
		.minAlpha_(0.5)
		.style_(style)
		.action_({ |value|
			amps[index] = value;
			if(players[index].notNil)
			{ players[index].set(\amp, amps[index]); };
		});
		var player = nil;
		var recorder = nil;
		var time;

		buffers[index] = Buffer.alloc(
			s,
			s.sampleRate * maxLoopLength,
			1
		);
		
		recButtons[index] = recordButton;
		clearButtons[index] = clearButton;
		muteButtons[index] = muteButton;

		view.layout_(
			VLayout()
			.margins_(0)
			.spacing_(12)
			.add(HLayout().margins_(10).add(clearButton), 1)
			.add(recordButton, 1)
			.add(HLayout().margins_(10).add(muteButton), 1)
			.add(volumeSlider, 4)
		);

		container.add(view);
	};

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
		amp = 1.0, duration = 20.0, gate = 1.0, mute = 1.0|
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

		snd = snd * amp * Lag.kr(mute);
		snd = snd * killer;

		Out.ar(out, snd);
	}).add;

	numLoops.do({ |index| addLoop.value(index); });

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

		if(clearKeys.includesEqual(char)) {
			var index = clearKeys.indexOfEqual(char);
			if(index <= (numLoops - 1)) {
				clear.value(index);
			};
		};

		if(recordKeys.includesEqual(char)) {
			var index = recordKeys.indexOfEqual(char);
			if(index <= (numLoops - 1)) {
				record.value(index);
			};
		};

		if(muteKeys.includesEqual(char)) {
			var index = muteKeys.indexOfEqual(char);
			if(index <= (numLoops - 1)) {
				mute.value(index);
			};
		};
	});

	win.front;
});
)

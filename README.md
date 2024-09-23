# Parrot

#### Overview

Parrot is a minimalist loop-station built with the SuperCollider language.

#### Installation

You will need SuperCollider to run this project. SuperCollider usage is beyond the scope of this documentation.

You also need to install the GraphicalModule quark to run it. You can use the dedicated interface, or evaluate `Quarks.install("GraphicalModule");` to do so. Then you'll have to recompile the library (re-open SuperCollider or use `CTRL + SHIFT + L`).

If you had the GraphicalModule installed already, make sure it is up-to-date by evaluating `Quarks.update("Graphical-Module")`. Then, recompile.

To run Parrot, evaluate `parrot.scd` within SuperCollider (once configured).

#### Configuration

On top of the code, you can find 5 parameters you might want to modify:

`numLoops` is the number of looping channels.

`inputChannel` is the index of the audio bus you will record. It starts at zero. For example, if your microphone is plugged into the second jack input of your soundcard, this should likely be set to '1'.

`outChannel` is the audio bus the sound will be sent to. This should stay at '0' unless you know what you're doing.

`maxLoopLength` sets the loops maximum duration. This allows to allocate enough memory to record the loops. You should never record a loop that exceeds this length, so plan ahead.

Then, you can find three string variables which defines which keyboard keys will control the software. As an example, `var recordKeys = "asdfghjkl;";` means that the 'a' keyboard key will start/stop the first channel recording, while the 'f' key will control the 4th channel recording, etc.

#### Usage

When the software is running, the input sound always goes through (so be careful with larsens). Then, you have access to an arbitrary number of loops (channels).

For each channel, 4 actions are available:

- **clear**: when a loop is running, clicking the topmost button, which displays a tape recorder, will stop and clear the loop.

- **record**: clicking the record button once will start recording. Clicking it again will stop the recording, and start looping the segment that has been recorded. The channel's topmost button will display a tape recorder, meaning a loop is currently playing. Starting recording an already playing loop will **clear** it immediatly, and start recording.

- **mute**: toggling the rest button will mute/unmute the channel.

- **volume**: a slider allows to mix the channel's volume.

#### Keyboard controls

**clear**, **record** and **mute** actions are also bound to character keys. Those are predefined within the file header.

`CTRL + F` to toggle fullscreen, `ESC` to quit.

#### Limitations

This software aims to be minimimalist, and as such, comes with some limitations :

Loops durations are independant, the only way to synchronize them is to click precisely.

But there might be small timing imprecisions regarding the start and the end of the recording.

Mono input, mono output.

Audio clicks might occur when the loop starts again, depending on certain conditions.

The interface is blue.
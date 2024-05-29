# Parrot

#### Overview

Parrot is a minimalist loop-station built with the SuperCollider language.

#### Installation

You will need SuperCollider to run this project. SuperCollider usage is beyond the scope of this documentation.

You also need to install the GraphicalModule quark to run it. You can use the dedicated interface, or evaluate `Quarks.install("GraphicalModule");` to do so. Then you'll have to recompile the library (re-open SuperCollider or use `CTRL + SHIFT + L`).

Then, evaluate `parrot.scd` within SuperCollider (once configured).

#### Configuration

On top of the code, you can find 4 parameters you might want to modify :

`numLoops` is the number of looping channels.

`inputChannel` is the index of the audio bus you will record. It starts at zero. For example, if your microphone is plugged into the second jack input of your soundcard, this should likely be set to '1'.

`outChannel` is the audio bus the sound will be sent to. This should stay at '0' unless you know what you're doing.

`maxLoopLength` sets the loops maximum duration. This allows to allocate enough memory to record the loops. You should never record a loop that exceeds this length, so plan ahead.

#### Usage

When the software is running, the input sound always goes through. Then, you have an arbitrary number of loops.

For each channel :

Clicking the record button once will start recording. Clicking it again will stop the recording, and start looping the segment that has been recorded.

Clicking the silence button will remove the loop.

Then, there's a slider that allows to control the volume of the loop.

On top of those controls, there's a visual hint indicating if there's a loop currently playing, or not.

`CTRL + F` to toggle fullscreen, `ESC` to quit.

#### Limitations

This software aims to be minimimalist, and as such, comes with some limitations :

Loops durations are independant, the only way to synchronize them is to click precisely.

But there might be small timing imprecisions regarding the start and the end of the recording.

Mono input, mono output.

Audio clicks might occur when the loop starts again, depending on certain conditions.

The interface is blue.
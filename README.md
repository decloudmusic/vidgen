vidgen - framework for video generation
==========================================

This is a framework that enables you to generate a video based on
input waveforms. These waveforms can be music, or used as automation
clips like in digital music production.

Usage
-----
After `git clone`, run `sh framework.sh` with as arguments:

 1. format: For example `1920x1080p60` for 1080p video at a framerate
    of 60.
 2. mapper: A program that, given the format and the framefile as
    input, generates one frame of video.
 3. cache: The directory where all data that can be regenerated is
    kept. Can be deleted without loss of information.
 4. audio...: `.wav` files that will be chopped up to generate the
    framefiles. The first one will only be used as the audio track
    for the video, and the length will be calculated from it.

This will set up a makefile that can be called from the same directory
that `framework.sh` was called from with (probably)
`make -f ${cache}/${format}.mk`. The given mapper will be called as
`${mapper} ${format} <${framefile} >${image}` for each frame.

Formats
-------
  - `format`: the format of the video. Resolution and framerate,
    encoded as `${width}x${height}p${fps}`.
  - `frame`: the 'timecode'. Seconds, with as many leading zeroes
    as needed, and the frame in that second, both starting from
    zero. Encoded as `${second}.${frame}`
  - framefile: a file or input stream with `${audiofile}: ${value}\n`
    for every input audio.

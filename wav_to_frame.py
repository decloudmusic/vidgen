#!/usr/bin/env python
#wav_to_frame.py - create frame information files from tracks
import contextlib, wave, struct, sys

fps = int(sys.argv[1].split('p')[1])
numfmt = sys.argv[2]
path = sys.argv[3]

with contextlib.closing(wave.open(path, 'rb')) as w:
    freq = w.getframerate() // fps
    bit = w.getsampwidth()
    channels = w.getnchannels()
    for i in range(0, w.getnframes() // freq):
        frames = bytes(w.readframes(freq if i != 0 else freq // 2))
        split = (bytes(frames[i:i + bit]) for i in range(0, len(frames), bit))
        padded = [(b'\0' if len(x) == 3 else b'') + x for x in split]
        normalized = [abs(struct.unpack('<' + '_Bh_i'[len(chunk)], chunk)[0]
            / 2.0 ** (8 * len(chunk) - 1)) for chunk in padded]
        value = max(normalized)
        print(numfmt % (i // fps, i % fps) + ': ' + str((value)))
    i += 1
    print(numfmt % (i // fps, i % fps) + ': ' + str(0.0))

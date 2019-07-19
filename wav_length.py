#/usr/bin/env python
import wave, contextlib, sys
with contextlib.closing(wave.open(sys.argv[1], 'r')) as f:
    print(f.getnframes() / float(f.getframerate()))

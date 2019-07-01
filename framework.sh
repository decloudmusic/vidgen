#!/usr/bin/env sh
#framework.sh - create video makefile from configuration

# FUNCTIONS -------------------------------------------------------------------
to_make() {
    printf "$@" >>"$makefile"
}

timecode() { #1: frame 2: fps, numfmt
    printf "$numfmt" "$(echo "$1/$2"|bc)" "$(echo "$1%$2"|bc)"
}

wav_get_length() { #1: wavfile
    python -c '
import wave, contextlib, sys
with contextlib.closing(wave.open(sys.argv[1],"r")) as f:
    print(f.getnframes() / float(f.getframerate()))
    ' "$1"
}

# MAIN ------------------------------------------------------------------------
[ "$#" = 2 ] || { echo "Usage: $0 format audio"; exit 1; }
w="${1%%x*}"
h="$(echo "$1"| sed 's/[0-9]*x\([0-9]*\)p[0-9]*/\1/')"
fps="${1##*p}"
audiofile="$2"
length="$(echo "$fps * $(wav_get_length "$audiofile") + 1"|bc|sed 's/\..*//')"
format="${w}x${h}p${fps}"
numfmt="%0$(echo "length($length/$fps)"|bc)d.%0$(echo "length($fps)"|bc)d"
makefile="Makefile.$format"

:>"$makefile"
to_make "${format}.mp4: "
for i in $(seq 0 "$(( $length - 1 ))"); do
    to_make "${format}_$(timecode "$i" "$fps").png "
done
to_make '\n'
to_make "\t%s%s\n" \
    "ffmpeg -framerate $fps -y -pattern_type glob -i \"${format}_*.png\" " \
    "-i \"$audiofile\" -c:a aac ${format}.mp4"


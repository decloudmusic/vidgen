#!/usr/bin/env sh
#framework.sh - create video makefile from configuration

# POLYFILLS -------------------------------------------------------------------
abspath() { #1: path
    set -- "$1" "$(pwd)" "$(dirname "$1")" #2: cwd, 3: dir
    [ "$3" != "." ] && cd "$3"
    set -- "$@" "$(pwd)/$(basename "$1")" #4: abspath
    cd "$2"
    echo "$4"
}

relpath() { #1: basepath, 2: path; 3: prefix, 4: dots
    set -- "$(echo "$1/"|sed 's_^[^/.]_./&_;s_//*_/_g')" "$2"
    set -- "$1" "$(echo "${2%/}"|sed 's_^[^/]_./&_;s_//*_/_g')"
    set -- "$@" "$(printf '%s//%s' "$1" "$2" | sed 's_\(.*/\).*//\1.*_\1_')"
    set -- "$@" "$(echo "${1#$3}" | sed 's/[^/][^/]*/../g')"
    echo "$4${2#$3}"
}

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
[ "$#" -lt 3 ] && { echo "Usage: $0 format cache audio"; exit 1; }
w="${1%%x*}"
h="$(echo "$1"| sed 's/[0-9]*x\([0-9]*\)p[0-9]*/\1/')"
fps="${1##*p}"
cache="$2"
audiofile="$(relpath . "$3")"
format="${w}x${h}p${fps}"
length="$(echo "$fps * $(wav_get_length "$audiofile") + 1"|bc|sed 's/\..*//')"
numfmt="%0$(echo "length($length/$fps)"|bc)d.%0$(echo "length($fps)"|bc)d"
makefile="$cache/$format.mk"

mkdir -p "$cache"

:>"$makefile"
to_make "$(relpath . "$cache/${format}.mp4"): "
for i in $(seq 0 "$(( $length - 1 ))"); do
    to_make "$(relpath . "$cache/${format}_$(timecode "$i" "$fps").png") "
done
to_make '\n'
to_make "\t%s%s%s\n" \
    "ffmpeg -framerate $fps -y -pattern_type glob " \
    "-i \"$(relpath . "$cache/${format}_*.png")\" " \
    "-i \"$audiofile\" -c:a aac '$cache/${format}.mp4'"
to_make "\n"


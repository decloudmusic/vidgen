#!/usr/bin/env sh
#framework.sh - create video makefile from configuration

# FUNCTIONS -------------------------------------------------------------------
to_make() {
    printf "$@" >>"$makefile"
}

timecode() { #1: frame 2: fps, numfmt
    printf "$numfmt" "$(echo "$1/$2"|bc)" "$(echo "$1%$2"|bc)"
}

wav_length() { #1: path
    python "${VIDGEN_PATH:+$VIDGEN_PATH/}wav_length.py" "$@"
}

wav_to_frame() { #1: fps, 2: numfmt, 3: path
    python "${VIDGEN_PATH:+$VIDGEN_PATH/}wav_to_frame.py" "$@"
}

lineinfile() { #1: path, 2: regexp, 3: line
    ex -sc"g/$3/q" -c"/$2/d" -c"i|$3" -cx "$1"
}

# MAIN ------------------------------------------------------------------------
[ "$#" -lt 4 ] && { echo "Usage: $0 format mapper cache audio..."; exit 1; }
VIDGEN_PATH="${VIDGEN_PATH:-$(dirname "$0")}"
w="${1%%x*}"
h="$(echo "$1"| sed 's/[0-9]*x\([0-9]*\)p[0-9]*/\1/')"
fps="${1##*p}"
cache="$3"
mapper="$([ -f "$2" ] && echo "./$2" || echo "$2")"
audiofile="$4"
format="${w}x${h}p${fps}"
length="$(echo "$fps * $(wav_length "$audiofile") + 1" | bc | sed 's/\..*//')"
numfmt="%0$(echo "length($length/$fps)"|bc)d.%0$(echo "length($fps)"|bc)d"
makefile="$cache/$format.mk"

mkdir -p "$cache"

# Makefile header
:>"$makefile"
to_make ".POSIX:\n"
to_make ".SUFFIXES:\n"
to_make "\n"

# Reduce images to mp4
to_make "$cache/${format}.mp4: "
for i in $(seq 0 "$(( $length - 1 ))"); do
    to_make "$cache/${format}_$(timecode "$i" "$fps").png "
done
to_make '\n'
to_make "\t%s%s%s\n" \
    "ffmpeg -framerate $fps -y -pattern_type glob " \
    "-i \"$cache/${format}_*.png\" " \
    "-i \"$audiofile\" -c:a aac '$cache/${format}.mp4'"
to_make "\n"

#map parameters to image
to_make ".SUFFIXES: .f .png\n"
to_make ".f.png:\n"
to_make "\t$mapper $format <'\$<' >'\$@'\n"

shift 4
for x in "$@"; do
    [ "$x" -ot "$cache/${x%.wav}.p$fps.frames" ] || \
        wav_to_frame "$format" "$numfmt" "$x" >"$cache/${x%.wav}.p$fps.frames"
    while IFS= read -r line; do
        lineinfile "$cache/${format}_${line%: *}.f" "^${x%.wav}: " \
            "${x%.wav}: ${line#*: }" || true
    done <"$cache/${x%.wav}.p${fps}.frames"
done

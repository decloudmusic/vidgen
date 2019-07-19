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

wav_length() { #1: path
    python ./wav_length.py "$@"
}

wav_to_frame() { #1: fps, 2: numfmt, 3: path
    python ./wav_to_frame.py "$@"
}

lineinfile() { #1: path, 2: regexp, 3: line
    [ -e "$1" ] && grep -qF "$3" "$1" && return 0
    touch "$1"
    ex -sc"/$2/d|a|$3" -cx "$1" </dev/null
    grep -qF "$3" "$1" && return 1
    echo "$3" >>"$1"
    return 1
}

# MAIN ------------------------------------------------------------------------
[ "$#" -lt 4 ] && { echo "Usage: $0 format mapper cache audio..."; exit 1; }
w="${1%%x*}"
h="$(echo "$1"| sed 's/[0-9]*x\([0-9]*\)p[0-9]*/\1/')"
fps="${1##*p}"
cache="$3"
mapper="$([ -f "$2" ] && relpath . "./$2" || echo "$2")"
audiofile="$(relpath . "$4")"
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

#map parameters to image
to_make ".SUFFIXES: .f .png\n"
to_make ".f.png:\n"
to_make "\t$mapper $format '\$<'\n"

shift 3
for x in "$@"; do
    wav_to_frame "$format" "$numfmt" "$x" >"$cache/${x%.wav}.p${fps}.frames"
    while IFS= read -r line; do
        lineinfile "$cache/${format}_${line%: *}.f" "^${x%.wav}: " \
            "${x%.wav}: ${line#*: }" || true
    done <"$cache/${x%.wav}.p${fps}.frames"
done

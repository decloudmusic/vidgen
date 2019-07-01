#!/usr/bin/env sh
#framework.sh - create video makefile from configuration

# FUNCTIONS -------------------------------------------------------------------
to_make() {
    printf "$@" >>"$makefile"
}

timecode() { #1: frame 2: fps, numfmt
    printf "$numfmt" "$(echo "$1/$2"|bc)" "$(echo "$1%$2"|bc)"
}

# MAIN ------------------------------------------------------------------------
[ "$#" = 4 ] || { echo "Usage: $0 width height fps length"; exit 1; }
w="$1"
h="$2"
fps="$3"
length="$4"
cfgfmt="${w}x${h}p${3}"
numfmt="%0$(echo "length($length/$fps)"|bc)d.%0$(echo "length($fps)"|bc)d"
makefile="Makefile.$cfgfmt"

:>"$makefile"
to_make "output.mp4: "
for i in $(seq 0 "$length"); do
    to_make "${cfgfmt}_$(timecode "$i" "$fps").png "
done
to_make "\n"
to_make "\tffmpeg -framerate $fps -y -pattern_type glob -i \"${cfgfmt}_*.png\" ${format}.mp4\n"


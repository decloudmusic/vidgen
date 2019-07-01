#!/usr/bin/env sh
#framework.sh - create video makefile from configuration

# FUNCTIONS -------------------------------------------------------------------
to_make() {
    printf "$@" >>"$makefile"
}

# MAIN ------------------------------------------------------------------------
[ "$#" = 4 ] || { echo "Usage: $0 width height fps length"; exit 1; }
w="$1"
h="$2"
fps="$3"
length="$4"
cfgfmt="${w}x${h}p${3}"
numfmt="%0$(echo "length($length)" | bc)d"
makefile="Makefile.$cfgfmt"

:>"$makefile"
to_make "output.mp4: "
for i in $(seq 0 "$length"); do
    to_make "${cfgfmt}_$(printf "$numfmt" "$i").png "
done
to_make "\n"
to_make "\tffmpeg -r "$fps" -i \"${cfgfmt}_%${numfmt}.png\" output.mp4"


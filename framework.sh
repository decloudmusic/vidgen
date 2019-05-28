#!/usr/bin/env sh
#framework.sh - create video makefile from configuration

[ "$#" = 4 ] || { echo "Usage: $0 width height fps length"; exit 1; }
w="$1"
h="$2"
fps="$3"
length="$4"
cfgfmt="${w}x${h}p${3}"
numfmt="%0$(echo "length($length)" | bc)d"
makefile="Makefile.$cfgfmt"

:>"$makefile"
printf "output.mp4: " >>"$makefile"
for i in $(seq 0 "$length"); do
    printf "${cfgfmt}_$(printf "$numfmt" "$i").png " >>"$makefile"
done
printf "\n" >>"$makefile"
printf "\tffmpeg -r "$fps" -i \"${cfgfmt}_%${numfmt}.png\" output.mp4" \
    >>"$makefile"



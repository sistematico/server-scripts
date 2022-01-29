#!/usr/bin/env bash

if [ $1 ]; then
    playlist="/opt/liquidsoap/playlist/${1}.m3u"
    music="/opt/liquidsoap/music/${1}"
    
    [ ! -f $playlist ] && find $music -type f -iname "*.mp3" > $playlist

    if [ $(find $music -type f -iname "*.mp3" | wc -l) -ne $(cat $playlist | wc -l) ]; then
        find ${music} -type f -iname "*.mp3" > $playlist
    fi
fi
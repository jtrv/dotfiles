#!/bin/sh

amixer set Master 5%-;
VOLUME_LEVEL="$(amixer get Master | awk -F'[][]' 'END{ print $2 }')";
notify-send -t 2500 "Volume" "Lowered: $VOLUME_LEVEL"


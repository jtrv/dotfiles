#!/bin/bash

amixer -D pulse sset Master toggle;
VOLUME_LEVEL="$(amixer get Master | awk -F'[][]' 'END{ print $4 }')";
notify-send -t 2500 "Volume" "Toggled $VOLUME_LEVEL"


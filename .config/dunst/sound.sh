#!/bin/bash

# Get the notification urgency level
URGENCY="$3"

# Define sound files for different urgency levels
SOUND_LOW="/usr/share/sounds/freedesktop/stereo/message.oga"
SOUND_NORMAL="/usr/share/sounds/freedesktop/stereo/message.oga"
SOUND_CRITICAL="/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"

# Play the appropriate sound based on urgency
case "$URGENCY" in
"LOW")
  paplay "$SOUND_LOW" --volume=50 &
  ;;
"NORMAL")
  paplay "$SOUND_NORMAL" --volume=70 &
  ;;
"CRITICAL")
  paplay "$SOUND_CRITICAL" --volume=100 &
  ;;
esac

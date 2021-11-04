#! /bin/sh
# With icon indicating the state of the mic

state=`amixer -D pulse set Capture toggle | gawk 'match($0, /(Front Left|Mono).*\[(.*)\]/, a) {print a[2]}'`
if [ "$state" = "off" ]; then
    icon="microphone-sensitivity-muted-symbolic"
else
    icon="audio-input-microphone-symbolic"
fi
notify-send --hint=int:transient:1 -i $icon "Mic switched: $state"

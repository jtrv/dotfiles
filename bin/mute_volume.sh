amixer set Master Toggle;
VOLUME_LEVEL="$(amixer get Master | awk -F'[][]' 'END{ print $4 }')";
notify-send -t 2500 "Volume" "Toggled $VOLUME_LEVEL"


 !/bin/bash
# Example Bar Action Script for Linux.

##############################
#    CPU
##############################
cpu() {
  read cpu a b c previdle rest < /proc/stat
  prevtotal=$((a+b+c+previdle))
    sleep 0.5
  read cpu a b c idle rest < /proc/stat
  total=$((a+b+c+idle))
  percent=$((100*( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))

  cpu=$(printf %3d $percent)
  echo -e "$cpu%"
}
##############################
#    RAM
##############################
ram() {
  used="$(free | grep Mem: | awk '{print $3}')"
  total="$(free | grep Mem: | awk '{print $2}')"
  
  percent=$(( 200 * $used/$total - 100 * $used/$total ))
  ram=$(printf %3d $percent)
  
  echo -e "$ram%"
}
##############################
#    STORAGE
##############################
ssd() {
  SSD="$(df -h /home | grep /dev | awk '{print $5}')"
    echo -e " $SSD"
}
##############################
#    MIC
##############################
mic() {
  state=`amixer -D pulse get Capture toggle | gawk 'match($0, /(Front Left|Mono).*\[(.*)\]/, a) {print a[2]}'`

  if [ "$state" = "on" ]; then
    echo ""
  else
    echo ""
  fi
}
##############################
#    NETWORK
##############################
network() {
  wire="$(mullvad status | rg Connected | wc -l)"
  wifi="$(ip a | grep wlp61s0 | grep UP | wc -l)"

  if [ $wire = 1 ]; then
    echo ""
  elif [ $wifi = 1 ]; then
    echo ""
  else
    echo "睊"
  fi
}
##############################
#    BLUETOOTH
##############################
bluetooth() {
  bluetoothStatus="$(bluetoothctl info | rg 'Connected: yes' | wc -l)"

  if [ $bluetoothStatus = 1 ]; then
    echo ""
  else
    echo ""
  fi
}
##############################
#    BATTERY
##############################
bat() {
  batstat="$(cat /sys/class/power_supply/BAT0/status)"
  percent="$(cat /sys/class/power_supply/BAT0/capacity)"
  if [ $batstat = 'Unknown' ]; then
    batstat=""
  elif [[ $percent -ge 5 ]] && [[ $percent -le 19 ]]; then
    batstat=""
  elif [[ $percent -ge 20 ]] && [[ $percent -le 39 ]]; then
    batstat=""
  elif [[ $percent -ge 40 ]] && [[ $percent -le 59 ]]; then
    batstat=""
  elif [[ $percent -ge 60 ]] && [[ $percent -le 79 ]]; then
    batstat=""
  elif [[ $percent -ge 80 ]] && [[ $percent -le 95 ]]; then
    batstat=""
  elif [[ $percent -ge 96 ]] && [[ $percent -le 100 ]]; then
    batstat=""
  fi

  battery=$(printf %3d $percent)

  echo "$batstat$battery%"
}
##############################
#    VOLUME
##############################
# vol() {
#   percent="$(amixer get Master | awk -F'[][]' 'END{ print $2 }')"
#   vol=$(printf %3d $percent)
#   echo -e "$vol%"
# }
##############################
#    WEATHER
##############################
# weather() {
#   wthr="$(sed 20q ~/.config/weather.txt | grep value | awk '{print $2 $3}' | sed 's/"//g')"
#   echo " $wthr"
# }
##############################
#    TEMP
##############################
# temp() {
#   tmp="$(grep temp_F ~/.config/weather.txt | awk '{print $2}' | sed 's/"//g' | sed 's/,/ F/g')"
#   echo " $tmp"
# }
##############################
#    PACKAGES
##############################
# pkgs() {
#   pkgs="$(pacman -Q | wc -l)"
#   echo -e "$pkgs"
# }
##############################
#    UPGRADES
##############################
# upgrades() {
#   upgrades="$(pacman -Qu | wc -l)"
#   echo -e "$upgrades"
# }
##############################
#    BAR RENDER
##############################
SLEEP_SEC=2
#loops forever outputting a line every SLEEP_SEC secs
while :; do
  echo "$(cpu) $(ram) $(ssd) | $(mic) $(network) $(bluetooth) | $(bat) |"
  sleep $sleep_sec
done

# this script is for frankensteining my laptop settings to my desktop monitor and peripherals
function megazord
  setxkbmap us -option ctrl:nocaps &&	# *holding* capslock = ctrl
  trackball-speed &&                  # set thumbball sensitivity
  bass mons -s &&                     # display on second monitor only
  feh --randomize --bg-scale --no-fehbg ~/pictures/wallpapers/ # adjust wallpaper for monitor
end

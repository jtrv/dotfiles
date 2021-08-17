# this script is for frankensteining my laptop to my desktop monitor and peripherals
function megazord
  setxkbmap us -option ctrl:nocaps &&	# *holding* capslock = ctrl
  xcape -e 'Control_L=Escape' &&      # *tapping* capslock = escape
  trackball-speed &&                  # function for sensitivity
  bass mons -s &&                     # display to second monitor only
  feh --randomize --bg-scale --no-fehbg ~/Pictures/wallpapers/
end

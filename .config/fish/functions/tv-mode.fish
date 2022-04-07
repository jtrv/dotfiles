# this script is for frankensteining my laptop to my desktop monitor and peripherals
function tv-mode
  mons -m &
  pactl set-card-profile 41 output:hdmi-stereo-extra1
end

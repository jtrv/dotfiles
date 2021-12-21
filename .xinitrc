#!/bin/sh

# prepare greeting
~/scripts/set-greeting.sh &

userresources=$HOME/.config/.Xresources
usermodmap=$HOME/.config/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
if [ -f $sysresources ]; then
  xrdb -merge $sysresources
fi
if [ -f $sysmodmap ]; then
  xmodmap $sysmodmap
fi
if [ -f "$userresources" ]; then
  xrdb -merge "$userresources"
fi
if [ -f "$usermodmap" ]; then
  xmodmap "$usermodmap"
fi

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
  for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

xrandr --output virtual-1 --mode 3440x1440

# randomized wallpapers
feh --randomize --bg-scale --no-fehbg ~/pictures/wallpapers/ &

dunst &                             # notifications
ntpd start &                        # time-sync
picom -f &                          # allow for opacities
redshift -l 34:-119 -b 1.0:0.6 &    # bluelight filter
udiskie -An --terminal=lf &         # notify mountable drives
~/scripts/low-battery.sh &          # low-battery notifications
~/scripts/rclone-init.sh &          # start rclone daemons
setxkbmap us -option ctrl:nocaps && # *holding* capslock = ctrl
xcape -e 'Control_L=Escape' &       # *tapping* capslock = escape

exec spectrwm

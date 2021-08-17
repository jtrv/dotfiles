#!/bin/sh

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

xrandr --output virtual-1 --mode 1920x1080
nitrogen --restore &                # wallpaper
picom -f &                          # allow for opacities
ntpd start &                        # time-sync
dunst &                             # notifications
redshift -l 34:-119 &               # bluelight filter
~/bin/low-battery.sh &              # low-battery notifications
trackball-speed &                   # function for sensitivity
setxkbmap us -option ctrl:nocaps &&	# *holding* capslock = ctrl
xcape -e 'Control_L=Escape' &       # *tapping* capslock = escape
rclone mount mxsdrive: ~/mxs/drive --daemon --fast-list &
rclone mount mxsftp: ~/mxs/ftp --daemon &
exec spectrwm

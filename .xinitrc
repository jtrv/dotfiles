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
nitrogen --restore & # wallpaper
picom -f & # allow for opacities
ntpd start & # time-sync
dunst & # notifications
redshift -l 34:-119 &  # bluelight filter
setxkbmap us -option ctrl:nocaps &&	# capslock = ctrl key
xcape -e 'Control_L=Escape' & # (capslock) ctrl = escape when tapped
kak -d -s sesh &  # kakoune daemon
rclone mount --daemon mxsdrive: ~/mxs/drive &
rclone mount --daemon mxsftp: ~/mxs/ftp &
exec spectrwm

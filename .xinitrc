#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
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

setxkbmap us -option ctrl:nocaps &	# capslock is ctrl key
xcape -e 'Control_L=Escape' & 		# ctrl key is escape when tapped
xrandr --output virtual-1 --mode 1920x1080
nitrogen --restore &
picom -f &
kak -d -s sesh &  # kakoune daemon for better performance
redshift -l 34:-119 &  # bluelight filter
exec spectrwm

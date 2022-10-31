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
if [ -d /etc/X11/xinit/xinitrc.d ]; then
	for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
		[ -x "$f" ] && . "$f"
	done
	unset f
fi

xrandr --output virtual-1 --mode 1920x1080

easyeffects --gapplication-service & # autoEQ service
mons -a &                            # fallback on main monitor
pcmanfm --daemon-mode &              # file-manager daemon
picom -f &                           # allow for opacities
redshift &                           # bluelight filter
udiskie -An --terminal=lf &          # notif for mountable drives
~/.local/bin/map-keys &              # map caps to ctrl/esc
~/.local/bin/rclone-init &           # start rclone daemons
~/.local/bin/trackball-speed &       # set trackball speed

# randomized wallpapers
feh --randomize --bg-scale --no-fehbg ~/media/pictures/wallpapers/ &

# startup sound
mpv --no-config --no-video ~/.config/sounds/ps2.flac &

exec spectrwm

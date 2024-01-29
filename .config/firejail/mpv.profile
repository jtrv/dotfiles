whitelist ${HOME}
read-only ${HOME}

ignore dbus-user none
dbus-user filter

dbus-user.own org.mpris.MediaPlayer2.mpv

include /etc/firejail/mpv.profile

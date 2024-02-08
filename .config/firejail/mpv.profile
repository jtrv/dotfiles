whitelist ${HOME}/downloads
whitelist ${HOME}/media

ignore dbus-user none
dbus-user filter

dbus-user.own org.mpris.MediaPlayer2.mpv

read-only ${HOME}/downloads
read-only ${HOME}/media

include /etc/firejail/mpv.profile

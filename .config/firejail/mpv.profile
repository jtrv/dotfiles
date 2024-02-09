whitelist ${HOME}/downloads
whitelist ${HOME}/media
whitelist ${HOME}/repos

read-only ${HOME}/downloads
read-only ${HOME}/media
read-only ${HOME}/repos

ignore noexec /tmp
ignore apparmor

private-bin bash,chmod,echo,ps,socat,tail,uname
private-tmp

ignore dbus-user none
dbus-user filter

dbus-user.own org.mpris.MediaPlayer2.mpv

include allow-bin-sh.inc
include /etc/firejail/mpv.profile

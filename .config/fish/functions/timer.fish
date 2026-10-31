# timer 25m tea  ->  desktop notification in 25m. systemd transient timer, no daemon.
# pending: systemctl --user list-timers   cancel: systemctl --user stop timer-<name>.timer
function timer -a delay -d 'notify after a delay (systemd time span: 10s, 25m, 1h30m)'
	set -l msg $argv[2..]
	test -n "$delay" -a -n "$msg"; or begin; echo 'usage: timer <delay> <message>' >&2; return 2; end
	systemd-run --user --quiet --on-active=$delay --timer-property=AccuracySec=1s \
		--unit=timer-(string replace -ra '[^a-z0-9]+' - (string lower "$msg")) \
		notify-send -u critical -a timer "$delay is up" "$msg"
end

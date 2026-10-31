# alarm 07:30 standup  ->  desktop notification at 07:30. systemd transient timer, no daemon.
# pending: systemctl --user list-timers   cancel: systemctl --user stop alarm-<name>.timer
function alarm -a when -d 'notify at a calendar time (systemd calendar spec: 07:30, "Mon 09:00", 2026-09-01 12:00)'
	set -l msg $argv[2..]
	test -n "$when" -a -n "$msg"; or begin; echo 'usage: alarm <calendar-time> <message>' >&2; return 2; end
	systemd-run --user --quiet --on-calendar="$when" --timer-property=AccuracySec=1s \
		--unit=alarm-(string replace -ra '[^a-z0-9]+' - (string lower "$msg")) \
		notify-send -u critical -a alarm "$when" "$msg"
end

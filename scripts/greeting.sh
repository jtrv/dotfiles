#!/bin/sh
GREETING=~/.config/greeting
{
	~/scripts/weather.sh &&
		iching
} >"$GREETING" &&
	kak -e "kakpipe -n greeting -- bat $GREETING" &&
	topgrade

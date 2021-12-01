#!/usr/bin/env sh
kak -e "kakpipe -n greeting -- bat $GREETING" &&
topgrade &&
btm

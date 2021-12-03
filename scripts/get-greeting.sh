#!/bin/bash

kak -e "kakpipe -n greeting -- bat $GREETING" &&
topgrade &&
btm


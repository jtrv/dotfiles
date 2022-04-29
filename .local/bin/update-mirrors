#!/bin/sh
# update mirrors and database
TMPFILE=$(mktemp)
rate-mirrors --save="$TMPFILE" arch --max-delay=43200 &&
	doas mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup &&
	doas mv "$TMPFILE" /etc/pacman.d/mirrorlist &&
	paru -Syy

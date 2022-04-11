#!/bin/sh

doas podman run \
	--detach \
	--label "io.containers.autoupdate=registry" \
	--name jellyfin \
	--publish 8096:8096/tcp \
	--rm \
	--user 1001:1001 \
	--userns keep-id \
	--volume /home/jellyfin/.cache:/cache \
	--volume /home/jellyfin/.config:/config \
	--volume /home/jellyfin/movies:/movies \
	--volume /home/jellyfin/series:/series \
	--volume /home/jellyfin/music:/music \
	--volume /home/jellyfin/library:/library \
	--volume /home/jellyfin/anime/movies/:/anime/movies \
	--volume /home/jellyfin/anime/series/:/anime/series \
	docker.io/jellyfin/jellyfin:latest

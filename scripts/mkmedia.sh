#!/bin/sh
set -e

sudo install -d -m 755 -o root -g media /media
sudo install -d -m 775 -o root -g media /media/shows
sudo install -d -m 775 -o root -g media /media/movies
sudo install -d -m 775 -o root -g media /media/downloads
sudo install -d -m 775 -o root -g media /media/downloads/torrents
sudo install -d -m 775 -o root -g media /media/downloads/.incomplete

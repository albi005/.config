#!/bin/sh
set -e

sudo install -d -m 755 -o root -g media /media
sudo install -d -m 775 -o root -g media /media/shows
sudo install -d -m 775 -o root -g media /media/movies
sudo install -d -m 775 -o root -g media /media/torrents
sudo install -d -m 775 -o root -g media /media/torrents/.incomplete
sudo install -d -m 775 -o root -g media /media/torrents/.torrents # .torrent files
sudo install -d -m 775 -o root -g media /media/torrents/shows
sudo install -d -m 775 -o root -g media /media/torrents/movies

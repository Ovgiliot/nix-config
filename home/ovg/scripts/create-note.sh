#!/bin/sh
mkdir -p ~/Documents/home/inbox
cd ~/Documents/home
exec nvim inbox/$(date +"%Y-%m-%d_%H-%M-%S.md")

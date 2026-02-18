#!/bin/sh
mkdir -p ~/Documents/org/inbox
cd ~/Documents/org
exec nvim inbox/$(date +"%Y-%m-%d_%H-%M-%S.org")

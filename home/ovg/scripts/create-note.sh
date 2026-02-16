#!/bin/sh
mkdir -p ~/Documents/home/inbox
exec nvim ~/Documents/home/inbox/$(date +"%Y-%m-%d_%H-%M-%S.md")

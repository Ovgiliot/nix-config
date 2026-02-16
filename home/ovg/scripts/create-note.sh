#!/bin/sh
mkdir -p ~/Documents/notes/inbox
exec nvim ~/Documents/notes/inbox/$(date +"%Y-%m-%d_%H-%M-%S.md")

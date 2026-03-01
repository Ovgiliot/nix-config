#!/usr/bin/env bash
# Cycles power profile: performance → balanced → power-saver → performance.

current=$(powerprofilesctl get 2>/dev/null || true)
case "$current" in
performance) powerprofilesctl set balanced ;;
balanced) powerprofilesctl set power-saver ;;
power-saver) powerprofilesctl set performance ;;
*) powerprofilesctl set balanced ;;
esac

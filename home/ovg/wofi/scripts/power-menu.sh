#!/usr/bin/env bash

# Define options
OPTIONS="Auto
Performance
Balanced
Power Saver"

# Show menu
SELECTED=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power Profile")

# Handle selection
case "$SELECTED" in
    "Auto")
        echo "auto" > /tmp/power_profile_override
        notify-send "Power Profile" "Switched to Automatic Mode"
        ;;
    "Performance")
        echo "performance" > /tmp/power_profile_override
        notify-send "Power Profile" "Manual Override: Performance"
        ;;
    "Balanced")
        echo "balanced" > /tmp/power_profile_override
        notify-send "Power Profile" "Manual Override: Balanced"
        ;;
    "Power Saver")
        echo "power-saver" > /tmp/power_profile_override
        notify-send "Power Profile" "Manual Override: Power Saver"
        ;;
esac

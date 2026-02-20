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
        systemctl --user restart power-monitor
        ;;
    "Performance")
        echo "performance" > /tmp/power_profile_override
        systemctl --user restart power-monitor
        ;;
    "Balanced")
        echo "balanced" > /tmp/power_profile_override
        systemctl --user restart power-monitor
        ;;
    "Power Saver")
        echo "power-saver" > /tmp/power_profile_override
        systemctl --user restart power-monitor
        ;;
esac

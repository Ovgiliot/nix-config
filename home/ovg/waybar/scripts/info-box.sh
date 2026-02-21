#!/usr/bin/env bash

# Function to get media info
get_media_info() {
    player_status=$(playerctl status 2>/dev/null)
    if [ "$player_status" = "Playing" ] || [ "$player_status" = "Paused" ]; then
        artist=$(playerctl metadata artist)
        title=$(playerctl metadata title)
        icon="󰎈"
        [ "$player_status" = "Paused" ] && icon="󰏤"
        
        # Truncate if too long
        text="$icon $artist - $title"
        if [ ${#text} -gt 60 ]; then
            text="${text:0:57}..."
        fi
        
        echo "{\"text\": \"$text\", \"class\": \"$player_status\", \"alt\": \"$player_status\"}"
    else
        # For now, if no media, show nothing or we could show system status
        echo "{\"text\": \"\", \"class\": \"none\"}"
    fi
}

get_media_info

#!/usr/bin/env bash

# Function to get system warnings
get_warning() {
    # 1. Battery: Unplugged and below 20%
    BAT_PATH="/sys/class/power_supply/BAT1"
    AC_PATH="/sys/class/power_supply/AC"
    if [ -d "$BAT_PATH" ] && [ -d "$AC_PATH" ]; then
        capacity=$(cat "$BAT_PATH/capacity")
        online=$(cat "$AC_PATH/online")
        if [ "$online" -eq 0 ] && [ "$capacity" -lt 20 ]; then
            echo "󰂃 Low Battery: $capacity%"
            return 0
        fi
    fi

    # 2. CPU Temperature: Above 95C
    max_temp=0
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$zone" ]; then
            t=$(cat "$zone")
            t=$((t / 1000))
            [ "$t" -gt "$max_temp" ] && max_temp=$t
        fi
    done
    if [ "$max_temp" -gt 95 ]; then
        echo " High Temp: ${max_temp}°C"
        return 0
    fi

    # 3. Disk Usage: Above 90%
    disk_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$disk_usage" -gt 90 ]; then
        echo "󰋊 Disk Full: $disk_usage%"
        return 0
    fi

    # 4. RAM Usage: Above 90%
    ram_usage=$(free | awk '/Mem:/ { printf("%.0f"), $3/$2 * 100 }')
    if [ "$ram_usage" -gt 90 ]; then
        echo "󰍛 High RAM: $ram_usage%"
        return 0
    fi

    # 5. CPU Usage: Above 90%
    # Accurate CPU usage calculation by sampling /proc/stat
    read -r cpu a b c d e f g h i < /proc/stat
    prev_total=$((a+b+c+d+e+f+g+h+i))
    prev_idle=$d
    sleep 0.2
    read -r cpu a b c d e f g h i < /proc/stat
    total=$((a+b+c+d+e+f+g+h+i))
    idle=$d
    total_diff=$((total-prev_total))
    idle_diff=$((idle-prev_idle))
    
    if [ "$total_diff" -gt 0 ]; then
        cpu_usage=$((100*(total_diff-idle_diff)/total_diff))
        if [ "$cpu_usage" -gt 90 ]; then
            echo "󰻠 High CPU: $cpu_usage%"
            return 0
        fi
    fi

    return 1
}

# Function to get media info
get_media_info() {
    player_status=$(playerctl status 2>/dev/null)
    if [ "$player_status" = "Playing" ] || [ "$player_status" = "Paused" ]; then
        artist=$(playerctl metadata artist 2>/dev/null)
        title=$(playerctl metadata title 2>/dev/null)
        icon="󰎈"
        [ "$player_status" = "Paused" ] && icon="󰏤"
        
        [ -z "$artist" ] && artist="Unknown"
        [ -z "$title" ] && title="Unknown"

        text="$icon $artist - $title"
        echo "{\"text\": \"$text\", \"class\": \"$player_status\", \"alt\": \"$player_status\"}"
    else
        echo "{\"text\": \"\", \"class\": \"none\"}"
    fi
}

# Main logic
warning_msg=$(get_warning)
if [ $? -eq 0 ]; then
    echo "{\"text\": \"$warning_msg\", \"class\": \"warning\", \"alt\": \"warning\"}"
else
    get_media_info
fi
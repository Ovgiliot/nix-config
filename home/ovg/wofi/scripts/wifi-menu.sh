#!/usr/bin/env bash

wifi_list=$(nmcli -t -f "SSID,SECURITY,BARS,ACTIVE" device wifi list | sed 's/\:/--/g')
formatted_list=$(echo "$wifi_list" | awk -F: '{ 
    ssid=$1; security=$2; bars=$3; active=$4; 
    gsub(/--/, ":", ssid);
    if (ssid == "") next;
    if (active == "yes") printf "CONNECTED: %s (%s) %s\n", ssid, security, bars
    else printf "%s (%s) %s\n", ssid, security, bars
}' | sort -u)

chosen=$(echo "$formatted_list" | wofi -dmenu -p "Wi-Fi Networks" -i)

if [ -n "$chosen" ]; then
    if [[ "$chosen" == CONNECTED:* ]]; then
        ssid=$(echo "$chosen" | sed 's/CONNECTED: //; s/ (.*//')
        nmcli connection down id "$ssid"
    else
        ssid=$(echo "$chosen" | sed 's/ (.*//')
        if nmcli connection show id "$ssid" >/dev/null 2>&1; then
            nmcli connection up id "$ssid"
        else
            security=$(echo "$chosen" | sed 's/.*(\(.*\)).*/\1/')
            if [[ "$security" == "--" || "$security" == "" ]]; then
                nmcli device wifi connect "$ssid"
            else
                password=$(wofi -dmenu -p "Password for $ssid" -P)
                if [ -n "$password" ]; then
                    nmcli device wifi connect "$ssid" password "$password"
                fi
            fi
        fi
    fi
fi

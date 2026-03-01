#!/usr/bin/env bash

wifi_list=$(nmcli -t -f "SSID,SECURITY,BARS,ACTIVE" device wifi list 2>/dev/null | sed 's/\\:/--/g' || true)
formatted_list=$(echo "$wifi_list" | awk -F: '{ 
    ssid=$1; security=$2; bars=$3; active=$4; 
    gsub(/--/, ":", ssid);
    if (ssid == "") next;
    if (active == "yes") printf "CONNECTED: %s (%s) %s\n", ssid, security, bars
    else printf "%s (%s) %s\n", ssid, security, bars
}' | sort -u)

chosen=$(echo "$formatted_list" | wofi -dmenu -p "Wi-Fi Networks" -i || true)

if [ -n "$chosen" ]; then
	if [[ "$chosen" == CONNECTED:* ]]; then
		ssid="${chosen#CONNECTED: }"
		ssid="${ssid% (*}"
		nmcli connection down id "$ssid"
	else
		ssid="${chosen% (*}"
		if nmcli connection show id "$ssid" >/dev/null 2>&1; then
			nmcli connection up id "$ssid"
		else
			re='\(([^)]*)\)'
			if [[ "$chosen" =~ $re ]]; then security="${BASH_REMATCH[1]}"; else security=""; fi
			if [[ "$security" == "--" || "$security" == "" ]]; then
				nmcli device wifi connect "$ssid"
			else
				password=$(wofi -dmenu -p "Password for $ssid" -P || true)
				if [ -n "$password" ]; then
					nmcli device wifi connect "$ssid" password "$password"
				fi
			fi
		fi
	fi
fi

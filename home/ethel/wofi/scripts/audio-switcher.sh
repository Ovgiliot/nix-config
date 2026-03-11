#!/usr/bin/env bash

# Build a list of sinks: "name|description" per line
sink_list=$(pactl list sinks | awk '
  /^Sink #/    { name = ""; desc = "" }
  /^\s+Name:/  { name = $2 }
  /^\s+Description:/ { $1 = ""; desc = substr($0, 2); print name "|" desc }
')

default_sink=$(pactl get-default-sink)

# Format for wofi, marking the active sink
formatted_list=$(echo "$sink_list" | awk -F'|' -v def="$default_sink" '{
  if ($1 == def) printf "[ACTIVE] %s\n", $2
  else           printf "%s\n", $2
}')

chosen=$(echo "$formatted_list" | wofi --dmenu -p "Audio Output" -i || true)
[ -z "$chosen" ] && exit 0

# Strip leading [ACTIVE] prefix if the user picked the current default
desc="${chosen#\[ACTIVE\] }"

# Resolve description back to sink name
sink_name=$(echo "$sink_list" | awk -F'|' -v d="$desc" '$2 == d { print $1; exit }')
[ -z "$sink_name" ] && exit 1

pactl set-default-sink "$sink_name"

# Move all currently playing streams to the new sink
pactl list short sink-inputs | awk '{ print $1 }' | while read -r input; do
	pactl move-sink-input "$input" "$sink_name"
done

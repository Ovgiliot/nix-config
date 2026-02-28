#!/usr/bin/env bash
# Outputs current niri keyboard layout as JSON.
# Class: "ru" for Russian, "en" for everything else.

info=$(niri msg --json keyboard-layouts 2>/dev/null)
if [[ -z "$info" ]]; then
	printf '{"text":"EN","class":"en"}\n'
	exit 0
fi

current_idx=$(echo "$info" | jq '.current_idx')
layout_name=$(echo "$info" | jq -r ".names[$current_idx]")

if [[ "$layout_name" == *"Russian"* ]] || [[ "$layout_name" == "ru" ]]; then
	printf '{"text":"RU","class":"ru"}\n'
else
	printf '{"text":"EN","class":"en"}\n'
fi

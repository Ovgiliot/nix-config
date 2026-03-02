#!/usr/bin/env bash
# Long-running WiFi state monitor for Quickshell StatusIcons.
# Emits one JSON line {"wifi":"on|off|ethernet"} at startup,
# then re-emits on every nmcli monitor event.
# Quickshell reads this via a long-running Process + SplitParser.

emit() {
	wifi_status=$(nmcli -t -f type,state dev 2>/dev/null || true)
	if echo "$wifi_status" | grep -qE '^wifi:connected'; then
		printf '{"wifi":"on"}\n'
	elif echo "$wifi_status" | grep -qE '^ethernet:connected'; then
		printf '{"wifi":"ethernet"}\n'
	else
		printf '{"wifi":"off"}\n'
	fi
}

# Emit current state immediately on startup
emit

# Re-emit on every nmcli monitor line (one line per network event)
nmcli monitor 2>/dev/null | while IFS= read -r _line; do
	emit
done

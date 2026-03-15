#!/usr/bin/env bash
# Show status of self-hosted services with memory usage.
# Scans for known service units and reports their state.

printf "%-25s %-12s %s\n" "SERVICE" "STATUS" "MEMORY"
printf "%s\n" "$(printf '=%.0s' {1..50})"

for svc in caddy prometheus grafana fail2ban \
	adguardhome nextcloud home-assistant esphome mosquitto \
	jellyfin transmission sonarr radarr lidarr prowlarr bazarr; do
	if systemctl list-unit-files "${svc}.service" &>/dev/null; then
		status=$(systemctl is-active "$svc" 2>/dev/null)
		memory=$(systemctl show "$svc" --property=MemoryCurrent --value 2>/dev/null)
		if [[ "$memory" == "[not set]" ]] || [[ -z "$memory" ]]; then
			memory="n/a"
		else
			memory=$(numfmt --to=iec "$memory" 2>/dev/null || echo "$memory")
		fi
		printf "%-25s %-12s %s\n" "$svc" "$status" "$memory"
	fi
done

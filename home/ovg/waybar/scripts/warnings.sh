#!/usr/bin/env bash
# One-shot system warnings check for Quickshell InfoBox.
# Checks: CPU temp >95°C, disk >90%, RAM >90%, CPU usage >90% (0.2 s sample).
# Battery and media are handled natively by UPower and Mpris — not checked here.
# Outputs {"text":"...","class":"warning"} or {"text":"","class":"none"}.

warnings=""

append() {
	if [ -n "$warnings" ]; then
		warnings="$warnings  $1"
	else
		warnings="$1"
	fi
}

# ── CPU temperature ───────────────────────────────────────────────────────────
for zone in /sys/class/thermal/thermal_zone*/temp; do
	temp_raw=$(cat "$zone" 2>/dev/null || true)
	[ -n "$temp_raw" ] || continue
	temp_c=$((temp_raw / 1000))
	if [ "$temp_c" -ge 95 ]; then
		append "CPU ${temp_c}°C"
		break
	fi
done

# ── Disk usage (root filesystem) ─────────────────────────────────────────────
disk_pct=$(df / 2>/dev/null | awk 'NR==2 {sub(/%/,"",$5); print $5}')
if [ -n "$disk_pct" ] && [ "$disk_pct" -ge 90 ]; then
	append "Disk ${disk_pct}%"
fi

# ── RAM usage ─────────────────────────────────────────────────────────────────
mem_pct=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%d", int((t-a)*100/t)}' /proc/meminfo 2>/dev/null || true)
if [ -n "$mem_pct" ] && [ "$mem_pct" -ge 90 ]; then
	append "RAM ${mem_pct}%"
fi

# ── CPU usage (0.2 s sample via /proc/stat) ───────────────────────────────────
read_cpu() { awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat; }
snap1=$(read_cpu)
sleep 0.2
snap2=$(read_cpu)
total1=$(echo "$snap1" | awk '{print $1}')
idle1=$(echo "$snap1" | awk '{print $2}')
total2=$(echo "$snap2" | awk '{print $1}')
idle2=$(echo "$snap2" | awk '{print $2}')
dt=$((total2 - total1))
di=$((idle2 - idle1))
if [ "$dt" -gt 0 ]; then
	cpu_pct=$(((dt - di) * 100 / dt))
	if [ "$cpu_pct" -ge 90 ]; then
		append "CPU ${cpu_pct}%"
	fi
fi

# ── Output ────────────────────────────────────────────────────────────────────
if [ -n "$warnings" ]; then
	printf '{"text":"%s","class":"warning"}\n' "$warnings"
else
	printf '{"text":"","class":"none"}\n'
fi

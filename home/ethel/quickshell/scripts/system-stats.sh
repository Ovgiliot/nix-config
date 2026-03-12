#!/usr/bin/env bash
# One-shot system stats for Quickshell StatusPoller.
# Outputs CPU %, memory %, and the highest-priority active warning.
# Checks: CPU usage (0.3 s sample), RAM, CPU temperature, disk (root fs).
# Fields: cpu (int 0-100), mem (int 0-100),
#         warning_text (string), warning_class ("none"|"warning"|"critical").

# ── CPU (0.3 s sample via /proc/stat) ────────────────────────────────────────
cpu1=$(grep '^cpu ' /proc/stat)
sleep 0.3
cpu2=$(grep '^cpu ' /proc/stat)

total1=$(echo "$cpu1" | awk '{t=0; for(i=2;i<=NF;i++) t+=$i; print t}')
idle1=$(echo "$cpu1" | awk '{print $5+$6}')
total2=$(echo "$cpu2" | awk '{t=0; for(i=2;i<=NF;i++) t+=$i; print t}')
idle2=$(echo "$cpu2" | awk '{print $5+$6}')

dt=$((total2 - total1))
di=$((idle2 - idle1))

if ((dt > 0)); then
	cpu_pct=$((100 * (dt - di) / dt))
else
	cpu_pct=0
fi

# ── Memory ───────────────────────────────────────────────────────────────────
mem_total=$(awk '/^MemTotal:/    {print $2}' /proc/meminfo)
mem_avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
mem_pct=$((100 * (mem_total - mem_avail) / mem_total))

# ── Warnings (warning ≥ 90 %; critical at higher thresholds) ─────────────────
warnings=""
is_critical=false

append() {
	if [ -n "$warnings" ]; then warnings="$warnings  $1"; else warnings="$1"; fi
}

if [ "$cpu_pct" -ge 90 ]; then
	append "CPU ${cpu_pct}%"
	[ "$cpu_pct" -ge 98 ] && is_critical=true
fi

if [ "$mem_pct" -ge 90 ]; then
	append "RAM ${mem_pct}%"
	[ "$mem_pct" -ge 95 ] && is_critical=true
fi

# Only check CPU thermal zones. The zone type lives in the sibling "type" file.
# Accepted types: x86_pkg_temp (Intel package), k10temp (AMD), cpu-thermal (ARM).
# This prevents non-CPU zones (disk, battery, embedded controller) from
# triggering a warning labelled "CPU °C".
for zone_dir in /sys/class/thermal/thermal_zone*; do
	type_file="$zone_dir/type"
	temp_file="$zone_dir/temp"
	[ -f "$type_file" ] && [ -f "$temp_file" ] || continue
	zone_type=$(cat "$type_file" 2>/dev/null || true)
	case "$zone_type" in
	x86_pkg_temp | k10temp | cpu-thermal) ;;
	*) continue ;;
	esac
	temp_raw=$(cat "$temp_file" 2>/dev/null || true)
	[ -n "$temp_raw" ] || continue
	temp_c=$((temp_raw / 1000))
	if [ "$temp_c" -ge 95 ]; then
		append "CPU ${temp_c}°C"
		[ "$temp_c" -ge 100 ] && is_critical=true
		break
	fi
done

disk_pct=$(df / 2>/dev/null | awk 'NR==2 {sub(/%/,"",$5); print $5}')
if [ -n "$disk_pct" ] && [ "$disk_pct" -ge 90 ]; then
	append "Disk ${disk_pct}%"
	[ "$disk_pct" -ge 95 ] && is_critical=true
fi

# ── Output ────────────────────────────────────────────────────────────────────
if $is_critical; then
	warning_class="critical"
elif [ -n "$warnings" ]; then
	warning_class="warning"
else
	warning_class="none"
fi

printf '{"cpu":%d,"mem":%d,"warning_text":"%s","warning_class":"%s"}\n' \
	"$cpu_pct" "$mem_pct" "$warnings" "$warning_class"

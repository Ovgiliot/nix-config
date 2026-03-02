#!/usr/bin/env bash
# One-shot system stats for Quickshell StatusPoller.
# Outputs CPU %, memory %, and the highest-priority active warning.
# Checks: CPU usage (0.3 s sample), RAM, CPU temperature, disk (root fs).
# Fields: cpu (int 0-100), mem (int 0-100),
#         warning_text (string), warning_class ("none"|"warning").

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

# ── Warnings (thresholds: CPU >90 %, RAM >90 %, temp >95 °C, disk >90 %) ────
warnings=""

append() {
	if [ -n "$warnings" ]; then warnings="$warnings  $1"; else warnings="$1"; fi
}

if [ "$cpu_pct" -ge 90 ]; then
	append "CPU ${cpu_pct}%"
fi

if [ "$mem_pct" -ge 90 ]; then
	append "RAM ${mem_pct}%"
fi

for zone in /sys/class/thermal/thermal_zone*/temp; do
	temp_raw=$(cat "$zone" 2>/dev/null || true)
	[ -n "$temp_raw" ] || continue
	temp_c=$((temp_raw / 1000))
	if [ "$temp_c" -ge 95 ]; then
		append "CPU ${temp_c}°C"
		break
	fi
done

disk_pct=$(df / 2>/dev/null | awk 'NR==2 {sub(/%/,"",$5); print $5}')
if [ -n "$disk_pct" ] && [ "$disk_pct" -ge 90 ]; then
	append "Disk ${disk_pct}%"
fi

# ── Output ────────────────────────────────────────────────────────────────────
if [ -n "$warnings" ]; then
	warning_class="warning"
else
	warning_class="none"
fi

printf '{"cpu":%d,"mem":%d,"warning_text":"%s","warning_class":"%s"}\n' \
	"$cpu_pct" "$mem_pct" "$warnings" "$warning_class"

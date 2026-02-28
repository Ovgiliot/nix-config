#!/usr/bin/env bash
# Outputs CPU and memory usage as JSON for Quickshell CpuMem widget.
# Fields: cpu (int 0-100), mem (int 0-100)

# ── CPU (sampled over 0.3 s) ──────────────────────────────────────────────────
cpu1=$(grep '^cpu ' /proc/stat)
sleep 0.3
cpu2=$(grep '^cpu ' /proc/stat)

total1=$(echo "$cpu1" | awk '{t=0; for(i=2;i<=NF;i++) t+=$i; print t}')
idle1=$(echo "$cpu1" | awk '{print $5+$6}')
total2=$(echo "$cpu2" | awk '{t=0; for(i=2;i<=NF;i++) t+=$i; print t}')
idle2=$(echo "$cpu2" | awk '{print $5+$6}')

dtotal=$((total2 - total1))
didle=$((idle2 - idle1))

if ((dtotal > 0)); then
	cpu_pct=$((100 * (dtotal - didle) / dtotal))
else
	cpu_pct=0
fi

# ── Memory ───────────────────────────────────────────────────────────────────
mem_total=$(awk '/^MemTotal/    {print $2}' /proc/meminfo)
mem_avail=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo)
mem_pct=$((100 * (mem_total - mem_avail) / mem_total))

printf '{"cpu":%d,"mem":%d}\n' "$cpu_pct" "$mem_pct"

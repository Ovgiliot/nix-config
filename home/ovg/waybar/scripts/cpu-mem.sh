#!/usr/bin/env bash
# Outputs a CPU + memory proportional bar for waybar (return-type: json).
# Bar width: 8 chars using block elements ░ and █.
# Class is low / medium / high based on max(cpu%, mem%).

BAR_WIDTH=8

make_bar() {
	local pct=$1
	local filled=$((pct * BAR_WIDTH / 100))
	local bar=""
	for ((i = 0; i < BAR_WIDTH; i++)); do
		if ((i < filled)); then
			bar="${bar}█"
		else
			bar="${bar}░"
		fi
	done
	echo "$bar"
}

# --- CPU (sampled over 0.3 s) ---
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

# --- Memory ---
mem_total=$(awk '/^MemTotal/  {print $2}' /proc/meminfo)
mem_avail=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo)
mem_pct=$((100 * (mem_total - mem_avail) / mem_total))

# --- Bars ---
cpu_bar=$(make_bar "$cpu_pct")
mem_bar=$(make_bar "$mem_pct")

text=" ${cpu_bar} ${cpu_pct}%   ${mem_bar} ${mem_pct}%"

# --- Class ---
max_pct=$((cpu_pct > mem_pct ? cpu_pct : mem_pct))
if ((max_pct < 40)); then
	class="low"
elif ((max_pct < 75)); then
	class="medium"
else
	class="high"
fi

printf '{"text": "%s", "class": "%s", "tooltip": "CPU: %d%%  MEM: %d%%"}\n' \
	"$text" "$class" "$cpu_pct" "$mem_pct"

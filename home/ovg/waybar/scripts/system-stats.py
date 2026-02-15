#!/usr/bin/env python3
import sys
import os
import json
import time

# Configuration
HISTORY_SIZE = 15
BLOCKS = [" ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
TEMP_DIR = "/tmp/waybar-stats"

def get_cpu_usage(state_file):
    try:
        with open("/proc/stat", "r") as f:
            fields = [float(x) for x in f.readline().split()[1:]]
        
        idle = fields[3] + fields[4]  # idle + iowait
        total = sum(fields)
        
        usage = 0
        if os.path.exists(state_file):
            with open(state_file, "r") as f:
                prev_idle, prev_total = map(float, f.read().split())
            
            diff_idle = idle - prev_idle
            diff_total = total - prev_total
            
            if diff_total > 0:
                usage = (1 - diff_idle / diff_total) * 100
        
        with open(state_file, "w") as f:
            f.write(f"{idle} {total}")
            
        return usage
    except Exception:
        return 0

def get_ram_usage():
    try:
        mem = {}
        with open("/proc/meminfo", "r") as f:
            for line in f:
                parts = line.split()
                mem[parts[0].rstrip(':')] = int(parts[1])
        
        total = mem['MemTotal']
        available = mem['MemAvailable']
        used = total - available
        return (used / total) * 100
    except Exception:
        return 0

def update_history(history_file, value):
    history = []
    if os.path.exists(history_file):
        try:
            with open(history_file, "r") as f:
                history = json.load(f)
        except:
            pass
    
    history.append(value)
    if len(history) > HISTORY_SIZE:
        history = history[-HISTORY_SIZE:]
        
    with open(history_file, "w") as f:
        json.dump(history, f)
        
    return history

def render_graph(history):
    graph = ""
    for val in history:
        idx = int((val / 100) * (len(BLOCKS) - 1))
        idx = max(0, min(len(BLOCKS) - 1, idx))
        graph += BLOCKS[idx]
    return graph

def main():
    if len(sys.argv) < 2:
        print("Usage: system-stats.py [cpu|ram]")
        sys.exit(1)
        
    mode = sys.argv[1]
    
    if not os.path.exists(TEMP_DIR):
        os.makedirs(TEMP_DIR, exist_ok=True)
        
    if mode == "cpu":
        val = get_cpu_usage(f"{TEMP_DIR}/cpu_state")
        hist = update_history(f"{TEMP_DIR}/cpu_hist", val)
        icon = "" # CPU icon
    elif mode == "ram":
        val = get_ram_usage()
        hist = update_history(f"{TEMP_DIR}/ram_hist", val)
        icon = "" # RAM icon (Memory)
    else:
        sys.exit(1)
        
    graph = render_graph(hist)
    
    # Waybar JSON output
    output = {
        "text": f"{icon} {graph}",
        "tooltip": f"{mode.upper()}: {val:.1f}%"
    }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()

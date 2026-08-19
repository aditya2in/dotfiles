#!/bin/bash
read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
prev_idle=$((idle + iowait))
prev_non_idle=$((user + nice + system + irq + softirq + steal))
prev_total=$((prev_idle + prev_non_idle))
sleep 0.5
read -r _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
idle=$((idle + iowait))
non_idle=$((user + nice + system + irq + softirq + steal))
total=$((idle + non_idle))
total_d=$((total - prev_total))
idle_d=$((idle - prev_idle))
if [ "$total_d" -eq 0 ]; then
    usage=0
else
    usage=$(((total_d - idle_d) * 100 / total_d))
fi
echo "{\"text\": \"󰻠 <font color='#89b4fa'>${usage}%</font>\", \"tooltip\": \"CPU Usage: ${usage}%\"}"

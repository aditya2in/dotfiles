#!/bin/bash

# Auto-detect Hyprland instance signature
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
fi

STATE_FILE="/tmp/break-monitor-mode"

if [ -f "$STATE_FILE" ]; then
    # Break mode is active → restore center + right monitors
    rm "$STATE_FILE"
    hyprctl eval 'hl.monitor({ output = "DP-2", mode = "3440x1440@60", position = "1080x240", scale = 1, disabled = false })' >/dev/null
    hyprctl eval 'hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "4520x0", scale = 1, transform = 3, disabled = false })' >/dev/null
    echo "BREAK:OFF | HDMI-A-1: keep | DP-2: on | DP-1: on"
    notify-send -a "Break Mode" "Center + right monitors restored" >/dev/null 2>&1
else
    # Break mode is inactive → disable center (DP-2) and right (DP-1)
    # Keep left vertical (HDMI-A-1) active — displays the Break Plan
    touch "$STATE_FILE"
    hyprctl eval 'hl.monitor({ output = "DP-2", disabled = true })' >/dev/null
    hyprctl eval 'hl.monitor({ output = "DP-1", disabled = true })' >/dev/null
    echo "BREAK:ON  | HDMI-A-1: keep | DP-2: off | DP-1: off"
    notify-send -a "Break Mode" "Center + right monitors disabled" >/dev/null 2>&1
fi

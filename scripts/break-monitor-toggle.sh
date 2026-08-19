#!/bin/bash

# Auto-detect Hyprland instance signature
SIG=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
if [ -n "$SIG" ]; then
    export HYPRLAND_INSTANCE_SIGNATURE="$SIG"
fi

STATE_FILE="/tmp/break-monitor-mode"

if [ -f "$STATE_FILE" ]; then
    # Break mode is active → restore center + right monitors
    rm "$STATE_FILE"
    hyprctl keyword monitor "DP-3, 3440x1440@60, 1080x240, 1" >/dev/null
    hyprctl keyword monitor "DP-2, 1920x1080@60, 4520x0, 1, transform, 3" >/dev/null
    echo "BREAK:OFF | HDMI-A-1: keep | DP-3: on | DP-2: on"
    notify-send -a "Break Mode" "Center + right monitors restored" >/dev/null 2>&1
else
    # Break mode is inactive → disable center (DP-3) and right (DP-2)
    # Keep left vertical (HDMI-A-1) active — displays the Break Plan
    touch "$STATE_FILE"
    hyprctl keyword monitor "DP-3, disable" >/dev/null
    hyprctl keyword monitor "DP-2, disable" >/dev/null
    echo "BREAK:ON  | HDMI-A-1: keep | DP-3: off | DP-2: off"
    notify-send -a "Break Mode" "Center + right monitors disabled" >/dev/null 2>&1
fi

# Restart waybar so bars respawn on whichever monitors are active
WLBAR_PID=$(pgrep -x waybar 2>/dev/null | head -1)
if [ -n "$WLBAR_PID" ]; then
    kill -9 "$WLBAR_PID" 2>/dev/null
    sleep 1
    SIG=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
    [ -n "$SIG" ] && export HYPRLAND_INSTANCE_SIGNATURE="$SIG"
    WAYLAND_DISPLAY="wayland-1" setsid waybar > /dev/null 2>&1 &
fi


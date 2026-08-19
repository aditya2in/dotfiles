#!/bin/bash
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
fi

MONITOR_COUNT=$(hyprctl monitors | grep "Monitor" | wc -l)
if [ "$MONITOR_COUNT" -eq 1 ]; then
    echo '{"text": "G", "class": "active", "tooltip": "Game Mode Active (Single Monitor)"}'
else
    echo '{"text": "G", "class": "inactive", "tooltip": "Work Mode Active (Triple Monitors)"}'
fi

#!/bin/bash
MONITOR_COUNT=$(hyprctl monitors | grep "Monitor" | wc -l)
if [ "$MONITOR_COUNT" -eq 1 ]; then
    echo '{"text": "󰊴", "class": "active", "tooltip": "Game Mode Active (Single Monitor)"}'
else
    echo '{"text": "󰊴", "class": "inactive", "tooltip": "Work Mode Active (Triple Monitors)"}'
fi

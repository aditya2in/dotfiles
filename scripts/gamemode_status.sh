#!/bin/bash
MONITOR_COUNT=$(hyprctl monitors | grep "Monitor" | wc -l)
if [ "$MONITOR_COUNT" -eq 1 ]; then
    echo '{"text": "<font color=\"#f38ba8\">G</font>", "tooltip": "Game Mode Active (Single Monitor)"}'
else
    echo '{"text": "<font color=\"#6c7086\">G</font>", "tooltip": "Work Mode Active (Triple Monitors)"}'
fi

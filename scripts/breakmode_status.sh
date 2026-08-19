#!/bin/bash
if [ -f "/tmp/break-monitor-mode" ]; then
    echo '{"text": "󰛊", "class": "active", "tooltip": "Break Mode Active (Center/Right Off)"}'
else
    echo '{"text": "󰛊", "class": "inactive", "tooltip": "Break Mode Inactive (All On)"}'
fi

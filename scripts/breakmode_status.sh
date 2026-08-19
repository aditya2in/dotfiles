#!/bin/bash
if [ -f "/tmp/break-monitor-mode" ]; then
    echo '{"text": "<font color=\"#f38ba8\">B</font>", "tooltip": "Break Mode Active (Center/Right Off)"}'
else
    echo '{"text": "<font color=\"#6c7086\">B</font>", "tooltip": "Break Mode Inactive (All On)"}'
fi

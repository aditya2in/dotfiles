#!/bin/bash
DATA=$(voxtype status --format json --icon-theme nerd-font 2>/dev/null)
if [ -z "$DATA" ]; then
    DATA='{"text": "", "class": "stopped", "tooltip": "Voxtype not running"}'
fi

CLASS=$(echo "$DATA" | jq -r '.class // "stopped"')
TEXT=$(echo "$DATA" | jq -r '.text // ""')
TOOLTIP=$(echo "$DATA" | jq -r '.tooltip // ""')

COLOR="#6c7086" # Default Gray / Off (stopped)
if [ "$CLASS" == "standby" ]; then
    COLOR="#a6e3a1" # Green
elif [ "$CLASS" == "recording" ]; then
    COLOR="#f38ba8" # Red
fi

echo "{\"text\": \"<font color='$COLOR'>$TEXT</font>\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"

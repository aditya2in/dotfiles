#!/bin/bash
STATUS_FILE="/tmp/whisper_status.json"

if [ -f "$STATUS_FILE" ]; then
    DATA=$(cat "$STATUS_FILE")
else
    DATA='{"text": "󰍭", "class": "stopped", "tooltip": "Whisper STT: OFF"}'
fi

CLASS=$(echo "$DATA" | jq -r '.class // "stopped"')
TEXT=$(echo "$DATA" | jq -r '.text // "󰍭"')
TOOLTIP=$(echo "$DATA" | jq -r '.tooltip // ""')

COLOR="#6c7086" # Default Gray / Off (stopped)
if [ "$CLASS" == "running" ]; then
    COLOR="#a6e3a1" # Green
elif [ "$CLASS" == "paused" ]; then
    COLOR="#f9e2af" # Yellow
elif [ "$CLASS" == "interrupted" ]; then
    COLOR="#89b4fa" # Blue
fi

echo "{\"text\": \"<font color='$COLOR'>$TEXT</font>\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"

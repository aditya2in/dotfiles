#!/bin/bash
STATUS_FILE="/tmp/whisper_status.json"

if [ -f "$STATUS_FILE" ]; then
    cat "$STATUS_FILE"
else
    echo '{"text": "󰍭", "class": "stopped", "tooltip": "Whisper STT: OFF"}'
fi

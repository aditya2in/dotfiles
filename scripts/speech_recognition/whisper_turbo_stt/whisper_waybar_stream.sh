#!/bin/bash
STATUS_FILE="/tmp/whisper_status.json"

# Function to output the current status
output_status() {
    if [ -f "$STATUS_FILE" ]; then
        cat "$STATUS_FILE"
    else
        echo '{"text": "󰍭", "class": "stopped", "tooltip": "Whisper STT: OFF"}'
    fi
}

# Initial output
output_status

# Monitor the file for changes and output them immediately
# We use tail -f with --follow=name to handle the file being overwritten by the Python script
tail -f "$STATUS_FILE" --follow=name --retry 2>/dev/null | while read -r line; do
    echo "$line"
done

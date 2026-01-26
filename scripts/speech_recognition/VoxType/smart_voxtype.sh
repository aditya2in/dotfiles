#!/bin/bash
# Smart wrapper for VoxType - Final Version with Wiremix & Large-v3-Turbo
# Shortcuts:
#   Shift + F12 -> Master Power (Toggle Service On/Off)
#   F12         -> Action (Toggle Recording if Service is On)

COMMAND=$1
MODEL_NAME="Large-v3-Turbo"
MODEL_PATH="/home/adityaws/.local/share/voxtype/models/ggml-large-v3-turbo.bin"

# Handle the Master Power Toggle (Shift + F12)
if [ "$COMMAND" == "toggle-power" ]; then
    if systemctl --user is-active --quiet voxtype.service; then
        systemctl --user stop voxtype.service
        # Close wiremix if it's running
        pkill -f "ghostty --class=org.omarchy.wiremix"
        notify-send "VoxType" "POWER OFF (RAM Freed)" -i microphone-sensitivity-muted -t 2000
    else
        notify-send "VoxType" "POWER ON (Model: $MODEL_NAME)" -i microphone-sensitivity-high -t 3000
        
        # Override the systemd ExecStart temporarily to use the Turbo model
        systemctl --user set-property voxtype.service ExecStart="/usr/bin/voxtype daemon --model $MODEL_PATH" 2>/dev/null
        
        systemctl --user start voxtype.service
        # Open wiremix to recording tab
        ghostty --class=org.omarchy.wiremix -e wiremix -v recording &
    fi
    exit 0
fi

# Handle the Action Button (F12)
if systemctl --user is-active --quiet voxtype.service; then
    # Service is running, behave normally (Toggle Recording)
    voxtype record toggle
else
    # Service is NOT running, warn the user
    notify-send "VoxType" "ERROR: Engine is OFF. Press Shift+F8 first." -i dialog-error -t 3000
fi

#!/bin/bash

# This script toggles Nerd Dictation on and off.
# It checks if the nerd-dictation process is running. If it is, it stops it.
# If it's not running, it starts it.

# The command used to start nerd-dictation
DICTATION_CMD="nerd-dictation begin --simulate-input-tool=YDOTOOL"

# Find the process ID (PID) of a running nerd-dictation instance.
# We use pgrep with the -f flag to search the full command line.
PID=$(pgrep -f "$DICTATION_CMD")

if [ -n "$PID" ]; then
    # If a PID was found, nerd-dictation is running.
    echo "Nerd Dictation is running (PID: $PID). Stopping it..."
    # Kill the main nerd-dictation process.
    kill "$PID"
    sleep 1 # Give it a moment to terminate gracefully.

    # As a fallback, also stop any lingering 'parec' processes,
    # which nerd-dictation uses for recording.
    if pgrep -x "parec" > /dev/null; then
        echo "Cleaning up 'parec' process..."
        pkill -x "parec"
    fi
    echo "Nerd Dictation stopped."
else
    # If no PID was found, nerd-dictation is not running.
    echo "Starting Nerd Dictation..."
    # Start nerd-dictation in the background.
    $DICTATION_CMD &
    echo "Nerd Dictation started in the background."
fi

#!/bin/bash

# Path to your Pomodoro PID file and state file
POMODORO_PID_FILE="/home/aditya/dotfiles/POMODORO-CLI/.config/pomodoro_cli/pomodoro_cli.pid"
POMODORO_STATE_FILE="/home/aditya/dotfiles/POMODORO-CLI/.config/pomodoro_cli/pomodoro_state.json"

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo '{"text": "JQ_MISSING", "class": "pomodoro-error"}'
    exit 1
fi

if [ ! -f "$POMODORO_PID_FILE" ]; then
    # Pomodoro daemon is not running
    echo '{"text": "OFF", "class": "pomodoro-off"}'
elif [ ! -f "$POMODORO_STATE_FILE" ]; then
    # PID file exists but state file doesn't, perhaps an error state or just starting up
    echo '{"text": "UNKNOWN", "class": "pomodoro-unknown"}'
else
    # Read the state from the JSON file
    STATE=$(jq -r '.state' "$POMODORO_STATE_FILE" 2>/dev/null)

    if [ -z "$STATE" ]; then
        echo '{"text": "ERROR", "class": "pomodoro-error"}'
    else
        case "$STATE" in
            "work")
                echo '{"text": "WORK", "class": "pomodoro-work"}'
                ;;
            "short_break")
                echo '{"text": "S-BREAK", "class": "pomodoro-short-break"}'
                ;;
            "long_break")
                echo '{"text": "L-BREAK", "class": "pomodoro-long-break"}'
                ;;
            "paused")
                echo '{"text": "PAUSED", "class": "pomodoro-paused"}'
                ;;
            "stopped")
                # If the state file says "stopped" but PID exists, it means the daemon is running but session is stopped.
                echo '{"text": "STOPPED", "class": "pomodoro-stopped"}'
                ;;
            *)
                echo '{"text": "UNKNOWN", "class": "pomodoro-unknown"}'
                ;;
        esac
    fi
fi

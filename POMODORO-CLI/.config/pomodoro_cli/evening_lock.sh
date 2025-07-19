#!/bin/bash

# This script is called by pomodoro_manager.sh daemon to enforce screen locking
# after a certain time.

# Configuration
LOCK_TIME="1900" # 7 PM (19:00 in 24-hour format)

# Get current time in HHMM format
CURRENT_TIME=$(date +%H%M)

# Check if current time is past LOCK_TIME
if (( CURRENT_TIME >= LOCK_TIME )); then
    # Check if hyprlock is already running
    if pgrep -x "hyprlock" > /dev/null; then
        echo "DEBUG: hyprlock is already running. Not re-locking." >&2
        exit 0
    fi

    echo "DEBUG: Evening lock activated. Current time: $CURRENT_TIME, Lock time: $LOCK_TIME" >&2
    # Lock the screen using hyprlock
    hyprlock &
    echo "DEBUG: Screen locked by evening_lock.sh" >&2
else
    echo "DEBUG: Evening lock not active. Current time: $CURRENT_TIME, Lock time: $LOCK_TIME" >&2
fi


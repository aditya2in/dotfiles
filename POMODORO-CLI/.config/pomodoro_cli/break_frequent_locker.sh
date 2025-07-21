#!/bin/bash

# -----------------------------------------------------------------------------
# Frequent Break Locker
# -----------------------------------------------------------------------------
# This script repeatedly locks the screen every 10 seconds for a given
# duration to encourage stepping away from the computer.
#
# Usage: ./break_frequent_locker.sh <duration_in_seconds>
# -----------------------------------------------------------------------------

# --- Argument Check ---
if [ -z "$1" ]; then
    echo "Error: Duration in seconds is required." >&2
    exit 1
fi

# --- Main Logic ---
duration_seconds=$1
end_time=$(( $(date +%s) + duration_seconds ))

echo "DEBUG: Starting frequent lock for $duration_seconds seconds." >&2

sleep 30 # Grace period before frequent locking begins

while [ $(date +%s) -lt $end_time ]; do
    # Lock the session using the system's lock command
    loginctl lock-session
    # Wait for 10 seconds before the next lock attempt
    sleep 10
done

echo "DEBUG: Frequent lock period finished." >&2

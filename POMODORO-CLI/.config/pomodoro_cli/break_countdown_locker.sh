#!/bin/bash

# -----------------------------------------------------------------------------
# Break Countdown Locker with loginctl
# -----------------------------------------------------------------------------
# This script locks the session using loginctl for the specified duration.
#
# Usage: ./break_countdown_locker.sh <duration_in_seconds>
# -----------------------------------------------------------------------------

# --- Argument Check ---
if [ -z "$1" ]; then
    echo "Error: Duration in seconds is required." >&2
    exit 1
fi

duration_seconds=$1

echo "DEBUG: Locking session for $duration_seconds seconds using loginctl." >&2

# Lock the session
loginctl lock-session

# Wait for the specified duration
sleep "$duration_seconds"

echo "DEBUG: Session unlocked after $duration_seconds seconds." >&2
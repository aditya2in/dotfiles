#!/bin/bash

# Define the path to the Num Lock LED
NUMLOCK_LED_PATH="/sys/class/leds/input8::numlock/brightness"

# Log file for debugging (optional, can be commented out after successful setup)
LOG_FILE="/tmp/numlock_watchdog_$(date +%Y%m%d).log"

# Start message for the log
echo "$(date): Numlock watchdog started." >> "$LOG_FILE"

while true; do
    # Attempt to set the Num Lock state to ON (1)
    # This requires sudo NOPASSWD for the specific command in /etc/sudoers
    sudo sh -c "echo 1 > \"$NUMLOCK_LED_PATH\"" >> "$LOG_FILE" 2>&1

    # Optional: Verify if the state was set correctly (for debugging)
    # CURRENT_BRIGHTNESS=$(cat "$NUMLOCK_LED_PATH" 2>/dev/null)
    # if [[ "$CURRENT_BRIGHTNESS" != "1" ]]; then
    #     echo "$(date): Numlock was not 1. Re-asserting." >> "$LOG_FILE"
    # fi

    # Pause for 1 second before the next iteration
    sleep 1
done

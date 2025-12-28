#!/bin/bash

# Configuration
LOG_FILE="/tmp/nerd_dictation_toggle.log"
PAREC_PROCESS_NAME="parec" # The process name to check for active recording

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "Toggle script called."

# Check if the 'parec' process is currently running
# 'parec' is the PulseAudio Record Client, commonly used by nerd-dictation for audio input.
if pgrep -x "$PAREC_PROCESS_NAME" > /dev/null; then
    log_message "'$PAREC_PROCESS_NAME' process found. Dictation is active. Attempting to end dictation."

    # Send the 'end' command to nerd-dictation
    nerd-dictation end
    NERD_DICTATION_END_STATUS=$? # Capture the exit status of 'nerd-dictation end'

    if [ "$NERD_DICTATION_END_STATUS" -eq 0 ]; then
        log_message "Nerd-dictation ended successfully."
    else
        log_message "Warning: 'nerd-dictation end' command exited with status $NERD_DICTATION_END_STATUS. It might have failed or timed out."
        # If 'nerd-dictation end' didn't exit cleanly, forcibly kill leftover parec processes.
        # This is a robust fallback to ensure no stray recording processes remain.
        if pgrep -x "$PAREC_PROCESS_NAME" > /dev/null; then
            log_message "Attempting to force kill remaining '$PAREC_PROCESS_NAME' processes due to previous failure."
            pkill -SIGTERM "$PAREC_PROCESS_NAME" # Send SIGTERM first for graceful termination
            sleep 1 # Give it a moment
            if pgrep -x "$PAREC_PROCESS_NAME" > /dev/null; then
                log_message "Warning: '$PAREC_PROCESS_NAME' processes still running after SIGTERM. Sending SIGKILL."
                pkill -SIGKILL "$PAREC_PROCESS_NAME" # If SIGTERM didn't work, force kill.
            fi
            log_message "Force kill attempt for '$PAREC_PROCESS_NAME' completed."
        fi
    fi
else
    log_message "'$PAREC_PROCESS_NAME' process not found. Dictation is inactive. Attempting to start dictation."

    # Start nerd-dictation in the background.
    # The `&` detaches it from the script, allowing the script to finish quickly.
    nerd-dictation begin &
    NERD_DICTATION_BEGIN_STATUS=$? # Capture the exit status of launching the command

    if [ "$NERD_DICTATION_BEGIN_STATUS" -eq 0 ]; then
        log_message "Nerd-dictation 'begin' command launched in background successfully."
    else
        log_message "Error: 'nerd-dictation begin &' command failed to launch. Exit status: $NERD_DICTATION_BEGIN_STATUS."
    fi
fi

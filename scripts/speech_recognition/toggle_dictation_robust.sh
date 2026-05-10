#!/bin/bash
# This is a more robust script to toggle the NeMo live dictation tool on and off.

# --- CONFIGURATION ---
LOG_FILE="/tmp/nemo_dictation_toggle_robust.log"
# The name of the audio recording process used by PyAudio/PortAudio/PulseAudio
AUDIO_PROCESS_NAME="parec" 
# A unique part of our python script's command to find its PID
PYTHON_SCRIPT_NAME="stream.py"
# --- END CONFIGURATION ---

# Get the absolute path of the directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PYTHON_SCRIPT_COMMAND="/home/adityaws/venvs/whisper_turbo_stt/bin/python $SCRIPT_DIR/$PYTHON_SCRIPT_NAME"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_message "Robust toggle script called."

# Check if the audio recording process is currently running
if pgrep -x "$AUDIO_PROCESS_NAME" > /dev/null; then
    log_message "Audio process '$AUDIO_PROCESS_NAME' found. Dictation appears to be active. Stopping..."

    # Find and kill the main Python script process
    PYTHON_PID=$(pgrep -f "$PYTHON_SCRIPT_NAME")
    if [ -n "$PYTHON_PID" ]; then
        log_message "Sending SIGTERM to Python script (PID: $PYTHON_PID)."
        kill "$PYTHON_PID" # Sends SIGTERM by default, allowing graceful shutdown
        sleep 1
    else
        log_message "Warning: Audio process was running, but could not find the main Python script PID."
    fi

    # As a robust fallback, ensure the audio process is terminated if it's still lingering
    if pgrep -x "$AUDIO_PROCESS_NAME" > /dev/null; then
        log_message "Audio process still running after attempting graceful shutdown. Force killing..."
        pkill --signal SIGKILL "$AUDIO_PROCESS_NAME"
        log_message "Force kill completed."
    fi

    echo "NeMo Dictation stopped."
    log_message "NeMo Dictation stop process completed."

else
    log_message "Audio process '$AUDIO_PROCESS_NAME' not found. Starting dictation..."

    # Start the Python script in the background. It will print its own startup messages.
    $PYTHON_SCRIPT_COMMAND &
    
    echo "NeMo Dictation started in the background. See output in this terminal for status."
    log_message "NeMo Dictation 'begin' command launched in background."
fi

#!/bin/bash

# Configuration
PROJECT_DIR="/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt"
VENV_PYTHON="$PROJECT_DIR/venv/bin/python"
SCRIPT_NAME="whisper_turbo_realtime_stt.py"
SCRIPT_PATH="$PROJECT_DIR/$SCRIPT_NAME"
PID_FILE="/tmp/whisper_dictation.pid"

# Function to stop the dictation
stop_dictation() {
    echo "Stopping Whisper Dictation..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill "$PID" 2>/dev/null
        rm "$PID_FILE"
    fi
    # Thorough cleanup
    pkill -f "$SCRIPT_NAME" 2>/dev/null
    
    notify-send "Whisper STT" "Status: STOPPED" -i microphone-sensitivity-muted -t 2000
}

# Function to start the dictation
start_dictation() {
    # Ensure a clean slate
    pkill -f "$SCRIPT_NAME" 2>/dev/null
    rm -f "$PID_FILE"

    echo "Starting Whisper Dictation..."
    # Run in background and save PID
    $VENV_PYTHON "$SCRIPT_PATH" > /dev/null 2>&1 &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
    
    # Check if it actually started
    sleep 1
    if ps -p $NEW_PID > /dev/null; then
        notify-send "Whisper STT" "Status: STARTED (Turbo Mode)" -i microphone-sensitivity-high -t 3000
    else
        notify-send "Whisper STT" "Status: ERROR (Failed to Start)" -i dialog-error -t 4000
        rm -f "$PID_FILE"
    fi
}

# Toggle Logic
if pgrep -f "$SCRIPT_NAME" > /dev/null; then
    stop_dictation
else
    start_dictation
fi

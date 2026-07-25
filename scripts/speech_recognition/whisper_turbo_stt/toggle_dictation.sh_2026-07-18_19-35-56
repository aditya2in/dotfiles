#!/bin/bash

# ==============================================================================
# 🛠 RECOVERY & FUTURE-PROOFING HEADER
# ==============================================================================
# If this script or the environment is ever lost, follow these steps:
#
# 1. VIRTUAL ENVIRONMENT (VENV):
#    Location: ~/venvs/whisper_turbo_stt
#    Setup:
#      mkdir -p ~/venvs
#      python -m venv ~/venvs/whisper_turbo_stt
#      source ~/venvs/whisper_turbo_stt/bin/activate
#      pip install RealtimeSTT faster-whisper hf-transfer
#
# 2. MODEL DETAILS:
#    Name: Whisper Large-v3-Turbo
#    Format: CTranslate2 (faster-whisper)
#    Central Path: ~/AI_MODELS/dictation_models/
#    Download: 
#      export HF_HUB_ENABLE_HF_TRANSFER=1
#      huggingface-cli download m-baccari/faster-whisper-large-v3-turbo --local-dir ~/AI_MODELS/dictation_models
#
# 3. SYSTEM DEPENDENCIES:
#    - PortAudio (for microphone access)
#    - NVIDIA CUDA & cuDNN (for GPU acceleration)
#    - wtype (for text injection)
# ==============================================================================

# Configuration
PROJECT_DIR="/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt"
VENV_PYTHON="/home/adityaws/venvs/whisper_turbo_stt/bin/python"
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
    rm -f "/tmp/whisper_paused"
    
    # Update Waybar to stopped state
    echo '{"text": "󰍭", "class": "stopped", "alt": "stopped", "tooltip": "Whisper STT: OFF"}' > "/tmp/whisper_status.json"
    
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

# Function to toggle pause
pause_dictation() {
    # Check if PID file exists and process is alive
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
        PAUSE_FILE="/tmp/whisper_paused"
        if [ -f "$PAUSE_FILE" ]; then
            rm "$PAUSE_FILE"
        else
            touch "$PAUSE_FILE"
        fi
    else
        notify-send "Whisper STT" "Engine is OFF. Press F7 to start first." -i dialog-warning -t 3000
    fi
}

# Function to toggle smart pause override
toggle_override() {
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
        OVERRIDE_FILE="/tmp/whisper_smart_pause_override"
        if [ -f "$OVERRIDE_FILE" ]; then
            rm "$OVERRIDE_FILE"
            notify-send "Whisper STT" "Smart Pause: RE-ENABLED (Blocked Apps Active)" -i security-high -t 2000
        else
            touch "$OVERRIDE_FILE"
            notify-send "Whisper STT" "Smart Pause: OVERRIDDEN (Dictate Everywhere)" -i security-low -t 2000
        fi
    else
        notify-send "Whisper STT" "Engine is OFF. Press F7 to start first." -i dialog-warning -t 3000
    fi
}

# Toggle Logic
if [ "$1" == "--pause" ]; then
    pause_dictation
elif [ "$1" == "--toggle-override" ]; then
    toggle_override
elif pgrep -f "$SCRIPT_NAME" > /dev/null; then
    stop_dictation
else
    start_dictation
fi

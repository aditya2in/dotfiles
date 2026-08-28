#!/bin/bash

# ==============================================================================
# RECOVERY & FUTURE-PROOFING HEADER
# ==============================================================================
# If this script or the environment is ever lost, follow these steps:
#
# 1. VIRTUAL ENVIRONMENT (VENV):
#    Location: ~/venvs/whisper_turbo_stt (shared with F7 Whisper Turbo STT)
#    Setup:
#      source ~/venvs/whisper_turbo_stt/bin/activate
#      pip install git+https://github.com/huggingface/transformers
#      pip install sounddevice silero-vad
#
# 2. MODEL DETAILS:
#    Name: NVIDIA Nemotron ASR Streaming (English 0.6B FastConformer-RNNT)
#    Central Path: ~/AI_MODELS/dictation_models/nemotron/en
#    Download:
#      export HF_HUB_ENABLE_HF_TRANSFER=1
#      huggingface-cli download nvidia/nemotron-speech-streaming-en-0.6b --local-dir ~/AI_MODELS/dictation_models/nemotron/en
#
# 3. SYSTEM DEPENDENCIES:
#    - PortAudio (for microphone access)
#    - NVIDIA CUDA & cuDNN (for GPU acceleration)
#    - wtype / tmux (for text injection)
# ==============================================================================

# Configuration
PROJECT_DIR="/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation"
VENV_PYTHON="/home/adityaws/venvs/whisper_turbo_stt/bin/python"
SCRIPT_NAME="nemotron_realtime_stt.py"
SCRIPT_PATH="$PROJECT_DIR/$SCRIPT_NAME"
PID_FILE="/tmp/nemotron_dictation.pid"
PAUSE_FILE="/tmp/nemotron_paused"

# Function to stop (unloads VRAM)
stop_dictation() {
    echo "Stopping Nemotron Dictation & Unloading VRAM..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill -9 "$PID" 2>/dev/null
        rm -f "$PID_FILE" 2>/dev/null
    fi
    pkill -9 -f "$SCRIPT_NAME" 2>/dev/null
    rm -f "$PAUSE_FILE" 2>/dev/null
    echo '{"text": "STOP", "class": "stopped", "alt": "stopped", "tooltip": "Nemotron STT: OFF"}' > "/tmp/nemotron_status.json"
    notify-send "Nemotron STT" "Status: STOPPED (VRAM Unloaded)" -i microphone-sensitivity-muted -t 2000
}

# Function to start (loads model into VRAM)
start_dictation() {
    pkill -9 -f "$SCRIPT_NAME" 2>/dev/null
    rm -f "$PID_FILE" 2>/dev/null
    rm -f "$PAUSE_FILE" 2>/dev/null
    echo "Starting Nemotron Dictation..."
    $VENV_PYTHON "$SCRIPT_PATH" > /dev/null 2>&1 &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
    sleep 1
    if ps -p $NEW_PID > /dev/null; then
        notify-send "Nemotron STT" "Status: STARTED (Loaded in VRAM)" -i microphone-sensitivity-high -t 3000
    else
        notify-send "Nemotron STT" "Status: ERROR (Failed to Start)" -i dialog-error -t 4000
        rm -f "$PID_FILE" 2>/dev/null
    fi
}

# Function to toggle power (Shift + F4)
toggle_power() {
    if pgrep -f "$SCRIPT_NAME" > /dev/null; then
        stop_dictation
    else
        start_dictation
    fi
}

# Function to toggle software pause (F4)
toggle_pause() {
    if pgrep -f "$SCRIPT_NAME" > /dev/null; then
        if [ -f "$PAUSE_FILE" ]; then
            rm -f "$PAUSE_FILE" 2>/dev/null
            notify-send "Nemotron STT" "Status: RESUMED (Listening)" -i microphone-sensitivity-high -t 1500
        else
            touch "$PAUSE_FILE"
            notify-send "Nemotron STT" "Status: PAUSED (Software Mute)" -i microphone-sensitivity-muted -t 1500
        fi
    else
        notify-send "Nemotron STT" "Engine is OFF. Press SHIFT + F4 to start." -i dialog-warning -t 3000
    fi
}

# Function to toggle smart pause override
override_dictation() {
    OVERRIDE_FILE="/tmp/nemotron_smart_pause_override"
    if [ -f "$OVERRIDE_FILE" ]; then
        rm -f "$OVERRIDE_FILE" 2>/dev/null
        notify-send "Nemotron STT" "Smart Pause: AUTO" -i dialog-information -t 2000
    else
        touch "$OVERRIDE_FILE"
        notify-send "Nemotron STT" "Smart Pause: FORCED ON" -i dialog-information -t 2000
    fi
}

# Command Line Routing
if [ "$1" == "--power" ] || [ "$1" == "--toggle-power" ]; then
    toggle_power
elif [ "$1" == "--pause" ] || [ "$1" == "--toggle-pause" ]; then
    toggle_pause
elif [ "$1" == "--toggle-override" ]; then
    override_dictation
elif [ "$1" == "--start" ]; then
    start_dictation
elif [ "$1" == "--stop" ]; then
    stop_dictation
else
    # Default without args: Software Pause Toggle (F4)
    toggle_pause
fi

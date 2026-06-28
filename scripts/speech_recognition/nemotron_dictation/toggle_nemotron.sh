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
#    Name: NVIDIA Nemotron ASR Streaming (English) / Nemotron 3.5 ASR (Multilingual)
#    Central Path: ~/AI_MODELS/dictation_models/nemotron/
#    Download:
#      export HF_HUB_ENABLE_HF_TRANSFER=1
#      huggingface-cli download nvidia/nemotron-speech-streaming-en-0.6b --local-dir ~/AI_MODELS/dictation_models/nemotron/en
#      huggingface-cli download nvidia/nemotron-3.5-asr-streaming-0.6b --local-dir ~/AI_MODELS/dictation_models/nemotron/multi
#
# 3. SYSTEM DEPENDENCIES:
#    - PortAudio (for microphone access)
#    - NVIDIA CUDA & cuDNN (for GPU acceleration)
#    - wtype (for text injection)
# ==============================================================================

# Configuration
PROJECT_DIR="/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation"
VENV_PYTHON="/home/adityaws/venvs/whisper_turbo_stt/bin/python"
SCRIPT_NAME="nemotron_realtime_stt.py"
SCRIPT_PATH="$PROJECT_DIR/$SCRIPT_NAME"
PID_FILE="/tmp/nemotron_dictation.pid"

# Function to stop
stop_dictation() {
    echo "Stopping Nemotron Dictation..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill "$PID" 2>/dev/null
        rm "$PID_FILE" 2>/dev/null
    fi
    pkill -f "$SCRIPT_NAME" 2>/dev/null
    rm -f "/tmp/nemotron_paused" 2>/dev/null
    echo '{"text": "STOP", "class": "stopped", "alt": "stopped", "tooltip": "Nemotron STT: OFF"}' > "/tmp/nemotron_status.json"
    notify-send "Nemotron STT" "Status: STOPPED" -i microphone-sensitivity-muted -t 2000
}

# Function to start
start_dictation() {
    pkill -f "$SCRIPT_NAME" 2>/dev/null
    rm -f "$PID_FILE" 2>/dev/null
    echo "Starting Nemotron Dictation..."
    $VENV_PYTHON "$SCRIPT_PATH" > /dev/null 2>&1 &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
    sleep 1
    if ps -p $NEW_PID > /dev/null; then
        notify-send "Nemotron STT" "Status: STARTED" -i microphone-sensitivity-high -t 3000
    else
        notify-send "Nemotron STT" "Status: ERROR (Failed to Start)" -i dialog-error -t 4000
        rm -f "$PID_FILE" 2>/dev/null
    fi
}

# Function to toggle pause
pause_dictation() {
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
        PAUSE_FILE="/tmp/nemotron_paused"
        if [ -f "$PAUSE_FILE" ]; then
            rm "$PAUSE_FILE" 2>/dev/null
        else
            touch "$PAUSE_FILE"
        fi
    else
        notify-send "Nemotron STT" "Engine is OFF. Press F9 to start first." -i dialog-warning -t 3000
    fi
}

# Toggle Logic
if [ "$1" == "--pause" ]; then
    pause_dictation
elif [ "$1" == "--start" ]; then
    start_dictation
elif pgrep -f "$SCRIPT_NAME" > /dev/null; then
    stop_dictation
else
    start_dictation
fi

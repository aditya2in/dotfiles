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

# Environment Fallbacks for Headless / Autostart contexts
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

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
    setsid $VENV_PYTHON "$SCRIPT_PATH" > /tmp/nemotron_daemon.log 2>&1 &
    NEW_PID=$!
    disown $NEW_PID 2>/dev/null
    echo $NEW_PID > "$PID_FILE"
    sleep 2
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

GLOBAL_OVERRIDE_FILE="/tmp/nemotron_global_typing_override"

# Function to toggle global focused window mode vs background ghostty mode (Ctrl + F4)
override_dictation() {
    if [ -f "$GLOBAL_OVERRIDE_FILE" ]; then
        rm -f "$GLOBAL_OVERRIDE_FILE" 2>/dev/null
        notify-send "Nemotron Target" "💻 Ghostty / Tmux K8 (Background)" -i utilities-terminal -t 2000
    else
        touch "$GLOBAL_OVERRIDE_FILE"
        notify-send "Nemotron Target" "🌐 Global Focused Window (Active Cursor)" -i input-keyboard -t 2500
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

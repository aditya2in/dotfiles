#!/bin/bash

# ==============================================================================
# RECOVERY & FUTURE-PROOFING HEADER
# ==============================================================================
# Model: NVIDIA Parakeet RNN-T 1.1B (FastConformer-RNNT)
# Path: ~/AI_MODELS/dictation_models/parakeet/rnnt_1.1b
# VENV: ~/venvs/whisper_turbo_stt
# Keybinding: F9 (Pause/Resume), SHIFT + F9 (Power Start/Stop)
# ==============================================================================

PROJECT_DIR="/home/adityaws/DOTfiles/scripts/speech_recognition/parakeet_dictation"
VENV_PYTHON="/home/adityaws/venvs/whisper_turbo_stt/bin/python"
SCRIPT_NAME="parakeet_realtime_stt.py"
SCRIPT_PATH="$PROJECT_DIR/$SCRIPT_NAME"
PID_FILE="/tmp/parakeet_dictation.pid"
PAUSE_FILE="/tmp/parakeet_paused"

stop_dictation() {
    echo "Stopping Parakeet 1.1B Dictation & Unloading VRAM..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill -9 "$PID" 2>/dev/null
        rm -f "$PID_FILE" 2>/dev/null
    fi
    pkill -9 -f "$SCRIPT_NAME" 2>/dev/null
    rm -f "$PAUSE_FILE" 2>/dev/null
    echo '{"text": "STOP", "class": "stopped", "alt": "stopped", "tooltip": "Parakeet 1.1B STT: OFF"}' > "/tmp/parakeet_status.json"
    notify-send "Parakeet 1.1B STT" "Status: STOPPED (VRAM Unloaded)" -i microphone-sensitivity-muted -t 2000
}

start_dictation() {
    pkill -9 -f "$SCRIPT_NAME" 2>/dev/null
    rm -f "$PID_FILE" 2>/dev/null
    rm -f "$PAUSE_FILE" 2>/dev/null
    echo "Starting Parakeet 1.1B Dictation..."
    notify-send "Parakeet 1.1B STT" "Loading 1.1B Model into GPU VRAM..." -i dialog-information -t 3000
    PYTHONUNBUFFERED=1 setsid $VENV_PYTHON "$SCRIPT_PATH" > /tmp/parakeet_dictation.log 2>&1 &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
}



toggle_power() {
    if pgrep -f "$SCRIPT_NAME" > /dev/null; then
        stop_dictation
    else
        start_dictation
    fi
}

toggle_pause() {
    if pgrep -f "$SCRIPT_NAME" > /dev/null; then
        if [ -f "$PAUSE_FILE" ]; then
            rm -f "$PAUSE_FILE" 2>/dev/null
            notify-send "Parakeet 1.1B STT" "Status: RESUMED (Listening)" -i microphone-sensitivity-high -t 1500
        else
            touch "$PAUSE_FILE"
            notify-send "Parakeet 1.1B STT" "Status: PAUSED (Software Mute)" -i microphone-sensitivity-muted -t 1500
        fi
    else
        notify-send "Parakeet 1.1B STT" "Engine is OFF. Press SHIFT + F9 to start." -i dialog-warning -t 3000
    fi
}

if [ "$1" == "--power" ] || [ "$1" == "--toggle-power" ]; then
    toggle_power
elif [ "$1" == "--pause" ] || [ "$1" == "--toggle-pause" ]; then
    toggle_pause
elif [ "$1" == "--start" ]; then
    start_dictation
elif [ "$1" == "--stop" ]; then
    stop_dictation
else
    toggle_pause
fi

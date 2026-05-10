#!/bin/bash
# ==============================================================================
# 🛠 RECOVERY & FUTURE-PROOFING HEADER
# ==============================================================================
# If this setup is lost, follow these steps:
#
# 1. APPLICATION:
#    Name: VoxType
#    Description: A compiled Rust/C++ push-to-talk dictation tool.
#    Installation: Check AUR for 'voxtype-bin' or 'voxtype-git'.
#
# 2. MODEL DETAILS:
#    Name: Whisper Large-v3-Turbo
#    Format: GGML (for whisper.cpp/voxtype)
#    Central Path: ~/AI_MODELS/dictation_models/ggml-large-v3-turbo.bin
#    Download: 
#      wget https://huggingface.co/guillaumekln/faster-whisper-large-v3-turbo/resolve/main/ggml-large-v3-turbo.bin -O ~/AI_MODELS/dictation_models/ggml-large-v3-turbo.bin
#
# 3. SERVICE:
#    File: ~/.config/systemd/user/voxtype.service
#    Setup: systemctl --user enable --now voxtype.service
# ==============================================================================

# Smart wrapper for VoxType - Final Version with Wiremix & Large-v3-Turbo
# Shortcuts:
#   Shift + F1 -> Master Power (Toggle Service On/Off)
#   F1         -> Action (Toggle Recording if Service is On)

COMMAND=$1
MODEL_NAME="Large-v3-Turbo"
# Original Model: OpenAI Whisper Large-v3-Turbo (GGML Format for whisper.cpp)
# Centralized Location: ~/AI_MODELS/dictation_models/ggml-large-v3-turbo.bin
MODEL_PATH="/home/adityaws/AI_MODELS/dictation_models/ggml-large-v3-turbo.bin"

# Handle the Master Power Toggle (Shift + F1)
if [ "$COMMAND" == "toggle-power" ]; then
    if systemctl --user is-active --quiet voxtype.service; then
        systemctl --user stop voxtype.service
        # Close wiremix if it's running
        pkill -f "ghostty --class=org.omarchy.wiremix"
        notify-send "VoxType" "POWER OFF (RAM Freed)" -i microphone-sensitivity-muted -t 2000
    else
        notify-send "VoxType" "POWER ON (Model: $MODEL_NAME)" -i microphone-sensitivity-high -t 3000
        
        systemctl --user start voxtype.service
        # Open wiremix to recording tab
        ghostty --class=org.omarchy.wiremix -e wiremix -v recording &
    fi
    exit 0
fi

# Handle the Action Button (F1)
if systemctl --user is-active --quiet voxtype.service; then
    # Service is running, behave normally (Toggle Recording)
    voxtype record toggle
else
    # Service is NOT running, warn the user
    notify-send "VoxType" "ERROR: Engine is OFF. Press Shift+F1 first." -i dialog-error -t 3000
fi

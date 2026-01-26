#!/bin/bash
# Script to run Whisper Turbo STT manually in the foreground for testing
PROJECT_DIR="/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt"
echo "Starting Whisper Turbo Streaming STT (Technical Mode)..."
# Stop any background instances first to avoid mic conflicts
pkill -f "whisper_turbo_realtime_stt.py" 2>/dev/null
rm -f /tmp/whisper_dictation.pid

$PROJECT_DIR/venv/bin/python $PROJECT_DIR/whisper_turbo_realtime_stt.py
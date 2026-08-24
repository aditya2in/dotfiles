#!/bin/bash
# Runner for the official NVIDIA Nemotron live streaming microphone test
VENV_PYTHON="/home/adityaws/venvs/whisper_turbo_stt/bin/python"
SCRIPT_PATH="/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/official_nemotron_live_test.py"

exec $VENV_PYTHON "$SCRIPT_PATH" "$@"

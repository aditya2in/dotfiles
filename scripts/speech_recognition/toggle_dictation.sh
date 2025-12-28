#!/bin/bash
# This script toggles the NeMo live dictation tool on and off.

# Get the absolute path of the directory where this script is located.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define the command that starts the Python script
PYTHON_SCRIPT_COMMAND="$SCRIPT_DIR/venv/bin/python $SCRIPT_DIR/stream.py"

# Find the process ID (PID) of a running instance of our Python script.
PID=$(pgrep -f "$PYTHON_SCRIPT_COMMAND")

if [ -n "$PID" ]; then
    # If a PID was found, the dictation script is running.
    echo "Stopping NeMo Dictation..."
    kill "$PID"
    echo "NeMo Dictation stopped."
else
    # If no PID was found, the dictation script is not running.
    # Start the Python script in the background, allowing it to print its initial messages
    # directly to the terminal. Subsequent output (like speaking/transcribing) will also be visible.
    $PYTHON_SCRIPT_COMMAND &
    echo "NeMo Dictation started in the background. See output above for status."
fi
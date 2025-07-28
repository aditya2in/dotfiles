#!/bin/bash

# Define the path to your pomodoro_manager.sh script
POMODORO_SCRIPT="$HOME/.config/pomodoro_cli/pomodoro_manager.sh"
STATE_FILE="$HOME/.config/pomodoro_cli/pomodoro_state.json"

# Define the output log file name with a timestamp
LOG_FILE="pomodoro_debug_log_$(date +%Y%m%d_%H%M%S).txt"

# --- Start Logging ---
echo "----------------------------------------------------" | tee -a "$LOG_FILE"
echo "Starting Pomodoro Debug Sequence Log" | tee -a "$LOG_FILE"
echo "Log file location: $(pwd)/$LOG_FILE" | tee -a "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "----------------------------------------------------" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo ">>> Step 1: Running 'debug-toggle' to ensure debugging is OFF" | tee -a "$LOG_FILE"
echo "--- Output from debug-toggle (OFF) ---" | tee -a "$LOG_FILE"
"$POMODORO_SCRIPT" debug-toggle 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo ">>> Step 2: Checking content of state file after debug-toggle (OFF)" | tee -a "$LOG_FILE"
echo "--- Content of $STATE_FILE ---" | tee -a "$LOG_FILE"
cat "$STATE_FILE" 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo ">>> Step 3: Running 'debug-toggle' to ensure debugging is ON" | tee -a "$LOG_FILE"
echo "--- Output from debug-toggle (ON) ---" | tee -a "$LOG_FILE"
"$POMODORO_SCRIPT" debug-toggle 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo ">>> Step 4: Checking content of state file after debug-toggle (ON)" | tee -a "$LOG_FILE"
echo "--- Content of $STATE_FILE ---" | tee -a "$LOG_FILE"
cat "$STATE_FILE" 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo ">>> Step 5: Running 'status' command to observe debug output" | tee -a "$LOG_FILE"
echo "--- Output from status command ---" | tee -a "$LOG_FILE"
"$POMODORO_SCRIPT" status 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "----------------------------------------------------" | tee -a "$LOG_FILE"
echo "Pomodoro Debug Sequence Log Finished" | tee -a "$LOG_FILE"
echo "Log saved to: $(pwd)/$LOG_FILE" | tee -a "$LOG_FILE"
echo "----------------------------------------------------" | tee -a "$LOG_FILE"

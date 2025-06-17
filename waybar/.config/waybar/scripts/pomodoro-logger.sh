#!/bin/bash

# Define the base directory for logs
LOG_DIR="/home/aditya/.local/share/pomodoro/logs"
mkdir -p "$LOG_DIR" # Ensure the directory structure exists

# Define the main activity log file
ACTIVITY_LOG_FILE="$LOG_DIR/activity_log.txt"

LOG_TYPE="$1"    # e.g., COMMAND_EXEC, POMODORO_STATUS_RAW, SCRIPT_DEBUG, STATE_CHANGE
MESSAGE="$2"     # The detailed message or relevant output

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Append the log entry to the main activity log file
echo "$TIMESTAMP [$LOG_TYPE] $MESSAGE" >> "$ACTIVITY_LOG_FILE"

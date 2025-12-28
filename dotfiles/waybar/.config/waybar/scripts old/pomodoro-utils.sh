
#!/bin/bash

# --- Configuration Variables ---
# Base directory for all pomodoro-related data (logs, state files)
BASE_DATA_DIR="/home/aditya/.local/share/pomodoro"
mkdir -p "$BASE_DATA_DIR/logs" # Ensure logs directory exists

# Define log file path
ACTIVITY_LOG_FILE="$BASE_DATA_DIR/logs/activity_log.txt"

# Path to the pomodoro-cli executable
# This must be the full path where 'cargo install' placed it.
POMODORO_CLI="/home/aditya/.cargo/bin/pomodoro-cli"

# Path to jq executable (ensure it's installed: sudo pacman -S jq)
JQ_PATH="/usr/bin/jq" # Common path for jq on Arch Linux

# File to store the internal cycle state (e.g., work sessions completed, total pomodoros)
CYCLE_STATE_FILE="$BASE_DATA_DIR/cycle_state.json"

# File to store the display state for Waybar (e.g., "stopped", "running", "reset")
DISPLAY_STATE_FILE="$BASE_DATA_DIR/display_state.json"

# Number of work sessions before a long break
SESSIONS_BEFORE_LONG_BREAK=4

# --- Utility Functions ---

# Function to log messages with timestamp and type
# Usage: log_message <TYPE> <MESSAGE>
log_message() {
    local LOG_TYPE="$1"
    local MESSAGE="$2"
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP [$LOG_TYPE] $MESSAGE" >> "$ACTIVITY_LOG_FILE" 2>&1
}

# Function to read the current cycle state from file
read_cycle_state() {
    if [[ -f "$CYCLE_STATE_FILE" ]]; then
        cat "$CYCLE_STATE_FILE"
    else
        echo '{}' # Return empty JSON if file doesn't exist
    fi
}

# Function to write the current cycle state to file
write_cycle_state() {
    local JSON_DATA="$1"
    echo "$JSON_DATA" | "$JQ_PATH" -c . > "${CYCLE_STATE_FILE}.tmp" && mv "${CYCLE_STATE_FILE}.tmp" "$CYCLE_STATE_FILE"
    log_message STATE_WRITE "Cycle state updated: $JSON_DATA"
}

# Function to read the current display state from file
read_display_state() {
    if [[ -f "$DISPLAY_STATE_FILE" ]]; then
        cat "$DISPLAY_STATE_FILE"
    else
        echo '{"status": "finished"}' # Default status if file doesn't exist
    fi
}

# Function to write the current display state to file
write_display_state() {
    local JSON_DATA="$1"
    echo "$JSON_DATA" | "$JQ_PATH" -c . > "${DISPLAY_STATE_FILE}.tmp" && mv "${DISPLAY_STATE_FILE}.tmp" "$DISPLAY_STATE_FILE"
    log_message DISPLAY_STATE_WRITE "Display state updated: $JSON_DATA"
}

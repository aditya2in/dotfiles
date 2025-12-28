#!/bin/bash

# -----------------------------------------------------------------------------
# Configuration Variables
# -----------------------------------------------------------------------------
# Base directory for Pomodoro CLI related files
POMODORO_DIR="$HOME/.config/pomodoro_cli"
# Path to the state file
STATE_FILE="$POMODORO_DIR/pomodoro_state.json"
# Path to the sound file for notifications (ensure you place a WAV or OGG here)
SOUND_FILE="$POMODORO_DIR/sounds/beep.wav"
# Path to the daily session log file
DAILY_LOG_FILE="$POMODORO_DIR/pomodoro_daily_log.txt"
# Lock file to prevent concurrent script execution
LOCK_FILE="$POMODORO_DIR/pomodoro_lock"
# PID file for the daemon process
DAEMON_PID_FILE="$POMODORO_DIR/pomodoro_daemon.pid"

# --- NEW: Routine Integration Configuration ---
GET_ROUTINE_SCRIPT="$HOME/.config/pomodoro_cli/RoutineTaskSubTaskScripts/get_current_CategoryAction.sh" # Updated script name
CURRENT_ROUTINE_FILE="$HOME/.config/pomodoro_cli/RoutineTaskSubTaskScripts/current_routine.txt"
ROUTINE_UPDATE_FREQUENCY_SEC="30" # Run get_current_CategoryAction.sh every 5 minutes (300 seconds)
LAST_ROUTINE_UPDATE_TIME_FILE="$POMODORO_DIR/last_routine_update.timestamp" # File to store last update timestamp
# ----------------------------------------------
# --- NEW: Obsidian Configuration ---
# Based on your vault folder /home/aditya/obsidian, the vault name is likely "obsidian"
OBSIDIAN_VAULT_NAME="obsidian" # <--- CONFIRM/REPLACE with your actual Obsidian vault name (e.g., "My Notes")
OBSIDIAN_BREAK_NOTE_PATH="POMODORO BREAK FILE.md" # <--- IMPORTANT: This is the file you provided
# ----------------------------------
# --- NEW: Markdown Log Configuration ---
MARKDOWN_LOG_FILE="$POMODORO_DIR/POMODORO mark down table data for obsidian Analysis.md"
# -----------------------------------------

# Session Durations for direct use with pomodoro-cli's --duration flag.
# Use "Xs" for X seconds, "Xm" for X minutes.
# For testing purposes, set all to 10 seconds ("10s").
# #25m for real usage
# WORK_DURATION="25m"
# SHORT_BREAK_DURATION="5m" # Adjust these for your actual break times
# LONG_BREAK_DURATION="30m" # Adjust these for your actual break times
#10 seconds for testing
WORK_DURATION="10s" # <--- CONFIRM/REPLACE with your actual work duration (e.g., "25m")
SHORT_BREAK_DURATION="10s" # Adjust these for your actual break times
LONG_BREAK_DURATION="10s"
# These variables hold our script's internal state.
# They are declared globally (without 'local') so they can be accessed by all functions.
_status=""
_session_type=""
_total_pomodoro_cycles_today=0
_current_session_in_cycle=0
_current_routine_name="Loading Routine..." # Initial placeholder for routine display
_current_category_action="Loading Action..." # Placeholder for category/action
_current_task_name="Loading Task..."
_current_subtask_name="Loading SubTask..."
_current_minitask_name="Loading MiniTask..."
_last_run_date=""


# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Function to acquire a lock to prevent multiple instances
acquire_lock() {
    # Using flock for robust locking. Requires `flock` command (usually part of util-linux).
    # Redirecting output to /dev/null to keep it silent.
    # We use FD 200 for locking.
    exec 200>"$LOCK_FILE"
    flock 200 || { echo "Error: Another instance of the script is running. Exiting." >&2; exit 1; }
}

# Function to release the lock (handled automatically by shell exit, but good practice)
release_lock() {
    flock -u 200
    exec 200>&-
}

# Initializes the state file with default values. This function is now only responsible
# for CREATING a default state file when explicitly told by read_state.
initialize_state_file() {
    echo "DEBUG: Initializing Pomodoro state file with default values..." >&2
    # Create the directory if it's not exist
    mkdir -p "$(dirname "$STATE_FILE")" || { echo "Error: Could not create directory for state file: $(dirname "$STATE_FILE")" >&2; exit 1; }
    jq -n \
        --arg status "Stopped" \
        --arg session_type "None" \
        --arg total_cycles "0" \
        --arg current_cycle "0" \
        --arg last_date "$(date +%Y-%m-%d)" \
        '{
            "status": $status,
            "session_type": $session_type,
            "total_pomodoro_cycles_today": ($total_cycles | tonumber),
            "current_session_in_cycle": ($current_cycle | tonumber),
            "last_run_date": $last_date
        }' > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    echo "DEBUG: State file initialized." >&2
}

# Reads the current state from the JSON file into shell variables.
read_state() {
    acquire_lock # Acquire lock for this operation
    # Check if the state file exists, is not empty, or contains valid JSON
    if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ] || ! jq -e . >/dev/null 2>&1 < "$STATE_FILE"; then
        echo "DEBUG: read_state: State file missing, empty or invalid JSON. Attempting to re-initialize." >&2
        initialize_state_file # Call the new initialization function
        # After initialization, the state file now exists with default zeros, so we can read it.
    fi

    # Read all values using jq and store them in global variables
    _status=$(jq -r '.status' "$STATE_FILE")
    _session_type=$(jq -r '.session_type' "$STATE_FILE")
    _total_pomodoro_cycles_today=$(jq -r '.total_pomodoro_cycles_today' "$STATE_FILE")
    _current_session_in_cycle=$(jq -r '.current_session_in_cycle' "$STATE_FILE")
    _last_run_date=$(jq -r '.last_run_date' "$STATE_FILE")

    update_current_routine_display_info # NEW: Update routine info every time state is read
    echo "DEBUG: read_state: Loaded state: status='$_status', session_type='$_session_type', total_cycles='$_total_pomodoro_cycles_today', current_cycle='$_current_session_in_cycle', last_date='$_last_run_date'" >&2

    release_lock # Release lock after this operation
    return 0
}

# Writes the current state from shell variables to the JSON file.
# Note: This function is now used for all state writes EXCEPT cmd_reset for explicit control.
write_state() {
    acquire_lock # Acquire lock for this operation
    # Use a temporary file and mv for atomic write
    jq -n \
        --arg status "$_status" \
        --arg session_type "$_session_type" \
        --arg total_cycles "$_total_pomodoro_cycles_today" \
        --arg current_cycle "$_current_session_in_cycle" \
        --arg last_date "$_last_run_date" \
        '{
            "status": $status,
            "session_type": $session_type,
            "total_pomodoro_cycles_today": ($total_cycles | tonumber),
            "current_session_in_cycle": ($current_cycle | tonumber),
            "last_run_date": $last_date
        }' > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    echo "DEBUG: write_state: Saved state: status='$_status', session_type='$_session_type', total_cycles='$_total_pomodoro_cycles_today', current_cycle='$_current_session_in_cycle', last_date='$_last_run_date'" >&2
    release_lock # Release lock after this operation
}

# Logs the previous day's Pomodoro summary before resetting counts.
# This function assumes global state variables (_last_run_date, _total_pomodoro_cycles_today,
# _current_session_in_cycle) hold the values from the day that just ended.
log_daily_summary() {
    # Create the directory for the log file if it's not exist
    mkdir -p "$(dirname "$DAILY_LOG_FILE")" || { echo "Error: Could not create directory for log file: $(dirname "$DAILY_LOG_FILE")" >&2; return 1; }

    # Format the log entry: Log date, then values for the day that *just ended*
    local log_entry="[$(date "+%Y-%m-%d %H:%M:%S")] Daily Summary for $_last_run_date: Total Pomodoros: $_total_pomodoro_cycles_today, Last Cycle Progress: ${_current_session_in_cycle}/4"
    echo "$log_entry" >> "$DAILY_LOG_FILE"
    echo "DEBUG: Logged daily summary for $_last_run_date to $DAILY_LOG_FILE" >&2
}


# Resets daily counts if the date has changed.
reset_daily_counts() {
    local today=$(date +%Y-%m-%d)
    if [ "$_last_run_date" != "$today" ]; then
        echo "DEBUG: New day detected. Logging previous day's summary before resetting counts." >&2
        log_daily_summary # <--- NEW: Call existing logging function HERE

        # NEW: Log to Markdown for daily reset event
        log_session_event \
            "Daily_Summary" \
            "Idle" \
            "0" \
            "0" \
            "0" \
            "Stopped" \
            "Daily reset - summary of previous day logged."

        echo "DEBUG: Resetting daily counts for new day." >&2
        _total_pomodoro_cycles_today=0
        _current_session_in_cycle=0 # This will still reset on a new day, which is probably desired behavior.
        _last_run_date="$today"
        write_state
    fi
}

# Plays a notification sound.
play_sound() {
    if [ -f "$SOUND_FILE" ]; then
        paplay "$SOUND_FILE" >/dev/null 2>&1 || aplay "$SOUND_FILE" >/dev/null 2>&1
    else
        echo "Warning: Sound file not found at $SOUND_FILE" >&2
    fi
}

# Sends a desktop notification.
send_notification() {
    local title="$1"
    local message="$2"
    notify-send "$title" "$message" -t 5000 # -t 5000 for 5 seconds display
    play_sound
}

# Converts a duration string (e.g., "10s", "5m") to seconds.
parse_duration_to_seconds() {
    local duration_str="$1"
    local value="${duration_str%[sm]}" # Extract the numeric part
    local unit="${duration_str##*[^sm]}" # Extract the unit ('s' or 'm')

    if [ "$unit" == "s" ]; then
        echo "$value"
    elif [ "$unit" == "m" ]; then
        echo "$((value * 60))"
    else
        echo "0" # Return 0 for invalid formats
    fi
}

# Converts total seconds back into a user-friendly "X minutes" or "X seconds" string.
parse_duration_to_minutes_or_seconds() {
    local total_seconds="$1"
    if [ "$total_seconds" -ge 60 ] && [ "$((total_seconds % 60))" -eq 0 ]; then
        echo "$((total_seconds / 60)) minutes"
    else
        echo "$total_seconds" seconds
    fi
}

# NEW: Logs a detailed session event to the Markdown file.
# Arguments: Event_Type, Session_Type, Planned_Duration_Seconds, Actual_Duration_Seconds,
#            Remaining_Time_Seconds, Current_Status_After_Event, Notes/Reason
log_session_event() {
    local event_type="$1"
    local session_type="$2"
    local planned_duration_sec="$3"
    local actual_duration_sec="$4"
    local remaining_time_sec="$5"
    local status_after_event="$6"
    local notes_reason="$7"

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local session_id=$(date "+%Y%m%d%H%M%S") # Simple unique ID
    local routine_name="$_current_routine_name" # Use the globally updated routine name
    local total_pomodoros="$_total_pomodoro_cycles_today"
    local cycle_progress="${_current_session_in_cycle}/4"

    # Create the directory for the log file if it doesn't exist
    mkdir -p "$(dirname "$MARKDOWN_LOG_FILE")" || { echo "Error: Could not create directory for Markdown log file: $(dirname "$MARKDOWN_LOG_FILE")" >&2; return 1; }

    # Check if file exists and is empty or has only a title, then add header and separator
    if [ ! -f "$MARKDOWN_LOG_FILE" ] || [ ! -s "$MARKDOWN_LOG_FILE" ] || ! grep -q "|---" "$MARKDOWN_LOG_FILE"; then
        echo "# Pomodoro Session History" > "$MARKDOWN_LOG_FILE"
        echo "" >> "$MARKDOWN_LOG_FILE" # Add a blank line for readability
        echo "| Session_ID | Event_Timestamp | Event_Type | Session_Type | Routine_Name | Planned_Duration_Sec | Actual_Duration_Sec | Remaining_Time_Sec | Status_After_Event | Total_Pomodoros_Today | Current_Cycle_Progress | Notes/Reason |" >> "$MARKDOWN_LOG_FILE"
        echo "|:----------:|:-----------------:|:----------:|:------------:|:------------:|:--------------------:|:-------------------:|:--------------------:|:------------------:|:---------------------:|:----------------------:|:-------------|" >> "$MARKDOWN_LOG_FILE"
    fi

    # Append the new data row
    echo "| "$session_id" | "$timestamp" | "$event_type" | "$session_type" | "$routine_name" | "$planned_duration_sec" | "$actual_duration_sec" | "$remaining_time_sec" | "$status_after_event" | "$total_pomodoros" | "$cycle_progress" | "$notes_reason" |" >> "$MARKDOWN_LOG_FILE"
    echo "DEBUG: Logged session event to "$MARKDOWN_LOG_FILE": "$event_type" for "$session_type"" >&2
}

# NEW: URL-encodes a string for use in URIs (e.g., for Obsidian links).
urlencode() {
    local string="$1"
    local length="${#string}"
    local url_encoded=""
    for (( i=0; i<length; i++ )); do
        local c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) url_encoded+="$c" ;;
            *) printf -v c_encoded '%%%02X' "'$c"
               url_encoded+="$c_encoded" ;;
        esac
    done
    echo "$url_encoded"
}

# Displays a full-screen blocking message during breaks using swaylock.
# Takes duration in seconds as argument, followed by DISPLAY, XAUTHORITY, DBUS_SESSION_BUS_ADDRESS.
display_break_block() {
    local duration_seconds="$1"
    local display_var="$2"      # Passed from start_session
    local xauthority_var="$3"   # Passed from start_session
    local dbus_address_var="$4" # Passed from start_session

    # Explicitly set environment variables for swaylock to connect to the correct display
    # While swaylock is Wayland native, passing these ensures consistency and might help XWayland compatibility if any part needs it.
    export DISPLAY="$display_var"
    export XAUTHORITY="$xauthority_var"
    export DBUS_SESSION_BUS_ADDRESS="$dbus_address_var"

    echo "DEBUG: display_break_block: DISPLAY=$DISPLAY, XAUTHORITY=$XAUTHORITY, DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS" >&2
    
    local break_duration_text=$(parse_duration_to_minutes_or_seconds "$duration_seconds")
    
    # Define the message content with Pango markup for large, centered text
    # Using a very large font size (e.g., 200) for maximum impact on screen.
    local pango_message_content="<span font_desc='Noto Sans Bold 200' foreground='#eceff4'>Time to get up and go to relax and take a break!</span>\n\n"
    pango_message_content+="<span font_desc='Noto Sans Bold 100' foreground='#eceff4'>This break is for ${break_duration_text}.</span>\n\n"
    pango_message_content+="<span font_desc='Noto Sans Bold 100' foreground='#eceff4'>Rest, come back after your break.</span>"

    # Temporary image file for the message
    local temp_image="/tmp/pomodoro_break_message_$(date +%s%N).png"

    echo "DEBUG: Generating temporary image for swaylock: "$temp_image"" >&2

    # Generate the PNG image with the message using pango-view
    # -o: output file, --font: font description, --markup: enable pango markup
    # --width, --height: ensure a large enough canvas for the text
    # --background: make it transparent for layering on swaylock
    # FIX: Quoted 'rgba(0,0,0,0)' to prevent shell syntax error.
    pango-view --markup --text="$pango_message_content" \
        -o "$temp_image" \
        --width=1920 --height=1080 --background='rgba(0,0,0,0)' >/dev/null 2>&1

    if [ ! -f "$temp_image" ]; then
        echo "Error: Failed to generate temporary image for break block. Swaylock will use default background." >&2
        # Fallback for swaylock if image generation fails (it will use its default config)
        swaylock --daemonize >/dev/null 2>&1 &
    else
        echo "DEBUG: Launching swaylock with custom image." >&2
        # Launch swaylock with the generated image as background
        # --daemonize: run in background
        # --image: specify the background image
        # You might need to configure swaylock further (e.g., blur, indicators) via its config file
        swaylock --image "$temp_image" --daemonize >/dev/null 2>&1 &
    fi

    # Get the PID of the last background command (swaylock)
    local swaylock_pid=$!

    echo "DEBUG: Swaylock launched with PID: "$swaylock_pid". Sleeping for "$duration_seconds" seconds." >&2

    # Wait for the duration
    sleep "$duration_seconds"

    echo "DEBUG: Attempting to kill swaylock (PID: "$swaylock_pid")." >&2
    # Kill swaylock to unlock the screen
    kill -TERM "$swaylock_pid" 2>/dev/null
    # Clean up the temporary image file
    rm -f "$temp_image"
    echo "DEBUG: Swaylock killed and temporary image removed." >&2
}


# -----------------------------------------------------------------------------
# Pomodoro Logic Functions
# -----------------------------------------------------------------------------

# Starts a Pomodoro session (Work or Break)
start_session() {
    local type="$1"
    local duration_str="$2" # This is now the string like "10s", "25m"
    local notify_title="$3"
    local notify_msg="$4"

    # Always stop any pomodoro-cli instance to clear its timer
    pomodoro-cli stop >/dev/null 2>/dev/null

    _status="Running"
    _session_type="$type"
    write_state

    # Log the start of the session
    log_session_event \
        "Start" \
        "$type" \
        "$(parse_duration_to_seconds "$duration_str")" \
        "0" \
        "$(parse_duration_to_seconds "$duration_str")" \
        "Running" \
        "User or auto-initiated session."

    # Start pomodoro-cli with the specified duration
    # Redirect stderr to /dev/null to prevent any unexpected output from pomodoro-cli
    nohup pomodoro-cli start --duration "$duration_str" >/dev/null 2>/dev/null &

    send_notification "$notify_title" "$notify_msg"

    # Handle break-specific actions
    if [ "$type" == "Break" ] || [ "$type" == "Long Break" ]; then
        echo "DEBUG: Triggering break action for "$type": Switching to Workspace 2 and Opening Obsidian note." >&2

        # Switch to Workspace 2 first
        # This assumes hyprctl is in your PATH and configured for your Hyprland session.
        hyprctl dispatch workspace 2
        echo "DEBUG: Switched to Workspace 2." >&2

        # Construct the Obsidian URI for the specific note
        local obsidian_uri="obsidian://open?vault=$(urlencode "$OBSIDIAN_VAULT_NAME")&file=$(urlencode "$OBSIDIAN_BREAK_NOTE_PATH")"
        echo "DEBUG: Obsidian URI: "$obsidian_uri"" >&2

        # Open the Obsidian note. 'xdg-open' is commonly used on Linux to open URIs/files with default apps.
        # Ensure 'xdg-open' is available and configured to handle 'obsidian://' links.
        nohup xdg-open "$obsidian_uri" >/tmp/pomodoro_obsidian_output.log 2>&1 &
        echo "DEBUG: Obsidian note launched via xdg-open." >&2
    fi

    echo "$notify_msg" >&2 # Ensure this informational message goes to stderr
}

# Handles the transition to the next session type after one completes.
# This function should ONLY manage transitions between active states.
# If called with 'None' session type (e.g., after a reset or manual stop), it should NOT auto-start.
handle_transition() {
    read_state # Re-read state to ensure it's fresh

    # Determine unit label for notifications (seconds or minutes)
    local unit_label="minutes"
    if [[ "$WORK_DURATION" == *"s"* ]]; then # Check if any duration uses 's'
        unit_label="seconds"
    fi

    # Retrieve current pomodoro-cli status for actual elapsed/remaining time
    local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)
    local pcli_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')
    local actual_duration_at_finish=$(echo "$pcli_json" | jq -r '.elapsed // 0 | tonumber')
    local remaining_duration_at_finish=$(echo "$pcli_json" | jq -r '.remaining // 0 | tonumber')

    # Planned duration of the session that just finished
    local planned_duration_of_finished_session_sec=0
    case "$_session_type" in
        "Work") planned_duration_of_finished_session_sec="$(parse_duration_to_seconds "$WORK_DURATION")" ;;
        "Break") planned_duration_of_finished_session_sec="$(parse_duration_to_seconds "$SHORT_BREAK_DURATION")" ;;
        "Long Break") planned_duration_of_finished_session_sec="$(parse_duration_to_seconds "$LONG_BREAK_DURATION")" ;;
    esac

    if [ "$_session_type" == "Work" ]; then
        # Log the completion of the Work session
        log_session_event \
            "End (Completed)" \
            "Work" \
            "$planned_duration_of_finished_session_sec" \
            "$actual_duration_at_finish" \
            "$remaining_duration_at_finish" \
            "Running" \
            "Work session completed, transitioning to break."

        _total_pomodoro_cycles_today=$((_total_pomodoro_cycles_today + 1))
        _current_session_in_cycle=$((_current_session_in_cycle + 1))

        if [ "$_current_session_in_cycle" -eq 4 ]; then
            # It's time for a Long Break
            start_session "Long Break" "$LONG_BREAK_DURATION" "Long Break Time!" "Enjoy your $(parse_duration_to_minutes_or_seconds "$(parse_duration_to_seconds "$LONG_BREAK_DURATION")") long break!"
        else
            # It's time for a Short Break
            start_session "Break" "$SHORT_BREAK_DURATION" "Take a $(parse_duration_to_minutes_or_seconds "$(parse_duration_to_seconds "$SHORT_BREAK_DURATION")") break."
        fi
    elif [ "$_session_type" == "Break" ] || [ "$_session_type" == "Long Break" ]; then
        # Log the completion of the Break session
        log_session_event \
            "End (Completed)" \
            "$_session_type" \
            "$planned_duration_of_finished_session_sec" \
            "$actual_duration_at_finish" \
            "$remaining_duration_at_finish" \
            "Stopped" \
            "Break completed, awaiting manual work start."

        if [ "$_current_session_in_cycle" -eq 4 ]; then
            _current_session_in_cycle=0 # Reset cycle count after the long break, preparing for next set of 4
        fi
        _status="Stopped"
        _session_type="None" # Set session type to None to reflect no active session
        write_state
        send_notification "Break Over!" "Time to start a new Work session when you're ready."
        echo "Break finished. Please start your next Work session manually." >&2 # Debug/info to terminal
    else
        # This branch is hit if handle_transition is called unexpectedly when _session_type is "None"
        echo "Warning: handle_transition called with unexpected session_type: "$_session_type". Setting to stopped." >&2
        _status="Stopped"
        _session_type="None"
        write_state
        send_notification "Pomodoro Session Ended" "No new session started automatically. Use 'start' to begin."
        # Log this unexpected state change
        log_session_event \
            "End (Cancelled)" \
            "None" \
            "0" \
            "0" \
            "0" \
            "Stopped" \
            "Unexpected transition to 'None' session type."
    fi
}

# -----------------------------------------------------------------------------
# NEW: Routine Integration Functions
# -----------------------------------------------------------------------------

# Runs the get_current_CategoryAction.sh script (conditionally) and updates the _current_routine_name global variable.
update_current_routine_display_info() {
    echo "DEBUG: Checking for routine update info..." >&2
    local current_timestamp=$(date +%s)
    local last_update_timestamp=0

    # Ensure the directory for the timestamp file exists
    mkdir -p "$(dirname "$LAST_ROUTINE_UPDATE_TIME_FILE")"

    if [ -f "$LAST_ROUTINE_UPDATE_TIME_FILE" ]; then
        last_update_timestamp=$(cat "$LAST_ROUTINE_UPDATE_TIME_FILE")
    fi

    # Check if the script should be run based on frequency
    if (( current_timestamp - last_update_timestamp >= ROUTINE_UPDATE_FREQUENCY_SEC )); then
        echo "DEBUG: Running get_current_CategoryAction.sh to update routine info..." >&2
        # Ensure the script is executable and run it silently
        if [ -f "$GET_ROUTINE_SCRIPT" ]; then
            bash "$GET_ROUTINE_SCRIPT" --quick >/dev/null 2>&1 # Run silently
            echo "$current_timestamp" > "$LAST_ROUTINE_UPDATE_TIME_FILE" # Update timestamp
            echo "DEBUG: get_current_CategoryAction.sh executed and timestamp updated." >&2
        else
            echo "Warning: get_current_CategoryAction.sh not found at "$GET_ROUTINE_SCRIPT"" >&2
        fi
    else
        echo "DEBUG: Not running get_current_CategoryAction.sh, too soon. Last run: $(date -d @"$last_update_timestamp" +'%Y-%m-%d %H:%M:%S')" >&2
    fi

    # Always read the routine name from the current_routine.txt file
    if [ -f "$CURRENT_ROUTINE_FILE" ]; then
        # The get_current_CategoryAction.sh script now provides a structured "Quick Result"
        # at the top of its output file. We parse this section.
        # Line 4: Routine Name (e.g., ******Office Work******)
        # Line 6: Category/Action
        # Line 8: Task
        # Line 10: SubTask
        # Line 12: MiniTask
        local routine_output=$(sed -n '4p' "$CURRENT_ROUTINE_FILE" | sed 's/^\*\{6\}//;s/\*\{6\}$//' | xargs)
        local category_action_output=$(sed -n '6p' "$CURRENT_ROUTINE_FILE" | xargs)
        local task_output=$(sed -n '8p' "$CURRENT_ROUTINE_FILE" | xargs)
        local subtask_output=$(sed -n '10p' "$CURRENT_ROUTINE_FILE" | xargs)
        local minitask_output=$(sed -n '12p' "$CURRENT_ROUTINE_FILE" | xargs)

        # Assign Routine Name
        if [[ -z "$routine_output" || "$routine_output" == "NONE" ]]; then
            _current_routine_name="No Routine"
        else
            _current_routine_name="$routine_output"
        fi

        # Assign Category/Action
        if [[ -z "$category_action_output" || "$category_action_output" == "NONE" ]]; then
            _current_category_action=""
        else
            _current_category_action="$category_action_output"
        fi

        # Assign Task
        if [[ -z "$task_output" ]]; then
            _current_task_name=""
        else
            _current_task_name="$task_output"
        fi

        # Assign SubTask
        if [[ -z "$subtask_output" ]]; then
            _current_subtask_name=""
        else
            _current_subtask_name="$subtask_output"
        fi

        # Assign MiniTask
        if [[ -z "$minitask_output" ]]; then
            _current_minitask_name=""
        else
            _current_minitask_name="$minitask_output"
        fi
    else
        _current_routine_name="Routine File N/A"
        _current_category_action="Action File N/A"
        _current_task_name=""
        _current_subtask_name=""
        _current_minitask_name=""
        echo "Warning: current_routine.txt not found at $CURRENT_ROUTINE_FILE" >&2
    fi
    echo "DEBUG: Retrieved routine: '"$_current_routine_name"'" >&2
    echo "DEBUG: Retrieved category/action: '"$_current_category_action"'" >&2
    echo "DEBUG: Retrieved task: '"$_current_task_name"'" >&2
    echo "DEBUG: Retrieved subtask: '"$_current_subtask_name"'" >&2
    echo "DEBUG: Retrieved minitask: '"$_current_minitask_name"'" >&2
}
# -----------------------------------------------------------------------------
# Main Commands (User Facing)
# -----------------------------------------------------------------------------

# Command to start the Pomodoro timer.
cmd_start() {
    read_state
    reset_daily_counts # Check for new day before starting
    if [ "$_status" == "Running" ]; then
        echo "Pomodoro is already running. Current session: "$_session_type"." >&2 # Redirected to stderr
        return 0
    fi
    start_session "Work" "$WORK_DURATION" "Pomodoro Started!" "Time to focus for $(parse_duration_to_minutes_or_seconds "$(parse_duration_to_seconds "$WORK_DURATION")")."
}

# Command to pause the Pomodoro timer.
cmd_pause() {
    read_state
    if [ "$_status" == "Stopped" ]; then
        echo "Pomodoro is not running. Cannot pause." >&2 # Redirected to stderr
        return 0
    fi

    # Get current status for elapsed/remaining time before pausing
    local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)
    local pcli_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')
    local elapsed_on_pause=$(echo "$pcli_json" | jq -r '.elapsed // 0 | tonumber')
    local remaining_on_pause=$(echo "$pcli_json" | jq -r '.remaining // 0 | tonumber')
    
    local planned_duration_sec_on_pause=0
    case "$_session_type" in
        "Work") planned_duration_sec_on_pause="$(parse_duration_to_seconds "$WORK_DURATION")" ;;
        "Break") planned_duration_sec_on_pause="$(parse_duration_to_seconds "$SHORT_BREAK_DURATION")" ;;
        "Long Break") planned_duration_sec_on_pause="$(parse_duration_to_seconds "$LONG_BREAK_DURATION")" ;;
    esac

    pomodoro-cli pause >/dev/null 2>/dev/null
    _status="Paused"
    write_state

    # Log the pause event
    log_session_event \
        "Paused" \
        "$_session_type" \
        "$planned_duration_sec_on_pause" \
        "$elapsed_on_pause" \
        "$remaining_on_pause" \
        "Paused" \
        "User manually paused session."

    send_notification "Pomodoro Paused" "Current session: "$_session_type"."
    echo "Pomodoro paused." >&2 # Redirected to stderr
}

# Command to resume the Pomodoro timer.
cmd_resume() {
    read_state
    if [ "$_status" != "Paused" ]; then
        echo "Pomodoro is not paused. Cannot resume." >&2 # Redirected to stderr
        return 0
    fi

    # Retrieve remaining time from pomodoro-cli or stored state (if available)
    local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)
    local pcli_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')
    local remaining_on_resume=$(echo "$pcli_json" | jq -r '.remaining // 0 | tonumber')

    local planned_duration_sec_on_resume=0
    case "$_session_type" in
        "Work") planned_duration_sec_on_resume="$(parse_duration_to_seconds "$WORK_DURATION")" ;;
        "Break") planned_duration_sec_on_resume="$(parse_duration_to_seconds "$SHORT_BREAK_DURATION")" ;;
        "Long Break") planned_duration_sec_on_resume="$(parse_duration_to_seconds "$LONG_BREAK_DURATION")" ;;
    esac


    pomodoro-cli resume >/dev/null 2>/dev/null
    _status="Running"
    write_state

    # Log the resume event
    log_session_event \
        "Resumed" \
        "$_session_type" \
        "$planned_duration_sec_on_resume" \
        "0" \
        "$remaining_on_resume" \
        "Running" \
        "User manually resumed session."

    send_notification "Pomodoro Resumed" "Current session: "$_session_type"."
    echo "Pomodoro resumed." >&2 # Redirected to stderr
}

# Command to stop the Pomodoro timer.
cmd_stop() {
    read_state
    if [ "$_status" == "Stopped" ] && [ "$_session_type" == "None" ]; then
        echo "Pomodoro is already stopped." >&2 # Redirected to stderr
        return 0
    fi

    # Get current status for elapsed/remaining time before stopping
    local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)
    local pcli_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')
    local elapsed_on_stop=$(echo "$pcli_json" | jq -r '.elapsed // 0 | tonumber')
    local remaining_on_stop=$(echo "$pcli_json" | jq -r '.remaining // 0 | tonumber')

    local session_type_at_stop="$_session_type" # Capture before it's set to None
    local planned_duration_sec_at_stop=0
    case "$session_type_at_stop" in
        "Work") planned_duration_sec_at_stop="$(parse_duration_to_seconds "$WORK_DURATION")" ;;
        "Break") planned_duration_sec_at_stop="$(parse_duration_to_seconds "$SHORT_BREAK_DURATION")" ;;
        "Long Break") planned_duration_sec_at_stop="$(parse_duration_to_seconds "$LONG_BREAK_DURATION")" ;;
    esac

    pomodoro-cli stop >/dev/null 2>/dev/null
    _status="Stopped"
    _session_type="None" # Reset session type on full stop
    write_state

    # Log the stop event
    log_session_event \
        "End (Stopped)" \
        "$session_type_at_stop" \
        "$planned_duration_sec_at_stop" \
        "$elapsed_on_stop" \
        "$remaining_on_stop" \
        "Stopped" \
        "User manually stopped session."

    send_notification "Pomodoro Stopped" "Pomodoro timer has been stopped."
    echo "Pomodoro stopped." >&2 # Redirected to stderr
}

# Command to reset the Pomodoro timer and state to default "Stopped" values, but preserves counts.
cmd_reset() {
    echo "DEBUG: cmd_reset: Starting reset command." >&2
    read_state # Load existing counts from state file into global variables

    # Get current status for elapsed/remaining time before reset (if any session was running)
    local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)
    local pcli_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')
    local elapsed_on_reset=$(echo "$pcli_json" | jq -r '.elapsed // 0 | tonumber')
    local remaining_on_reset=$(echo "$pcli_json" | jq -r '.remaining // 0 | tonumber')

    local session_type_at_reset="$_session_type" # Capture before it's set to None
    local planned_duration_sec_at_reset=0
    case "$session_type_at_reset" in
        "Work") planned_duration_sec_at_reset="$(parse_duration_to_seconds "$WORK_DURATION")" ;;
        "Break") planned_duration_sec_at_reset="$(parse_duration_to_seconds "$SHORT_BREAK_DURATION")" ;;
        "Long Break") planned_duration_sec_at_reset="$(parse_duration_to_seconds "$LONG_BREAK_DURATION")" ;;
    esac

    echo "DEBUG: cmd_reset: State after read_state: total_cycles='"$_total_pomodoro_cycles_today"', current_cycle='"$_current_session_in_cycle"'" >&2

    pomodoro-cli reset >/dev/null 2>/dev/null

    # Explicitly define the new status, session type, and last_run_date
    # The counts (_total_pomodoro_cycles_today, _current_session_in_cycle)
    # are kept as they were loaded by read_state and passed to jq directly.
    local new_status="Stopped"
    local new_session_type="None"
    local new_last_run_date=$(date +%Y-%m-%d)

    echo "DEBUG: cmd_reset: Values to write: status='"$new_status"', session_type='"$new_session_type"', total_cycles='"$_total_pomodoro_cycles_today"', current_cycle='"$_current_session_in_cycle"', last_date='"$new_last_run_date"'" >&2

    # Perform the state write directly here, explicitly passing all required values.
    # This avoids potential issues with global variables implicitly changing before write_state.
    acquire_lock # Acquire lock for this explicit write
    jq -n \
        --arg status "$new_status" \
        --arg session_type "$new_session_type" \
        --arg total_cycles "$_total_pomodoro_cycles_today" \
        --arg current_cycle "$_current_session_in_cycle" \
        --arg last_run_date "$new_last_run_date" \
        '{
            "status": $status,
            "session_type": $session_type,
            "total_pomodoro_cycles_today": ($total_cycles | tonumber),
            "current_session_in_cycle": ($current_cycle | tonumber),
            "last_run_date": $last_run_date
        }' > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    release_lock # Release lock after this explicit write
    echo "DEBUG: cmd_reset: State written to file (via inline jq)." >&2

    # Log the reset event
    log_session_event \
        "End (Cancelled)" \
        "$session_type_at_reset" \
        "$planned_duration_sec_at_reset" \
        "$elapsed_on_reset" \
        "$remaining_on_reset" \
        "Stopped" \
        "User manually reset session. Counts preserved."

    send_notification "Pomodoro Reset" "Timer and current session have been reset to Stopped. Counts are preserved."
    echo "Pomodoro timer and session status have been reset. Counts are preserved." >&2
}

# Command to get the current status for Waybar (outputs JSON).
cmd_status() {
    read_state
    reset_daily_counts # Daily reset check for status display

    # Capture raw output from pomodoro-cli, including any non-JSON prefix like "Time is up!".
    # Redirect stderr to /dev/null to prevent any unexpected error messages from pomodoro-cli.
    local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)

    # Extract only the JSON part from the raw output.
    # This sed command finds the first occurrence of '{' and prints everything from that point onwards.
    # This handles cases where "Time is up!" is on the same line or precedes the JSON.
    local pcli_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')

    # Add a check to ensure pcli_json is valid JSON before proceeding.
    # If it's not valid, default it to an empty JSON object to prevent 'jq' errors downstream.
    if ! echo "$pcli_json" | jq -e . >/dev/null 2>&1; then
        echo "DEBUG: Failed to parse pomodoro-cli output as JSON. Raw output was: '"$raw_pcli_output"'" >&2
        echo "DEBUG: Attempted JSON extraction resulted in: '"$pcli_json"'" >&2
        pcli_json='{}' # Fallback to empty JSON if extraction or validation fails
    fi

    # Initialize with default values
    local time_text="00:00"
    local tooltip_text="No timer running. Click to start work." # More descriptive default tooltip
    local class_name="stopped" # Default class
    local percentage_val="0" # Initialize for jq

    # First, handle the pomodoro-cli output if it's running
    if [[ -n "$pcli_json" && "$pcli_json" != "{}" ]]; then
        time_text=$(echo "$pcli_json" | jq -r '.text // "00:00"') # Use // to provide default
        tooltip_text=$(echo "$pcli_json" | jq -r '.tooltip // "No timer running."')
        percentage_val=$(echo "$pcli_json" | jq -r '.percentage // 0 | tonumber // 0')
    fi

    # Then, determine Waybar class based on our script's internal state
    if [ "$_status" == "Running" ]; then
        if [ "$_session_type" == "Work" ]; then
            class_name="running work"
        elif [ "$_session_type" == "Break" ]; then
            class_name="running break"
        elif [ "$_session_type" == "Long Break" ]; then
            class_name="running long-break"
        fi
    elif [ "$_status" == "Paused" ]; then
        class_name="paused"
    elif [ "$_status" == "Stopped" ]; then
        class_name="stopped"
        # When stopped, override time_text and tooltip_text for clarity
        time_text="00:00"
        tooltip_text="Pomodoro is stopped. Click to start work."
        percentage_val="0" # Reset percentage when stopped
    fi

    # Always use _current_session_in_cycle for display, as it holds the correct value
    local current_cycle_display="${_current_session_in_cycle}/4"

    # Determine the icon based on status and session type
    local icon=""
    case "$_status" in
        "Stopped")
            icon=" 🛑 🛑 🛑  " # Stop sign emoji for stopped state
            ;;
        "Paused")
            icon="⏸️⏸️⏸️ " # Pause button emoji for paused state
            ;;
        "Running")
            case "$_session_type" in
                "Work")
                    icon="⚡ ⚡ ⚡ " # High voltage/energy for work
                    ;;
                "Break")
                    icon="☕ ☕ ☕ " # Coffee cup for short break
                    ;;
                "Long Break")
                    icon="🏖️ 🏖️ 🏖️  " # Beach for long break
                    ;;
            esac
            ;;
    esac
    local routine_display="<span foreground='#89b4fa'>${_current_routine_name}</span>" # Start with the base routine name (blue)

    # Conditionally append other task levels if they exist with different colors
    local separator=" || "
    if [ -n "$_current_category_action" ]; then
        routine_display+="${separator}<span foreground='#a6e3a1'>${_current_category_action}</span>" # Green
    fi
    if [ -n "$_current_task_name" ]; then
        routine_display+="${separator}<span foreground='#f9e2af'>${_current_task_name}</span>" # Yellow
    fi
    if [ -n "$_current_subtask_name" ]; then
        routine_display+="${separator}<span foreground='#b4befe'>${_current_subtask_name}</span>" # Lavender
    fi
    if [ -n "$_current_minitask_name" ]; then
        routine_display+="${separator}<span foreground='#fab387'>${_current_minitask_name}</span>" # Peach
    fi

    local full_text="${icon} [[${_total_pomodoro_cycles_today}]] ${_status}/${_session_type} ${time_text} (${current_cycle_display}) ${routine_display}"

    # --- DEBUGGING OUTPUT TO STDERR ---
    echo "DEBUG: pcli_json: '"$pcli_json"'" >&2
    echo "DEBUG: _status: '"$_status"'" >&2
    echo "DEBUG: _session_type: '"$_session_type"'" >&2
    echo "DEBUG: _total_pomodoro_cycles_today: '"$_total_pomodoro_cycles_today"'" >&2
    echo "DEBUG: _current_session_in_cycle: '"$_current_session_in_cycle"'" >&2
    echo "DEBUG: time_text: '"$time_text"'" >&2
    echo "DEBUG: tooltip_text: '"$tooltip_text"'" >&2
    echo "DEBUG: class_name: '"$class_name"'" >&2
    echo "DEBUG: percentage_val: '"$percentage_val"'" >&2 # Corrected to show the value
    echo "DEBUG: full_text (final display string): '"$full_text"'" >&2
    echo "DEBUG: About to call jq -nc with above arguments." >&2
    # --- END DEBUGGING OUTPUT ---

    # Final JSON output for Waybar. This MUST use jq -nc for single-line output.
    # We construct the JSON object directly using --arg values.
    jq -nc \
        --arg text_arg "$full_text" \
        --arg class_arg "$class_name" \
        --arg tooltip_arg "$tooltip_text" \
        --arg percentage_arg "$percentage_val" \
        --arg total_pomodoro_cycles_today_arg "$_total_pomodoro_cycles_today" \
        --arg current_session_in_cycle_arg "$_current_session_in_cycle" \
        '{ "text": $text_arg, "class": $class_arg, "tooltip": $tooltip_arg, "percentage": ($percentage_arg | tonumber), "total_pomodoro_cycles_today": ($total_pomodoro_cycles_today_arg | tonumber), "current_session_in_cycle": ($current_session_in_cycle_arg | tonumber) }'
}

# Daemon to continuously monitor sessions and trigger transitions.
cmd_daemon() {
    # Check if daemon is already running
    if [ -f "$DAEMON_PID_FILE" ] && kill -0 "$(cat "$DAEMON_PID_FILE")" 2>/dev/null; then
        echo "Pomodoro daemon is already running (PID: $(cat "$DAEMON_PID_FILE"))." >&2
        exit 0
    fi

    echo $$ > "$DAEMON_PID_FILE" # Store current PID

    echo "DEBUG: Pomodoro daemon started. Monitoring sessions..." >&2
    # Loop indefinitely to check the timer
    while true; do
        read_state # Always read the latest state
        reset_daily_counts # Ensure daily reset even if daemon runs continuously

        if [ "$_status" == "Running" ]; then
            # Capture raw output from pomodoro-cli, including any non-JSON prefix like "Time is up!".
            # Redirect stderr to /dev/null to prevent any unexpected error messages from pomodoro-cli.
            local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)

            # Extract only the JSON part from the raw output.
            # This sed command finds the first occurrence of '{' and prints everything from that point onwards.
            # This handles cases where "Time is up!" is on the same line or precedes the JSON.
            local pcli_status_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')

            # Add a check to ensure pcli_status_json is valid JSON before proceeding.
            # If it's not valid, default it to an empty JSON object to prevent 'jq' errors downstream.
            if ! echo "$pcli_status_json" | jq -e . >/dev/null 2>&1; then
                echo "DEBUG: Failed to parse pomodoro-cli output as JSON in daemon. Raw output was: '"$raw_pcli_output"'" >&2
                echo "DEBUG: Attempted JSON extraction resulted in: '"$pcli_status_json"'" >&2
                pcli_status_json='{}' # Fallback to empty JSON if extraction or validation fails
            fi

            # --- NEW DEBUGGING FOR DAEMON'S INTERNAL STATUS CHECK ---
            echo "DEBUG: Daemon loop: Raw pcli_json: '"$pcli_status_json"'" >&2
            # --- END NEW DEBUGGING ---

            local pcli_status_class="unknown" # Default if parsing fails or no output
            
            # Extract the 'class' field from pomodoro-cli's JSON output
            # Use // "unknown" to handle cases where .class might be null or missing
            if [[ -n "$pcli_status_json" ]]; then
                pcli_status_class=$(echo "$pcli_status_json" | jq -r '.class // "unknown"')
            fi
            # --- NEW DEBUGGING FOR DAEMON'S INTERNAL PARSED CLASS ---
            echo "DEBUG: Daemon loop: Parsed pcli_status_class: '"$pcli_status_class"'" >&2
            # --- END NEW DEBUGGING ---

            # Check if pomodoro-cli has finished its timer based on its 'class'
            if [[ "$pcli_status_class" == "finished" ]]; then
                echo "DEBUG: Daemon detected pomodoro-cli 'finished' class. Triggering transition." >&2
                handle_transition
            elif [[ "$pcli_status_class" == "stopped" ]]; then # Also check for 'stopped' class, as a fallback
                echo "DEBUG: Daemon detected pomodoro-cli 'stopped' class while script state is 'Running'. Triggering transition." >&2
                handle_transition
            fi
        fi
        sleep 1 # Check every 1 second
    done
}

# Stop the daemon process
cmd_stop_daemon() {
    if [ -f "$DAEMON_PID_FILE" ]; then
        local pid=$(cat "$DAEMON_PID_FILE")
        if kill -TERM "$pid" 2>/dev/null; then
            echo "Pomodoro daemon (PID: "$pid") stopped." >&2
            rm -f "$DAEMON_PID_FILE"
        else
            echo "Failed to stop daemon (PID: "$pid"). It might not be running or permission denied." >&2
        fi
    else
        echo "Pomodoro daemon not running (PID file not found)." >&2
    fi
}

# --- NEW FUNCTION: cmd_cleanup ---
# Command to perform a comprehensive cleanup of Pomodoro CLI related processes and files.
cmd_cleanup() {
    echo "Performing comprehensive Pomodoro CLI cleanup..." >&2

    # Stop the custom daemon if running
    ~/.config/pomodoro_cli/pomodoro_manager.sh stop-daemon &>/dev/null
    echo "Cleanup: Daemon stopped." >&2

    # Kill any lingering pomodoro-cli instances
    killall pomodoro-cli 2>/dev/null || true
    echo "Cleanup: pomodoro-cli instances killed." >&2

    # Kill any lingering yad windows (if any still exist from previous runs)
    killall yad 2>/dev/null || true
    echo "Cleanup: Yad windows killed." >&2

    # Kill any lingering swaylock instances (important for the new approach)
    killall swaylock 2>/dev/null || true
    echo "Cleanup: Swaylock instances killed." >&2

    # Capture current state before cleanup for logging purposes if a session was active
    local current_session_type_on_cleanup="$_session_type"
    local planned_duration_sec_on_cleanup=0
    case "$current_session_type_on_cleanup" in
        "Work") planned_duration_sec_on_cleanup="$(parse_duration_to_seconds "$WORK_DURATION")" ;;
        "Break") planned_duration_sec_on_cleanup="$(parse_duration_to_seconds "$SHORT_BREAK_DURATION")" ;;
        "Long Break") planned_duration_sec_on_cleanup="$(parse_duration_to_seconds "$LONG_BREAK_DURATION")" ;;
    esac

    # Attempt to get actual elapsed/remaining only if a session was running/paused
    local elapsed_on_cleanup=0
    local remaining_on_cleanup=0
    if [[ "$_status" == "Running" || "$_status" == "Paused" ]]; then
        local raw_pcli_output=$(pomodoro-cli status --format json --time-format digital 2>/dev/null)
        local pcli_json=$(echo "$raw_pcli_output" | sed -n 's/^[^\{]*\(.*\)/\1/p' || echo '{}')
        elapsed_on_cleanup=$(echo "$pcli_json" | jq -r '.elapsed // 0 | tonumber')
        remaining_on_cleanup=$(echo "$pcli_json" | jq -r '.remaining // 0 | tonumber')
    fi


    # Remove state, lock, and PID files for a fresh start (but PRESERVE DAILY_LOG_FILE and MARKDOWN_LOG_FILE)
    rm -f "$HOME/.config/pomodoro_cli/pomodoro_state.json"
    # The line below is intentionally commented out to preserve the daily log file.
    # rm -f "$HOME/.config/pomodoro_cli/pomodoro_daily_log.txt"
    rm -f "$HOME/.config/pomodoro_cli/pomodoro_lock"
    rm -f "$HOME/.config/pomodoro_cli/pomodoro_daemon.pid"
    # NEW: Also remove the last routine update timestamp file
    rm -f "$HOME/.config/pomodoro_cli/last_routine_update.timestamp"
    echo "Cleanup: State, lock, PID, and routine update timestamp files removed. Daily log file preserved." >&2

    # Also clear temporary log files and the new temporary image file
    rm -f /tmp/pomodoro_yad_output.log
    rm -f /tmp/pomodoro_break_message_*.png # Remove any generated message images
    rm -f /tmp/pomodoro_obsidian_output.log # NEW: Clean up Obsidian output log
    echo "Cleanup: Temporary log and image files cleared." >&2

    # Log the cleanup event (after most cleanup actions, but before potential Waybar restart)
    log_session_event \
        "System_Cleanup" \
        "$current_session_type_on_cleanup" \
        "$planned_duration_sec_on_cleanup" \
        "$elapsed_on_cleanup" \
        "$remaining_on_cleanup" \
        "Stopped" \
        "Comprehensive cleanup initiated. Session (if any) cancelled."

    # Optionally, restart Waybar if you're experiencing display issues (uncomment if needed)
    # killall waybar &>/dev/null && waybar &
    # echo "Cleanup: Waybar restarted (if applicable)." >&2

    echo "Comprehensive cleanup complete." >&2
}
# --- END NEW FUNCTION ---

# Command to quickly reset, start daemon, and start a new work session.
cmd_quick_start() {
    echo "Performing quick start: Stopping old daemon, restarting Waybar, starting new daemon, then starting work session..." >&2
    
    # Stop the custom daemon if running
    ~/.config/pomodoro_cli/pomodoro_manager.sh stop-daemon &>/dev/null
    echo "Quick Start: Old daemon stopped." >&2

    # Kill and restart Waybar
    echo "Quick Start: Restarting Waybar..." >&2
    killall waybar &>/dev/null || true # Kill all existing Waybar instances, suppress errors
    sleep 1 # Give Waybar a moment to terminate
    waybar & # Start Waybar in the background
    echo "Quick Start: Waybar restarted." >&2
    sleep 1 # Give Waybar a moment to initialize
    
    # Start daemon in background, redirecting its output to log file
    nohup "$0" daemon > /tmp/pomodoro_daemon_output.log 2>&1 &
    echo "Quick Start: Pomodoro daemon launched in background." >&2
    sleep 2 # Give daemon time to fully initialize
    
    # cmd_start # Removed: User prefers manual start after quick-start setup.
    echo "Quick start sequence complete." >&2
}


# Main script logic: parse arguments
case "$1" in
    start)
        cmd_start
        ;;
    pause)
        cmd_pause
        ;;
    resume)
        cmd_resume
        ;;\
    stop)
        cmd_stop
        ;;
    reset)
        cmd_reset
        ;;
    status)
        cmd_status
        ;;
    daemon)
        cmd_daemon
        ;;
    stop-daemon)
        cmd_stop_daemon
        ;;
    cleanup)
        cmd_cleanup
        ;;
    quick-start)
        cmd_quick_start
        ;;
    run-display-block)
        # This case is no longer actively used by start_session for breaks,\
        # but kept for completeness in case it's called elsewhere or for debug.
        display_break_block "$2" "$3" "$4" "$5"
        ;;
    *)
        echo "Usage: "$0" {start|pause|resume|stop|reset|status|daemon|stop-daemon|cleanup|quick-start}" >&2
        exit 1
        ;;
esac

exit 0

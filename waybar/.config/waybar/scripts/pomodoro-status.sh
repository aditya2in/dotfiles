#!/bin/bash
set -x # Add this line for debugging
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.cargo/bin:$PATH"
# Define a log file for this script for detailed debugging
LOG_FILE="/tmp/pomodoro_status_script.log"
# Clear the log file at the start of each execution (optional, for fresh logs)
# echo "" > "$LOG_FILE" # Uncomment if you want to clear log on every run

# --- NEW: Define paths for sound files and Zenity variables ---
FINISHED_SOUND_PATH="$HOME/.config/waybar/sounds/finished_sound.mp3"
START_WORK_SOUND_PATH="$HOME/.config/waybar/sounds/start_sound.mp3"
BREAK_DURATION_MINUTES=5 # 5 minutes break
POMODORO_CLI_COMMAND="pomodoro-cli" # Use the direct command, assuming it's in PATH

# Zenity constants
ZENITY_WINDOW_TITLE="Pomodoro Alert"
ZENITY_ICON_PATH="/usr/share/icons/Adwaita/scalable/actions/alarm-symbolic.svg" # A generic icon, change if you have a better one
# --- END NEW ---

# Function to generate JSON for idle/error state with an icon
generate_idle_json() {
    # Added -c here for compact output
    jq -n -c '{
        text: " Idle",
        tooltip: "Pomodoro timer is idle or error.",
        class: "idle",
        percentage: 0
    }'
}

# --- NEW: Function to handle the finished state, including sounds and popups ---
handle_finished_state() {
    echo "$(date): Pomodoro FINISHED state detected. Triggering break sequence." >> "$LOG_FILE"

    # Play continuous sound for 5 seconds in the background
    # We use `mpv --no-video --loop --end=+5 "$FINISHED_SOUND_PATH"`
    # `pgrep mpv` finds the mpv process, `xargs kill` kills it.
    pkill mpv 2>/dev/null # Ensure no previous mpv is running
    mpv --no-video --loop --end=+5 "$FINISHED_SOUND_PATH" &
    MPV_PID=$! # Capture the PID of the mpv process

    echo "$(date): Started finished sound with PID: $MPV_PID" >> "$LOG_FILE"

    # Ensure mpv is killed if script exits
    trap "kill $MPV_PID 2>/dev/null; exit" EXIT

    # Stop the current pomodoro-cli timer if it's still somehow 'finished'
    # This ensures a clean state before the break
    "$POMODORO_CLI_COMMAND" stop &>/dev/null

    # Show "BREAK TIME" popup with countdown
    # Zenity progress bar simulates a countdown
    (
        echo "0"
        echo "# BREAK TIME"
        for (( i=0; i<=$BREAK_DURATION_MINUTES*60; i++ )); do
            current_progress=$(( (i * 100) / ($BREAK_DURATION_MINUTES * 60) ))
            remaining_seconds=$(( ($BREAK_DURATION_MINUTES * 60) - i ))
            minutes=$(( remaining_seconds / 60 ))
            seconds=$(( remaining_seconds % 60 ))
            printf "%d\n# Time remaining: %02d:%02d\n" "$current_progress" "$minutes" "$seconds" || break
            sleep 1
        done
        echo "100"
    ) | zenity --progress \
        --title="$ZENITY_WINDOW_TITLE" \
        --text="Take a well-deserved break." \
        --percentage=0 \
        --pulsate \
        --auto-close \
        --no-cancel \
        --width=400 \
        --height=150 \
        --window-icon="$ZENITY_ICON_PATH" \
        --extra-button="Skip Break" \
        --hide-text # This will make the progress bar the main focus

    # Capture Zenity exit code and button click
    ZENITY_EXIT_CODE=$?
    echo "$(date): Zenity Break popup exited with code: $ZENITY_EXIT_CODE" >> "$LOG_FILE"

    # Kill the sound after the break popup is dismissed/timed out
    kill $MPV_PID 2>/dev/null
    echo "$(date): Killed finished sound (PID: $MPV_PID)." >> "$LOG_FILE"

    # Handle "Skip Break" button
    if [ "$ZENITY_EXIT_CODE" -eq 1 ]; then # Zenity returns 1 for extra buttons (first one)
        echo "$(date): Break skipped by user." >> "$LOG_FILE"
    else
        echo "$(date): Break time completed." >> "$LOG_FILE"
    fi

    # Show "START WORK" popup
    # Use Zenity --question for a single button to click
    zenity --question \
        --title="$ZENITY_WINDOW_TITLE" \
        --text="Break is over. Ready to start working?" \
        --width=300 \
        --height=100 \
        --window-icon="$ZENITY_ICON_PATH" \
        --ok-label="Start Work" \
        --cancel-label="" \
        --hide-cancel # Hides the cancel button

    START_WORK_CHOICE=$?
    echo "$(date): Zenity Start Work popup exited with code: $START_WORK_CHOICE" >> "$LOG_FILE"

    if [ "$START_WORK_CHOICE" -eq 0 ]; then # Zenity returns 0 for OK/accept
        echo "$(date): User clicked 'Start Work'. Starting new pomodoro." >> "$LOG_FILE"
        # Play start work sound
        mpv --no-video --end=+2 "$START_WORK_SOUND_PATH" &>/dev/null &

        # Start a new pomodoro session (25m default)
        "$POMODORO_CLI_COMMAND" start --add 25m --notify &>/dev/null

        # Trigger Waybar update to reflect new running state
        pkill -SIGRTMIN+10 waybar
    else
        echo "$(date): User closed 'Start Work' popup unexpectedly or chose cancel (though hidden)." >> "$LOG_FILE"
        # If the user closes the window without clicking "Start Work", it might leave
        # pomodoro-cli in a stopped state. We could potentially loop here or
        # just leave it stopped and they'd have to manually start.
        # For this setup, we'll assume "Start Work" is always clicked or the cycle breaks.
    fi
}
# --- END NEW ---

# 1. Capture raw output from pomodoro-cli, handling potential errors and timeouts
#    2>/tmp/pomodoro_cli_stderr.log redirects stderr of pomodoro-cli to a file.
#    timeout 2s prevents the command from hanging indefinitely.
pomodoro_raw_cli_output=$(timeout 2s "$POMODORO_CLI_COMMAND" status --format json --time-format digital 2>/tmp/pomodoro_cli_stderr.log)
cli_exit_code=$? # Capture the exit code of the last command (timeout)

# Log the raw output from pomodoro-cli for debugging
echo "$(date): Raw pomodoro-cli output: \"$pomodoro_raw_cli_output\"" >> "$LOG_FILE"
echo "$(date): pomodoro-cli exit code: $cli_exit_code" >> "$LOG_FILE"

# 2. Attempt to extract *only* the JSON string from the raw output.
#    This regex is more robust at finding a JSON object starting with '{' and ending with '}'.
#    It captures the first occurrence.
json_string=$(echo "$pomodoro_raw_cli_output" | grep -oP '\{.*\}' | head -n 1)

# Log the extracted JSON string
echo "$(date): Extracted JSON string: \"$json_string\"" >> "$LOG_FILE"

# Default to failure for parsing
jq_parse_success=1
pomodoro_json_parsed=""
status_class_val="idle" # Initialize status_class_val to 'idle'

# 3. Try to parse the extracted string with jq
if [ -n "$json_string" ] && echo "$json_string" | jq -e . > /dev/null 2>&1; then
    # If jq parses successfully, proceed with extracting values
    # The -c here ensures the intermediate parsed JSON is compact (already present)
    pomodoro_json_parsed=$(echo "$json_string" | jq -c '.')
    jq_parse_success=0
    echo "$(date): jq parsed successfully." >> "$LOG_FILE"

    # --- NEW: Extract status_class_val here immediately after parsing ---
    status_class_val=$(echo "$pomodoro_json_parsed" | jq -r '.class // "idle"')
    # --- END NEW ---

else
    echo "$(date): jq failed to parse extracted string or string was empty." >> "$LOG_FILE"
fi

# 4. Process the parsed JSON or fall back to idle state
if [ $jq_parse_success -eq 0 ] && [ -n "$pomodoro_json_parsed" ]; then
    # Use jq to extract fields. -r for raw output (no quotes).
    # Provide default values using // in case fields are missing or null.
    status_text_val=$(echo "$pomodoro_json_parsed" | jq -r '.text // "pomodoro"')
    tooltip_val=$(echo "$pomodoro_json_parsed" | jq -r '.tooltip // "Pomodoro timer is idle"')
    # status_class_val is already extracted above
    percentage=$(echo "$pomodoro_json_parsed" | jq -r '.percentage // 0')

    # Validate that 'percentage' is a number. If not, default to 0.
    if ! [[ "$percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        percentage=0
        echo "$(date): Invalid percentage detected, defaulting to 0." >> "$LOG_FILE"
    fi

    # Determine the icon based on the class
    icon_char=""
    case "$status_class_val" in
        "running")
            icon_char="🚀 🚀 🚀 " # Timer/running icon
            ;;
        "paused")
            icon_char=" " # Pause icon
            ;;
        "finished")
            icon_char="   " # Checkmark/completed icon
            # --- NEW: Call the handler for finished state ---
            handle_finished_state
            # After handling the finished state, we output an idle state to Waybar
            # while the popups are active, or re-run the script for updated status.
            # For simplicity, we'll output an idle state here until a new session starts.
            # This prevents Waybar from showing "finished" indefinitely.
            echo "$(generate_idle_json)"
            exit 0 # Exit the script here, as handle_finished_state takes over the cycle
            ;;
        "idle")
            icon_char=" " # Circle for idle/stopped
            ;;
        *)
            icon_char="❓ " # Fallback icon for unknown state
            echo "$(date): Unknown status class: \"$status_class_val\", using fallback icon." >> "$LOG_FILE"
            ;;
    esac

    # Generate the final Waybar JSON output using jq for robust escaping
    # IMPORTANT: Added -c here to ensure compact, single-line output for Waybar
    final_json=$(jq -n -c \
                        --arg icon_arg "$icon_char" \
                        --arg text_arg "$status_text_val" \
                        --arg tooltip_arg "$tooltip_val" \
                        --arg class_arg "$status_class_val" \
                        --argjson percentage_arg "$percentage" \
                        '{
                          text: ($icon_arg + $text_arg),
                          tooltip: $tooltip_arg,
                          class: $class_arg,
                          percentage: $percentage_arg
                        }')
    echo "$final_json"
    echo "$(date): Successfully generated and outputted JSON: \"$final_json\"" >> "$LOG_FILE"
    echo "$final_json" >> "${LOG_FILE/.log/.final_output.log}" # Log the final output
else
    # If jq failed to parse even after sanitization, or if output was empty, fall back to idle.
    generated_idle_json=$(generate_idle_json) # Capture the output of generate_idle_json
    echo "$generated_idle_json" # Print the captured output
    echo "$(date): Falling back to idle JSON output due to parsing failure or empty input." >> "$LOG_FILE"
    echo "$generated_idle_json" >> "${LOG_FILE/.log/.final_output.log}" # Log the final idle output
fi

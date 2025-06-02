#!/bin/bash

# Define a log file for this script for detailed debugging
LOG_FILE="/tmp/pomodoro_status_script.log"
# Clear the log file at the start of each execution (optional, for fresh logs)
# echo "" > "$LOG_FILE" # Uncomment if you want to clear log on every run

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

# 1. Capture raw output from pomodoro-cli, handling potential errors and timeouts
#    2>/tmp/pomodoro_cli_stderr.log redirects stderr of pomodoro-cli to a file.
#    timeout 2s prevents the command from hanging indefinitely.
pomodoro_raw_cli_output=$(timeout 2s pomodoro-cli status --format json --time-format digital 2>/tmp/pomodoro_cli_stderr.log)
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

# 3. Try to parse the extracted string with jq
if [ -n "$json_string" ] && echo "$json_string" | jq -e . > /dev/null 2>&1; then
    # If jq parses successfully, proceed with extracting values
    # The -c here ensures the intermediate parsed JSON is compact (already present)
    pomodoro_json_parsed=$(echo "$json_string" | jq -c '.')
    jq_parse_success=0
    echo "$(date): jq parsed successfully." >> "$LOG_FILE"
else
    echo "$(date): jq failed to parse extracted string or string was empty." >> "$LOG_FILE"
fi

# 4. Process the parsed JSON or fall back to idle state
if [ $jq_parse_success -eq 0 ] && [ -n "$pomodoro_json_parsed" ]; then
    # Use jq to extract fields. -r for raw output (no quotes).
    # Provide default values using // in case fields are missing or null.
    status_text_val=$(echo "$pomodoro_json_parsed" | jq -r '.text // "pomodoro"')
    tooltip_val=$(echo "$pomodoro_json_parsed" | jq -r '.tooltip // "Pomodoro timer is idle"')
    status_class_val=$(echo "$pomodoro_json_parsed" | jq -r '.class // "idle"')
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
            icon_char="🚀 🚀  " # Timer/running icon
            ;;
        "paused")
            icon_char="  " # Pause icon
            ;;
        "finished")
            icon_char="     " # Checkmark/completed icon
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

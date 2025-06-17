#!/bin/bash

# --- Source common utilities and configurations ---
source "/home/aditya/.config/waybar/scripts/pomodoro-utils.sh"

# --- Main Logic ---

pomodoro_cli_status_json="$("$POMODORO_CLI" status --format json --time-format digital 2>/dev/null | head -n 1 | tr -d '\n')"
cli_time="00:00"
cli_class="finished" # Default if pomodoro-cli is not running or provides no output

if [[ -n "$pomodoro_cli_status_json" ]]; then
    cli_time=$(echo "$pomodoro_cli_status_json" | "$JQ_PATH" -r '.time // "00:00"')
    cli_class=$(echo "$pomodoro_cli_status_json" | "$JQ_PATH" -r '.class // "finished"')
    log_message SCRIPT_DEBUG "Raw pomodoro-cli status: $pomodoro_cli_status_json"
fi

# --- Determine cycle state (current session type and count) ---
# Read directly from CYCLE_STATE_FILE without calling action.sh as that causes new processes
current_cycle_state_json=$(read_cycle_state 2>/dev/null || echo '{}') # No action.sh call needed here, utils handles it.
if [[ -z "$current_cycle_state_json" || "$current_cycle_state_json" == "null" ]]; then
    log_message ERROR "Failed to read cycle state from utils. Defaulting to finished."
    cycle_session_type="finished"
    work_sessions_completed=0
    total_pomodoros_done=0
    last_reset_date=""
else
    cycle_session_type=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.current_session_type // "finished"' 2> >(log_message ERROR "jq error for cycle_session_type from file: $(cat)"))
    work_sessions_completed=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.work_sessions_completed // 0' 2> >(log_message ERROR "jq error for work_sessions_completed from file: $(cat)"))
    total_pomodoros_done=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.total_pomodoros_done // 0' 2> >(log_message ERROR "jq error for total_pomodoros_done from file: $(cat)"))
    last_reset_date=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.last_reset_date // ""' 2> >(log_message ERROR "jq error for last_reset_date from file: $(cat)"))
fi
log_message SCRIPT_DEBUG "pomodoro-status.sh: Read cycle_session_type from file: '$cycle_session_type', work_sessions_completed: '$work_sessions_completed', total_pomodoros_done: '$total_pomodoros_done', last_reset_date: '$last_reset_date'"

# Check if pomodoro-cli reports 'finished' but our internal cycle state implies a transition is due
if [[ "$cli_class" == "finished" ]]; then
    # if cycle_session_type is 'stopped' or 'reset', it means user manually stopped/reset, don't auto-trigger
    if [[ "$cycle_session_type" != "finished" && "$cycle_session_type" != "stopped" && "$cycle_session_type" != "reset" ]]; then
        log_message SCRIPT_DEBUG "CLI is finished, but cycle state says '$cycle_session_type' was active. Triggering next session via action script."
        # Use nohup to ensure it runs independently and doesn't block Waybar or status updates
        nohup "/home/aditya/.config/waybar/scripts/pomodoro-action.sh" trigger_next_session >/dev/null 2>&1 &
        # Immediately set display to reflect a "transitioning" or "finished" state to avoid stale display
        # This will be updated by action.sh once the trigger is complete
        display_status="transitioning" # Internal temporary status for Waybar display
    fi
fi

# Read the current display state from our custom file (which is set by action.sh)
current_display_state_json=$(read_display_state)
display_status_from_file=$(echo "$current_display_state_json" | "$JQ_PATH" -r '.status // "finished"') # Default to "finished" if not set
log_message SCRIPT_DEBUG "pomodoro-status.sh: Read display_status from file: '$display_status_from_file'"


# Default values for output
text=""
tooltip=""
class=""
icon=""
color=""
percentage=0 # Always default percentage to 0 as it's not dynamically calculated yet

# Determine what to display based on pomodoro-cli's status AND our custom display_state
if [[ "$cli_class" == "running" ]]; then
    # pomodoro-cli is actively running a timer
    # Use the cycle_session_type determined above
    case "$cycle_session_type" in
        work)
            text="[[${total_pomodoros_done}]] Work 🍅 $cli_time ($work_sessions_completed/$SESSIONS_BEFORE_LONG_BREAK)"
            tooltip="Current work session. Focus time!"
            class="work"
            icon="🍅"
            color="#FAB387" # Peach
            ;;
        short_break)
            text="[[${total_pomodoros_done}]] Break ☕ $cli_time ($work_sessions_completed/$SESSIONS_BEFORE_LONG_BREAK)"
            tooltip="Enjoy your short break!"
            class="break"
            icon="☕"
            color="#F5C2E7" # Mauve
            ;;
        long_break)
            text="[[${total_pomodoros_done}]] Long Break 🏖️ $cli_time ($work_sessions_completed/$SESSIONS_BEFORE_LONG_BREAK)"
            tooltip="Time for a long, relaxing break!"
            class="long-break"
            icon="🏖️"
            color="#89B4FA" # Sky
            ;;
        *) # Fallback if cycle_session_type is unexpected or not yet set
            text="[[${total_pomodoros_done}]] Running ▶️ $cli_time"
            tooltip="Pomodoro timer is active."
            class="running"
            icon="▶️"
            color="#A6E3A1" # Green
            ;;
    esac
    # Update display_state to reflect running status immediately if it's not already
    if [[ "$display_status_from_file" != "running_work" && "$display_status_from_file" != "running" ]]; then
        log_message DEBUG "pomodoro-status.sh: CLI running, display state '$display_status_from_file', updating to 'running'."
        new_display_state=$(echo '{}' | "$JQ_PATH" --arg status "running" '.status = $status')
        echo "$new_display_state" | "$JQ_PATH" -c . > "${DISPLAY_STATE_FILE}.tmp" && mv "${DISPLAY_STATE_FILE}.tmp" "$DISPLAY_STATE_FILE"
    fi

elif [[ "$cli_class" == "finished" ]]; then
    # pomodoro-cli reports "finished" (no session running)
    # Now, check our custom display_state (from file) to differentiate stopped/reset/finished naturally
    case "$display_status_from_file" in
        stopped)
            text="[[${total_pomodoros_done}]] STOPPED 🛑 ($work_sessions_completed/$SESSIONS_BEFORE_LONG_BREAK)"
            tooltip="Pomodoro manually stopped. Click to restart."
            class="stopped"
            icon="🛑"
            color="#F38BA8" # Red
            ;;
        reset) # This means the reset command was explicitly used. (X/4) is 0, Total is preserved.
            text="[[${total_pomodoros_done}]] 00:00 🔄 (0/$SESSIONS_BEFORE_LONG_BREAK)"
            tooltip="Pomodoro current cycle reset. Click to start a new work session."
            class="reset"
            icon="🔄"
            color="#F9E2AF" # Yellow
            ;;
        ready_to_start) # For when a break finishes and it's ready for next work
            text="[[${total_pomodoros_done}]] Ready ✅ ($work_sessions_completed/$SESSIONS_BEFORE_LONG_BREAK)"
            tooltip="Break finished. Click to start next work session."
            class="ready"
            icon="✅"
            color="#A6E3A1" # Green
            ;;
        transitioning) # Acknowledge the temporary state while action.sh is working
            text="[[${total_pomodoros_done}]] Transitioning..."
            tooltip="Session ended, transitioning to next phase."
            class="transitioning"
            icon="⏳"
            color="#CBA6F7" # Lavender
            ;;
        *) # Default to finished if display_status is anything else (e.g., "finished" or uninitialized)
            text="[[${total_pomodoros_done}]] Finished ✅ ($work_sessions_completed/$SESSIONS_BEFORE_LONG_BREAK)"
            tooltip="Pomodoro session completed. Click to start a new work session."
            class="finished"
            icon="✅"
            color="#A6E3A1" # Green
            ;;
    esac
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s", "icon": "%s", "alt": "%s", "percentage": %d, "markup": "pango"}\n' \
    "$text" \
    "$tooltip" \
    "$class" \
    "$icon" \
    "${text}" \
    "$percentage"

exit 0

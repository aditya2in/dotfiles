#!/bin/bash

# --- Source common utilities and configurations ---
source "/home/aditya/.config/waybar/scripts/pomodoro-utils.sh"

# Debug line (can be removed after confirming path fix)
log_message SCRIPT_DEBUG "pomodoro-action.sh started. POMODORO_CLI is: $POMODORO_CLI, JQ_PATH is: $JQ_PATH"

# --- Main Logic ---

ACTION="$1"
log_message COMMAND_EXEC "Action requested: $ACTION"

# Read current cycle state
current_cycle_state_json=$(read_cycle_state)
current_session_type=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.current_session_type // "finished"')
work_sessions_completed=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.work_sessions_completed // 0')
total_pomodoros_done=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.total_pomodoros_done // 0')
last_reset_date=$(echo "$current_cycle_state_json" | "$JQ_PATH" -r '.last_reset_date // ""')

# Get current date for reset logic
current_date=$(date +"%Y-%m-%d")
log_message SCRIPT_DEBUG "Current date: $current_date, last_reset_date from file: '$last_reset_date'"

# Check if it's a new day and reset if needed
# The primary check is if last_reset_date is empty (first run) or different from current date.
if [[ -z "$last_reset_date" || "$last_reset_date" != "$current_date" ]]; then
    log_message INFO "New day detected or last_reset_date missing. Initiating daily counter reset process."

    # Only reset work_sessions_completed if the last recorded reset was on a *different* day.
    # This prevents resetting multiple times if action.sh runs again on the same "new" day.
    if [[ "$last_reset_date" != "$current_date" ]]; then
        work_sessions_completed=0 # Reset daily work session count
        log_message INFO "work_sessions_completed reset to 0 for the new day ($current_date)."
    else
        log_message INFO "last_reset_date was empty, setting up for first daily run. work_sessions_completed starts at 0."
        work_sessions_completed=0 # Ensure it's 0 if last_reset_date was empty
    fi

    # The last_reset_date will be updated when new_cycle_state is written below.
    # total_pomodoros_done is NOT reset daily, only work_sessions_completed.
fi


case "$ACTION" in
    start)
        # Check if already running or if it's a new day start
        if [[ "$current_session_type" == "finished" || "$current_session_type" == "stopped" || "$current_session_type" == "reset" ]]; then
            log_message INFO "Starting work session."
            "$POMODORO_CLI" start --work >/dev/null 2>&1
            new_cycle_state=$(echo '{}' | \
                "$JQ_PATH" --arg type "work" \
                            --argjson work_count "$work_sessions_completed" \
                            --argjson total_count "$total_pomodoros_done" \
                            --arg date "$current_date" \
                            '.current_session_type = $type | .work_sessions_completed = $work_count | .total_pomodoros_done = $total_count | .last_reset_date = $date')
            write_cycle_state "$new_cycle_state"
            write_display_state '{"status": "running"}'
        else
            log_message INFO "Pomodoro is already running ($current_session_type). Cannot start."
        fi
        ;;

    stop)
        log_message INFO "Stopping pomodoro."
        "$POMODORO_CLI" stop >/dev/null 2>&1
        new_cycle_state=$(echo "$current_cycle_state_json" | "$JQ_PATH" --arg type "stopped" --arg date "$current_date" '.current_session_type = $type | .last_reset_date = $date')
        write_cycle_state "$new_cycle_state"
        write_display_state '{"status": "stopped"}'
        ;;

    reset)
        log_message INFO "Resetting pomodoro cycle."
        "$POMODORO_CLI" stop >/dev/null 2>&1 # Ensure it's stopped before reset
        work_sessions_completed=0 # Reset daily work session count
        # total_pomodoros_done remains as is for overall count
        new_cycle_state=$(echo '{}' | \
            "$JQ_PATH" --arg type "reset" \
                        --argjson work_count "$work_sessions_completed" \
                        --argjson total_count "$total_pomodoros_done" \
                        --arg date "$current_date" \
                        '.current_session_type = $type | .work_sessions_completed = $work_count | .total_pomodoros_done = $total_count | .last_reset_date = $date')
        write_cycle_state "$new_cycle_state"
        write_display_state '{"status": "reset"}'
        ;;

    toggle)
        pomodoro_status="$("$POMODORO_CLI" status --format json 2>/dev/null | "$JQ_PATH" -r '.class // "finished"')"
        log_message INFO "Toggle: Current CLI status: $pomodoro_status"

        if [[ "$pomodoro_status" == "running" ]]; then
            log_message INFO "Toggle: CLI is running, stopping."
            "$POMODORO_CLI" stop >/dev/null 2>&1
            new_cycle_state=$(echo "$current_cycle_state_json" | "$JQ_PATH" --arg type "stopped" --arg date "$current_date" '.current_session_type = $type | .last_reset_date = $date')
            write_cycle_state "$new_cycle_state"
            write_display_state '{"status": "stopped"}'
        else
            log_message INFO "Toggle: CLI is not running, triggering next session (start or break)."
            # Triggering next session will handle starting work or break
            # We explicitly call it here rather than falling through to avoid re-evaluating state.
            # Using nohup to avoid blocking the current execution and ensure it runs in background
            nohup "/home/aditya/.config/waybar/scripts/pomodoro-action.sh" trigger_next_session >/dev/null 2>&1 &
        fi
        ;;

    trigger_next_session)
        pomodoro_status="$("$POMODORO_CLI" status --format json 2>/dev/null | "$JQ_PATH" -r '.class // "finished"')"
        log_message INFO "Trigger Next Session: Current CLI status from pomodoro-cli: '$pomodoro_status', Internal Cycle Type: '$current_session_type'"

        if [[ "$pomodoro_status" == "running" ]]; then
            log_message SCRIPT_DEBUG "Trigger Next: pomodoro-cli is still running. Will not auto-trigger. Exiting."
            # This case means pomodoro-cli hasn't registered end yet, or user clicked too fast.
            # No action needed, wait for CLI to finish naturally.
            exit 0 # Exit cleanly if still running
        fi

        # Logic for determining next session type (work, short break, long break)
        if [[ "$current_session_type" == "work" ]]; then
            # Increment work_sessions_completed AFTER a work session *finishes*
            work_sessions_completed=$((work_sessions_completed + 1))
            total_pomodoros_done=$((total_pomodoros_done + 1))
            log_message INFO "Completed a work session. Now work_sessions_completed: $work_sessions_completed, total_pomodoros_done: $total_pomodoros_done"

            if (( work_sessions_completed % SESSIONS_BEFORE_LONG_BREAK == 0 )); then
                log_message INFO "Starting long break."
                "$POMODORO_CLI" start --long-break >/dev/null 2>&1
                new_session_type="long_break"
            else
                log_message INFO "Starting short break."
                "$POMODORO_CLI" start --short-break >/dev/null 2>&1
                new_session_type="short_break"
            fi
        elif [[ "$current_session_type" == "short_break" || "$current_session_type" == "long_break" ]]; then
            log_message INFO "Starting next work session after a break."
            "$POMODORO_CLI" start --work >/dev/null 2>&1
            new_session_type="work"
        elif [[ "$current_session_type" == "finished" || "$current_session_type" == "stopped" || "$current_session_type" == "reset" ]]; then
            log_message INFO "Triggering start of first work session (from finished/stopped/reset/initial state)."
            "$POMODORO_CLI" start --work >/dev/null 2>&1
            new_session_type="work"
            # If starting from finished/stopped/reset, work_sessions_completed depends on daily reset
            # handled at top of script, so we just set current type and update total.
            # total_pomodoros_done is incremented upon completion of a work session.
            # For a *fresh start* it's not incremented yet.
        else
            log_message ERROR "Unknown cycle state '$current_session_type' for trigger_next_session. Defaulting to work."
            "$POMODORO_CLI" start --work >/dev/null 2>&1
            new_session_type="work"
        fi

        # Update cycle state after session determined
        new_cycle_state=$(echo '{}' | \
            "$JQ_PATH" --arg type "$new_session_type" \
                        --argjson work_count "$work_sessions_completed" \
                        --argjson total_count "$total_pomodoros_done" \
                        --arg date "$current_date" \
                        '.current_session_type = $type | .work_sessions_completed = $work_count | .total_pomodoros_done = $total_count | .last_reset_date = $date')
        write_cycle_state "$new_cycle_state"

        # Update display state based on the actual session type that was started
        if [[ "$new_session_type" == "work" ]]; then
            write_display_state '{"status": "running"}'
        elif [[ "$new_session_type" == "short_break" || "$new_session_type" == "long_break" ]]; then
            write_display_state '{"status": "break"}' # Use 'break' for display consistency
        else
            write_display_state '{"status": "finished"}' # Fallback
        fi
        ;;

    *)
        log_message ERROR "Unknown action: $ACTION"
        echo "Usage: $0 [start|stop|reset|toggle|trigger_next_session]"
        ;;
esac

exit 0

# 📚 Pomodoro CLI Technical Documentation

This document provides a comprehensive technical overview of the Pomodoro CLI application. It details the architecture, core components, key logic, configuration, and operational flows, serving as a blueprint for understanding, maintaining, or even recreating the application.

---

## 1. Introduction

The Pomodoro CLI is a command-line interface application designed to help users manage their work and break cycles using the Pomodoro Technique. It features session management, desktop notifications, screen locking during breaks, daily logging, and integration with an Obsidian vault for detailed session tracking and routine management. It operates primarily through a main shell script (`pomodoro_manager.sh`) and a background daemon.

---

## 2. Architecture Overview

The application's architecture is centered around a main `pomodoro_manager.sh` script that acts as the central orchestrator.

*   **`pomodoro_manager.sh` (Main Script):**
    *   Handles all user commands (`start`, `stop`, `pause`, `resume`, `status`, `reset`, `cleanup`, `quick-start`, `daemon`, `stop-daemon`).
    *   Manages application state (`pomodoro_state.json`).
    *   Orchestrates session transitions (Work <-> Break).
    *   Integrates with external tools for notifications (`notify-send`, `paplay`), screen locking (`loginctl`), and window management (`hyprctl`, `xdg-open`).
    *   Launches and manages the background `pomodoro-cli` timer.
    *   Logs session data to various files.
    *   Manages routine integration.

*   **`pomodoro_config.conf` (Configuration):** Stores user-configurable settings like durations, test mode, and evening lock parameters.

*   **`pomodoro_state.json` (State File):** A JSON file that persists the application's current state (status, session type, cycle counts, last run date) across script executions.

*   **`pomodoro-cli` (External Timer):** An assumed external command-line utility that handles the actual countdown timer. `pomodoro_manager.sh` interacts with it to start, pause, resume, stop, and query the timer's status.

*   **Daemon (`cmd_daemon`):** A long-running background process (launched by `pomodoro_manager.sh daemon`) that continuously monitors the `pomodoro-cli` timer. It is responsible for:
    *   Detecting session completion and triggering `handle_transition`.
    *   Performing daily resets.
    *   Managing evening screen locking.

*   **Screen Locking Mechanisms:**
    *   **Break Locker (`_break_frequent_locker`):** A separate background process launched during breaks to repeatedly lock the screen.
    *   **Evening Locker (`_evening_lock`):** Periodically called by the daemon to lock the screen during configured evening hours.

*   **Logging:**
    *   `pomodoro_daily_log.txt`: Summarizes daily Pomodoro cycles.
    *   `POMODORO mark down table data for obsidian Analysis.md`: Detailed, structured log of every session event (start, pause, resume, end, cleanup).

*   **Routine Integration:** Scripts in `RoutineTaskSubTaskScripts/` (e.g., `get_current_CategoryAction.sh`) are used to fetch and display current routine/task information, which is then incorporated into status displays and logs.

---

## 3. Core Components (Files)

### 3.1 `pomodoro_manager.sh`

The main executable script. It contains all the core logic, functions, and command handlers.

*   **Configuration Loading:** Sources `pomodoro_config.conf` and sets up default values if the config file is missing.
*   **Global Variables:** Declares internal state variables (prefixed with `_`) that hold the current status, session type, cycle counts, routine info, etc.
*   **Utility Functions:** Provides helper functions for logging, sound, notifications, duration parsing, and URL encoding.
*   **State Management:** Implements `read_state` and `write_state` for persistent storage of application state.
*   **Session Control:** Contains `start_session`, `cmd_pause`, `cmd_resume`, `cmd_stop`, `cmd_reset` for managing Pomodoro timers.
*   **Transition Logic:** `handle_transition` orchestrates the flow between work and break sessions.
*   **Daemon Logic:** `cmd_daemon` runs the background monitoring loop.
*   **Cleanup:** `cmd_cleanup` provides a comprehensive way to stop all related processes and clean up temporary files.
*   **Command Parsing:** Parses command-line arguments to execute the appropriate `cmd_` function.

### 3.2 `pomodoro_config.conf`

A simple shell script sourced by `pomodoro_manager.sh` to define configurable parameters.

*   `TEST_MODE`: "ON" or "OFF" to switch between default and test durations/delays.
*   `BREAK_LOCK_DELAY_SEC_DEFAULT`/`_TEST`: Initial grace period before frequent screen locking begins during breaks.
*   `WORK_DURATION_DEFAULT`/`_TEST`: Duration of a work session (e.g., "25m", "15s").
*   `SHORT_BREAK_DURATION_DEFAULT`/`_TEST`: Duration of a short break.
*   `LONG_BREAK_DURATION_DEFAULT`/`_TEST`: Duration of a long break.
*   `EVENING_LOCK_ENABLED`: "ON" or "OFF" to enable/disable evening screen locking.
*   `LOCK_START_TIME_CONFIG`: Time (HHMM) when evening locking starts.
*   `LOCK_FREQUENCY_CONFIG`: How often (in seconds) the screen is re-locked during breaks and evening lock.
*   `UNSCHEDULED_REMINDER_ENABLED`: "ON" or "OFF" to enable/disable pop-up reminders when no Pomodoro session is active.
*   `UNSCHEDULED_REMINDER_INTERVAL_SEC`: How often (in seconds) the unscheduled reminder will be shown if no session is active.
*   `OBSIDIAN_VAULT_PATH`: Absolute path to the user's Obsidian vault.
*   `OBSIDIAN_VAULT_NAME`: Name of the Obsidian vault.
*   `DEBUG_ENABLED`: "ON" or "OFF" for verbose debug logging.

### 3.3 `pomodoro_state.json`

A JSON file located at `$POMODORO_DIR/pomodoro_state.json` that stores the current operational state of the Pomodoro CLI.

*   `status`: Current status ("Running", "Paused", "Stopped").
*   `session_type`: Type of the current session ("Work", "Break", "Long Break", "None").
*   `total_pomodoro_cycles_today`: Number of completed Pomodoro work cycles for the current day.
*   `current_session_in_cycle`: Progress within the 4-session Pomodoro cycle (1-4).
*   `last_run_date`: The date of the last recorded activity, used for daily resets.

### 3.4 `pomodoro_daily_log.txt`

A plain text file (`$POMODORO_DIR/pomodoro_daily_log.txt`) that logs a summary of the previous day's Pomodoro activity when a new day is detected.

*   Each entry includes a timestamp, the date of the summarized day, total Pomodoros completed, and the last cycle progress.

### 3.5 `POMODORO mark down table data for obsidian Analysis.md`

A Markdown file (`$OBSIDIAN_VAULT_PATH/All Things/Journal/Pomodoro session records/POMODORO mark down table data for obsidian Analysis.md`) that serves as a detailed, structured log of every significant session event.

*   Events logged include: "Start", "Paused", "Resumed", "End (Completed)", "End (Stopped)", "End (Cancelled)", "Daily_Summary", "System_Cleanup".
*   Each entry is a row in a Markdown table, containing: `Session_ID`, `Event_Timestamp`, `Event_Type`, `Session_Type`, `Routine_Name`, `Planned_Duration_Sec`, `Actual_Duration_Sec`, `Remaining_Time_Sec`, `Status_After_Event`, `Total_Pomodoros_Today`, `Current_Cycle_Progress`, `Notes/Reason`.

### 3.6 `RoutineTaskSubTaskScripts/`

A directory containing scripts responsible for fetching and updating current routine/task information.

*   `get_current_CategoryAction.sh`: (Assumed external script) This script is run periodically by `pomodoro_manager.sh` to update the `current_routine.txt` file with the user's current routine, category, action, task, subtask, and minitask.
*   `current_routine.txt`: A file updated by `get_current_CategoryAction.sh` that `pomodoro_manager.sh` reads to display current routine information in the status output and logs.

### 3.7 `sounds/beep.wav`

A WAV audio file used for desktop notifications.

### 3.8 `web_gui/`

(If implemented) This directory would contain files for a web-based graphical user interface, typically `app.py` (Flask application), `static/` for static assets, and `templates/` for HTML templates. The `pomodoro_manager.sh web-gui` command would launch this.

---

## 4. Key Functions & Logic

### 4.1 `acquire_lock()` and `release_lock()`

*   **Purpose:** Ensures that only one instance of `pomodoro_manager.sh` can modify the state file at a time, preventing race conditions and data corruption.
*   **Mechanism:** Uses `flock` on a designated lock file (`$POMODORO_DIR/pomodoro_lock`). `acquire_lock` attempts to get an exclusive lock; if unsuccessful, it exits. `release_lock` explicitly releases the lock (though it's often implicitly released on script exit).

### 4.2 `read_state()` and `write_state()`

*   **Purpose:** `read_state` loads the application's state from `pomodoro_state.json` into global shell variables. `write_state` saves the current global shell variables back to `pomodoro_state.json`.
*   **Robustness:** `read_state` includes checks for missing, empty, or invalid JSON files and will re-initialize the state file if necessary. `write_state` uses a temporary file and atomic `mv` operation to prevent data loss during writes.
*   **Concurrency:** Both functions acquire and release the `flock` to ensure safe access to the state file.

### 4.3 `reset_daily_counts()`

*   **Purpose:** Resets the daily Pomodoro cycle counts (`_total_pomodoro_cycles_today`, `_current_session_in_cycle`) if a new day is detected.
*   **Logging:** Before resetting, it calls `log_daily_summary` to record the previous day's activity in `pomodoro_daily_log.txt` and `log_session_event` for the Markdown log.
*   **Daemon Integration:** Crucial for the daemon to maintain accurate daily counts and trigger new work sessions at the start of a new day.

### 4.4 `start_session(type, duration_str, notify_title, notify_msg)`

*   **Purpose:** Initiates a Pomodoro session (Work, Break, or Long Break).
*   **Actions:**
    *   Sets global `_status` and `_session_type` variables.
    *   Writes state.
    *   Logs the session start to the Markdown log.
    *   Starts the `pomodoro-cli` timer in the background (`nohup`).
    *   Sends a desktop notification.
    *   **Break-Specific Logic:** If the session is a "Break" or "Long Break":
        *   Performs Hyprland window manipulation (moves Obsidian to specific workspaces, fullscreen).
        *   Launches the `_break_frequent_locker` in the background.

### 4.5 `handle_transition()`

*   **Purpose:** Called by the daemon when a `pomodoro-cli` timer finishes. It determines the next session type and initiates it.
*   **Logic:**
    *   If a "Work" session just finished: Increments `_total_pomodoro_cycles_today` and `_current_session_in_cycle`. If `_current_session_in_cycle` reaches 4, it starts a "Long Break"; otherwise, a "Short Break".
    *   If a "Break" or "Long Break" just finished: Resets `_current_session_in_cycle` if it was a long break, sets `_status` to "Stopped" and `_session_type` to "None", and sends a notification.
    *   **Crucially, it calls `kill_break_locker` after any break to stop the screen locking.**
    *   Performs Hyprland window manipulation to revert Obsidian's position after a break.
    *   Logs the session completion to the Markdown log.

### 4.6 `_break_frequent_locker(duration_seconds)`

*   **Purpose:** Continuously locks the screen during a break session.
*   **Mechanism:**
    *   Runs as a background process, its PID stored in `BREAK_LOCKER_PID_FILE`.
    *   Waits for an initial `BREAK_LOCK_DELAY_SEC` grace period.
    *   Enters a loop, repeatedly calling `loginctl lock-session` every `LOCK_FREQUENCY_SEC` until the `duration_seconds` have passed.

### 4.7 `_evening_lock()`

*   **Purpose:** Locks the screen periodically during configured evening/night hours.
*   **Mechanism:** Called by the `cmd_daemon` at intervals defined by `EVENING_LOCK_INTERVAL_SEC`. It checks the current time against `LOCK_START_TIME_CONFIG` and `LOCK_END_TIME` and calls `loginctl lock-session` if within the window.

### 4.8 `cmd_daemon()`

*   **Purpose:** The main background process that keeps the Pomodoro CLI running and automates transitions.
*   **Actions:**
    *   Checks if already running (using `DAEMON_PID_FILE`).
    *   Enters an infinite loop (`while true`).
    *   Inside the loop:
        *   Calls `read_state` to get the latest state.
        *   Calls `reset_daily_counts` to handle new days.
        *   Checks for and triggers `_evening_lock` if enabled and time permits.
        *   **Unscheduled Reminder:** If no session is active, it periodically sends a desktop notification to remind the user to start a session.
        *   Queries `pomodoro-cli` status. If `pomodoro-cli` reports "finished" or "stopped" while the script's internal state is "Running", it calls `handle_transition`.
        *   Plays a continuous warning sound during the last 5 seconds of a session.
        *   Sleeps for 1 second before the next iteration.

### 4.9 `log_session_event(...)`

*   **Purpose:** Records detailed information about every significant Pomodoro event into the Markdown log file.
*   **Format:** Appends a new row to a Markdown table, ensuring the table header is present if the file is new or empty.
*   **Data Points:** Captures event type, session type, planned/actual/remaining durations, status, routine info, and cycle progress.

### 4.10 `update_current_routine_display_info()`

*   **Purpose:** Periodically updates the global variables (`_current_routine_name`, `_current_category_action`, etc.) by running `get_current_CategoryAction.sh` and parsing its output from `current_routine.txt`.
*   **Frequency Control:** Uses a timestamp file (`LAST_ROUTINE_UPDATE_TIME_FILE`) to ensure the routine script is only run at a defined `ROUTINE_UPDATE_FREQUENCY_SEC`.

---

## 5. User Commands

All commands are executed via `pomodoro_manager.sh <command>`.

*   `start`: Starts a new Pomodoro work session. If a session is already running, it prints a message.
*   `pause`: Pauses the current Pomodoro session.
*   `resume`: Resumes a paused Pomodoro session.
*   `stop`: Stops the current Pomodoro session, resets its state to "Stopped", and kills any active screen locking.
*   `reset`: Resets the current session status to "Stopped" but preserves the daily Pomodoro counts.
*   `status`: Outputs the current Pomodoro status in JSON format, primarily for Waybar integration. Includes session type, time remaining, total cycles, and routine information.
*   `daemon`: Starts the background daemon process. If already running, it prints a message.
*   `stop-daemon`: Stops the background daemon process. **Crucially, it now also calls `cmd_stop` to ensure any active session and screen locking are terminated.**
*   `cleanup`: Performs a comprehensive cleanup: stops daemon, kills `pomodoro-cli` and `yad` processes, removes state, lock, and PID files (preserving daily logs).
*   `quick-start`: A convenience command that stops the old daemon, restarts Waybar, starts a new daemon, and then starts a new work session.
*   `web-gui`: (If implemented) Launches the Python Flask web GUI.
*   `--testMode=ON|OFF`: Persistently enables or disables test mode in `pomodoro_config.conf`, which uses shorter durations for testing.
*   `--debug`: Enables verbose debug logging for the current script execution.

---

## 6. Configuration Variables

As detailed in section 3.2, these variables are defined in `pomodoro_config.conf` and control the application's behavior. They are sourced at the beginning of `pomodoro_manager.sh`.

---

## 7. Dependencies

The Pomodoro CLI relies on several external command-line tools:

*   `bash`: The shell interpreter.
*   `jq`: A lightweight and flexible command-line JSON processor, used extensively for reading and writing `pomodoro_state.json` and parsing `pomodoro-cli` output.
*   `notify-send`: Sends desktop notifications (part of `libnotify-bin` on Debian/Ubuntu).
*   `paplay` or `aplay`: Plays sound files (part of `pulseaudio-utils` or `alsa-utils`).
*   `loginctl`: Used for locking the user's session (`loginctl lock-session`). Part of `systemd`.
*   `hyprctl`: (Specific to Hyprland Wayland compositor) Used for window and workspace manipulation during breaks.
*   `xdg-open`: Opens files or URLs with the default application.
*   `flock`: For robust file locking (part of `util-linux`).
*   `pomodoro-cli`: An assumed external command-line timer utility that handles the actual countdown. Its `status --format json` output is critical for the daemon.
*   `sed`: Stream editor for text manipulation.
*   `grep`: For searching text.
*   `date`: For timestamp and date operations.
*   `kill`/`killall`: For process management.
*   `nohup`: To run processes in the background, detached from the terminal.

---

## 8. Operational Flows

### 8.1 Standard Pomodoro Cycle

1.  **Start Work:** User runs `pomodoro_manager.sh start`. `start_session` is called, `pomodoro-cli` starts a work timer.
2.  **Daemon Monitoring:** `cmd_daemon` (running in the background) continuously checks `pomodoro-cli`'s status.
3.  **Work Session Ends:** `pomodoro-cli` signals "finished". `cmd_daemon` detects this and calls `handle_transition`.
4.  **Transition to Break:** `handle_transition` determines it's time for a short break (or long break if it's the 4th cycle). It calls `start_session` for the break.
5.  **Break Session Starts:** `start_session` for break launches `_break_frequent_locker` in the background, which starts repeatedly locking the screen. Hyprland window manipulation occurs.
6.  **Break Session Ends:** `pomodoro-cli` signals "finished". `cmd_daemon` detects this and calls `handle_transition`.
7.  **Transition to Idle/Work:** `handle_transition` stops the break, calls `kill_break_locker` to stop screen locking, resets session state to "Stopped", and prompts the user to start the next work session manually. Hyprland window manipulation reverts.
8.  **Cycle Repeats:** User runs `pomodoro_manager.sh start` to begin the next work session.

### 8.2 Daily Reset

1.  **New Day Detection:** At the beginning of any `pomodoro_manager.sh` command execution (including `cmd_daemon`'s loop), `reset_daily_counts` is called.
2.  **Date Comparison:** It compares the current date with `_last_run_date` from `pomodoro_state.json`.
3.  **Logging & Reset:** If dates differ, it logs the previous day's summary, resets `_total_pomodoro_cycles_today` and `_current_session_in_cycle` to zero, updates `_last_run_date`, and writes the new state.

### 8.3 Evening Lock

1.  **Daemon Active:** `cmd_daemon` is running.
2.  **Periodic Check:** Every `EVENING_LOCK_INTERVAL_SEC`, `cmd_daemon` calls `_evening_lock`.
3.  **Time Window:** `_evening_lock` checks if the current time falls within the `LOCK_START_TIME_CONFIG` and `LOCK_END_TIME` range.
4.  **Lock:** If within the window, `loginctl lock-session` is executed.

---

## 9. Testing & Debugging

*   **`TEST_MODE`:** Setting `TEST_MODE="ON"` in `pomodoro_config.conf` (or using `--testMode=ON` command-line argument) switches to much shorter durations for work and breaks, facilitating quick testing of the entire cycle.
*   **`DEBUG_MODE`:** Setting `DEBUG_ENABLED="ON"` in `pomodoro_config.conf` (or using `--debug` command-line argument) enables verbose `debug_log` messages to stderr, providing detailed insights into script execution.
*   **`pomodoro-cli status --format json`:** This command is invaluable for debugging the timer's state.
*   **Log Files:** `pomodoro_daily_log.txt` and `POMODORO mark down table data for obsidian Analysis.md` provide historical data for analysis.
*   **PID Files:** `pomodoro_daemon.pid` and `break_locker.pid` can be used to check if processes are running and to manually kill them if necessary (though `cmd_cleanup` is preferred).

---

## 10. Future Enhancements/Considerations

*   **More Robust Error Handling:** Implement more specific error handling for external command failures (e.g., `jq` not found, `notify-send` failing).
*   **User-Defined Sounds:** Allow users to configure custom sound files for different events.
*   **Cross-Platform Compatibility:** Currently heavily reliant on Linux-specific tools (`loginctl`, `hyprctl`, `notify-send`). Could be extended with platform-agnostic alternatives or conditional logic.
*   **Configuration Management:** A more sophisticated configuration system (e.g., using `toml` or `yaml` with a Python parser) could offer more flexibility than a simple sourced shell script.
*   **Web GUI Expansion:** Develop the `web_gui` further to provide full control and visualization of the Pomodoro state.
*   **Obsidian Integration:** Deeper integration with Obsidian, perhaps allowing the script to read tasks directly from Obsidian notes.
*   **Test Suite:** Implement a dedicated test suite (e.g., using `bats` or `shunit2`) for automated testing of script functions.
*   **Dynamic Routine Updates:** Explore ways to trigger `update_current_routine_display_info` more dynamically, perhaps via file system watches, rather than just time-based polling.
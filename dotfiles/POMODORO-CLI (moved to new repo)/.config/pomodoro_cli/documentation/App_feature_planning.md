# 📝 Pomodoro CLI: Master Feature Planning Document

This document provides a comprehensive, detailed, and interconnected overview of all features within the Pomodoro CLI application. It serves as a master planning and reference guide, utilizing internal linking for easy navigation to detailed feature descriptions.

---

## 🚀 Master Feature Table

| Feature Group | Feature | Mini Features | Description | Related Components/Files | Dependencies | User Command/Function | Operational Flow | Testing Notes |
|---|---|---|---|---|---|---|---|---|
| **Session Management** | [[#Core Pomodoro Timer]] | Start, Pause, Resume, Stop, Reset | Manages the core Pomodoro work and break timers. | `pomodoro_manager.sh`, `pomodoro-cli` | `pomodoro-cli` | `start`, `pause`, `resume`, `stop`, `reset` | Standard Pomodoro Cycle | `TEST_MODE`, `pomodoro-cli status --format json` |
| | [[#Session State Management]] | Persist state, Read state, Write state, Handle missing/invalid state | Manages the application's current operational state persistently. | `pomodoro_state.json`, `pomodoro_manager.sh` (`read_state`, `write_state`) | `jq`, `flock` | N/A | `acquire_lock()`, `release_lock()`, `read_state()`, `write_state()` | Check `pomodoro_state.json` content. |
| | [[#Session Transitions]] | Automatic transition, Long Break logic, Reset after break | Orchestrates the flow between work and break sessions automatically. | `pomodoro_manager.sh` (`handle_transition`, `start_session`) | `pomodoro-cli` | N/A | Standard Pomodoro Cycle | `TEST_MODE` |
| **Daemon & Automation** | [[#Background Daemon]] | Monitor timer, Handle transitions, Daily resets, Evening lock, Prevent multiple instances | Long-running background process that automates session management and daily tasks. | `pomodoro_manager.sh` (`cmd_daemon`), `pomodoro_daemon.pid` | `pomodoro-cli`, `jq`, `flock` | `daemon`, `stop-daemon` | `cmd_daemon()` | Check `pomodoro_daemon.pid`, `DEBUG_MODE` |
| | [[#Daily Reset]] | Reset cycle counts, Log daily summary | Resets daily Pomodoro counts and logs previous day's summary. | `pomodoro_manager.sh` (`reset_daily_counts`), `pomodoro_daily_log.txt`, `pomodoro_state.json` | `date` | N/A (automated by daemon) | Daily Reset | Change system date, check log files. |
| **Screen Locking** | [[#Break Screen Locking]] | Automatic lock during breaks, Configurable grace period, Repeated re-lock, Stop locker | Ensures the screen is locked during break sessions to enforce breaks. | `pomodoro_manager.sh` (`_break_frequent_locker`), `break_countdown_locker.sh`, `pomodoro_config.conf` | `loginctl` | N/A (automated during break) | Standard Pomodoro Cycle (Break Session Starts) | `TEST_MODE`, observe screen lock behavior. |
| | [[#Evening Screen Locking]] | Periodic lock, Enable/disable, Configurable start time | Locks the screen during configured evening/night hours. | `pomodoro_manager.sh` (`_evening_lock`), `pomodoro_config.conf` | `loginctl` | N/A (automated by daemon) | Evening Lock | Adjust system time, observe screen lock behavior. |
| **Logging & Reporting** | [[#Daily Summary Log]] | Summarize daily activity, Include timestamp/date/total Pomodoros/cycle progress | Provides a summary of daily Pomodoro activity. | `pomodoro_daily_log.txt`, `pomodoro_manager.sh` (`log_daily_summary`) | `date` | N/A (automated during daily reset) | Daily Reset | Check `pomodoro_daily_log.txt` content. |
| | [[#Detailed Session Event Log]] | Log significant events, Markdown table format, Capture detailed data points | Records detailed information about every significant Pomodoro event. | `POMODORO mark down table data for obsidian Analysis.md`, `pomodoro_manager.sh` (`log_session_event`) | N/A | N/A (automated on events) | `log_session_event(...)` | Check Markdown log file content. |
| **Integration** | [[#Obsidian Integration]] | Log detailed session data, Configure vault path/name | Integrates with Obsidian to log detailed session data for analysis. | `POMODORO mark down table data for obsidian Analysis.md`, `pomodoro_config.conf` (`OBSIDIAN_VAULT_PATH`, `OBSIDIAN_VAULT_NAME`) | Obsidian (external application) | N/A | `log_session_event(...)` | Check Obsidian vault for log file. |
| | [[#Routine Management]] | Fetch routine info, Display routine, Update periodically | Fetches and displays current routine/task information. | `RoutineTaskSubTaskScripts/`, `get_current_CategoryAction.sh`, `current_routine.txt`, `pomodoro_manager.sh` (`update_current_routine_display_info`) | `get_current_CategoryAction.sh` (external script) | N/A | `update_current_routine_display_info()` | Check status output and log for routine info. |
| | [[#Desktop Notifications]] | Send notifications, Play sound | Provides visual and auditory notifications for session events. | `pomodoro_manager.sh`, `sounds/beep.wav` | `notify-send`, `paplay` or `aplay` | N/A | `start_session`, `handle_transition` | Observe notifications and sounds. |
| | [[#Window Management (Hyprland)]] | Move/resize windows during breaks, Revert positions | Manipulates Hyprland windows (e.g., Obsidian) during breaks. | `pomodoro_manager.sh` (`start_session`, `handle_transition`) | `hyprctl` | N/A | Standard Pomodoro Cycle (Break Session Starts/Ends) | Observe window behavior in Hyprland. |
| **Configuration** | [[#Main Configuration File]] | User-configurable settings, Test Mode settings, Durations, Evening lock settings, Obsidian settings, Debug logging | Centralized configuration for the application's behavior. | `pomodoro_config.conf`, `pomodoro_manager.sh` (sources config) | N/A | N/A | Configuration Loading | Modify `pomodoro_config.conf` and observe changes. |
| | [[#Command-line Overrides]] | Persist Test Mode, Temporary debug mode | Allows overriding configuration settings via command-line arguments. | `pomodoro_manager.sh` (command parsing) | N/A | `--testMode=ON \| OFF`, `--debug` | Command Parsing | Run commands with flags and observe behavior. |
| **User Interface** | [[#Command-Line Interface (CLI)]] | Clear commands, JSON status output, Quick restarts | Provides a command-line interface for user interaction. | `pomodoro_manager.sh` | `jq` (for status output) | `start`, `pause`, `resume`, `stop`, `reset`, `status`, `daemon`, `stop-daemon`, `cleanup`, `quick-start` | Command Parsing | Execute commands and check output. |
| | [[#Web GUI (Future)]] | Launch web GUI | Placeholder for a future web-based graphical user interface. | `web_gui/` (app.py, static/, templates/) | Python Flask (assumed) | `web-gui` | N/A | Launch web GUI and interact. |
| **System & Utilities** | [[#Concurrency Control]] | Prevent race conditions, Safe state file access | Ensures only one instance of the script modifies the state file at a time. | `pomodoro_manager.sh` (`acquire_lock`, `release_lock`), `pomodoro_lock` | `flock` | N/A | `acquire_lock()` and `release_lock()` | Run multiple instances concurrently. |
| | [[#Cleanup]] | Stop processes, Remove temporary files | Provides a comprehensive way to stop all related processes and clean up temporary files. | `pomodoro_manager.sh` (`cmd_cleanup`) | `kill`, `killall` | `cleanup` | N/A | Run `cleanup` and verify processes/files are gone. |
| | [[#Testing & Debugging]] | Test Mode, Debug Mode, Timer status access | Provides tools and modes for testing and debugging the application. | `pomodoro_config.conf`, `pomodoro_manager.sh` | `pomodoro-cli` | `--testMode=ON \| OFF`, `--debug`, `pomodoro-cli status --format json` | N/A | Use these modes/commands to verify functionality. |

---

## 📚 Detailed Feature Descriptions

### Core Pomodoro Timer

*   **Description:** This is the fundamental feature of the Pomodoro CLI, responsible for managing the work and break countdowns according to the Pomodoro Technique. It allows users to initiate, control, and reset their Pomodoro sessions.
*   **Mini Features:**
    *   **Start:** Initiates a new Pomodoro work session.
    *   **Pause:** Temporarily halts the active Pomodoro session.
    *   **Resume:** Continues a previously paused Pomodoro session.
    *   **Stop:** Terminates the current Pomodoro session, resetting its state.
    *   **Reset:** Resets the current session status to "Stopped" without affecting daily Pomodoro counts.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh`: Contains the core logic for `start_session`, `cmd_pause`, `cmd_resume`, `cmd_stop`, `cmd_reset`.
    *   `pomodoro-cli`: An external command-line utility that handles the actual countdown timer. `pomodoro_manager.sh` interacts with it.
*   **Dependencies:**
    *   `pomodoro-cli`: Essential for the timer functionality.
*   **User Command/Function:**
    *   `pomodoro_manager.sh start`
    *   `pomodoro_manager.sh pause`
    *   `pomodoro_manager.sh resume`
    *   `pomodoro_manager.sh stop`
    *   `pomodoro_manager.sh reset`
*   **Operational Flow:** Part of the [[#Standard Pomodoro Cycle]]. When a session starts, `pomodoro-cli` is launched in the background. The daemon monitors its status.
*   **Testing Notes:**
    *   Use `--testMode=ON` to set shorter durations for quick testing of the full cycle.
    *   Monitor `pomodoro-cli status --format json` to check the timer's internal state.

### Session State Management

*   **Description:** This feature ensures the persistence of the application's operational state across different script executions and system reboots. It prevents data loss and allows the Pomodoro CLI to resume from where it left off.
*   **Mini Features:**
    *   **Persist state:** Stores the current status, session type, cycle counts, and last run date.
    *   **Read state:** Loads the application's state from `pomodoro_state.json` into global shell variables.
    *   **Write state:** Saves the current global shell variables back to `pomodoro_state.json`.
    *   **Handle missing/invalid state:** Re-initializes the state file if it's missing, empty, or contains invalid JSON.
*   **Related Components/Files:**
    *   `pomodoro_state.json`: The JSON file where the state is stored.
    *   `pomodoro_manager.sh`: Implements `read_state` and `write_state` functions.
*   **Dependencies:**
    *   `jq`: Used for parsing and manipulating JSON data in `pomodoro_state.json`.
    *   `flock`: Used for file locking to prevent race conditions during state file access.
*   **User Command/Function:** N/A (internal functions, not directly called by user commands).
*   **Operational Flow:**
    *   `acquire_lock()` and `release_lock()`: Ensure exclusive access to the state file.
    *   `read_state()`: Called at the beginning of most `pomodoro_manager.sh` executions and within the daemon loop.
    *   `write_state()`: Called after any state change, using a temporary file and atomic `mv` for robustness.
*   **Testing Notes:**
    *   Manually inspect the content of `pomodoro_state.json` after various operations (start, pause, stop, daemon restart).
    *   Delete `pomodoro_state.json` and run a command to verify re-initialization.

### Session Transitions

*   **Description:** This feature automates the flow between different Pomodoro session types (Work, Short Break, Long Break) based on completed cycles. It ensures a smooth and consistent application of the Pomodoro Technique.
*   **Mini Features:**
    *   **Automatic transition:** Automatically moves from a completed work session to a break, or from a break back to an idle state.
    *   **Long Break logic:** Initiates a "Long Break" after every 4 completed Pomodoro work cycles.
    *   **Reset after break:** Resets the session state to "Stopped" after a break ends, prompting the user to start the next work session manually.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh`: Contains the `handle_transition` function, which is the core logic for this feature, and calls `start_session`.
*   **Dependencies:**
    *   `pomodoro-cli`: The daemon relies on its status to detect session completion.
*   **User Command/Function:** N/A (automated by the daemon).
*   **Operational Flow:** Part of the [[#Standard Pomodoro Cycle]]. The `cmd_daemon` detects when `pomodoro-cli` finishes a session and then calls `handle_transition` to determine and initiate the next session.
*   **Testing Notes:**
    *   Use `--testMode=ON` to quickly simulate multiple cycles and verify correct transitions between work, short breaks, and long breaks.
    *   Observe notifications and state changes during transitions.

### Background Daemon

*   **Description:** The daemon is a critical long-running background process that ensures the continuous operation and automation of the Pomodoro CLI. It monitors the timer, handles transitions, performs daily resets, and manages evening screen locking.
*   **Mini Features:**
    *   **Monitor timer:** Continuously queries the `pomodoro-cli` status to detect session completion.
    *   **Handle transitions:** Triggers `handle_transition` when a session finishes.
    *   **Daily resets:** Initiates the daily Pomodoro count reset at the start of a new day.
    *   **Manage evening lock:** Periodically checks and applies evening screen locking if enabled.
    *   **Prevent multiple instances:** Ensures only one daemon instance is running at a time.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh` (`cmd_daemon` function): Contains the main loop and logic for the daemon.
    *   `pomodoro_daemon.pid`: Stores the PID of the running daemon to prevent multiple instances.
*   **Dependencies:**
    *   `pomodoro-cli`: For querying timer status.
    *   `jq`: For parsing `pomodoro-cli` JSON output.
    *   `flock`: For ensuring single instance and safe state file access.
*   **User Command/Function:**
    *   `pomodoro_manager.sh daemon`: Starts the background daemon.
    *   `pomodoro_manager.sh stop-daemon`: Stops the background daemon.
*   **Operational Flow:** The `cmd_daemon()` function enters an infinite loop, periodically reading state, checking for new days, managing evening lock, and querying the `pomodoro-cli` status to trigger transitions.
*   **Testing Notes:**
    *   Check for the existence of `pomodoro_daemon.pid` after starting the daemon.
    *   Use `ps aux | grep pomodoro_manager.sh` to verify the daemon process is running.
    *   Enable `DEBUG_ENABLED="ON"` in `pomodoro_config.conf` or use `--debug` to see verbose daemon logs.

### Daily Reset

*   **Description:** This feature automatically resets the daily Pomodoro cycle counts at the beginning of a new day. It also logs a summary of the previous day's activity, providing a clear record of daily productivity.
*   **Mini Features:**
    *   **Reset cycle counts:** Sets `_total_pomodoro_cycles_today` and `_current_session_in_cycle` to zero.
    *   **Log daily summary:** Records the previous day's activity in `pomodoro_daily_log.txt` and the detailed Markdown log.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh` (`reset_daily_counts` function): Contains the logic for detecting a new day and performing the reset.
    *   `pomodoro_daily_log.txt`: The file where daily summaries are logged.
    *   `pomodoro_state.json`: Stores `_last_run_date` for new day detection.
*   **Dependencies:**
    *   `date`: Used for comparing current date with the last run date.
*   **User Command/Function:** N/A (automated by the daemon or any `pomodoro_manager.sh` command execution).
*   **Operational Flow:** The `reset_daily_counts()` function is called at the start of any `pomodoro_manager.sh` command or within the `cmd_daemon` loop. It compares the current date with `_last_run_date` and, if different, logs the summary and resets counts.
*   **Testing Notes:**
    *   Manually change your system date to a new day and then run any `pomodoro_manager.sh` command or ensure the daemon is running.
    *   Check the content of `pomodoro_daily_log.txt` and the detailed Markdown log for the daily summary entry.

### Break Screen Locking

*   **Description:** This feature enforces breaks by automatically locking the user's screen during short and long break sessions. It includes a configurable grace period and repeatedly re-locks the screen to ensure the user steps away.
*   **Mini Features:**
    *   **Automatic lock during breaks:** Initiates screen locking when a break session begins.
    *   **Configurable grace period:** Allows a short delay before the first lock, giving the user time to prepare.
    *   **Repeated re-lock:** Continuously re-locks the screen at a set frequency throughout the break.
    *   **Stop locker:** Terminates the screen locking process when the break ends or is manually stopped.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh` (`_break_frequent_locker` function): The background process responsible for locking.
    *   `break_countdown_locker.sh`: A separate script that might be used for the actual locking mechanism.
    *   `pomodoro_config.conf`: Configures `BREAK_LOCK_DELAY_SEC_DEFAULT`/`_TEST` and `LOCK_FREQUENCY_CONFIG`.
*   **Dependencies:**
    *   `loginctl`: The command-line tool used to lock the user's session (`loginctl lock-session`).
*   **User Command/Function:** N/A (automated during break sessions).
*   **Operational Flow:** Part of the [[#Standard Pomodoro Cycle]]. When `start_session` is called for a "Break" or "Long Break", `_break_frequent_locker` is launched in the background. It waits for a grace period, then loops, calling `loginctl lock-session` periodically. `kill_break_locker` is called by `handle_transition` to stop it.
*   **Testing Notes:**
    *   Use `--testMode=ON` to quickly enter and exit break sessions.
    *   Observe the screen locking behavior and ensure it stops when the break ends or is stopped.

### Evening Screen Locking

*   **Description:** This feature provides an optional mechanism to periodically lock the user's screen during configured evening or night hours. This can help enforce a winding-down period or signal the end of the workday.
*   **Mini Features:**
    *   **Periodic lock:** Locks the screen at regular intervals during the configured time window.
    *   **Enable/disable:** Can be turned on or off via configuration.
    *   **Configurable start time:** Allows the user to define when the evening locking period begins.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh` (`_evening_lock` function): Contains the logic for checking time and locking.
    *   `pomodoro_config.conf`: Configures `EVENING_LOCK_ENABLED`, `LOCK_START_TIME_CONFIG`, and `LOCK_FREQUENCY_CONFIG`.
*   **Dependencies:**
    *   `loginctl`: The command-line tool used to lock the user's session.
*   **User Command/Function:** N/A (automated by the daemon).
*   **Operational Flow:** The `_evening_lock()` function is called by the `cmd_daemon` at intervals defined by `EVENING_LOCK_INTERVAL_SEC`. It checks the current time against the configured start and end times and calls `loginctl lock-session` if within the window.
*   **Testing Notes:**
    *   Adjust your system time to fall within the configured evening lock window.
    *   Ensure the daemon is running and observe if the screen locks periodically.
    *   Toggle `EVENING_LOCK_ENABLED` in `pomodoro_config.conf` to test enable/disable functionality.

### Daily Summary Log

*   **Description:** This feature generates a concise summary of the previous day's Pomodoro activity. It provides a quick overview of productivity and cycle completion, stored in a simple text file.
*   **Mini Features:**
    *   **Summarize daily activity:** Aggregates data for the previous day.
    *   **Include timestamp/date/total Pomodoros/cycle progress:** Provides key metrics for the summarized day.
*   **Related Components/Files:**
    *   `pomodoro_daily_log.txt`: The plain text file where daily summaries are appended.
    *   `pomodoro_manager.sh` (`log_daily_summary` function): Responsible for formatting and writing the summary.
*   **Dependencies:**
    *   `date`: Used for generating timestamps and dates.
*   **User Command/Function:** N/A (automated during daily reset).
*   **Operational Flow:** Part of the [[#Daily Reset]] operational flow. Before resetting daily counts, `log_daily_summary` is called to record the previous day's data.
*   **Testing Notes:**
    *   Perform some Pomodoro cycles, then change your system date to the next day.
    *   Run any `pomodoro_manager.sh` command or ensure the daemon is running to trigger the daily reset.
    *   Check the content of `pomodoro_daily_log.txt` for the new summary entry.

### Detailed Session Event Log

*   **Description:** This feature provides a highly detailed, structured log of every significant Pomodoro session event. It records granular data points in a Markdown table format, suitable for in-depth analysis and integration with tools like Obsidian.
*   **Mini Features:**
    *   **Log significant events:** Records "Start", "Paused", "Resumed", "End (Completed)", "End (Stopped)", "End (Cancelled)", "Daily_Summary", "System_Cleanup".
    *   **Markdown table format:** Appends new entries as rows in a Markdown table, ensuring header presence.
    *   **Capture detailed data points:** Includes `Session_ID`, `Event_Timestamp`, `Event_Type`, `Session_Type`, `Routine_Name`, `Planned_Duration_Sec`, `Actual_Duration_Sec`, `Remaining_Time_Sec`, `Status_After_Event`, `Total_Pomodoros_Today`, `Current_Cycle_Progress`, `Notes/Reason`.
*   **Related Components/Files:**
    *   `POMODORO mark down table data for obsidian Analysis.md`: The Markdown file where detailed session events are logged.
    *   `pomodoro_manager.sh` (`log_session_event` function): Responsible for formatting and writing the event data.
*   **Dependencies:** N/A (relies on shell scripting for file manipulation).
*   **User Command/Function:** N/A (automated on various session events).
*   **Operational Flow:** The `log_session_event(...)` function is called by `start_session`, `handle_transition`, `cmd_pause`, `cmd_resume`, `cmd_stop`, `cmd_reset`, `cmd_cleanup`, and `reset_daily_counts` to record relevant events.
*   **Testing Notes:**
    *   Perform various Pomodoro operations (start, pause, resume, stop, complete cycles).
    *   Check the `POMODORO mark down table data for obsidian Analysis.md` file to ensure all events are logged correctly with accurate data.

### Obsidian Integration

*   **Description:** This feature facilitates deeper integration with Obsidian, a popular knowledge base application. It allows the Pomodoro CLI to log detailed session data directly into a specified Markdown file within an Obsidian vault, enabling users to analyze their productivity within their existing knowledge management system.
*   **Mini Features:**
    *   **Log detailed session data:** Utilizes the [[#Detailed Session Event Log]] to write data to an Obsidian-compatible Markdown file.
    *   **Configure vault path/name:** Allows users to specify the absolute path and name of their Obsidian vault.
*   **Related Components/Files:**
    *   `POMODORO mark down table data for obsidian Analysis.md`: The target Markdown file within the Obsidian vault.
    *   `pomodoro_config.conf`: Configures `OBSIDIAN_VAULT_PATH` and `OBSIDIAN_VAULT_NAME`.
*   **Dependencies:**
    *   Obsidian (external application): The data is formatted for Obsidian, but Obsidian itself is not directly controlled by the script beyond file writing.
*   **User Command/Function:** N/A (logging is automated).
*   **Operational Flow:** The `log_session_event` function constructs the full path to the Obsidian log file using `OBSIDIAN_VAULT_PATH` and `OBSIDIAN_VAULT_NAME` from `pomodoro_config.conf` before writing the event data.
*   **Testing Notes:**
    *   Ensure `OBSIDIAN_VAULT_PATH` and `OBSIDIAN_VAULT_NAME` are correctly set in `pomodoro_config.conf`.
    *   Perform Pomodoro sessions and then check the specified file within your Obsidian vault to confirm data is being written and rendered correctly.

### Routine Management

*   **Description:** This feature integrates with external scripts to fetch and display the user's current routine or task information. This information is then incorporated into status displays and logs, providing context to Pomodoro sessions.
*   **Mini Features:**
    *   **Fetch routine info:** Executes an external script (`get_current_CategoryAction.sh`) to retrieve current routine details.
    *   **Display routine:** Shows the current routine information in the Pomodoro CLI's status output.
    *   **Update periodically:** Updates the routine information at a defined frequency.
*   **Related Components/Files:**
    *   `RoutineTaskSubTaskScripts/`: Directory containing routine-related scripts.
    *   `get_current_CategoryAction.sh`: The external script that provides routine information.
    *   `current_routine.txt`: A temporary file updated by `get_current_CategoryAction.sh` and read by `pomodoro_manager.sh`.
    *   `pomodoro_manager.sh` (`update_current_routine_display_info` function): Manages the execution and parsing of the routine script.
*   **Dependencies:**
    *   `get_current_CategoryAction.sh` (external script): This script must exist and function correctly to provide routine data.
*   **User Command/Function:** N/A (automated).
*   **Operational Flow:** The `update_current_routine_display_info()` function is called periodically. It runs `get_current_CategoryAction.sh`, reads `current_routine.txt`, and updates internal variables (`_current_routine_name`, `_current_category_action`, etc.).
*   **Testing Notes:**
    *   Ensure `get_current_CategoryAction.sh` is executable and outputs the expected format to `current_routine.txt`.
    *   Check the output of `pomodoro_manager.sh status` and the detailed session logs to verify routine information is displayed correctly.

### Desktop Notifications

*   **Description:** This feature provides timely visual and auditory alerts for various Pomodoro session events, such as session start, end, and transitions. This keeps the user informed without needing to constantly check the CLI.
*   **Mini Features:**
    *   **Send notifications:** Displays desktop notifications using `notify-send`.
    *   **Play sound:** Plays an audible alert using `paplay` or `aplay` alongside notifications.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh`: Contains functions for sending notifications and playing sounds.
    *   `sounds/beep.wav`: The audio file used for notifications.
*   **Dependencies:**
    *   `notify-send`: For displaying desktop notifications (e.g., `libnotify-bin` on Debian/Ubuntu).
    *   `paplay` or `aplay`: For playing sound files (e.g., `pulseaudio-utils` or `alsa-utils`).
*   **User Command/Function:** N/A (automated on session events).
*   **Operational Flow:** Notifications and sounds are triggered by `start_session` (session start), `handle_transition` (session end/transition), and potentially other event-driven functions.
*   **Testing Notes:**
    *   Perform `pomodoro_manager.sh start`, let sessions complete, and observe if notifications pop up and sounds play.
    *   Ensure `paplay` or `aplay` is correctly configured and the `beep.wav` file is accessible.

### Window Management (Hyprland)

*   **Description:** (Specific to Hyprland Wayland compositor) This feature automatically manipulates application windows, such as Obsidian, during break sessions. It can move and resize windows to specific workspaces or fullscreen them, and then revert their positions after the break, optimizing the user's workspace for focus and relaxation.
*   **Mini Features:**
    *   **Move/resize windows during breaks:** Adjusts window properties (e.g., moves Obsidian to specific workspaces, fullscreen).
    *   **Revert positions after breaks:** Restores windows to their original state or a predefined post-break state.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh`: Contains the `hyprctl` commands within `start_session` (for breaks) and `handle_transition` (after breaks).
*   **Dependencies:**
    *   `hyprctl`: The command-line utility for interacting with the Hyprland compositor.
*   **User Command/Function:** N/A (automated during session transitions).
*   **Operational Flow:** When a break session starts, `start_session` executes `hyprctl` commands. When the break ends, `handle_transition` executes `hyprctl` commands to revert the changes.
*   **Testing Notes:**
    *   Ensure you are running Hyprland.
    *   Perform Pomodoro cycles that include breaks and observe if Obsidian (or other configured applications) windows are manipulated as expected.
    *   Verify that windows revert correctly after the break.

### Main Configuration File

*   **Description:** This feature provides a centralized and easily editable file (`pomodoro_config.conf`) for all user-configurable settings. It allows users to customize various aspects of the Pomodoro CLI's behavior without modifying the main script.
*   **Mini Features:**
    *   **User-configurable settings:** Defines parameters like durations, locking behavior, and logging paths.
    *   **Test Mode settings:** Separate durations for work and breaks specifically for testing.
    *   **Configurable work and break durations:** `WORK_DURATION`, `SHORT_BREAK_DURATION`, `LONG_BREAK_DURATION`.
    *   **Configurable evening lock settings:** `EVENING_LOCK_ENABLED`, `LOCK_START_TIME_CONFIG`, `LOCK_FREQUENCY_CONFIG`.
    *   **Configurable Obsidian integration:** `OBSIDIAN_VAULT_PATH`, `OBSIDIAN_VAULT_NAME`.
    *   **Enable/disable debug logging:** `DEBUG_ENABLED`.
*   **Related Components/Files:**
    *   `pomodoro_config.conf`: The shell script sourced for configuration.
    *   `pomodoro_manager.sh`: Sources `pomodoro_config.conf` at startup.
*   **Dependencies:** N/A (standard shell sourcing).
*   **User Command/Function:** N/A (manual editing of `pomodoro_config.conf`).
*   **Operational Flow:** At the beginning of `pomodoro_manager.sh` execution, `pomodoro_config.conf` is sourced, loading all defined variables into the script's environment.
*   **Testing Notes:**
    *   Modify various settings in `pomodoro_config.conf` and observe if the application's behavior changes accordingly.
    *   Test both `_DEFAULT` and `_TEST` durations by toggling `TEST_MODE`.

### Command-line Overrides

*   **Description:** This feature allows users to temporarily or persistently override certain configuration settings directly from the command line. This is useful for quick adjustments or for testing specific behaviors without editing the main configuration file.
*   **Mini Features:**
    *   **Persist Test Mode:** Allows enabling or disabling test mode permanently via a command-line flag.
    *   **Temporary debug mode:** Enables verbose debug logging for a single script execution.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh`: Contains the command-line argument parsing logic.
*   **Dependencies:** N/A.
*   **User Command/Function:**
    *   `pomodoro_manager.sh --testMode=ON|OFF`
    *   `pomodoro_manager.sh --debug`
*   **Operational Flow:** The `pomodoro_manager.sh` script parses its command-line arguments. If `--testMode` is present, it updates `pomodoro_config.conf`. If `--debug` is present, it sets an internal debug flag for the current run.
*   **Testing Notes:**
    *   Run `pomodoro_manager.sh --testMode=ON` and then `pomodoro_manager.sh status` to confirm test mode is active.
    *   Run `pomodoro_manager.sh --debug start` and observe verbose output on stderr.

### Command-Line Interface (CLI)

*   **Description:** The primary user interface for the Pomodoro CLI, providing a set of clear and intuitive commands for all application actions. It also offers structured output for integration with other tools.
*   **Mini Features:**
    *   **Clear commands:** Provides distinct commands for starting, pausing, stopping, and managing sessions.
    *   **JSON status output:** Outputs the current Pomodoro status in JSON format, ideal for integration with status bars like Waybar.
    *   **Quick restarts:** A convenience command to quickly reset and restart the daemon and a new work session.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh`: The main script that implements all CLI commands.
*   **Dependencies:**
    *   `jq`: Used for formatting the JSON status output.
*   **User Command/Function:**
    *   `pomodoro_manager.sh start`
    *   `pomodoro_manager.sh pause`
    *   `pomodoro_manager.sh resume`
    *   `pomodoro_manager.sh stop`
    *   `pomodoro_manager.sh reset`
    *   `pomodoro_manager.sh status`
    *   `pomodoro_manager.sh daemon`
    *   `pomodoro_manager.sh stop-daemon`
    *   `pomodoro_manager.sh cleanup`
    *   `pomodoro_manager.sh quick-start`
*   **Operational Flow:** The script parses the first argument as a command and executes the corresponding `cmd_` function.
*   **Testing Notes:**
    *   Execute each command and verify its intended action and output.
    *   Test `pomodoro_manager.sh status` and parse its JSON output.

### Web GUI (Future)

*   **Description:** This is a placeholder for a future enhancement to provide a web-based graphical user interface for the Pomodoro CLI. This would offer a more visual and interactive way to control and monitor Pomodoro sessions.
*   **Mini Features:**
    *   **Launch web GUI:** A command to start the web server for the GUI.
*   **Related Components/Files:**
    *   `web_gui/`: Directory intended to contain the web application files (e.g., `app.py`, `static/`, `templates/`).
*   **Dependencies:**
    *   Python Flask (assumed): A common framework for simple web GUIs.
*   **User Command/Function:**
    *   `pomodoro_manager.sh web-gui`
*   **Operational Flow:** (Currently conceptual) The `web-gui` command would likely launch a Python Flask application in the background.
*   **Testing Notes:**
    *   (Once implemented) Launch the web GUI and interact with its interface to control Pomodoro sessions.

### Concurrency Control

*   **Description:** This feature ensures the integrity of the application's state by preventing multiple instances of the `pomodoro_manager.sh` script from simultaneously modifying the state file. This avoids race conditions and data corruption.
*   **Mini Features:**
    *   **Prevent race conditions:** Uses file locking to serialize access to critical shared resources.
    *   **Safe state file access:** Guarantees that only one process can write to `pomodoro_state.json` at a time.
*   **Related Components/Files:**
    *   `pomodoro_manager.sh` (`acquire_lock`, `release_lock` functions): Implement the locking mechanism.
    *   `pomodoro_lock`: The designated lock file.
*   **Dependencies:**
    *   `flock`: The command-line utility for robust file locking.
*   **User Command/Function:** N/A (internal functions).
*   **Operational Flow:** The `acquire_lock()` function attempts to obtain an exclusive lock on `pomodoro_lock`. If unsuccessful, the script exits. `release_lock()` explicitly releases the lock.
*   **Testing Notes:**
    *   Attempt to run multiple instances of `pomodoro_manager.sh` commands concurrently (e.g., `start` and `status` at the exact same time) and observe that only one succeeds or that the second one exits gracefully.

### Cleanup

*   **Description:** This feature provides a comprehensive way to stop all related Pomodoro CLI processes and remove temporary files. It ensures a clean shutdown and helps in troubleshooting by resetting the application to a known state.
*   **Mini Features:**
    *   **Stop processes:** Kills the daemon, `pomodoro-cli`, and any `yad` processes.
    *   **Remove temporary files:** Deletes state, lock, and PID files (preserving daily logs).
*   **Related Components/Files:**
    *   `pomodoro_manager.sh` (`cmd_cleanup` function): Contains the logic for stopping processes and removing files.
*   **Dependencies:**
    *   `kill`, `killall`: For terminating processes.
*   **User Command/Function:**
    *   `pomodoro_manager.sh cleanup`
*   **Operational Flow:** The `cmd_cleanup()` function reads PID files, uses `kill` or `killall` to terminate processes, and then removes various temporary files.
*   **Testing Notes:**
    *   Start the daemon and a Pomodoro session.
    *   Run `pomodoro_manager.sh cleanup` and verify that no Pomodoro-related processes are running (`ps aux | grep pomodoro`) and that `pomodoro_state.json`, `pomodoro_lock`, `pomodoro_daemon.pid`, etc., are removed.

### Testing & Debugging

*   **Description:** This feature provides dedicated modes and tools to facilitate the testing and debugging of the Pomodoro CLI. It allows developers and users to quickly verify functionality and diagnose issues.
*   **Mini Features:**
    *   **Test Mode:** Switches to much shorter durations for work and breaks, enabling rapid testing of the entire Pomodoro cycle.
    *   **Debug Mode:** Enables verbose logging to stderr, providing detailed insights into script execution.
    *   **Timer status access:** Allows querying the `pomodoro-cli` status in JSON format for debugging the timer's internal state.
*   **Related Components/Files:**
    *   `pomodoro_config.conf`: Configures `TEST_MODE` and `DEBUG_ENABLED`.
    *   `pomodoro_manager.sh`: Implements the logic for test and debug modes.
*   **Dependencies:**
    *   `pomodoro-cli`: For accessing timer status.
*   **User Command/Function:**
    *   `pomodoro_manager.sh --testMode=ON|OFF`
    *   `pomodoro_manager.sh --debug`
    *   `pomodoro-cli status --format json` (external command)
*   **Operational Flow:** When `TEST_MODE` is "ON", the script uses the `_TEST` duration variables. When `DEBUG_ENABLED` is "ON" or `--debug` is used, `debug_log` messages are printed.
*   **Testing Notes:**
    *   Run `pomodoro_manager.sh --testMode=ON start` and observe the rapid countdown.
    *   Run `pomodoro_manager.sh --debug start` and examine the detailed output for troubleshooting.
    *   Regularly use `pomodoro-cli status --format json` to understand the timer's state during development.

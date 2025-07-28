import os
import re
import subprocess
from flask import Flask, render_template, request, redirect, url_for
from datetime import datetime
import zoneinfo # Python 3.9+ for timezone support

app = Flask(__name__)

# --- Configuration ---
POMODORO_MANAGER_SCRIPT = os.path.expanduser("~/.config/pomodoro_cli/pomodoro_manager.sh")
POMODORO_STATE_FILE = os.path.expanduser("~/.config/pomodoro_cli/pomodoro_state.json")
POMODORO_CONFIG_FILE = os.path.expanduser("~/.config/pomodoro_cli/pomodoro_config.conf")

# Define default configuration values. These should match the defaults in pomodoro_manager.sh
DEFAULT_CONFIG = {
    "TEST_MODE": "OFF",
    "BREAK_LOCK_DELAY_SEC_DEFAULT": "30",
    "BREAK_LOCK_DELAY_SEC_TEST": "3",
    "WORK_DURATION_DEFAULT": "25m",
    "SHORT_BREAK_DURATION_DEFAULT": "5m",
    "LONG_BREAK_DURATION_DEFAULT": "15m",
    "WORK_DURATION_TEST": "15s",
    "SHORT_BREAK_DURATION_TEST": "15s",
    "LONG_BREAK_DURATION_TEST": "15s",
    "POMODORO_DIR": os.path.expanduser("~/.config/pomodoro_cli"),
    "SOUND_FILE": os.path.expanduser("~/.config/pomodoro_cli/sounds/beep.wav"),
    "ROUTINE_UPDATE_FREQUENCY_SEC": "30",
    "OBSIDIAN_VAULT_PATH": os.path.expanduser("~/.config/obsidian"),
    "OBSIDIAN_VAULT_NAME": "obsidian",
    "OBSIDIAN_BREAK_NOTE_PATH": os.path.expanduser("~/.config/obsidian/All Things/Journal/Pomodoro session records/POMODORO BREAK FILE.md"),
    "OBSIDIAN_MARKDOWN_LOG_PATH": os.path.expanduser("~/.config/obsidian/All Things/Journal/Pomodoro session records/POMODORO mark down table data for obsidian Analysis.md"),
    "EVENING_LOCK_INTERVAL_SEC": "30",
    "EVENING_LOCK_ENABLED": "ON",
    "LOCK_START_TIME_CONFIG": "1930",
    "LOCK_FREQUENCY_CONFIG": "10",
    "THEME_MODE": "dark"
}

# --- Utility Functions ---

def get_current_config():
    config = {}
    try:
        with open(POMODORO_CONFIG_FILE, 'r') as f:
            config_content = f.read()

        # Parse key-value pairs from the config file
        for line in config_content.splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"') # Remove quotes
                    config[key] = value
        
        # Determine active durations based on TEST_MODE
        if config.get("TEST_MODE") == "ON":
            config["WORK_DURATION"] = config.get("WORK_DURATION_TEST", "N/A")
            config["SHORT_BREAK_DURATION"] = config.get("SHORT_BREAK_DURATION_TEST", "N/A")
            config["LONG_BREAK_DURATION"] = config.get("LONG_BREAK_DURATION_TEST", "N/A")
            config["BREAK_LOCK_DELAY_SEC"] = config.get("BREAK_LOCK_DELAY_SEC_TEST", "N/A")
        else:
            config["WORK_DURATION"] = config.get("WORK_DURATION_DEFAULT", "N/A")
            config["SHORT_BREAK_DURATION"] = config.get("SHORT_BREAK_DURATION_DEFAULT", "N/A")
            config["LONG_BREAK_DURATION"] = config.get("LONG_BREAK_DURATION_DEFAULT", "N/A")
            config["BREAK_LOCK_DELAY_SEC"] = config.get("BREAK_LOCK_DELAY_SEC_DEFAULT", "N/A")

        # Handle EVENING_LOCK_ENABLED as a boolean for the UI
        if config.get("EVENING_LOCK_INTERVAL_SEC") and config["EVENING_LOCK_INTERVAL_SEC"] != "0":
            config["EVENING_LOCK_ENABLED"] = "on"
        else:
            config["EVENING_LOCK_ENABLED"] = "off"

        # Get local timezone for display
        try:
            # For Python 3.9+
            tz = datetime.now().astimezone().tzinfo
            config["LOCAL_TIMEZONE"] = str(tz) if tz else "Unknown"
        except Exception:
            # Fallback for older Python versions or issues
            config["LOCAL_TIMEZONE"] = "Unknown (Install 'tzdata' or use Python 3.9+)"

    except FileNotFoundError:
        print(f"Error: {POMODORO_CONFIG_FILE} not found. Creating with defaults.")
        # If config file not found, create it with defaults and then read
        with open(POMODORO_CONFIG_FILE, 'w') as f:
            f.write("# Pomodoro Configuration\n")
            f.write(f"""TEST_MODE="{DEFAULT_CONFIG['TEST_MODE']}"\n""")
            f.write(f"""BREAK_LOCK_DELAY_SEC_DEFAULT={DEFAULT_CONFIG['BREAK_LOCK_DELAY_SEC_DEFAULT']}\n""")
            f.write(f"""BREAK_LOCK_DELAY_SEC_TEST={DEFAULT_CONFIG['BREAK_LOCK_DELAY_SEC_TEST']}\n""")
            f.write(f"""WORK_DURATION_DEFAULT="{DEFAULT_CONFIG['WORK_DURATION_DEFAULT']}"\n""")
            f.write(f"""SHORT_BREAK_DURATION_DEFAULT="{DEFAULT_CONFIG['SHORT_BREAK_DURATION_DEFAULT']}"\n""")
            f.write(f"""LONG_BREAK_DURATION_DEFAULT="{DEFAULT_CONFIG['LONG_BREAK_DURATION_DEFAULT']}"\n""")
            f.write(f"""WORK_DURATION_TEST="{DEFAULT_CONFIG['WORK_DURATION_TEST']}"\n""")
            f.write(f"""SHORT_BREAK_DURATION_TEST="{DEFAULT_CONFIG['SHORT_BREAK_DURATION_TEST']}"\n""")
            f.write(f"""LONG_BREAK_DURATION_TEST="{DEFAULT_CONFIG['LONG_BREAK_DURATION_TEST']}"\n""")
            f.write(f"""POMODORO_DIR="{DEFAULT_CONFIG['POMODORO_DIR']}"\n""")
            f.write(f"""SOUND_FILE="{DEFAULT_CONFIG['SOUND_FILE']}"\n""")
            f.write(f"""ROUTINE_UPDATE_FREQUENCY_SEC="{DEFAULT_CONFIG['ROUTINE_UPDATE_FREQUENCY_SEC']}"\n""")
            f.write(f"""OBSIDIAN_VAULT_PATH="{DEFAULT_CONFIG['OBSIDIAN_VAULT_PATH']}"\n""")
            f.write(f"""OBSIDIAN_VAULT_NAME="{DEFAULT_CONFIG['OBSIDIAN_VAULT_NAME']}"\n""")
            f.write(f"""OBSIDIAN_BREAK_NOTE_PATH="{DEFAULT_CONFIG['OBSIDIAN_BREAK_NOTE_PATH']}"\n""")
            f.write(f"""OBSIDIAN_MARKDOWN_LOG_PATH="{DEFAULT_CONFIG['OBSIDIAN_MARKDOWN_LOG_PATH']}"\n""")
            f.write(f"""EVENING_LOCK_INTERVAL_SEC={DEFAULT_CONFIG['EVENING_LOCK_INTERVAL_SEC']}\n""")
            f.write(f"""EVENING_LOCK_ENABLED="{DEFAULT_CONFIG['EVENING_LOCK_ENABLED']}"\n""")
            f.write(f"""LOCK_START_TIME_CONFIG="{DEFAULT_CONFIG['LOCK_START_TIME_CONFIG']}"\n""")
            f.write(f"""LOCK_FREQUENCY_CONFIG="{DEFAULT_CONFIG['LOCK_FREQUENCY_CONFIG']}"\n""")
            f.write(f"""THEME_MODE="{DEFAULT_CONFIG['THEME_MODE']}"\n""")
        return get_current_config() # Recurse to read the newly created file
    except Exception as e:
        print(f"Error reading config: {e}")
        return None
    return config

def update_config(new_config_values):
    print(f"DEBUG: Starting update_config with values: {new_config_values}")
    try:
        with open(POMODORO_CONFIG_FILE, 'r') as f:
            config_content = f.readlines()
        print(f"DEBUG: Original config content length: {len(config_content)}")

        updated_lines = []
        
        # Extract special handling values first
        test_mode_value = new_config_values.pop("TEST_MODE", None)
        evening_lock_enabled_value = new_config_values.pop("EVENING_LOCK_ENABLED", None)

        # Create a set of keys that are explicitly handled to avoid processing them again
        explicitly_handled_keys = {
            "TEST_MODE", "EVENING_LOCK_INTERVAL_SEC", "EVENING_LOCK_ENABLED", "THEME_MODE",
            "LOCK_START_TIME_CONFIG", "LOCK_FREQUENCY_CONFIG",
            "WORK_DURATION_DEFAULT", "SHORT_BREAK_DURATION_DEFAULT", "LONG_BREAK_DURATION_DEFAULT", "BREAK_LOCK_DELAY_SEC_DEFAULT",
            "WORK_DURATION_TEST", "SHORT_BREAK_DURATION_TEST", "LONG_BREAK_DURATION_TEST", "BREAK_LOCK_DELAY_SEC_TEST"
        }

        for line in config_content:
            stripped_line = line.strip()
            updated = False

            # Handle TEST_MODE
            if test_mode_value is not None and stripped_line.startswith("TEST_MODE="):
                updated_lines.append(f"""TEST_MODE="{test_mode_value}"\n""")
                updated = True
            
            # Handle EVENING_LOCK_ENABLED (which controls EVENING_LOCK_INTERVAL_SEC)
            elif evening_lock_enabled_value is not None and stripped_line.startswith("EVENING_LOCK_INTERVAL_SEC="):
                if evening_lock_enabled_value == "on":
                    interval_value = DEFAULT_CONFIG["EVENING_LOCK_INTERVAL_SEC"]
                else:
                    interval_value = "0"
                updated_lines.append(f"""EVENING_LOCK_INTERVAL_SEC={interval_value}
""")
                updated = True

            # Handle LOCK_START_TIME_CONFIG
            elif "LOCK_START_TIME_CONFIG" in new_config_values and stripped_line.startswith("LOCK_START_TIME_CONFIG="):
                updated_lines.append(f"""LOCK_START_TIME_CONFIG="{new_config_values["LOCK_START_TIME_CONFIG"]}"
""")
                updated = True
                new_config_values.pop("LOCK_START_TIME_CONFIG")

            # Handle LOCK_FREQUENCY_CONFIG
            elif "LOCK_FREQUENCY_CONFIG" in new_config_values and stripped_line.startswith("LOCK_FREQUENCY_CONFIG="):
                updated_lines.append(f"""LOCK_FREQUENCY_CONFIG="{new_config_values["LOCK_FREQUENCY_CONFIG"]}"
""")
                updated = True
                new_config_values.pop("LOCK_FREQUENCY_CONFIG")

            # Handle THEME_MODE
            elif "THEME_MODE" in new_config_values and stripped_line.startswith("THEME_MODE="):
                updated_lines.append(f"""THEME_MODE="{new_config_values["THEME_MODE"]}"\n""")
                updated = True
                new_config_values.pop("THEME_MODE") # Remove after handling

            # Handle other configuration variables (including all durations)
            else:
                for key, value in new_config_values.items():
                    # Only process keys that are not explicitly handled above
                    if key not in explicitly_handled_keys:
                        # Check for exact key match, considering quoted/unquoted values
                        if stripped_line.startswith(f"{key}=") or stripped_line.startswith(f'"{key}="') :
                            # Preserve quotes if original had them, or add if it's a string that needs them
                            if '"' in stripped_line:
                                updated_lines.append(f"""{key}=\"{value}\"\n""")
                            else:
                                updated_lines.append(f"""{key}={value}\n""")
                            updated = True
                            break # Move to next line after updating this key
                    # Handle duration keys that are now explicitly passed
                    elif key in explicitly_handled_keys and stripped_line.startswith(f"{key}="):
                        if '"' in stripped_line: # Check if original line had quotes
                            updated_lines.append(f"""{key}=\"{value}\"\n""")
                        else:
                            updated_lines.append(f"""{key}={value}\n""")
                        updated = True
                        break # Move to next line after updating this key
            
            if not updated:
                updated_lines.append(line) # Keep original line if not updated

        with open(POMODORO_CONFIG_FILE, 'w') as f:
            f.writelines(updated_lines)
        print("DEBUG: Config file write successful.")

        # After updating the config file, trigger pomodoro_manager.sh to re-source it
        # This ensures the shell script's internal variables are updated.
        subprocess.run([POMODORO_MANAGER_SCRIPT, "status"], check=False, capture_output=True) # Run a dummy command to trigger sourcing
        print("DEBUG: Triggered pomodoro_manager.sh to re-source config.")

        return True
    except Exception as e:
        print(f"ERROR: Exception during update_config: {e}")
        return False

# --- Utility Functions ---

def get_daemon_status():
    daemon_pid_file = os.path.expanduser("~/.config/pomodoro_cli/pomodoro_daemon.pid")
    if os.path.exists(daemon_pid_file):
        try:
            with open(daemon_pid_file, 'r') as f:
                pid = int(f.read().strip())
            # Check if the process with this PID is actually running
            if os.path.exists(f"/proc/{pid}"):
                return "Running"
            else:
                # PID file exists but process doesn't, clean up
                os.remove(daemon_pid_file)
                return "Stopped"
        except (ValueError, IOError):
            return "Stopped" # PID file corrupted or unreadable
    return "Stopped"

def get_pomodoro_status():
    try:
        # Execute the status command from pomodoro_manager.sh
        result = subprocess.run(
            [POMODORO_MANAGER_SCRIPT, "status"],
            capture_output=True, text=True, check=True
        )
        # The status command outputs JSON, so we parse it
        status_json = result.stdout.strip()
        import json
        status_data = json.loads(status_json)
        return status_data.get('text', 'Unknown Status')
    except FileNotFoundError:
        return "Error: Manager script not found."
    except subprocess.CalledProcessError as e:
        return f"Error getting status: {e.stderr.strip()}"
    except json.JSONDecodeError:
        return f"Error: Could not decode status JSON: {status_json}"
    except Exception as e:
        return f"Error: {e}"

def execute_pomodoro_command(command):
    try:
        subprocess.run([POMODORO_MANAGER_SCRIPT, command], check=True)
        return True
    except FileNotFoundError:
        return False
    except subprocess.CalledProcessError as e:
        print(f"Command '{command}' failed: {e.stderr}")
        return False

# --- Flask Routes ---

@app.route('/', methods=['GET', 'POST'])
def index():
    current_config = get_current_config()
    pomodoro_status = get_pomodoro_status()
    daemon_status = get_daemon_status() # Get daemon status

    if request.method == 'POST':
        if 'save_config' in request.form:
            new_config = {}
            # Collect all relevant keys from DEFAULT_CONFIG and form
            all_config_keys = set(DEFAULT_CONFIG.keys())
            all_config_keys.add("EVENING_LOCK_ENABLED") # Add this as it's a form field, not directly in DEFAULT_CONFIG

            for key in all_config_keys:
                # Special handling for EVENING_LOCK_ENABLED (radio button)
                if key == "EVENING_LOCK_ENABLED": # This key is special, its value depends on the radio button
                    new_config["EVENING_LOCK_ENABLED"] = request.form.get("EVENING_LOCK_ENABLED")
                elif key == "EVENING_LOCK_INTERVAL_SEC": # This key is special, its value depends on the radio button
                    # We don't directly set INTERVAL_SEC from form, it's controlled by ENABLED
                    pass
                else:
                    # Get value from form, if not present, use current config value
                    form_value = request.form.get(key)
                    if form_value is not None:
                        new_config[key] = form_value
                    elif key in current_config: # If not in form, but in current config, keep it
                        new_config[key] = current_config[key]
            
            if update_config(new_config):
                return redirect(url_for('index', message='Configuration saved successfully!'))
            else:
                return redirect(url_for('index', error='Failed to save configuration.'))
        
        elif 'restore_defaults' in request.form:
            # Restore all defaults
            # Need to create a mutable copy of DEFAULT_CONFIG for update_config
            defaults_to_restore = DEFAULT_CONFIG.copy()
            # Ensure EVENING_LOCK_ENABLED is set correctly for restore all
            defaults_to_restore["EVENING_LOCK_ENABLED"] = DEFAULT_CONFIG["EVENING_LOCK_ENABLED"]

            if update_config(defaults_to_restore):
                return redirect(url_for('index', message='All defaults restored successfully!'))
            else:
                return redirect(url_for('index', error='Failed to restore all defaults.'))
        
        elif 'restore_individual_default' in request.form:
            key_to_restore = request.form['restore_individual_default']
            value_to_restore = DEFAULT_CONFIG.get(key_to_restore)
            
            # Special handling for EVENING_LOCK_INTERVAL_SEC when restoring individually
            if key_to_restore == "EVENING_LOCK_INTERVAL_SEC":
                # If restoring EVENING_LOCK_INTERVAL_SEC, it means setting the switch to ON
                if update_config({"EVENING_LOCK_ENABLED": DEFAULT_CONFIG["EVENING_LOCK_ENABLED"], "EVENING_LOCK_INTERVAL_SEC": DEFAULT_CONFIG["EVENING_LOCK_INTERVAL_SEC"] }):
                    return redirect(url_for('index', message=f'Default for {key_to_restore} restored!'))
                else:
                    return redirect(url_for('index', error=f'Failed to restore default for {key_to_restore}.'))
            elif value_to_restore is not None:
                if update_config({key_to_restore: value_to_restore}):
                    return redirect(url_for('index', message=f'Default for {key_to_restore} restored!'))
                else:
                    return redirect(url_for('index', error=f'Failed to restore default for {key_to_restore}.'))
            else:
                return redirect(url_for('index', error=f'Default value for {key_to_restore} not found.'))

        elif 'pomodoro_action' in request.form:
            action = request.form['pomodoro_action']
            if execute_pomodoro_command(action):
                return redirect(url_for('index', message=f'Command "{action}" executed successfully!'))
            else:
                return redirect(url_for('index', error=f'Failed to execute command "{action}".'))

    message = request.args.get('message')
    error = request.args.get('error')

    return render_template('index.html',
                           current_config=current_config,
                           default_config=DEFAULT_CONFIG,
                           pomodoro_status=pomodoro_status,
                           daemon_status=daemon_status, # Pass daemon status to template
                           theme_mode=current_config.get("THEME_MODE", "dark"), # Pass theme mode to template
                           message=message,
                           error=error)

if __name__ == '__main__':
    app.run(debug=True, port=5001)
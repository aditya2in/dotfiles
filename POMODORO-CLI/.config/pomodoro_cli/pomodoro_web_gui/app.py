import os
import re
import subprocess
from flask import Flask, render_template, request, redirect, url_for

app = Flask(__name__)

# --- Configuration ---
POMODORO_MANAGER_SCRIPT = os.path.expanduser("~/.config/pomodoro_cli/pomodoro_manager.sh")
POMODORO_STATE_FILE = os.path.expanduser("~/.config/pomodoro_cli/pomodoro_state.json")

# Define default configuration values extracted from pomodoro_manager.sh
# These will be used to restore defaults and display alongside current values.
# Note: OBSIDIAN_VAULT_PATH and OBSIDIAN_BREAK_NOTE_PATH are expanded here for consistency
# but will be written back to the script as $HOME/...
DEFAULT_CONFIG = {
    "POMODORO_DIR": os.path.expanduser("~/.config/pomodoro_cli"),
    "SOUND_FILE": os.path.expanduser("~/.config/pomodoro_cli/sounds/beep.wav"),
    "ROUTINE_UPDATE_FREQUENCY_SEC": "30",
    "OBSIDIAN_VAULT_PATH": os.path.expanduser("~/.config/obsidian"),
    "OBSIDIAN_VAULT_NAME": "obsidian",
    "OBSIDIAN_BREAK_NOTE_PATH": os.path.expanduser("~/.config/obsidian/All Things/Journal/Pomodoro session records/POMODORO BREAK FILE.md"),
    "OBSIDIAN_MARKDOWN_LOG_PATH": os.path.expanduser("~/.config/obsidian/All Things/Journal/Pomodoro session records/POMODORO mark down table data for obsidian Analysis.md"),
    "BREAK_LOCK_DELAY_SEC": "30",
    "WORK_DURATION": "25m",
    "SHORT_BREAK_DURATION": "5m",
    "LONG_BREAK_DURATION": "15m",
    "EVENING_LOCK_INTERVAL_SEC": "30" # Default to ON
}

# --- Utility Functions ---

def get_current_config():
    config = {}
    try:
        with open(POMODORO_MANAGER_SCRIPT, 'r') as f:
            script_content = f.read()

        patterns = {
            "POMODORO_DIR": r'POMODORO_DIR="([^"]+)"',
            "SOUND_FILE": r'SOUND_FILE="([^"]+)"',
            "ROUTINE_UPDATE_FREQUENCY_SEC": r'ROUTINE_UPDATE_FREQUENCY_SEC="([^"]+)"',
            "OBSIDIAN_VAULT_PATH": r'OBSIDIAN_VAULT_PATH="([^"]+)"',
            "OBSIDIAN_VAULT_NAME": r'OBSIDIAN_VAULT_NAME="([^"]+)"',
            "OBSIDIAN_BREAK_NOTE_PATH": r'OBSIDIAN_BREAK_NOTE_PATH="([^"]+)"',
            "OBSIDIAN_MARKDOWN_LOG_PATH": r'OBSIDIAN_MARKDOWN_LOG_PATH="([^"]+)"',
            "BREAK_LOCK_DELAY_SEC": r'BREAK_LOCK_DELAY_SEC=([^\s#]+)',
            "WORK_DURATION": r'WORK_DURATION="([^"]+)"',
            "SHORT_BREAK_DURATION": r'SHORT_BREAK_DURATION="([^"]+)"',
            "LONG_BREAK_DURATION": r'LONG_BREAK_DURATION="([^"]+)"',
            "EVENING_LOCK_INTERVAL_SEC": r'EVENING_LOCK_INTERVAL_SEC=([^\s#]+)'
        }

        for key, pattern in patterns.items():
            match = re.search(pattern, script_content)
            if match:
                config[key] = match.group(1)
            else:
                config[key] = "N/A" # Not found or error in parsing
        
        # Handle EVENING_LOCK_ENABLED as a boolean
        if config.get("EVENING_LOCK_INTERVAL_SEC") and config["EVENING_LOCK_INTERVAL_SEC"] != "0":
            config["EVENING_LOCK_ENABLED"] = "on"
        else:
            config["EVENING_LOCK_ENABLED"] = "off"

    except FileNotFoundError:
        print(f"Error: {POMODORO_MANAGER_SCRIPT} not found.")
        return None
    except Exception as e:
        print(f"Error reading config: {e}")
        return None
    return config

def update_config(new_config_values):
    print(f"DEBUG: Starting update_config with values: {new_config_values}")
    try:
        with open(POMODORO_MANAGER_SCRIPT, 'r') as f:
            script_content = f.read()
        print(f"DEBUG: Original script content length: {len(script_content)}")

        updated_content = script_content

        # Handle EVENING_LOCK_ENABLED first and separately
        if "EVENING_LOCK_ENABLED" in new_config_values:
            print(f"DEBUG: Processing EVENING_LOCK_ENABLED: {new_config_values['EVENING_LOCK_ENABLED']}")
            if new_config_values["EVENING_LOCK_ENABLED"] == "on":
                interval_value = DEFAULT_CONFIG["EVENING_LOCK_INTERVAL_SEC"]
            else:
                interval_value = "0"
            
            pattern = rf'^(EVENING_LOCK_INTERVAL_SEC=).*$'
            replacement = rf'\1{interval_value}'
            print(f"DEBUG: Regex for EVENING_LOCK_INTERVAL_SEC: pattern='{pattern}', replacement='{replacement}'")
            updated_content = re.sub(pattern, replacement, updated_content, flags=re.MULTILINE)
            print(f"DEBUG: Content after EVENING_LOCK_INTERVAL_SEC update (length: {len(updated_content)})")
            # Remove from new_config_values to avoid re-processing as a regular key
            del new_config_values["EVENING_LOCK_ENABLED"]

        for key, value in new_config_values.items():
            print(f"DEBUG: Processing key: {key}, value: {value}")
            # Handle other variables
            if key in ["BREAK_LOCK_DELAY_SEC", "EVENING_LOCK_INTERVAL_SEC"]:
                # For variables without quotes
                pattern = rf'^({key}=).*$'
                replacement = rf'\1{value}'
                print(f"DEBUG: Regex (no quotes) for {key}: pattern='{pattern}', replacement='{replacement}'")
                updated_content = re.sub(pattern, replacement, updated_content, flags=re.MULTILINE)
            else:
                # For variables with quotes
                pattern = rf'^({key}=")[^"]*"';
                replacement = rf'\1{value}"'
                print(f"DEBUG: Regex (quotes) for {key}: pattern='{pattern}', replacement='{replacement}'")
                updated_content = re.sub(pattern, replacement, updated_content, flags=re.MULTILINE)
            print(f"DEBUG: Content after {key} update (length: {len(updated_content)})")

        with open(POMODORO_MANAGER_SCRIPT, 'w') as f:
            f.write(updated_content)
        print("DEBUG: File write successful.")
        return True
    except Exception as e:
        print(f"ERROR: Exception during update_config: {e}")
        return False

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

    if request.method == 'POST':
        if 'save_config' in request.form:
            new_config = {}
            for key in DEFAULT_CONFIG.keys():
                # Handle EVENING_LOCK_ENABLED checkbox
                if key == "EVENING_LOCK_INTERVAL_SEC": # This key is special, its value depends on the checkbox
                    new_config["EVENING_LOCK_ENABLED"] = request.form.get("EVENING_LOCK_ENABLED")
                else:
                    new_config[key] = request.form.get(key)
            
            if update_config(new_config):
                return redirect(url_for('index', message='Configuration saved successfully!'))
            else:
                return redirect(url_for('index', error='Failed to save configuration.'))
        
        elif 'restore_defaults' in request.form:
            # Restore all defaults
            # Need to create a mutable copy of DEFAULT_CONFIG for update_config
            defaults_to_restore = DEFAULT_CONFIG.copy()
            # Ensure EVENING_LOCK_ENABLED is set correctly for restore all
            defaults_to_restore["EVENING_LOCK_ENABLED"] = "on" if DEFAULT_CONFIG["EVENING_LOCK_INTERVAL_SEC"] != "0" else "off"

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
                if update_config({"EVENING_LOCK_ENABLED": "on"}):
                    return redirect(url_for('index', message=f'Default for {key_to_restore} restored (ON)!'))
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
                           message=message,
                           error=error)

if __name__ == '__main__':
    app.run(debug=True, port=5001)
#!/bin/bash
set -x # Enable verbose output for debugging

# --- Mock Environment and Variables ---
# These are simplified for debugging purposes.
# In a real scenario, these would be set by your Hyprland environment.
export HYPRLAND_INSTANCE_SIGNATURE="debug_instance"
export DISPLAY=":0"
export XAUTHORITY="$HOME/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" # Example, adjust if needed

# Mock hyprctl command to simulate an Obsidian window on workspace 10
# In a real scenario, this would be the actual output from 'hyprctl clients -j'
mock_hyprctl_clients_output() {
    cat <<EOF
[
  {
    "address": "0x1234567890abcdef",
    "mapped": true,
    "hidden": false,
    "at": [100, 100],
    "size": [800, 600],
    "workspace": {
      "id": 10,
      "name": "10"
    },
    "floating": false,
    "fullscreen": true,
    "monitor": 0,
    "class": "obsidian",
    "title": "Obsidian - My Vault",
    "initialClass": "obsidian",
    "initialTitle": "Obsidian - My Vault",
    "pid": 12345,
    "xwayland": false,
    "pinned": false,
    "locked": false,
    "fullscreenMode": 1,
    "fakeFullscreen": false,
    "grouped": [],
    "swallowing": "0x0"
  },
  {
    "address": "0xabcdef1234567890",
    "mapped": true,
    "hidden": false,
    "at": [50, 50],
    "size": [600, 400],
    "workspace": {
      "id": 3,
      "name": "3"
    },
    "floating": false,
    "fullscreen": false,
    "monitor": 0,
    "class": "some_other_app",
    "title": "Some Other App",
    "initialClass": "some_other_app",
    "initialTitle": "Some Other App",
    "pid": 67890,
    "xwayland": false,
    "pinned": false,
    "locked": false,
    "fullscreenMode": 0,
    "fakeFullscreen": false,
    "grouped": [],
    "swallowing": "0x0"
  }
]
EOF
}

# --- Global Variables (simulating pomodoro_manager.sh) ---
OBSIDIAN_VAULT_NAME="obsidian"
OBSIDIAN_BREAK_NOTE_PATH="All Things/Journal/Pomodoro session records/POMODORO BREAK FILE.md"
OBSIDIAN_MARKDOWN_LOG_PATH="All Things/Journal/Pomodoro session records/POMODORO mark down table data for obsidian Analysis.md"
_obsidian_break_window_address="" # This will be populated by the simulation

# --- Utility Functions (from pomodoro_manager.sh) ---
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

# --- Simulate start_session (relevant parts for window capture) ---
echo "--- Simulating start_session (window capture) ---"

# Simulate opening Obsidian and moving it to workspace 10 and fullscreen
# In a real run, this would be done by xdg-open and hyprctl dispatch
echo "Simulating: hyprctl dispatch workspace 2"
echo "Simulating: hyprctl dispatch movetoworkspace 1"
echo "Simulating: hyprctl dispatch movetoworkspace 10"
echo "Simulating: hyprctl dispatch fullscreen 0"

# Capture the address of the Obsidian window that just went fullscreen on workspace 10
# Using the mock_hyprctl_clients_output function
_obsidian_break_window_address=$(mock_hyprctl_clients_output | jq -r '.[] | select(.workspace.id == 10 and .class == "obsidian") | .address' | head -n 1)
echo "DEBUG: Captured Obsidian break window address: $_obsidian_break_window_address"

# --- Simulate handle_transition (window manipulation) ---
echo ""
echo "--- Simulating handle_transition (window manipulation) ---"

# Ensure we are on workspace 10 and focus the specific Obsidian window
echo "Simulating: hyprctl dispatch workspace 10"
if [ -n "$_obsidian_break_window_address" ]; then
    echo "Simulating: hyprctl dispatch focuswindow address:$_obsidian_break_window_address"
    # Exit fullscreen for the specific Obsidian window
    echo "Simulating: hyprctl dispatch fullscreen 1,address:$_obsidian_break_window_address"
    # Move the specific Obsidian window to workspace 1
    echo "Simulating: hyprctl dispatch movetoworkspace 1,address:$_obsidian_break_window_address"
    # Move the specific Obsidian window to workspace 2
    echo "Simulating: hyprctl dispatch movetoworkspace 2,address:$_obsidian_break_window_address"
    _obsidian_break_window_address="" # Clear the address after use
else
    echo "Warning: No Obsidian break window address found. Performing generic window moves."
    echo "Simulating: hyprctl dispatch fullscreen 1"
    echo "Simulating: hyprctl dispatch movetoworkspace 1,class:obsidian"
    echo "Simulating: hyprctl dispatch movetoworkspace 2,class:obsidian"
fi
echo "Simulating: hyprctl dispatch workspace 1"

echo ""
echo "--- Simulation Complete ---"
echo "Review the 'Simulating:' lines above to see the commands that would be executed."
echo "If 'DEBUG: Captured Obsidian break window address:' is empty, the issue is in capturing the address."
echo "If it's populated, the issue might be in Hyprland's behavior with address-based commands."

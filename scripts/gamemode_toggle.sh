#!/bin/bash
# ==============================================================================
# Focused Game Mode Manager (F4 Nemotron & Brave Browser)
# ==============================================================================
# Snapshots the active status of F4 (Nemotron STT) and Brave Browser, shuts them
# down when entering Game Mode to free VRAM & RAM for gaming, and automatically
# restores them along with your triple monitors when exiting Game Mode.
# ==============================================================================

STATE_DIR="$HOME/.local/state/omarchy"
STATE_FILE="$STATE_DIR/gamemode_state.json"
mkdir -p "$STATE_DIR"

if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
fi

MONITOR_COUNT=$(hyprctl monitors | grep "Monitor" | wc -l)

if [ "$MONITOR_COUNT" -gt 1 ]; then
    # --------------------------------------------------------------------------
    # 🎮 ENTERING GAME MODE (Single Monitor + F4 & Brave Clearance)
    # --------------------------------------------------------------------------

    # 1. Snapshot running status of F4 and Brave
    RUNNING_NEMOTRON=false
    RUNNING_BRAVE=false

    if pgrep -f "nemotron_realtime_stt.py" >/dev/null; then RUNNING_NEMOTRON=true; fi
    if pgrep -x "brave" >/dev/null; then RUNNING_BRAVE=true; fi

    cat <<EOF > "$STATE_FILE"
{
  "nemotron": $RUNNING_NEMOTRON,
  "brave": $RUNNING_BRAVE
}
EOF

    # 2. Terminate running items to free VRAM & RAM
    if [ "$RUNNING_NEMOTRON" = true ]; then
        pkill -9 -f "nemotron_realtime_stt.py" 2>/dev/null || true
    fi

    if [ "$RUNNING_BRAVE" = true ]; then
        pkill -x "brave" 2>/dev/null || true
    fi

    sync

    # 3. Move workspaces and configure single Ultrawide monitor
    for ws in {1..10}; do
        hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$ws\", monitor = \"DP-2\" })" 2>/dev/null
    done

    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
    hyprctl eval 'hl.monitor({ output = "DP-1", disabled = true })'
    hyprctl eval 'hl.monitor({ output = "DP-2", mode = "3440x1440@75", position = "0x0", scale = 1 })'

    notify-send -a "Game Mode" "🎮 Game Mode ON" "Single Ultrawide Active · F4 & Brave Cleared"

else
    # --------------------------------------------------------------------------
    # 💼 ENTERING WORK MODE (Triple Monitors + F4 & Brave Restoration)
    # --------------------------------------------------------------------------

    # 1. Restore 3-Monitor Geometry
    hyprctl eval 'hl.monitor({ output = "DP-2", mode = "3440x1440@75", position = "1080x240", scale = 1, disabled = false })'
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1, transform = 1, disabled = false })'
    hyprctl eval 'hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "4520x0", scale = 1, transform = 3, disabled = false })'
    hyprctl reload
    xrandr --output DP-2 --primary 2>/dev/null || true

    # 2. Restore F4 and Brave from state snapshot
    if [ -f "$STATE_FILE" ]; then
        if grep -q '"brave": true' "$STATE_FILE"; then
            setsid uwsm-app -- brave --ozone-platform=wayland >/dev/null 2>&1 &
        fi

        if grep -q '"nemotron": true' "$STATE_FILE"; then
            /home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh --power >/dev/null 2>&1 &
        fi

        rm -f "$STATE_FILE"
    fi

    notify-send -a "Work Mode" "💼 Work Mode ON" "Triple Monitors, F4 Dictation & Browser Restored"
fi

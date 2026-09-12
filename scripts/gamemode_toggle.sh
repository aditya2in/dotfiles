#!/bin/bash
# ==============================================================================
# Focused Game Mode Manager (Gaming Environment, Single Monitor & VRAM Clearance)
# ==============================================================================
# Snapshots the active status of F4 (Nemotron STT), Brave Browser, and default
# audio sink. When entering Game Mode:
#   1. Pauses the Omarchy Pomodoro timer
#   2. Switches default audio output to Realme Studio H1 headphones
#   3. Terminates F4 Nemotron and Brave to free VRAM & RAM
#   4. Switches monitor layout to single Ultrawide (DP-2)
#   5. Switches Hyprland active workspace to Workspace 4
#   6. Launches Steam & JamesDSP audio processing engine
# When exiting Game Mode (returning to Work Mode):
#   1. Restores 3-monitor layout
#   2. Restores original default audio output sink
#   3. Restores Brave browser and F4 Nemotron STT if they were active
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
    # 🎮 ENTERING GAME MODE
    # --------------------------------------------------------------------------

    # 1. Pause Pomodoro Timer
    if command -v omarchy-pomodoro >/dev/null 2>&1; then
        omarchy-pomodoro pause >/dev/null 2>&1 || true
    elif command -v omarchy-shell >/dev/null 2>&1; then
        omarchy-shell omarchy-pomodoro pause >/dev/null 2>&1 || true
    fi

    # 2. Snapshot running status of F4, Brave, and current audio sink
    RUNNING_NEMOTRON=false
    RUNNING_BRAVE=false
    PREV_AUDIO_SINK=$(pactl get-default-sink 2>/dev/null || echo "")

    if pgrep -f "nemotron_realtime_stt.py" >/dev/null; then RUNNING_NEMOTRON=true; fi
    if pgrep -x "brave" >/dev/null; then RUNNING_BRAVE=true; fi

    cat <<EOF > "$STATE_FILE"
{
  "nemotron": $RUNNING_NEMOTRON,
  "brave": $RUNNING_BRAVE,
  "audio_sink": "$PREV_AUDIO_SINK"
}
EOF

    # 3. Switch Default Audio Sink to Realme Headphones
    REALME_SINK=$(pactl list short sinks | grep -iE "realme|jieli" | awk '{print $2}' | head -n 1)
    if [ -n "$REALME_SINK" ]; then
        pactl set-default-sink "$REALME_SINK" 2>/dev/null || true
    fi

    # 4. Terminate running items to free VRAM & RAM
    if [ "$RUNNING_NEMOTRON" = true ]; then
        pkill -9 -f "nemotron_realtime_stt.py" 2>/dev/null || true
    fi

    if [ "$RUNNING_BRAVE" = true ]; then
        pkill -x "brave" 2>/dev/null || true
    fi

    sync

    # 5. Move workspaces and configure single Ultrawide monitor
    for ws in {1..10}; do
        hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$ws\", monitor = \"DP-2\" })" 2>/dev/null
    done

    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
    hyprctl eval 'hl.monitor({ output = "DP-1", disabled = true })'
    hyprctl eval 'hl.monitor({ output = "DP-2", mode = "3440x1440@75", position = "0x0", scale = 1 })'

    # 6. Switch to Workspace 4 for Gaming
    hyprctl dispatch workspace 4 2>/dev/null || true

    # 7. Launch Steam if not running
    if ! pgrep -x "steam" >/dev/null; then
        setsid uwsm-app -- steam >/dev/null 2>&1 &
    fi

    # 8. Launch JamesDSP if not running
    if ! pgrep -x "jamesdsp" >/dev/null; then
        setsid uwsm-app -- jamesdsp >/dev/null 2>&1 &
    fi

    notify-send -a "Game Mode" "🎮 Game Mode ON" "Workspace 4 · Steam & JamesDSP · Realme Audio · Pomodoro Paused"

else
    # --------------------------------------------------------------------------
    # 💼 ENTERING WORK MODE (Triple Monitors + Restoration)
    # --------------------------------------------------------------------------

    # 1. Restore 3-Monitor Geometry
    hyprctl eval 'hl.monitor({ output = "DP-2", mode = "3440x1440@75", position = "1080x240", scale = 1, disabled = false })'
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1, transform = 1, disabled = false })'
    hyprctl eval 'hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "4520x0", scale = 1, transform = 3, disabled = false })'
    hyprctl reload
    xrandr --output DP-2 --primary 2>/dev/null || true

    # 2. Restore previous Audio Sink, F4 and Brave from state snapshot
    if [ -f "$STATE_FILE" ]; then
        SAVED_SINK=$(grep '"audio_sink":' "$STATE_FILE" | sed -E 's/.*"audio_sink": *"([^"]*)".*/\1/')
        if [ -n "$SAVED_SINK" ] && [ "$SAVED_SINK" != "null" ]; then
            pactl set-default-sink "$SAVED_SINK" 2>/dev/null || true
        fi

        if grep -q '"brave": true' "$STATE_FILE"; then
            setsid uwsm-app -- brave --ozone-platform=wayland >/dev/null 2>&1 &
        fi

        if grep -q '"nemotron": true' "$STATE_FILE"; then
            /home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh --power >/dev/null 2>&1 &
        fi

        rm -f "$STATE_FILE"
    fi

    notify-send -a "Work Mode" "💼 Work Mode ON" "Triple Monitors, Audio, Dictation & Browser Restored"
fi

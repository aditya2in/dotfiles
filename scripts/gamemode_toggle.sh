#!/bin/bash
# ==============================================================================
# Focused Game Mode Manager (Omarchy Quattro Native hyprmoncfg Architecture)
# ==============================================================================
# Snapshots the active status of F4 (Nemotron STT), Brave Browser, and default
# audio sink. When entering Game Mode:
#   1. Pauses the Omarchy Pomodoro timer
#   2. Switches default audio output to Realme Studio H1 headphones
#   3. Terminates F4 Nemotron and Brave to free VRAM & RAM (~1.2 GB VRAM / ~7.8 GB RAM)
#   4. Applies native hyprmoncfg 'gaming' profile (isolates Center Ultrawide at 0x0)
#   5. Switches Hyprland active workspace to Workspace 4
#   6. Launches / Focuses Steam & JamesDSP audio processing engine on Workspace 4
# When exiting Game Mode (returning to Work Mode):
#   1. Applies native hyprmoncfg 'default' profile (restores 3-monitor 1-2-3 setup)
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

    # 5. Apply native hyprmoncfg gaming profile
    hyprmoncfg apply gaming --confirm-timeout=0 >/dev/null 2>&1 || true

    # 6. Switch to Workspace 4 for Gaming via Lua dispatcher
    hyprctl repl 'hl.dispatch(hl.dsp.focus({ workspace = "4" }))' >/dev/null 2>&1 || true

    # 7. Launch or open Steam window on Workspace 4
    setsid uwsm-app -- steam steam://open/main >/dev/null 2>&1 &

    # 8. Launch JamesDSP if not running
    if ! pgrep -x "jamesdsp" >/dev/null; then
        setsid uwsm-app -- jamesdsp >/dev/null 2>&1 &
    fi

    notify-send -a "Game Mode" "🎮 Game Mode ON" "Workspace 4 · Steam & JamesDSP · Realme Audio · Single Ultrawide"

else
    # --------------------------------------------------------------------------
    # 💼 ENTERING WORK MODE (Triple Monitors + Restoration)
    # --------------------------------------------------------------------------

    # 1. Restore native hyprmoncfg default profile (3-monitor 1-2-3 setup)
    hyprmoncfg apply default --confirm-timeout=0 >/dev/null 2>&1 || true

    # 2. Focus Center Monitor (Workspace 2)
    hyprctl repl 'hl.dispatch(hl.dsp.focus({ workspace = "2" }))' >/dev/null 2>&1 || true

    # 3. Restore previous Audio Sink, F4 and Brave from state snapshot
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

#!/bin/bash
# ==============================================================================
# Nemotron STT Top Bar Shell Status (Omarchy Shell / Waybar)
# ==============================================================================
# Visual Indicators:
#   🔴 RED (#f38ba8)    : LISTENING / RECORDING Active
#   🟡 YELLOW (#f9e2af) : PAUSED (Stand-by / Software Mute)
#   ⚪ FADED (#585b70)  : OFF / NOT STARTED (VRAM Unloaded)
# ==============================================================================

PAUSE_FILE="/tmp/nemotron_paused"
GLOBAL_OVERRIDE_FILE="/tmp/nemotron_global_typing_override"

if pgrep -f "nemotron_realtime_stt.py" >/dev/null; then
    if [ -f "$PAUSE_FILE" ]; then
        TEXT="󰍭"
        COLOR="#f9e2af" # 🟡 Amber Yellow (Traffic Light Pause)
        CLASS="paused"
        if [ -f "$GLOBAL_OVERRIDE_FILE" ]; then
            TOOLTIP="Nemotron STT: PAUSED [🌐 Global Window] (F4 to Resume · Ctrl+F4 for Tmux K8)"
        else
            TOOLTIP="Nemotron STT: PAUSED [💻 Tmux K8] (F4 to Resume · Shift+F4 to Power Off)"
        fi
    else
        COLOR="#f38ba8" # 🔴 Vibrant Red (Recording / Listening Active)
        CLASS="recording"
        if [ -f "$GLOBAL_OVERRIDE_FILE" ]; then
            TEXT="󰌌"
            TOOLTIP="Nemotron STT: RECORDING [🌐 Global Window] (F4 to Pause · Ctrl+F4 for Tmux K8)"
        else
            TEXT="󰍬"
            TOOLTIP="Nemotron STT: RECORDING [💻 Tmux K8] (F4 to Pause · Shift+F4 to Power Off)"
        fi
    fi
else
    TEXT=""
    COLOR="#585b70" # ⚪ Faded Gray (Stopped / Not Started)
    CLASS="stopped"
    TOOLTIP="Nemotron STT: OFF (Click or Shift+F4 to Power On)"
fi

echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"

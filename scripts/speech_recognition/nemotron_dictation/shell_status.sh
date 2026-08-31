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

if pgrep -f "nemotron_realtime_stt.py" >/dev/null; then
    if [ -f "$PAUSE_FILE" ]; then
        TEXT="󰍭"
        COLOR="#f9e2af" # 🟡 Amber Yellow (Traffic Light Pause)
        CLASS="paused"
        TOOLTIP="Nemotron STT: PAUSED (F4 to Resume · Shift+F4 to Power Off)"
    else
        TEXT="󰍬"
        COLOR="#f38ba8" # 🔴 Vibrant Red (Recording / Listening Active)
        CLASS="recording"
        TOOLTIP="Nemotron STT: RECORDING / LISTENING (F4 to Pause · Shift+F4 to Power Off)"
    fi
else
    TEXT=""
    COLOR="#585b70" # ⚪ Faded Gray (Stopped / Not Started)
    CLASS="stopped"
    TOOLTIP="Nemotron STT: OFF (Click or Shift+F4 to Power On)"
fi

echo "{\"text\": \"$TEXT\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"

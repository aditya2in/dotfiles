#!/usr/bin/env bash
# Pomodoro & Lock Screen Audio Event Dispatcher
# Hardware Sink: GPU HDMI -> LG Monitor -> 3.5mm AUX -> External Room Speakers
# Sink Name: alsa_output.pci-0000_65_00.1.hdmi-stereo

SINK="alsa_output.pci-0000_65_00.1.hdmi-stereo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_DIR="$SCRIPT_DIR/sounds"

# Ensure card profile is output:hdmi-stereo and sink is unmuted
pactl set-card-profile alsa_card.pci-0000_65_00.1 output:hdmi-stereo 2>/dev/null || true
pactl set-sink-mute "$SINK" 0 2>/dev/null || true

case "$1" in
  start)
    # 1. Timer Start (Login Bell)
    paplay --device="$SINK" "$SOUND_DIR/1_timer_start_login_bell.wav" &
    ;;
  stop|end)
    # 2. Timer Stop / End (Logout Descend)
    paplay --device="$SINK" "$SOUND_DIR/2_timer_end_logout_descend.wav" &
    ;;
  block|alarm)
    # 3. Anti-Unlock Break Blocker (Ringback Pings)
    paplay --device="$SINK" "$SOUND_DIR/3_anti_unlock_blocker_ringback_pings.wav" &
    ;;
  grace|tick)
    # 4. 5-Second Grace Countdown (Instant Ticks 5s)
    paplay --device="$SINK" "$SOUND_DIR/4_grace_countdown_instant_ticks.wav" &
    ;;
  *)
    echo "Usage: $0 [start|stop|end|block|alarm|grace|tick]"
    exit 1
    ;;
esac

#!/usr/bin/env bash
# Pomodoro & Lock Screen Audio Event Dispatcher
# Hardware Sink: GPU HDMI -> LG Monitor -> 3.5mm AUX -> External Room Speakers
# Sink Name: alsa_output.pci-0000_65_00.1.hdmi-stereo

SINK="alsa_output.pci-0000_65_00.1.hdmi-stereo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_DIR="$SCRIPT_DIR/sounds"
TARGET_VOLUME="${POMODORO_TARGET_VOLUME:-75}"

play_event_sound() {
  local sound_file="$1"
  local sync_mode="$2"
  [ ! -f "$sound_file" ] && return 1

  _play() {
    local PREV_VOL
    PREV_VOL=$(pactl get-sink-volume "$SINK" 2>/dev/null | grep -Po '[0-9]+(?=%)' | head -n1)
    [ -z "$PREV_VOL" ] && PREV_VOL="100"

    # Enforce hardware sink unmuted and calibrated 75% target volume
    # This prevents LG Monitor internal DAC clipping / buffer choppiness regardless of system volume
    pactl set-sink-mute "$SINK" 0 2>/dev/null
    pactl set-sink-volume "$SINK" "${TARGET_VOLUME}%" 2>/dev/null

    # Play sound to completion
    pw-play --target "$SINK" "$sound_file"

    # Restore previous system volume
    pactl set-sink-volume "$SINK" "${PREV_VOL}%" 2>/dev/null
  }

  if [ "$sync_mode" = "--sync" ]; then
    _play
  else
    _play &
  fi
}

case "$1" in
  start)
    # 1. Timer Start (Login Bell)
    play_event_sound "$SOUND_DIR/1_timer_start_login_bell.wav" "$2"
    ;;
  stop|end)
    # 2. Timer Stop / End (Logout Descend)
    play_event_sound "$SOUND_DIR/2_timer_end_logout_descend.wav" "$2"
    ;;
  block|alarm)
    # 3. Anti-Unlock Break Blocker (Alert Chime)
    play_event_sound "$SOUND_DIR/3_anti_unlock_blocker_ringback_pings.wav" "$2"
    ;;
  grace|tick)
    # 4. 5-Second Grace Countdown (Instant Ticks 5s)
    play_event_sound "$SOUND_DIR/4_grace_countdown_instant_ticks.wav" "$2"
    ;;
  *)
    echo "Usage: $0 [start|stop|end|block|alarm|grace|tick] [--sync]"
    exit 1
    ;;
esac

#!/usr/bin/env bash
# ==============================================================================
# Obsidian Scratchpad Focus / Toggle Manager (Hyprland v0.56+ Lua Architecture)
# ==============================================================================
# Behavior:
# 1. Finds active Obsidian window matching "000_SCRATCHPAD_Brain_Dump"
#    (supports both "obsidian" and "md.obsidian.Obsidian" classes).
# 2. If the window does not exist, automatically spawns it as a popout window
#    via Obsidian's workspace API.
# 3. Toggles focus: if active, dismisses to previous workspace; if inactive, focuses it.
# ==============================================================================

set -euo pipefail

# Ensure active Hyprland IPC environment is configured
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  for sig in $(ls -1t /run/user/1000/hypr 2>/dev/null || true); do
    if [[ -S "/run/user/1000/hypr/$sig/.socket.sock" ]]; then
      export HYPRLAND_INSTANCE_SIGNATURE="$sig"
      break
    fi
  done
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
fi

SCRATCH_TITLE="000_SCRATCHPAD_Brain_Dump"

find_scratchpad_window() {
  hyprctl clients -j 2>/dev/null | jq -r --arg title "$SCRATCH_TITLE" '
    .[]
    | select((.class == "obsidian" or .class == "md.obsidian.Obsidian") and (.title | contains($title)))
    | .address
  ' | head -n 1
}

WINDOW_ADDRESS="$(find_scratchpad_window)"

# Auto-spawn if not currently open
if [[ -z "$WINDOW_ADDRESS" || "$WINDOW_ADDRESS" == "null" ]]; then
  if command -v obscli >/dev/null 2>&1; then
    obscli eval code="app.workspace.openLinkText('000_SCRATCHPAD_Brain_Dump', '', 'window')" >/dev/null 2>&1 || true
  fi

  for _ in {1..15}; do
    sleep 0.1
    WINDOW_ADDRESS="$(find_scratchpad_window)"
    if [[ -n "$WINDOW_ADDRESS" && "$WINDOW_ADDRESS" != "null" ]]; then
      break
    fi
  done
fi

if [[ -z "$WINDOW_ADDRESS" || "$WINDOW_ADDRESS" == "null" ]]; then
  notify-send "Obsidian Scratch Pad" "Could not open scratch pad window" -t 2500
  exit 0
fi

ACTIVE_WINDOW_ADDRESS="$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')"

if [[ "$ACTIVE_WINDOW_ADDRESS" == "$WINDOW_ADDRESS" ]]; then
  hyprctl dispatch "hl.dsp.focus({ workspace = 'previous' })"
else
  hyprctl dispatch "hl.dsp.focus({ window = 'address:$WINDOW_ADDRESS' })"
fi

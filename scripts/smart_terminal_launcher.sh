#!/usr/bin/env bash
# ==============================================================================
# Smart Terminal Launcher for Hyprland / Omarchy
# ==============================================================================
# Logic:
# 1. If Workspace 1 (Left Vertical Monitor) is empty:
#    Launch primary Ghostty (class: com.mitchellh.ghostty) -> routed to Workspace 1, Fullscreen.
# 2. If Workspace 1 already has a running instance:
#    Launch secondary Ghostty (class: com.mitchellh.ghostty.secondary) -> routed to Workspace 2 (Ultrawide Monitor).
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

# Detect current working directory from active terminal if supported
CWD=""
if command -v omarchy-cmd-terminal-cwd >/dev/null 2>&1; then
  CWD="$(omarchy-cmd-terminal-cwd 2>/dev/null || true)"
fi

# Count active windows on Workspace 1
WS1_WINDOWS="$(hyprctl clients -j 2>/dev/null | jq '[.[] | select(.workspace.id == 1)] | length' 2>/dev/null || echo "0")"

if [[ "$WS1_WINDOWS" -eq 0 ]]; then
  # Workspace 1 is empty: launch primary fullscreen terminal
  if [[ -n "$CWD" ]]; then
    exec setsid uwsm-app -- ghostty --working-directory="$CWD" "$@"
  else
    exec setsid uwsm-app -- ghostty "$@"
  fi
else
  # Workspace 1 already occupied: launch secondary terminal on Workspace 2 (Ultrawide)
  if [[ -n "$CWD" ]]; then
    exec setsid uwsm-app -- ghostty --class=com.mitchellh.ghostty.secondary --working-directory="$CWD" "$@"
  else
    exec setsid uwsm-app -- ghostty --class=com.mitchellh.ghostty.secondary "$@"
  fi
fi

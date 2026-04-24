#!/bin/bash

set -euo pipefail

SCRATCH_TITLE="000_SCRATCHPAD_Brain_Dump"

WINDOW_ADDRESS="$(
  hyprctl clients -j | jq -r --arg title "$SCRATCH_TITLE" '
    .[]
    | select(.class == "obsidian" and (.title | contains($title)))
    | .address
  ' | head -n 1
)"

ACTIVE_WINDOW_ADDRESS="$(hyprctl activewindow -j | jq -r '.address // empty')"

if [[ -z "$WINDOW_ADDRESS" || "$WINDOW_ADDRESS" == "null" ]]; then
  notify-send "Obsidian Scratch Pad" "Scratch pad window not found" -t 2500
  exit 0
fi

if [[ "$ACTIVE_WINDOW_ADDRESS" == "$WINDOW_ADDRESS" ]]; then
  hyprctl dispatch workspace previous
else
  hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
fi

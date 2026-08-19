#!/bin/bash

if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)
fi

# Check how many monitors are currently enabled
MONITOR_COUNT=$(hyprctl monitors | grep "Monitor" | wc -l)

if [ "$MONITOR_COUNT" -gt 1 ]; then
    # Currently have multiple monitors, switch to SINGLE (Gaming)
    notify-send -a "Monitor Switch" "Switching to Game Mode (Single Monitor)"
    
    # Move all workspaces to the main monitor DP-3 to prevent trapped windows
    for ws in {1..10}; do
        hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$ws\", monitor = \"DP-3\" })" 2>/dev/null
    done
    
    # Disable secondary monitors using Lua eval syntax
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
    hyprctl eval 'hl.monitor({ output = "DP-2", disabled = true })'
    
    # Position main monitor at 0x0
    hyprctl eval 'hl.monitor({ output = "DP-3", mode = "3440x1440@60", position = "0x0", scale = 1 })'
else
    # Currently have single monitor, switch to MULTI (Work)
    notify-send -a "Monitor Switch" "Switching to Work Mode (Multi Monitor)"
    
    # Restore configuration
    # 1. Move Main monitor back to its position
    hyprctl eval 'hl.monitor({ output = "DP-3", mode = "3440x1440@60", position = "1080x240", scale = 1, disabled = false })'
    # 2. Enable Left Vertical (Inverted)
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1, transform = 3, disabled = false })'
    # 3. Enable Right Vertical
    hyprctl eval 'hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "4520x0", scale = 1, transform = 3, disabled = false })'
fi

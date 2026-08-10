#!/bin/bash

# Check how many monitors are currently enabled
MONITOR_COUNT=$(hyprctl monitors | grep "Monitor" | wc -l)

if [ "$MONITOR_COUNT" -gt 1 ]; then
    # Currently have multiple monitors, switch to SINGLE (Gaming)
    notify-send -a "Monitor Switch" "Switching to Game Mode (Single Monitor)"
    
    # Move all workspaces to the main monitor DP-1 to prevent trapped windows
    for ws in {1..10}; do
        hyprctl dispatch moveworkspacetomonitor "$ws" DP-1
    done
    
    # Disable secondary monitors
    hyprctl keyword monitor "HDMI-A-1, disable"
    hyprctl keyword monitor "DP-2, disable"
    
    # Position main monitor at 0x0
    # -------------------------------------------------------------
    # SETUP 2: native Ultrawide (Active)
    # -------------------------------------------------------------
    hyprctl keyword monitor "DP-1, 3440x1440@60, 0x0, 1"
    
    # -------------------------------------------------------------
    # SETUP 1: standard 1080p (Inactive)
    # -------------------------------------------------------------
    # hyprctl keyword monitor "DP-1, 1920x1080@60, 0x0, 1"
else
    # Currently have single monitor, switch to MULTI (Work)
    notify-send -a "Monitor Switch" "Switching to Work Mode (Multi Monitor)"
    
    # Restore configuration
    
    # -------------------------------------------------------------
    # SETUP 2: NEW L-C-R SETUP (Vertical - Ultrawide - Vertical) - ACTIVE
    # -------------------------------------------------------------
    # 1. Move Main monitor back to its position
    hyprctl keyword monitor "DP-1, 3440x1440@60, 1080x240, 1"
    # 2. Enable Left Vertical (Inverted)
    hyprctl keyword monitor "HDMI-A-1, 1920x1080@60, 0x0, 1, transform, 3"
    # 3. Enable Right Vertical
    hyprctl keyword monitor "DP-2, 1920x1080@60, 4520x0, 1, transform, 3"
    
    # -------------------------------------------------------------
    # SETUP 1: OLD L-C-R SETUP (Vertical - 1080p Horizontal - Vertical) - INACTIVE
    # -------------------------------------------------------------
    # # 1. Move Main monitor back to its position
    # hyprctl keyword monitor "DP-1, 1920x1080@60, 1080x740, 1"
    # # 2. Enable Left Vertical
    # hyprctl keyword monitor "HDMI-A-1, 1920x1080@60, 0x0, 1, transform, 1"
    # # 3. Enable Right Vertical
    # hyprctl keyword monitor "DP-2, 1920x1080@60, 3000x0, 1, transform, 3"
fi

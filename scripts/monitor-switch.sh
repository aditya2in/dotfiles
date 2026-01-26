#!/bin/bash

# Check how many monitors are currently enabled
MONITOR_COUNT=$(hyprctl monitors | grep "Monitor" | wc -l)

if [ "$MONITOR_COUNT" -gt 1 ]; then
    # Currently have multiple monitors, switch to SINGLE (Gaming)
    notify-send -a "Monitor Switch" "Switching to Game Mode (Single Monitor)"
    
    # Disable secondary monitors
    hyprctl keyword monitor "HDMI-A-1, disable"
    hyprctl keyword monitor "DP-2, disable"
    
    # Position main monitor at 0x0 for best compatibility
    hyprctl keyword monitor "DP-1, 1920x1080@60, 0x0, 1"
else
    # Currently have single monitor, switch to MULTI (Work)
    notify-send -a "Monitor Switch" "Switching to Work Mode (Multi Monitor)"
    
    # Restore configuration
    # 1. Move Main monitor back to its position
    hyprctl keyword monitor "DP-1, 1920x1080@60, 1080x740, 1"
    
    # 2. Enable Left Vertical
    hyprctl keyword monitor "HDMI-A-1, 1920x1080@60, 0x0, 1, transform, 1"
    
    # 3. Enable Right Vertical
    hyprctl keyword monitor "DP-2, 1920x1080@60, 3000x0, 1, transform, 3"
fi

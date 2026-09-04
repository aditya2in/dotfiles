#!/bin/bash
# Witcher 3 API Switcher Wrapper Script
# Usage in Steam:
# /home/adityaws/DOTfiles/scripts/witcher3_wrapper.sh [11|12] %command% --launcher-skip

DX_VER="$1"
shift # Remove the DX version from arguments, leaving %command% and rest of args

# Path to the launcher configuration file
CONFIG_FILE="/home/adityaws/.local/share/Steam/steamapps/common/The Witcher 3/launcher-configuration.json"

# Dynamically modify the fallback setting in launcher-configuration.json on the fly
if [ "$DX_VER" = "11" ] || [ "$DX_VER" = "12" ]; then
    sed -i 's/"fallback": "DirectX [0-9]*"/"fallback": "DirectX '$DX_VER'"/' "$CONFIG_FILE"
fi

# Force MangoHUD to use our custom configuration file, bypassing Proton sandbox isolation
export MANGOHUD_CONFIGFILE="/home/adityaws/.config/mangohud/MangoHud.conf"

# Hardware frame rate cap: Lock at 72 FPS (75Hz monitor minus 3 FPS rule for zero tearing & lowest input latency)
export DXVK_FRAME_RATE=72

# Ensure Ultrawide DP-2 is set as Primary in XWayland so Proton exposes native 3440x1440p in multi-monitor mode
xrandr --output DP-2 --primary 2>/dev/null || true

# Run the game launcher exactly as Steam intended
exec "$@"

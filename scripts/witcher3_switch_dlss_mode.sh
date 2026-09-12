#!/bin/bash
# ==============================================================================
# Script: witcher3_switch_dlss_mode.sh
# Usage:
#   witcher3_switch_dlss_mode.sh official  --> Restores Official DLSS 3.7+
#   witcher3_switch_dlss_mode.sh dlss5     --> Enables DLSS 5 Neural Rendering
#   witcher3_switch_dlss_mode.sh           --> Auto-detects & toggles mode
# ==============================================================================
set -e

GAME_DIR="$HOME/.local/share/Steam/steamapps/common/The Witcher 3/bin/x64_dx12"
ACTION="$1"

if [ -z "$ACTION" ]; then
    if [ -f "$GAME_DIR/dxgi.dll" ]; then
        ACTION="official"
    else
        ACTION="dlss5"
    fi
fi

case "$ACTION" in
    official|stock|plana|disable_dlss5|off)
        /home/adityaws/DOTfiles/scripts/witcher3_enable_official_dlss_3_7.sh
        ;;
    dlss5|neural|sandbox|enable_dlss5|on)
        /home/adityaws/DOTfiles/scripts/witcher3_enable_dlss5_neural_rendering.sh
        ;;
    *)
        echo "Usage: $0 [official | dlss5]"
        exit 1
        ;;
esac

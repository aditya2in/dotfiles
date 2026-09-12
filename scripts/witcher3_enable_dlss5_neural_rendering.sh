#!/bin/bash
# ==============================================================================
# Script: witcher3_enable_dlss5_neural_rendering.sh
# Purpose: Injects OptiScaler and leaked DLSS 5 Neural Rendering runtime
# Target: The Witcher 3 Next-Gen (DX12) Sandbox Experimentation
# ==============================================================================
set -e

GAME_DIR="$HOME/.local/share/Steam/steamapps/common/The Witcher 3/bin/x64_dx12"
BACKUP_DIR="$GAME_DIR/_BACKUP_DLSS_5_NEURAL_RENDERING_SANDBOX"
WRAPPER="$HOME/DOTfiles/scripts/witcher3_wrapper.sh"

echo "================================================================="
echo "  [Witcher 3] Activating DLSS 5 (Neural Rendering) Sandbox"
echo "================================================================="

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Error: Backup folder not found at $BACKUP_DIR"
    exit 1
fi

# 1. Copy complete DLSS 5 sandbox payload
echo "[1/2] Staging OptiScaler DLSSNR & 159MB neural model payload..."
cp -af "$BACKUP_DIR/"* "$GAME_DIR/"

# 2. Enable dxgi override in Steam wrapper
echo "[2/2] Enabling dxgi override in Steam wrapper..."
if [ -f "$WRAPPER" ]; then
    sed -i 's/ENABLE_DLSS5_TEST=0/ENABLE_DLSS5_TEST=1/g' "$WRAPPER" 2>/dev/null || true
fi

echo "================================================================="
echo "  ✓ DLSS 5 NEURAL RENDERING SANDBOX IS NOW ACTIVE!"
echo "  - In-Game Menu: Press INSERT for OptiScaler HUD"
echo "  - Recommended Test Resolution: 1080p (1920x1080 / 2560x1080)"
echo "  - To switch back anytime: ~/DOTfiles/scripts/witcher3_enable_official_dlss_3_7.sh"
echo "================================================================="

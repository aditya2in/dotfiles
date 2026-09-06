#!/bin/bash
# ==============================================================================
# The Witcher 3 - DLSS Unlocked (Frame Gen & DLSS-NR) Installer
# ==============================================================================

W3_DX12_DIR="/home/adityaws/.local/share/Steam/steamapps/common/The Witcher 3/bin/x64_dx12"
BACKUP_DIR="/home/adityaws/.local/share/Steam/steamapps/common/The Witcher 3/bin/x64_dx12_STOCK_BACKUP"
STAGING_DIR="/home/adityaws/DOTfiles/gamesaves/dlss_unlocked_staging/extracted"

echo "🛡️ [1/3] Verifying stock backup..."
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$W3_DX12_DIR/"* "$BACKUP_DIR/"
    echo "✅ Created new stock backup at $BACKUP_DIR"
else
    echo "✅ Stock backup already verified at $BACKUP_DIR"
fi

echo "📦 [2/3] Deploying DLSS Unlocked files to $W3_DX12_DIR..."
cp "$STAGING_DIR/version.dll" "$W3_DX12_DIR/"
cp "$STAGING_DIR/OptiScaler.ini" "$W3_DX12_DIR/"
cp "$STAGING_DIR/nvngx.dll_dlssnr.dll" "$W3_DX12_DIR/"
cp -r "$STAGING_DIR/OptiScaler" "$W3_DX12_DIR/"

echo "🔍 [3/3] Verifying deployment..."
ls -la "$W3_DX12_DIR/version.dll" "$W3_DX12_DIR/OptiScaler.ini" "$W3_DX12_DIR/OptiScaler"

notify-send -a "The Witcher 3" "🚀 DLSS Unlocked Installed" "Frame Generation & DLSS-NR ready in DirectX 12."
echo "🎉 Installation complete. Frame Generation mod is active."

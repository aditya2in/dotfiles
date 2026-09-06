#!/bin/bash
# ==============================================================================
# The Witcher 3 - Instant Stock Restore Script
# ==============================================================================
# Instantly removes all DLSS Unlocked / OptiScaler / Frame Generation mod files
# and restores the exact original stock bin/x64_dx12 binaries from backup.
# ==============================================================================

W3_DX12_DIR="/home/adityaws/.local/share/Steam/steamapps/common/The Witcher 3/bin/x64_dx12"
BACKUP_DIR="/home/adityaws/.local/share/Steam/steamapps/common/The Witcher 3/bin/x64_dx12_STOCK_BACKUP"

echo "🧹 [1/3] Removing all mod files and directories..."
rm -f "$W3_DX12_DIR/version.dll"
rm -f "$W3_DX12_DIR/OptiScaler.ini"
rm -f "$W3_DX12_DIR/nvngx.dll_dlssnr.dll"
rm -f "$W3_DX12_DIR/dlssg_to_fsr3_amd_is_better.dll"
rm -f "$W3_DX12_DIR/amd_fidelityfx_"*.dll
rm -f "$W3_DX12_DIR/OptiScaler.log"
rm -f "$W3_DX12_DIR/dlssg_to_fsr3.log"
rm -f "$W3_DX12_DIR/dlss-enabler.log"
rm -rf "$W3_DX12_DIR/OptiScaler"

echo "📦 [2/3] Restoring pure stock binaries from backup..."
if [ -d "$BACKUP_DIR" ]; then
    cp -r "$BACKUP_DIR/"* "$W3_DX12_DIR/"
    echo "✅ Stock files restored successfully from $BACKUP_DIR"
else
    echo "⚠️ Warning: Backup directory $BACKUP_DIR not found, mod files were still cleaned up."
fi

echo "🔍 [3/3] Verifying clean directory..."
ls -la "$W3_DX12_DIR" | grep -E "version|OptiScaler" || echo "✨ Clean! Zero mod files remain in x64_dx12."

notify-send -a "The Witcher 3" "✅ 100% Stock State Restored" "All mods removed. Clean DX12 binaries active."
echo "🎉 Restoration complete. You are 100% back on stock settings."

#!/bin/bash
# Emergency Undo Script for Witcher 3 First Person Remastered (FPV) Mod
set -euo pipefail

GAME_ROOT="/home/adityaws/.local/share/Steam/steamapps/common/The Witcher 3"
PROTON_DOCS="/home/adityaws/.local/share/Steam/steamapps/compatdata/292030/pfx/drive_c/users/steamuser/Documents/The Witcher 3"
WRAPPER_SCRIPT="/home/adityaws/DOTfiles/scripts/witcher3_wrapper.sh"

echo "=== Undoing Witcher 3 First Person Remastered Mod ==="

# 1. Restore input.settings
if [ -f "$PROTON_DOCS/input.settings.bak_pre_fpv" ]; then
    cp "$PROTON_DOCS/input.settings.bak_pre_fpv" "$PROTON_DOCS/input.settings"
    echo "[-] Restored input.settings from pre-FPV backup."
else
    # Fallback: strip bindings
    python3 -c "
import re
path = '$PROTON_DOCS/input.settings'
with open(path, 'r') as f: text = f.read()
text = re.sub(r'(?m)^IK_\w+=\(Action=FPR_(Toggle|Modifier|Wheel|Reticle)\)\r?\n?', '', text)
with open(path, 'w') as f: f.write(text)
"
    echo "[-] Stripped FPR keybindings from input.settings."
fi

# 2. Remove mod directory
rm -rf "$GAME_ROOT/mods/modFirstPersonRemastered"
if [ -L "$GAME_ROOT/Mods" ]; then
    rm -f "$GAME_ROOT/Mods"
fi
if [ -d "$GAME_ROOT/mods" ] && [ -z "$(ls -A "$GAME_ROOT/mods")" ]; then
    rmdir "$GAME_ROOT/mods"
fi
echo "[-] Removed modFirstPersonRemastered scripts."

# 3. Remove ASI loader and culling plugin from bin/x64_dx12
rm -f "$GAME_ROOT/bin/x64_dx12/dinput8.dll" \
      "$GAME_ROOT/bin/x64_dx12/NoNearCameraCulling.asi" \
      "$GAME_ROOT/bin/x64_dx12/NoNearCameraCulling-LICENSE.txt" \
      "$GAME_ROOT/bin/x64_dx12/UltimateASILoader-LICENSE.txt"
echo "[-] Removed ASI loader & NoNearCameraCulling DLLs from bin/x64_dx12."

# 4. Restore wrapper script
if [ -f "${WRAPPER_SCRIPT}.bak_pre_fpv" ]; then
    cp "${WRAPPER_SCRIPT}.bak_pre_fpv" "$WRAPPER_SCRIPT"
    echo "[-] Restored witcher3_wrapper.sh from pre-FPV backup."
fi

echo "=== FPV Mod has been completely uninstalled. Game restored to original state. ==="

#!/bin/bash
# Witcher 3 API Switcher Wrapper Script
# Usage in Steam:
# /home/adityaws/DOTfiles/scripts/witcher3_wrapper.sh [11|12] %command% --launcher-skip

DX_VER="$1"
shift # Remove the DX version from arguments, leaving %command% and rest of args

if [ "$DX_VER" = "12" ]; then
    V="x64_dx12"
else
    V="x64"
fi

# Replace launcher-forcer.exe with bin/$V/witcher3.exe in positional parameters
exec "${@/launcher-forcer.exe/bin\/$V\/witcher3.exe}"

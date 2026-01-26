# VoxType (F12)

Fast, lightweight Push-to-Talk dictation tool.

## 🚀 How to Use
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **Shift + F12** | **Master Power** | Toggles the background service. Use this to save 1.5GB of VRAM when not dictating. Opens `wiremix`. |
| **F12** | **Record Button** | **Push-to-Talk.** Press once to start recording, press again to stop and type. |

## 🛠 Technical Details
- **Hardware:** **GPU (NVIDIA CUDA)** via `ctranslate2`.
- **Primary Model:** `ggml-medium.en` (Default).
- **VRAM Usage:** ~1.5 GB.
- **Service:** Managed via `systemd` user service (`voxtype.service`).

## ⚙️ Customization
VoxType is a compiled application, but you can manage its models:

1.  **View Installed Models:**
    Look in `~/.local/share/voxtype/models/`.
2.  **Change Model:**
    Run `voxtype setup` in your terminal to download different versions (e.g., `large-v3-turbo` for higher accuracy).
3.  **Config Location:**
    Settings are usually handled by the binary, but the master service is managed by the `smart_voxtype.sh` script in this folder.

## 📂 File Structure
- `smart_voxtype.sh`: The logic handler that manages the Power Toggle and the F12 Action.
- This script ensures the service is ONLY running when you specifically want it to.

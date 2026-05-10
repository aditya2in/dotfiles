# VoxType (F1)

## 🛠 RECONSTRUCTION GUIDE (Future-Proofing)
If this setup is lost, follow these steps to restore functionality:

### 1. The Application
- **Name:** VoxType
- **Installation:** Check AUR for `voxtype-bin`.
- **Service:** The script relies on a user service at `~/.config/systemd/user/voxtype.service`.

### 2. The AI Model (GGML)
Download the **Large-v3-Turbo** model in GGML format:
```bash
wget https://huggingface.co/guillaumekln/faster-whisper-large-v3-turbo/resolve/main/ggml-large-v3-turbo.bin -O ~/AI_MODELS/dictation_models/ggml-large-v3-turbo.bin
```

### 3. Verification
Run `smart_voxtype.sh toggle-power` (Shift+F1) to verify the service starts and connects to `wiremix`.

---

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

# System Troubleshooting Guide

This document captures system-level issues and fixes encountered during the development and use of the Whisper Turbo STT project.

---

## 1. Dual Audio Output Issue (Headphones + CPU Speaker)

### **Problem**
When using the Intel PCH audio output (e.g., in Brave or system-wide), audio plays simultaneously through the headphones and the internal "CPU" (chassis) speaker. This occurs even when headphones are plugged in.

### **Technical Cause**
The system uses a **Dual-Codec** HDA Intel PCH configuration:
*   **Codec 1:** Realtek ALC662 (Handling specific ports like Line Out/Speaker).
*   **Codec 2:** Realtek ALC233 (Handling Headphone ports).

Because these ports are managed by separate chips on the same card, the standard ALSA "Auto-Mute" feature (which usually detects a jack insertion and mutes the speaker) fails to bridge the gap between the two codecs.

### **The Solution**
Manually mute the specific "Speaker" control on the Intel PCH card while leaving the "Headphone" and "Master" controls active.

#### **Manual Command (One-time fix)**
Run the following in your terminal:
```bash
amixer -c 1 sset Speaker mute
```
*(Note: `-c 1` specifies the Intel PCH card based on your current `aplay -l` output.)*

#### **Making it Permanent**
To ensure the speaker stays muted after a reboot, you can save the current ALSA mixer state:
```bash
sudo alsactl store
```
This writes the settings to `/var/lib/alsa/asound.state`, which the system loads automatically on startup.

---
*Last updated: January 26, 2026.*

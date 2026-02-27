# Whisper Turbo Real-Time STT: The Definitive Guide & Plan

## 1. Project Vision
To create a "Professional-Grade" streaming dictation tool for Arch Linux/Hyprland. Unlike standard tools that wait for you to finish speaking, this system provides a **real-time flow** of text using your NVIDIA RTX 3060 GPU, ensuring world-class accuracy with near-zero latency.

---

## 2. The Technology Stack (The "Why")

### **The Model: Whisper Large-v3-Turbo**
*   **Definition:** A "distilled" version of OpenAI's massive Large-v3 model.
*   **The Benefit:** Large-v3 is highly accurate but slow. "Turbo" offers ~99% of that accuracy but runs **8x faster**. It is the "brain" that understands your voice.

### **The Engine: faster-whisper (CTranslate2)**
*   **Definition:** A custom implementation of Whisper designed for speed.
*   **The Benefit:** Standard Whisper uses PyTorch (heavy/slow). `faster-whisper` uses CTranslate2, which is optimized for "inference" (running the model). It uses 4x less VRAM and is much snappier on your GPU.

### **The Wrapper: RealtimeSTT**
*   **Definition:** The "Glue" that connects your microphone to the AI.
*   **The Benefit:** It handles the complex threading required to record audio and transcribe it simultaneously without losing data.

---

## 3. Advanced Features (The "Hybrid" Build)

### **Context Memory (Phrase Continuity)**
*   **How it works:** The script saves the text of your last spoken phrase. When you start speaking again, it feeds that text back to the AI as a "Prompt."
*   **The Goal:** Prevents fragmented sentences. The AI "remembers" you are mid-sentence and avoids adding unnecessary periods or capital letters.

### **Threaded Output (The Two-Lane System)**
*   **Lane 1 (The Ear):** Always listening. As soon as a phrase is ready, it "drops" it into a queue and immediately goes back to listening.
*   **Lane 2 (The Finger):** A background worker that types the text from the queue using `wtype`.
*   **The Goal:** Ensures the AI never stops listening while it is busy typing a long sentence.

### **Safety Cut (Max Segment Length)**
*   **How it works:** If you speak for more than **15 seconds** without a pause, the system forces a "snapshot" transcription.
*   **The Goal:** Ensures you see text on the screen regularly during long monologues, rather than waiting until the very end of a 5-minute speech.

---

## 4. The "Control Knobs" (How to Tune Your AI)

If you want to change the "feel" of the dictation later, these are the variables inside `whisper_turbo_realtime_stt.py` you should change:

| Knob (Parameter) | Current Value | What it does | If you make it HIGHER... | If you make it LOWER... |
| :--- | :--- | :--- | :--- | :--- |
| `post_speech_silence_duration` | **0.6s** | How long to wait after you stop talking. | More patient; better for thinking/breathing. | More real-time; text pops up faster but breaks sentences. |
| `silero_sensitivity` | **0.20** | The "Gatekeeper" threshold. | Ignores more noise (keyboard/fans) but might miss quiet words. | Catches every whisper but might transcribe your keyboard "clacks." |
| `min_length_of_recording` | **0.3s** | The shortest sound allowed. | Filters out more accidental noises/keyboard clicks. | System is more "jittery" and responsive to short sounds. |
| `max_recording_time` (Logic) | **15s** | Force-cut duration. | You see text less often during long speeches. | Text pops up more frequently in smaller chunks. |

---

## 5. Frequently Asked Questions (Q&A)

### **Q: Why does it show two "recordings" in Wiremix?**
**A:** One is Wiremix itself showing you the volume bar. The second is the Python script "grabbing" the audio to feed it to the AI. This is normal and safe on PipeWire.

### **Q: How do I stop or restart the engine?**
**A:** Press **F7**. The toggle script is "bulletproof"—it checks if the AI is running and will kill any old or "zombie" processes before starting a fresh one.

### **Q: Why did it miss my first word?**
**A:** This happens if the `silero_sensitivity` is too high (e.g., 0.4). The AI takes a split second to "wake up" and misses the start of the word. We have set it to **0.2** to prevent this.

### **Q: Why is it typing letter-by-letter?**
**A:** We use `wtype` for a "Smooth Flow" effect. It looks more natural than a "Copy-Paste" block. If it's too slow, we can optimize the code further, but currently, it runs at max OS speed.

---

## 6. Verification & Performance Testing

To confirm the advanced features are working correctly, perform these two tests:

### **Test 1: The "Monologue" Test (Verifies Safety Cut)**
*   **Action:** Speak continuously for at least 20–30 seconds without taking a significant pause.
*   **What to observe:** Around the **15-second mark**, a "burst" of text should appear on your screen even though you haven't stopped talking. 
*   **Technical Reason:** This confirms the **Safety Cut** is forcing a transcription snapshot to keep the screen updated during long speeches.

### **Test 3: The "Smart Pause" Test (Verifies Focus Detection)**
*   **Action:** Ensure the Waybar icon is **Green**. Open your browser (Brave) and click on it to focus.
*   **What to observe:** The icon should turn **Yellow** (Mute icon) within 1 second. Try speaking; no text should be typed into the browser. Click back to your terminal; the icon should return to **Green**.
*   **Technical Reason:** This confirms the **Hyprland Socket2 Listener** is correctly catching focus events and pausing the recorder to prevent headphone leakage.

---

## 7. Upcoming Ideas (Future Roadmap)

### **Visual Dictation Indicator (Siri-style)**
*   **The Idea:** Add a visual animation at the bottom of the screen (similar to Apple's Siri or Google Assistant) that activates when dictation is running.
*   **The Goal:** Provide a clear "live" indicator that the AI is listening and active, even when no text is currently being typed.
*   **Status:** Concept stage (Evaluating frameworks like AGS, Fabric, or simple Overlay windows).

---

## 8. Project Structure

*   `whisper_turbo_realtime_stt.py`: The "Master" script (The Brain).
*   `toggle_dictation.sh`: The "Toggle" script (The Muscle). Connected to **F7**.
*   `run_test.sh`: The "Debug" script. Use this to see what the AI is thinking in the terminal.
*   `venv/`: The "Closet." Contains all the heavy GPU libraries (torch, faster-whisper).

---

## 9. The "Smart Pause" & Waybar System (Added Feb 13, 2026)

### **The Problem: Audio Leakage**
When watching online courses in a browser (Brave), the audio from the headphones can leak into the microphone. The STT engine then transcribes the course content into your active window, causing unwanted text and potential disruptions.

### **The Solution: Focus-Aware Suppression**
The system now includes an **Event-Driven Smart Pause** mechanism. It automatically stops the microphone recording whenever you are focused on specific "blocked" applications (like your browser).

### **How it Works (The "Expert" Way)**
*   **Hyprland Socket2:** Instead of constantly checking which window is open (polling), the script connects to Hyprland's native Unix socket (`.socket2.sock`). 
*   **Zero Overhead:** The script sits idle and only wakes up when Hyprland "pushes" a focus change event. This consumes **0% CPU** while you are working.
*   **Instant Reaction:** The moment you click on the Brave browser, the engine stops. The moment you click back to your terminal or Obsidian, it resumes.

### **Visual Feedback (Waybar)**
The system is integrated into your Waybar with a dedicated module that shows the exact state of the engine:
*   🟢 **Green (Running):** Active and transcribing.
*   🟡 **Yellow (Smart/Manual Pause):** Muted. The tooltip will tell you if it's because of a manual pause (F8) or because you are focused on a blocked app (Brave).
*   🔴 **Red (Stopped):** The engine is completely turned off.

### **Future-Proofing: Customization**
You can control this behavior without touching any code by editing:
`~/DOTfiles/scripts/speech_recognition/whisper_turbo_stt/whisper_config.json`

| Setting | Value | Description |
| :--- | :--- | :--- |
| `smart_pause_enabled` | `true/false` | Master switch for the auto-pause feature. |
| `ignored_classes` | `["brave-browser"]` | A list of window classes that should trigger a pause. Add more apps here to block them! |

---
*Updated on: February 13, 2026. Optimized for focus and professional workflow.*


## Future Improvements & Efficiency Ideas (Feb 22, 2026)

Based on recent system recovery and optimization analysis, here are the top ideas for improving the dictation engine:

1. **Engine Optimization (Faster-Whisper):**
   - **Action:** Transition from the standard OpenAI Whisper library to **Faster-Whisper** using **CTranslate2**.
   - **Benefit:** Up to 4x faster transcription speed and ~50% reduction in VRAM usage (Int8 quantization).

2. **Ultra-Low Latency (SenseVoiceSmall):**
   - **Action:** Experiment with the **SenseVoiceSmall** model for real-time streaming.
   - **Benefit:** Significantly lower latency than Whisper, better handling of non-speech audio (laughter, noise), and minimal VRAM footprint.

3. **VRAM Efficiency (Distil-Whisper):**
   - **Action:** Replace the current `large-v3-turbo` with **distil-large-v3**.
   - **Benefit:** Maintains identical accuracy to full models while being 50% faster and much smaller, allowing more headroom for other GPU-heavy tasks (like Witcher 3).

4. **Integration Audit:**
   - **Action:** Audit the redundancy between this script and **Voxtype**.
   - **Benefit:** Consolidate model storage to reclaim the ~15 GB currently used by duplicate venvs if features can be merged.

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

### **Test 2: The "Overlap" Test (Verifies Lane 2 Threading)**
*   **Action:** Say a sentence, and then **immediately** start saying your next sentence while the first one is still being typed onto the screen.
*   **What to observe:** Both sentences should appear perfectly. The system should not "miss" the start of the second sentence.
*   **Technical Reason:** This confirms the **Threaded Output (Lane 2)** is working. The "Ear" (AI) is listening to your new words while the "Finger" (Background Thread) is busy typing the old ones.

---

## 7. Project Structure

*   `whisper_turbo_realtime_stt.py`: The "Master" script (The Brain).
*   `toggle_dictation.sh`: The "Toggle" script (The Muscle). Connected to **F7**.
*   `run_test.sh`: The "Debug" script. Use this to see what the AI is thinking in the terminal.
*   `venv/`: The "Closet." Contains all the heavy GPU libraries (torch, faster-whisper).

---
*Created on: January 26, 2026. This document is your manual for the ultimate dictation experience.*

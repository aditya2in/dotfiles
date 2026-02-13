import os
import sys
import subprocess
import threading
import queue
import time
import signal
from RealtimeSTT import AudioToTextRecorder

# Force usage of GPU if available
os.environ["CT2_CUDA_ALLOW_TF32"] = "1"

# Global state for pausing
is_paused = False
PAUSE_FILE = "/tmp/whisper_paused"
recorder = None  # Global reference to allow background interruption

def pause_watcher():
    """Background thread that watches for a pause file."""
    global is_paused, recorder
    # Ensure file doesn't exist at start
    if os.path.exists(PAUSE_FILE):
        os.remove(PAUSE_FILE)
        
    last_state = False
    while True:
        current_state = os.path.exists(PAUSE_FILE)
        if current_state != last_state:
            is_paused = current_state
            status = "PAUSED" if is_paused else "RESUMED"
            icon = "microphone-sensitivity-muted" if is_paused else "microphone-sensitivity-high"
            
            # INSTANT STOP: If we just paused, force the recorder to stop immediately
            if is_paused and recorder:
                try:
                    recorder.stop()
                except Exception:
                    pass

            print(f"\n[INFO] Dictation {status}")
            subprocess.run([
                "notify-send", 
                "Whisper STT", 
                f"Status: {status}", 
                "-i", icon, 
                "-t", "1500",
                "-h", "string:x-canonical-private-synchronous:whisper-pause"
            ])
            last_state = current_state
        time.sleep(0.1) # Faster check for snappier response

# Start the pause watcher thread
threading.Thread(target=pause_watcher, daemon=True).start()

# Lane 2: The typing queue and worker
text_queue = queue.Queue()

def typing_worker():
    """Background thread that types text from the queue as fast as possible."""
    while True:
        text = text_queue.get()
        if text is None:
            break
        try:
            # High-speed wtype execution
            subprocess.run(["wtype", text], check=True)
        except Exception:
            pass
        text_queue.task_done()

# Start the background typing thread immediately
threading.Thread(target=typing_worker, daemon=True).start()

def main():
    print("[DEBUG] Script started (Threaded Hybrid Mode).")
    
    print("\n[INFO] Using SYSTEM DEFAULT audio device.")
    print("\n[DEBUG] Initializing Whisper Turbo Model...")
    
    # Store context for continuity
    last_text = ""

    recorder_config = {
        "model": "large-v3-turbo",
        "device": "cuda",
        "compute_type": "float16",
        "language": "en",
        "post_speech_silence_duration": 0.65,
        "min_gap_between_recordings": 0.0,
        "input_device_index": None,
        "spinner": False,
        "use_microphone": True,
        "silero_sensitivity": 0.4, # Keyboard/Headset Leakage Filter
        "webrtc_sensitivity": 3,
        "min_length_of_recording": 0.3,
        "beam_size": 1, # Maximize speed, reduce missed words
        "initial_prompt": "This is a continuous dictation session."
    }

    def process_text(text):
        nonlocal last_text
        if is_paused:
            return  # Instant discard if we are paused

        text = text.strip()
        if text:
            # Provide full context to the next chunk for perfect grammar
            recorder.initial_prompt = f"Previous text: {last_text}. Continue the thought naturally."
            last_text = text
            
            # Drop text into Lane 2 (Typing) and immediately return to listening
            text_queue.put(text + " ")

    try:
        global recorder
        recorder = AudioToTextRecorder(**recorder_config)
        print("[DEBUG] Recorder instantiated successfully.")
        
        # SAFETY CUT LOGIC:
        def safety_monitor():
            while True:
                if not is_paused and hasattr(recorder, 'is_recording') and recorder.is_recording:
                    start_time = getattr(recorder, 'recording_start_time', 0)
                    if start_time > 0 and (time.time() - start_time) > 20:
                        print("\n[DEBUG] Safety Cut (15s limit).")
                        recorder.stop()
                time.sleep(0.5)

        threading.Thread(target=safety_monitor, daemon=True).start()

        print("\n>>> System Ready! Speak into your microphone.")

        while True:
            if is_paused:
                if getattr(recorder, 'is_recording', False):
                    print("[DEBUG] Pausing: Stopping recorder...")
                    recorder.stop()
                time.sleep(0.5)
                continue
            
            if not getattr(recorder, 'is_recording', False):
                print("[DEBUG] Resuming: Starting recorder...")
                recorder.start()

            # This blocks while listening, then calls process_text
            try:
                recorder.text(process_text)
            except Exception as e:
                if not is_paused:
                    print(f"[ERROR] Recorder error: {e}")
                time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nStopping...")
        text_queue.put(None)
    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    main()
import os
import sys
import subprocess
import threading
import queue
import time
from RealtimeSTT import AudioToTextRecorder

# Force usage of GPU if available
os.environ["CT2_CUDA_ALLOW_TF32"] = "1"

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
        "post_speech_silence_duration": 0.7,
        "min_gap_between_recordings": 0.05,
        "input_device_index": None,
        "spinner": False,
        "use_microphone": True,
        "silero_sensitivity": 0.2, # Keyboard Filter
        "webrtc_sensitivity": 3,
        "min_length_of_recording": 0.3,
        "initial_prompt": "This is a continuous dictation session."
    }

    def process_text(text):
        nonlocal last_text
        text = text.strip()
        if text:
            # Provide full context to the next chunk for perfect grammar
            recorder.initial_prompt = f"Previous text: {last_text}. Continue the thought naturally."
            last_text = text
            
            # Drop text into Lane 2 (Typing) and immediately return to listening
            text_queue.put(text + " ")

    try:
        recorder = AudioToTextRecorder(**recorder_config)
        print("[DEBUG] Recorder instantiated successfully.")
        
        # SAFETY CUT LOGIC:
        # A background thread that forces a stop if you talk for > 15s
        def safety_monitor():
            while True:
                if hasattr(recorder, 'is_recording') and recorder.is_recording:
                    # If recording exceeds 15 seconds, trigger a cut
                    start_time = getattr(recorder, 'recording_start_time', 0)
                    if start_time > 0 and (time.time() - start_time) > 20:
                        print("\n[DEBUG] Safety Cut (15s limit).")
                        recorder.stop()
                time.sleep(0.5)

        threading.Thread(target=safety_monitor, daemon=True).start()

        print("\n>>> System Ready! Speak into your microphone.")

        while True:
            # This blocks while listening, then calls process_text
            recorder.text(process_text)

    except KeyboardInterrupt:
        print("\nStopping...")
        text_queue.put(None)
    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    main()
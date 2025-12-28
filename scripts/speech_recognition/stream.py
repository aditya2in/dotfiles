import pyaudio
import nemo.collections.asr as nemo_asr
import numpy as np
import torch
import time
import subprocess
from queue import Queue
import webrtcvad
import collections

# --- Model Selection ---
# This script is optimized for the Parakeet model, which is compatible
# with the simple streaming approach.
MODEL_NAME = "nvidia/parakeet-tdt-0.6b-v3"


# --- VAD and Audio Parameters ---
SAMPLE_RATE = 16000
CHANNELS = 1
# webrtcvad requires audio chunks of 10, 20, or 30 ms.
# 30ms at 16kHz is 480 samples.
CHUNK_SAMPLES = 480 
AUDIO_FORMAT = pyaudio.paInt16
VAD_AGGRESSIVENESS = 3  # 0 to 3, 3 is most aggressive at filtering out non-speech
SILENCE_THRESHOLD_S = 0.8  # Seconds of silence to trigger transcription
SPEECH_START_THRESHOLD_MS = 150 # Milliseconds of speech to start recording

def is_ydotoold_running():
    """Check if the ydotoold daemon is running."""
    try:
        subprocess.check_output(["pgrep", "-x", "ydotoold"])
        return True
    except subprocess.CalledProcessError:
        return False

def main():
    ydotoold_process = None
    try:
        # Start ydotoold if it's not already running
        if not is_ydotoold_running():
            print("--- INFO: Starting ydotoold daemon... ---")
            ydotoold_process = subprocess.Popen(["ydotoold"])
            time.sleep(1) # Give it a moment to initialize
            if ydotoold_process.poll() is not None:
                print("--- ERROR: Could not start ydotoold. Please start it manually. ---")
                return
            print("--- INFO: ydotoold started successfully. ---")
        else:
            print("--- INFO: ydotoold is already running. ---")

        print(f"--- INFO: Loading NeMo ASR model: {MODEL_NAME}... ---")
        
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        if not torch.cuda.is_available():
            print("--- WARNING: CUDA not available, using CPU. This will be very slow. ---")

        asr_model = nemo_asr.models.ASRModel.from_pretrained(MODEL_NAME, map_location=device)
        asr_model.eval()

        vad = webrtcvad.Vad(VAD_AGGRESSIVENESS)
        audio_queue = Queue()

        def record_callback(in_data, frame_count, time_info, status):
            audio_queue.put(in_data)
            return in_data, pyaudio.paContinue

        p = pyaudio.PyAudio()
        stream = p.open(
            format=AUDIO_FORMAT,
            channels=CHANNELS,
            rate=SAMPLE_RATE,
            input=True,
            frames_per_buffer=CHUNK_SAMPLES,
            stream_callback=record_callback,
        )
        
        print("--- INFO: NeMo Dictation Engine READY. Place your cursor and speak after the beep. ---")
        print("NE_MO_DICTATION_READY") # Unique string for shell script to detect
        time.sleep(5) # Give user time to place cursor

        # Remaining messages will be handled by the shell script (silencing them)
        stream.start_stream()

        is_speaking = False
        accumulated_audio_buffer = []
        
        padding_ms = 300
        num_padding_chunks = padding_ms // (1000 * CHUNK_SAMPLES // SAMPLE_RATE)
        ring_buffer = collections.deque(maxlen=num_padding_chunks)
        
        while stream.is_active():
            if not audio_queue.empty():
                raw_audio_chunk = audio_queue.get()
                
                try:
                    is_speech = vad.is_speech(raw_audio_chunk, SAMPLE_RATE)
                except:
                    continue

                if not is_speaking:
                    ring_buffer.append(raw_audio_chunk)
                    num_voiced = sum(1 for chunk in ring_buffer if vad.is_speech(chunk, SAMPLE_RATE))
                    if num_voiced > 0.5 * ring_buffer.maxlen:
                        is_speaking = True
                        accumulated_audio_buffer.extend(list(ring_buffer))
                        ring_buffer.clear()
                else:
                    accumulated_audio_buffer.append(raw_audio_chunk)
                    ring_buffer.append(raw_audio_chunk)
                    
                    num_unvoiced = sum(1 for chunk in ring_buffer if not vad.is_speech(chunk, SAMPLE_RATE))
                    if num_unvoiced > 0.9 * ring_buffer.maxlen:
                        is_speaking = False
                        
                        full_audio_segment_np = np.concatenate([np.frombuffer(chunk, dtype=np.int16) for chunk in accumulated_audio_buffer])
                        accumulated_audio_buffer = []
                        ring_buffer.clear()

                        with torch.no_grad():
                            hypotheses = asr_model.transcribe(
                                audio=[full_audio_segment_np],
                                batch_size=1,
                                verbose=False,
                            )
                        
                        if hypotheses and hypotheses[0]:
                            text_to_type = hypotheses[0].text
                            if text_to_type:
                                subprocess.run(["ydotool", "type", text_to_type + " "])
            else:
                time.sleep(0.01)

    except KeyboardInterrupt:
        print("\n--- INFO: Stopping dictation... ---")

    finally:
        if 'stream' in locals() and stream.is_active():
            stream.stop_stream()
            stream.close()
        if 'p' in locals():
            p.terminate()
        
        if ydotoold_process:
            print("--- INFO: Stopping the ydotoold daemon... ---")
            ydotoold_process.terminate()
            ydotoold_process.wait()
            print("--- INFO: ydotoold stopped. ---")
        
        print("--- INFO: Script terminated. ---")

if __name__ == "__main__":
    main()
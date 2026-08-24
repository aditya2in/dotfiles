#!/usr/bin/env python3
"""
Official NVIDIA Nemotron Speech Streaming (0.6B) - Live Microphone Test
Pure execution following official NVIDIA NeMo & Hugging Face Transformers documentation.
"""

import sys, time, threading, queue
import numpy as np
import sounddevice as sd
import torch
from transformers import AutoProcessor, AutoModelForRNNT, TextIteratorStreamer

MODEL_DIR = "/home/adityaws/AI_MODELS/dictation_models/nemotron/en"
SAMPLE_RATE = 16000
device = "cuda" if torch.cuda.is_available() else "cpu"

print("================================================================")
print("🚀 Initializing Official NVIDIA Nemotron Streaming ASR")
print(f"📁 Model Path: {MODEL_DIR}")
print(f"⚡ Device: {device.upper()} ({torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU'})")
print("================================================================")

# 1. Load official Processor and Model
print("\n[1/3] Loading Processor and Model onto GPU...")
processor = AutoProcessor.from_pretrained(MODEL_DIR)
model = AutoModelForRNNT.from_pretrained(
    MODEL_DIR,
    dtype=torch.float16 if device == "cuda" else torch.float32
).to(device)
model.eval()

# 2. Configure Lookahead Latency (Official 80ms/160ms chunk config)
# Available right context tokens: {0: 80ms, 1: 160ms, 6: 560ms, 13: 1120ms}
processor.set_num_lookahead_tokens(6)
print(f"[2/3] Configured Streaming Latency: {processor.streaming_latency_ms} ms")

# 3. Setup Audio Capture Stream
audio_queue = queue.Queue()

def audio_callback(indata, frames, time_info, status):
    if status:
        print(f"[Audio Warning]: {status}", file=sys.stderr)
    audio_queue.put(indata[:, 0].copy())

block_size = int(SAMPLE_RATE * 0.08) # 80ms chunk size = 1280 samples
stream = sd.InputStream(
    samplerate=SAMPLE_RATE,
    channels=1,
    blocksize=block_size,
    callback=audio_callback,
    dtype=np.float32
)

print("[3/3] Audio Stream Ready (Maono Microphone / PipeWire @ 16kHz).")
print("\n" + "=" * 64)
print("🎙️  SPEAK FREELY INTO YOUR MICROPHONE")
print("Press [Ctrl+C] to stop.")
print("=" * 64 + "\n")

stream.start()

accumulated_audio = []
last_text_len = 0

try:
    while True:
        # Collect new audio chunks from microphone
        new_chunks = []
        while not audio_queue.empty():
            new_chunks.append(audio_queue.get_nowait())

        if new_chunks:
            for chunk in new_chunks:
                accumulated_audio.append(chunk)

            # Concatenate current audio buffer
            audio_array = np.concatenate(accumulated_audio)
            
            # Process once audio meets minimum first chunk threshold
            if len(audio_array) >= processor.num_samples_first_audio_chunk:
                inputs = processor(
                    audio_array,
                    sampling_rate=SAMPLE_RATE,
                    return_tensors="pt"
                ).to(device, dtype=model.dtype)

                with torch.no_grad():
                    output = model.generate(**inputs, return_dict_in_generate=True)
                
                full_text = processor.decode(output.sequences[0], skip_special_tokens=True).strip()
                
                if full_text and len(full_text) > last_text_len:
                    new_token = full_text[last_text_len:]
                    print(new_token, end="", flush=True)
                    last_text_len = len(full_text)

        # Cap audio buffer when speaker pauses (reset state every ~10s of continuous speech)
        if len(accumulated_audio) > 100: # ~8 seconds
            accumulated_audio = accumulated_audio[-30:] # Keep last ~2.4s context
            last_text_len = 0
            print(" ", end="", flush=True)

        time.sleep(0.05)

except KeyboardInterrupt:
    print("\n\n🛑 Test stopped by user.")
finally:
    stream.stop()
    stream.close()
    print("Microphone stream closed.")

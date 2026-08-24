#!/usr/bin/env python3
"""
NVIDIA Nemotron ASR Streaming - SentencePiece Whitespace Streamer (F4)
Architecture:
- Official NVIDIA Nemotron FastConformer-RNNT on CUDA
- DirectTokenStreamer with SentencePiece subword whitespace reconstruction (▁ /  )
- Emits words with proper natural spacing and syllable attachment in real-time
- Automatic Zero-Padding Flush Frame on speech pauses
- Injects keystrokes directly into active cursor via wtype
- Instant kernel-level termination with os._exit(0)
"""

import os
import sys
import json
import subprocess
import threading
import queue
import time
import signal
import numpy as np
import sounddevice as sd
import torch
from transformers import AutoProcessor, AutoModelForRNNT
from transformers.generation.streamers import BaseStreamer

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "nemotron_config.json")
PID_FILE = "/tmp/nemotron_dictation.pid"
PAUSE_FILE = "/tmp/nemotron_paused"
SAMPLE_RATE = 16000

DEFAULT_CONFIG = {
    "lookahead_latency_tokens": 6,
    "silence_flush_seconds": 0.35,
    "silence_energy_threshold": 0.0015,
    "device": "cuda",
    "compute_type": "float16",
    "model_path": "/home/adityaws/AI_MODELS/dictation_models/nemotron/en",
    "typing_target": "active_window"
}

def load_config():
    try:
        if os.path.exists(CONFIG_PATH):
            with open(CONFIG_PATH, "r") as f:
                return {**DEFAULT_CONFIG, **json.load(f)}
    except Exception:
        pass
    return DEFAULT_CONFIG

# State
is_paused = False
is_running = True
audio_queue = queue.Queue()
typing_queue = queue.Queue()

class DirectTokenStreamer(BaseStreamer):
    """
    Direct Token Streamer with SentencePiece Whitespace Reconstruction:
    - Restores leading whitespace whenever subwords start with ▁ or  
    - Connects word syllables seamlessly
    - Emits words with zero caching delay
    """
    def __init__(self, tokenizer):
        self.tokenizer = tokenizer

    def put(self, value):
        if value is None:
            return
        if isinstance(value, torch.Tensor):
            tokens = value.tolist()
        else:
            tokens = [value]
        
        # Flatten batch dimension if present
        if isinstance(tokens, list) and len(tokens) > 0 and isinstance(tokens[0], list):
            tokens = tokens[0]

        for token_id in tokens:
            try:
                token_str = self.tokenizer.convert_ids_to_tokens(token_id)
                if token_str is None or token_str == "<unk>" or token_str.startswith("<"):
                    continue
                # SentencePiece space prefix check
                if token_str.startswith("▁") or token_str.startswith(" ") or token_str.startswith(" "):
                    clean_text = " " + token_str[1:]
                else:
                    clean_text = token_str
                
                if clean_text:
                    typing_queue.put(clean_text)
            except Exception:
                pass

    def end(self):
        pass

def signal_handler(sig, frame):
    global is_running
    is_running = False
    try:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
    except Exception:
        pass
    os._exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

def pause_watcher():
    global is_paused
    last_state = False
    while is_running:
        current_state = os.path.exists(PAUSE_FILE)
        if current_state != last_state:
            is_paused = current_state
            last_state = current_state
        time.sleep(0.15)

def typing_worker():
    """Consumes real-time streaming tokens and types them via wtype."""
    while is_running:
        try:
            text = typing_queue.get(timeout=0.1)
        except queue.Empty:
            continue
        if text is None:
            break
        try:
            subprocess.run(["wtype", text], check=False)
        except Exception:
            pass
        typing_queue.task_done()

def compute_rms(audio_chunk):
    if len(audio_chunk) == 0:
        return 0.0
    return float(np.sqrt(np.mean(audio_chunk ** 2)))

def audio_callback(indata, frames, time_info, status):
    if not is_paused:
        audio_queue.put(indata[:, 0].copy())

def main():
    global is_running
    config = load_config()

    device = config.get("device", "cuda") if torch.cuda.is_available() else "cpu"
    dtype = torch.float16 if (device == "cuda" and config.get("compute_type") == "float16") else torch.float32
    lookahead = config.get("lookahead_latency_tokens", 6)
    silence_flush_dur = config.get("silence_flush_seconds", 0.35)
    silence_thresh = config.get("silence_energy_threshold", 0.0015)
    model_path = config.get("model_path", DEFAULT_CONFIG["model_path"])

    print("================================================================")
    print("🚀 Starting SentencePiece Spaced Nemotron Engine (F4)")
    print(f"⚡ Device: {device.upper()} | Lookahead: {lookahead} tokens | Natural Spacing")
    print("================================================================")

    try:
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
    except Exception:
        pass

    threading.Thread(target=pause_watcher, daemon=True).start()
    threading.Thread(target=typing_worker, daemon=True).start()

    # 1. Load Official Model
    try:
        processor = AutoProcessor.from_pretrained(model_path)
        model = AutoModelForRNNT.from_pretrained(model_path, dtype=dtype).to(device)
        model.eval()
        processor.set_num_lookahead_tokens(lookahead)
    except Exception as e:
        subprocess.run(["notify-send", "Nemotron STT", f"Model Load Failed: {e}", "-i", "dialog-error", "-t", "4000"])
        sys.exit(1)

    subprocess.run(["notify-send", "Nemotron STT", "Ready — streaming with natural spaces", "-i", "microphone-sensitivity-high", "-t", "2000"])

    # 2. Start Microphone Stream (1280 samples / 80ms chunks)
    stream = sd.InputStream(
        samplerate=SAMPLE_RATE,
        channels=1,
        blocksize=1280,
        callback=audio_callback,
        dtype=np.float32
    )
    stream.start()

    first_chunk_size = processor.num_samples_first_audio_chunk
    per_chunk_size = processor.num_samples_per_audio_chunk

    def get_audio_samples(required_samples, timeout=0.1):
        collected = []
        collected_len = 0
        start_t = time.time()
        while is_running and collected_len < required_samples:
            try:
                chunk = audio_queue.get(timeout=timeout)
                collected.append(chunk)
                collected_len += len(chunk)
            except queue.Empty:
                if (time.time() - start_t) > 0.5:
                    break
                continue
        if collected:
            arr = np.concatenate(collected)
            if len(arr) > required_samples:
                excess = arr[required_samples:]
                audio_queue.queue.appendleft(excess)
                return arr[:required_samples]
            elif len(arr) < required_samples:
                pad = np.zeros(required_samples - len(arr), dtype=np.float32)
                return np.concatenate([arr, pad])
            return arr
        return np.zeros(required_samples, dtype=np.float32)

    # 3. Native Streaming Loop
    try:
        while is_running:
            # Collect first chunk
            first_audio = get_audio_samples(first_chunk_size)
            if not is_running:
                break

            first_inputs = processor(
                first_audio,
                sampling_rate=SAMPLE_RATE,
                is_streaming=True,
                is_first_audio_chunk=True,
                return_tensors="pt"
            ).to(device, dtype=model.dtype)

            def input_features_generator():
                yield first_inputs.input_features[:, : processor.num_mel_frames_first_audio_chunk, :]

                last_speech_time = time.time()
                has_spoken = False
                flushed = False

                while is_running and not is_paused:
                    next_audio = get_audio_samples(per_chunk_size)
                    if not is_running or is_paused:
                        break

                    energy = compute_rms(next_audio)
                    if energy > silence_thresh:
                        last_speech_time = time.time()
                        has_spoken = True
                        flushed = False
                    
                    next_inputs = processor(
                        next_audio,
                        sampling_rate=SAMPLE_RATE,
                        is_streaming=True,
                        is_first_audio_chunk=False,
                        return_tensors="pt"
                    ).to(device, dtype=model.dtype)

                    yield next_inputs.input_features

                    # Automatic silence flush to release trailing lookahead tokens
                    if has_spoken and not flushed and (time.time() - last_speech_time) >= silence_flush_dur:
                        silent_flush = np.zeros(per_chunk_size, dtype=np.float32)
                        flush_inputs = processor(
                            silent_flush,
                            sampling_rate=SAMPLE_RATE,
                            is_streaming=True,
                            is_first_audio_chunk=False,
                            return_tensors="pt"
                        ).to(device, dtype=model.dtype)
                        yield flush_inputs.input_features
                        flushed = True
                        has_spoken = False

            streamer = DirectTokenStreamer(processor.tokenizer)
            gen_kwargs = {
                **first_inputs,
                "input_features": input_features_generator(),
                "streamer": streamer
            }

            gen_thread = threading.Thread(target=model.generate, kwargs=gen_kwargs, daemon=True)
            gen_thread.start()
            gen_thread.join()

    except KeyboardInterrupt:
        pass
    finally:
        is_running = False
        stream.stop()
        stream.close()
        typing_queue.put(None)
        try:
            if os.path.exists(PID_FILE):
                os.remove(PID_FILE)
        except Exception:
            pass

if __name__ == "__main__":
    main()

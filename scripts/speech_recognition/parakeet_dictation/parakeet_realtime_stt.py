#!/usr/bin/env python3
"""
NVIDIA Parakeet 1.1B ASR Dictation Engine with Silero VAD + Pre-Roll (F9 Setup)
Architecture:
- Official NVIDIA Parakeet FastConformer-RNNT (1.1B Parameters) on CUDA FP16
- Neural Silero VAD with 160ms Lookback Ring Buffer to prevent initial consonant clipping
- Softened VAD sensitivity (0.35 threshold) for effortless quiet/conversational speech
- Instant Bracketed Buffer Injection (tmux set-buffer + paste-buffer -p) for 0ms CLI insertion
- 0.40s Speech Pause Threshold for natural human conversational cadence
- In-Python Hardware-Gated "READY" Notification upon 100% CUDA load
- Software Pause/Resume toggle via F9 without touching system mic hardware
- Instant VRAM load/unload on SHIFT + F9
"""

import os
import sys
import json
import time
import queue
import signal
import socket
import collections
import threading
import subprocess
import numpy as np
import sounddevice as sd
import torch
from transformers import AutoProcessor, AutoModelForRNNT

is_running = True
is_paused = False
audio_queue = queue.Queue()
typing_queue = queue.Queue()
is_scratchpad_focused = False

# Noise & Breath Hallucination Filter List
NOISE_FILLERS = {
    "mm", "mmhm", "m", "h", "ah", "uh", "um", "hmm", "hm", 
    "m m h h", "m m h h r a h", "r", "eh", "ha", "sh", "ts",
    "no", "no no", "n o n o", "not", "no no no"
}

def signal_handler(sig, frame):
    global is_running
    is_running = False
    os._exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def load_config():
    config_path = os.path.join(os.path.dirname(__file__), "parakeet_config.json")
    default_config = {
        "silence_pause_seconds": 0.40,
        "vad_threshold": 0.35,
        "device": "cuda",
        "compute_type": "float16",
        "model_path": "/home/adityaws/AI_MODELS/dictation_models/parakeet/rnnt_1.1b",
        "typing_target": "ghostty_background",
        "tmux_target_session": "K8",
        "allowed_titles": ["000_SCRATCHPAD_Brain_Dump"]
    }
    if os.path.exists(config_path):
        try:
            with open(config_path, "r") as f:
                cfg = json.load(f)
                default_config.update(cfg)
        except Exception as e:
            print(f"[Config] Error loading config: {e}", flush=True)
    return default_config

def pause_watcher():
    global is_paused
    pause_file = "/tmp/parakeet_paused"
    while is_running:
        is_paused = os.path.exists(pause_file)
        time.sleep(0.05)

def hyprland_event_listener(allowed_titles):
    global is_scratchpad_focused
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        try:
            uid = os.getuid()
            paths = [f"/run/user/{uid}/hypr/", "/tmp/hypr/"]
            for p in paths:
                if os.path.exists(p):
                    dirs = [d for d in os.listdir(p) if len(d) > 30]
                    if dirs:
                        signature = dirs[0]
                        break
        except Exception:
            pass

    if not signature:
        return

    uid = os.getuid()
    sock_path = f"/run/user/{uid}/hypr/{signature}/.socket2.sock"
    if not os.path.exists(sock_path):
        sock_path = f"/tmp/hypr/{signature}/.socket2.sock"

    while is_running:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                client.connect(sock_path)
                with client.makefile('r') as f:
                    res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
                    if res.returncode == 0:
                        try:
                            w = json.loads(res.stdout)
                            t = w.get("title", "")
                            is_scratchpad_focused = any(at in t for at in allowed_titles)
                        except Exception:
                            pass

                    while is_running:
                        line = f.readline()
                        if not line:
                            break
                        line = line.strip()
                        if line.startswith("activewindow>>") or line.startswith("activewindowv2>>"):
                            parts = line.split(">>", 1)[1].split(",")
                            win_title = parts[1] if len(parts) > 1 else parts[0]
                            is_scratchpad_focused = any(at in win_title for at in allowed_titles)
        except Exception:
            time.sleep(1.0)

def inject_text(text, config):
    global is_scratchpad_focused
    if not text:
        return

    # 1. Scratchpad active window injection
    if is_scratchpad_focused:
        try:
            subprocess.run(["wtype", text], check=False)
        except Exception:
            pass
        return

    # 2. Ghostty / Tmux Background Target (Instant Bracketed Buffer Paste)
    target = config.get("typing_target", "ghostty_background")
    session = config.get("tmux_target_session", "K8")

    if target == "ghostty_background":
        try:
            # Auto-snap: Exit tmux copy-mode (scrollback) so speech is never dropped or garbled into blue selection
            mode_chk = subprocess.run(["tmux", "display-message", "-p", "-t", session, "#{pane_in_mode}"], capture_output=True, text=True)
            if mode_chk.returncode == 0 and mode_chk.stdout.strip() == "1":
                subprocess.run(["tmux", "send-keys", "-t", session, "-X", "cancel"], capture_output=True)

            set_buf = subprocess.run(["tmux", "set-buffer", text], capture_output=True, text=True)
            if set_buf.returncode == 0:
                res_paste = subprocess.run(["tmux", "paste-buffer", "-t", session, "-d", "-p"], capture_output=True, text=True)
                if res_paste.returncode == 0:
                    return
        except Exception:
            pass

        subprocess.run(["tmux", "send-keys", "-t", session, "-l", text], check=False)
        return

    try:
        subprocess.run(["wtype", text], check=False)
    except Exception:
        pass

def typing_worker(config):
    while is_running:
        try:
            text = typing_queue.get(timeout=0.05)
        except queue.Empty:
            continue
        if text is None:
            break
        inject_text(text, config)
        typing_queue.task_done()

def audio_callback(indata, frames, time_info, status):
    if not is_paused:
        audio_queue.put(indata[:, 0].copy())

def main():
    global is_running
    config = load_config()
    device = config.get("device", "cuda")
    compute_type = torch.float16 if config.get("compute_type") == "float16" else torch.float32
    model_path = config.get("model_path")
    silence_pause_seconds = config.get("silence_pause_seconds", 0.40)
    vad_threshold = config.get("vad_threshold", 0.35)
    allowed_titles = config.get("allowed_titles", ["000_SCRATCHPAD_Brain_Dump"])

    print(f"[Parakeet 1.1B] Loading Silero VAD neural network...", flush=True)
    try:
        vad_model, _ = torch.hub.load(
            repo_or_dir='snakers4/silero-vad',
            model='silero_vad',
            force_reload=False,
            onnx=False
        )
        vad_model.eval()
    except Exception as e:
        print(f"[Parakeet 1.1B] Failed to load Silero VAD: {e}", flush=True)
        sys.exit(1)

    print(f"[Parakeet 1.1B] Loading Parakeet 1.1B model from: {model_path} on {device} (FP16)...", flush=True)
    try:
        processor = AutoProcessor.from_pretrained(model_path)
        model = AutoModelForRNNT.from_pretrained(
            model_path,
            dtype=compute_type,
            low_cpu_mem_usage=True
        ).to(device)
        model.eval()
    except Exception as e:
        print(f"[Parakeet 1.1B] Failed to load model: {e}", flush=True)
        subprocess.run(["notify-send", "Parakeet 1.1B STT", "Status: ERROR (Failed to Load)", "-i", "dialog-error", "-t", "4000"], check=False)
        sys.exit(1)

    print("[Parakeet 1.1B] Both Silero VAD & Parakeet 1.1B loaded on CUDA!", flush=True)

    # Hardware-gated notification
    subprocess.run(["notify-send", "Parakeet 1.1B STT", "Status: READY (Loaded in VRAM — Speak Now)", "-i", "microphone-sensitivity-high", "-t", "3000"], check=False)

    sample_rate = 16000
    block_samples = 512  # Exact 32ms chunk required by Silero VAD
    silence_blocks_needed = int(silence_pause_seconds / 0.032)
    if silence_blocks_needed < 4:
        silence_blocks_needed = 4

    # Start background threads
    threading.Thread(target=pause_watcher, daemon=True).start()
    threading.Thread(target=hyprland_event_listener, args=(allowed_titles,), daemon=True).start()
    threading.Thread(target=typing_worker, args=(config,), daemon=True).start()

    def transcription_worker():
        nonlocal processor, model, vad_model, sample_rate, silence_blocks_needed, vad_threshold
        # Rolling 160ms pre-roll buffer (5 chunks * 32ms) to preserve soft initial consonants
        preroll_buffer = collections.deque(maxlen=5)
        speech_buffer = []
        is_speaking = False
        consecutive_silent_blocks = 0

        while is_running:
            try:
                block = audio_queue.get(timeout=0.02)
            except queue.Empty:
                continue

            tensor_chunk = torch.from_numpy(block).float()
            with torch.no_grad():
                speech_prob = vad_model(tensor_chunk, sample_rate).item()

            if speech_prob >= vad_threshold:
                if not is_speaking:
                    # Speech began! Prepend the 160ms pre-roll audio so zero words are clipped
                    is_speaking = True
                    consecutive_silent_blocks = 0
                    speech_buffer = list(preroll_buffer) + [block]
                else:
                    consecutive_silent_blocks = 0
                    speech_buffer.append(block)
            else:
                preroll_buffer.append(block)
                if is_speaking:
                    consecutive_silent_blocks += 1
                    speech_buffer.append(block)

                    if consecutive_silent_blocks >= silence_blocks_needed:
                        full_audio = np.concatenate(speech_buffer)
                        speech_buffer = []
                        is_speaking = False
                        consecutive_silent_blocks = 0

                        # Minimum 0.30s genuine speech duration required
                        if len(full_audio) >= sample_rate * 0.30:
                            inputs = processor(full_audio, sampling_rate=sample_rate, return_tensors="pt").to(device)
                            with torch.inference_mode():
                                outputs = model.generate(inputs.input_features.to(dtype=compute_type))
                                tokens = outputs.sequences[0].tolist()
                                text = processor.tokenizer.decode(tokens, skip_special_tokens=True).strip()

                            # Strict noise & hallucination filter
                            cleaned_lower = text.lower().strip()
                            if cleaned_lower in NOISE_FILLERS or len(cleaned_lower) <= 1:
                                print(f"[Parakeet 1.1B] Silenced non-speech artefact: {text}", flush=True)
                                continue

                            if text:
                                print(f"[Parakeet 1.1B] Transcribed: {text}", flush=True)
                                typing_queue.put(text + " ")

    threading.Thread(target=transcription_worker, daemon=True).start()

    try:
        with sd.InputStream(
            channels=1,
            samplerate=sample_rate,
            callback=audio_callback,
            blocksize=block_samples
        ):
            print(f"[Parakeet 1.1B] Ready with Silero VAD + Pre-Roll (0.40s pause) @ {sample_rate}Hz...", flush=True)
            while is_running:
                time.sleep(0.5)
    except Exception as e:
        print(f"[Parakeet 1.1B] Audio stream error: {e}", flush=True)
    finally:
        os._exit(0)

if __name__ == "__main__":
    main()

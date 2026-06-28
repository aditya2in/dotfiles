import os
import sys
import subprocess
import threading
import queue
import time
import signal
import json
import socket
import numpy as np
import sounddevice as sd
import torch
from transformers import AutoProcessor, AutoModelForRNNT
import warnings
warnings.filterwarnings("ignore")

os.environ["CT2_CUDA_ALLOW_TF32"] = "1"

SAMPLE_RATE = 16000
CHANNELS = 1
BLOCK_SIZE = 512

is_paused = False
is_browser_focused = False
smart_pause_override = False
audio_buffer = []
audio_lock = threading.Lock()
speech_detected = False
silence_duration = 0.0
speech_segment = []
last_text = ""
chunk_duration = BLOCK_SIZE / SAMPLE_RATE

PAUSE_FILE = "/tmp/nemotron_paused"
OVERRIDE_FILE = "/tmp/nemotron_smart_pause_override"
STATUS_FILE = "/tmp/nemotron_status.json"
PID_FILE = "/tmp/nemotron_dictation.pid"
SILENCE_THRESHOLD_SECONDS = 0.8
MIN_RECORDING_SECONDS = 0.5
MAX_RECORDING_SECONDS = 15.0
VAD_THRESHOLD = 0.5

MODEL_DIR_EN = "/home/adityaws/AI_MODELS/dictation_models/nemotron/en"
MODEL_DIR_MULTI = "/home/adityaws/AI_MODELS/dictation_models/nemotron/multi"

processor = None
model = None
device = None

def log_engine(msg):
    try:
        with open("/tmp/nemotron_engine.log", "a") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")
    except Exception:
        pass

def update_waybar():
    global is_paused, is_browser_focused, smart_pause_override
    state = "running"
    icon = "\uf130"
    tooltip = "Nemotron STT: Active"
    if smart_pause_override:
        icon = "\uf131"
        tooltip = "Nemotron STT: Override Active"
        if is_paused:
            state = "paused"
            icon = "\uf131"
            tooltip = "Nemotron STT: Paused"
    elif is_paused:
        state = "paused"
        icon = "\uf131"
        tooltip = "Nemotron STT: Paused"
    elif is_browser_focused:
        state = "paused"
        icon = "\uf131"
        tooltip = "Nemotron STT: Smart Paused"
    status = {"text": icon, "class": state, "alt": state, "tooltip": tooltip}
    try:
        temp = STATUS_FILE + ".tmp"
        with open(temp, "w") as f:
            json.dump(status, f)
        os.rename(temp, STATUS_FILE)
    except Exception as e:
        log_engine(f"Waybar update failed: {e}")

def signal_handler(sig, frame):
    log_engine("Received termination signal.")
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)

CONFIG_FILE = os.path.join(os.path.dirname(__file__), "nemotron_config.json")

def load_config():
    defaults = {
        "smart_pause_enabled": True,
        "ignored_classes": ["brave-browser"],
        "allowed_titles": ["000_SCRATCHPAD_Brain_Dump"],
        "model": "en",
        "language": "en-US",
        "silero_sensitivity": 0.5,
        "post_speech_silence_duration": 0.8,
        "min_length_of_recording": 0.5
    }
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, "r") as f:
                return {**defaults, **json.load(f)}
    except Exception as e:
        log_engine(f"Config load error: {e}")
    return defaults

def hyprland_event_listener():
    global is_browser_focused
    config = load_config()
    if not config.get("smart_pause_enabled"):
        log_engine("Smart Pause is disabled.")
        return
    ignored_apps = config.get("ignored_classes", [])
    allowed_titles = config.get("allowed_titles", [])
    log_engine(f"Smart Pause for: {ignored_apps}")
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        log_engine("Searching Hyprland signature...")
        try:
            uid = os.getuid()
            paths = [f"/run/user/{uid}/hypr/", "/tmp/hypr/"]
            for p in paths:
                if os.path.exists(p):
                    dirs = [d for d in os.listdir(p) if len(d) > 30]
                    if dirs:
                        signature = dirs[0]
                        break
        except Exception as e:
            log_engine(f"Search failed: {e}")
    if not signature:
        log_engine("Could not find Hyprland signature.")
        return
    uid = os.getuid()
    sock_path = f"/run/user/{uid}/hypr/{signature}/.socket2.sock"
    if not os.path.exists(sock_path):
        sock_path = f"/tmp/hypr/{signature}/.socket2.sock"
    log_engine(f"Socket: {sock_path}")
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                client.connect(sock_path)
                log_engine("Connected to Hyprland socket.")
                with client.makefile('r') as f:
                    res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
                    if res.returncode == 0:
                        data = json.loads(res.stdout)
                        wc = data.get("class", "")
                        wt = data.get("title", "")
                        app_ignored = wc in ignored_apps
                        title_allowed = any(t in wt for t in allowed_titles)
                        is_browser_focused = app_ignored and not title_allowed
                        log_engine(f"Initial focus: {wc} (Blocked: {is_browser_focused})")
                        update_waybar()
                    for line in f:
                        if "activewindow>>" in line:
                            try:
                                payload = line.split("activewindow>>")[1].strip()
                                parts = payload.split(",")
                                socket_class = parts[0].strip()
                                socket_title = ",".join(parts[1:]).strip()
                                app_ignored = socket_class in ignored_apps
                                title_allowed = any(t in socket_title for t in allowed_titles)
                                new_focus = app_ignored and not title_allowed
                                if new_focus != is_browser_focused:
                                    is_browser_focused = new_focus
                                    log_engine(f"Focus: {socket_class} -> {'PAUSED' if is_browser_focused else 'RESUMED'}")
                                    update_waybar()
                            except Exception as e:
                                log_engine(f"Parse error: {e}")
        except Exception as e:
            log_engine(f"Socket error: {e}. Retrying...")
            time.sleep(2)

def pause_watcher():
    global is_paused
    last_state = False
    while True:
        current = os.path.exists(PAUSE_FILE)
        if current != last_state:
            is_paused = current
            log_engine(f"Pause: {'ON' if is_paused else 'OFF'}")
            update_waybar()
            last_state = current
        time.sleep(0.2)

def override_watcher():
    global smart_pause_override
    last_state = False
    while True:
        current = os.path.exists(OVERRIDE_FILE)
        if current != last_state:
            smart_pause_override = current
            log_engine(f"Override: {'ON' if smart_pause_override else 'OFF'}")
            update_waybar()
            last_state = current
        time.sleep(0.2)

text_queue = queue.Queue()

def typing_worker():
    while True:
        text = text_queue.get()
        if text is None:
            break
        try:
            subprocess.run(["wtype", text], check=True)
        except Exception:
            pass
        text_queue.task_done()

def load_nemotron_model():
    global processor, model, device
    config = load_config()
    model_name = config.get("model", "en")
    model_path = MODEL_DIR_EN if model_name == "en" else MODEL_DIR_MULTI
    log_engine(f"Loading Nemotron model: {model_name} ({model_path})")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    try:
        processor = AutoProcessor.from_pretrained(model_path)
        model = AutoModelForRNNT.from_pretrained(
            model_path,
            dtype=torch.float16 if device == "cuda" else torch.float32,
        ).to(device)
        model.eval()
        log_engine(f"Model loaded on {device.upper()}")
        return True
    except Exception as e:
        log_engine(f"Model load failed: {e}")
        return False

def transcribe_audio(audio_np):
    global processor, model, device
    if processor is None or model is None:
        log_engine("Model not loaded")
        return ""
    try:
        config = load_config()
        lang = config.get("language", "en-US")
        model_name = config.get("model", "en")
        if model_name == "multi":
            inputs = processor(
                audio_np,
                sampling_rate=SAMPLE_RATE,
                language=lang,
                return_tensors="pt"
            )
        else:
            inputs = processor(
                audio_np,
                sampling_rate=SAMPLE_RATE,
                return_tensors="pt"
            )
        input_features = inputs["input_features"].to(device).to(torch.float16)
        attention_mask = inputs["attention_mask"].to(device)
        nlt = inputs.get("num_lookahead_tokens", 13)
        with torch.no_grad():
            generated = model.generate(
                input_features=input_features,
                attention_mask=attention_mask,
                num_lookahead_tokens=nlt,
                return_dict_in_generate=True
            )
        text = processor.decode(generated.sequences[0], skip_special_tokens=True)
        return text.strip()
    except Exception as e:
        log_engine(f"Transcription error: {e}")
        return ""

def init_vad():
    try:
        from silero_vad import load_silero_vad
        vad_model = load_silero_vad()
        vad_model = vad_model.to(device)
        vad_model.eval()
        return vad_model
    except Exception as e:
        log_engine(f"VAD init failed: {e}")
        return None

def audio_callback(indata, frames, time_info, status):
    global audio_buffer
    if is_paused or (is_browser_focused and not smart_pause_override):
        return
    audio_chunk = indata[:, 0].copy()
    with audio_lock:
        audio_buffer.append(audio_chunk)
        max_buffered = int(SAMPLE_RATE * MAX_RECORDING_SECONDS / BLOCK_SIZE) + 10
        if len(audio_buffer) > max_buffered:
            discard = len(audio_buffer) - max_buffered
            del audio_buffer[:discard]

def main():
    global audio_buffer, speech_detected, silence_duration, speech_segment, last_text
    log_engine("Nemotron STT starting...")
    print("[INFO] Starting Nemotron STT Dictation Engine...")
    threading.Thread(target=pause_watcher, daemon=True).start()
    threading.Thread(target=override_watcher, daemon=True).start()
    threading.Thread(target=hyprland_event_listener, daemon=True).start()
    threading.Thread(target=typing_worker, daemon=True).start()
    if not load_nemotron_model():
        notify("Nemotron STT", "Model load FAILED", "dialog-error")
        return
    vad_model = init_vad()
    if vad_model is None:
        log_engine("VAD not available, using simple energy-based detection")
        notify("Nemotron STT", "VAD init FAILED", "dialog-error")
        return
    print("[INFO] Model ready. Starting audio capture...")
    write_pid()
    stream = None
    try:
        stream = sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=CHANNELS,
            blocksize=BLOCK_SIZE,
            callback=audio_callback,
            dtype=np.float32
        )
        stream.start()
        log_engine("Audio stream started")
        update_waybar()
        print(">>> Ready. Speak into your microphone.")
        notify("Nemotron STT", "Engine STARTED", "microphone-sensitivity-high")
        while True:
            if is_paused or (is_browser_focused and not smart_pause_override):
                if speech_detected:
                    speech_detected = False
                    speech_segment = []
                    silence_duration = 0.0
                time.sleep(0.1)
                continue
            with audio_lock:
                if not audio_buffer:
                    time.sleep(chunk_duration * 0.5)
                    continue
                chunk = audio_buffer.pop(0)
            if len(chunk) < 512:
                chunk = np.pad(chunk, (0, max(0, 512 - len(chunk))), 'constant')
            audio_tensor = torch.from_numpy(chunk[:512]).float().unsqueeze(0)
            if torch.cuda.is_available():
                audio_tensor = audio_tensor.cuda()
            with torch.no_grad():
                speech_prob = vad_model(audio_tensor, SAMPLE_RATE).item()
            if speech_prob > VAD_THRESHOLD:
                if not speech_detected:
                    speech_detected = True
                    silence_duration = 0.0
                    speech_segment = [chunk]
                    log_engine("Speech start")
                else:
                    speech_segment.append(chunk)
                    silence_duration = 0.0
            else:
                if speech_detected:
                    speech_segment.append(chunk)
                    silence_duration += chunk_duration
                    if silence_duration >= SILENCE_THRESHOLD_SECONDS:
                        if speech_segment:
                            segment = np.concatenate(speech_segment)
                            seg_len = len(segment) / SAMPLE_RATE
                            if seg_len >= MIN_RECORDING_SECONDS:
                                log_engine(f"Transcribing {seg_len:.1f}s...")
                                text = transcribe_audio(segment)
                                if text and text != last_text:
                                    log_engine(f"OK: {text[:40]}...")
                                    text_queue.put(text + " ")
                                    last_text = text
                                elif text:
                                    log_engine(f"Duplicate: skipped")
                                else:
                                    log_engine("No text")
                            speech_segment = []
                        speech_detected = False
                        silence_duration = 0.0
                else:
                    silence_duration += chunk_duration
    except KeyboardInterrupt:
        pass
    except Exception as e:
        log_engine(f"Fatal error: {e}")
        print(f"[ERROR] {e}")
    finally:
        if stream:
            stream.stop()
            stream.close()
        text_queue.put(None)
        remove_pid()
        print("Stopped.")
        notify("Nemotron STT", "Engine STOPPED", "microphone-sensitivity-muted")

def notify(title, msg, icon="dialog-information"):
    try:
        subprocess.run(["notify-send", title, msg, "-i", icon, "-t", "2000",
                        "-h", "string:x-canonical-private-synchronous:nemotron"])
    except Exception:
        pass

def write_pid():
    try:
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
    except Exception:
        pass

def remove_pid():
    try:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
    except Exception:
        pass

if __name__ == "__main__":
    main()

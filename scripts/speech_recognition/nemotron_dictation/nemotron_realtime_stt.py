import os, sys, subprocess, threading, queue, time, signal, json, socket
import numpy as np
import sounddevice as sd
import torch
from transformers import AutoProcessor, AutoModelForRNNT
import warnings; warnings.filterwarnings("ignore")

os.environ["CT2_CUDA_ALLOW_TF32"] = "1"

SAMPLE_RATE, CHANNELS, BLOCK_SIZE = 16000, 1, 512
is_paused = is_browser_focused = smart_pause_override = False
audio_buffer = []; audio_lock = threading.Lock()

PAUSE_FILE = "/tmp/nemotron_paused"
OVERRIDE_FILE = "/tmp/nemotron_smart_pause_override"
STATUS_FILE = "/tmp/nemotron_status.json"
PID_FILE = "/tmp/nemotron_dictation.pid"
MODEL_DIR_EN = "/home/adityaws/AI_MODELS/dictation_models/nemotron/en"
MODEL_DIR_MULTI = "/home/adityaws/AI_MODELS/dictation_models/nemotron/multi"

processor = model = None
device = "cuda" if torch.cuda.is_available() else "cpu"
last_text = ""
last_typed_len = 0
typing_queue = queue.Queue()
CONFIG_FILE = os.path.join(os.path.dirname(__file__), "nemotron_config.json")

def log(m): 
    try:
        with open("/tmp/nemotron_engine.log", "a") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {m}\n")
    except: pass

def update_waybar():
    s = "running"; i = "\uf130"; t = "Nemotron STT: Active"
    if smart_pause_override and is_paused: s = "paused"
    elif is_paused: s = "paused"; i = "\uf131"
    elif is_browser_focused: s = "paused"; i = "\uf131"
    try:
        temp = STATUS_FILE + ".tmp"
        with open(temp, "w") as f: json.dump({"text": i, "class": s, "alt": s, "tooltip": t}, f)
        os.rename(temp, STATUS_FILE)
    except: pass

signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))

def load_config():
    d = {"smart_pause_enabled": True, "ignored_classes": ["brave-browser", "obsidian"],
         "allowed_titles": ["000_SCRATCHPAD_Brain_Dump"], "model": "en", "language": "en-US"}
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE) as f: return {**d, **json.load(f)}
    except: pass
    return d

def hyprland_event_listener():
    global is_browser_focused
    c = load_config()
    if not c.get("smart_pause_enabled"): return
    ia, at = c.get("ignored_classes", []), c.get("allowed_titles", [])
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not sig:
        try:
            uid = os.getuid()
            for p in [f"/run/user/{uid}/hypr/", "/tmp/hypr/"]:
                if os.path.exists(p):
                    ds = [d for d in os.listdir(p) if len(d) > 30]
                    if ds: sig = ds[0]; break
        except: pass
    if not sig: return
    uid = os.getuid()
    sp = f"/run/user/{uid}/hypr/{sig}/.socket2.sock"
    if not os.path.exists(sp): sp = f"/tmp/hypr/{sig}/.socket2.sock"
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as cl:
                cl.connect(sp)
                with cl.makefile('r') as f:
                    r = subprocess.run(["hyprctl","activewindow","-j"], capture_output=True, text=True)
                    if r.returncode == 0:
                        d = json.loads(r.stdout)
                        is_browser_focused = (d.get("class","") in ia) and not any(t in d.get("title","") for t in at)
                        update_waybar()
                    for line in f:
                        if "activewindow>>" in line:
                            try:
                                p = line.split("activewindow>>")[1].strip().split(",")
                                wc, wt = p[0].strip(), ",".join(p[1:]).strip()
                                f2 = (wc in ia) and not any(t in wt for t in at)
                                if f2 != is_browser_focused: is_browser_focused = f2; update_waybar()
                            except: pass
        except: time.sleep(2)

def pause_watcher():
    global is_paused
    l = False
    while True:
        c = os.path.exists(PAUSE_FILE)
        if c != l: is_paused = c; update_waybar(); l = c
        time.sleep(0.2)

def override_watcher():
    global smart_pause_override
    l = False
    while True:
        c = os.path.exists(OVERRIDE_FILE)
        if c != l: smart_pause_override = c; update_waybar(); l = c
        time.sleep(0.2)

def typing_worker():
    while True:
        t = typing_queue.get()
        if t is None: break
        try: subprocess.run(["wtype", t], check=True)
        except: pass
        typing_queue.task_done()

def load_model():
    global processor, model
    c = load_config()
    mp = MODEL_DIR_EN if c.get("model","en") == "en" else MODEL_DIR_MULTI
    log(f"Loading: {c.get('model','en')}")
    try:
        processor = AutoProcessor.from_pretrained(mp)
        model = AutoModelForRNNT.from_pretrained(mp, dtype=torch.float16 if device=="cuda" else torch.float32).to(device)
        model.eval()
        log(f"Loaded on {device.upper()}")
        return True
    except Exception as e:
        log(f"Model load failed: {e}")
        return False

def transcribe(audio):
    if len(audio) < 1600: return ""
    try:
        c = load_config()
        lang = c.get("language", "en-US")
        if c.get("model","en") == "multi":
            inputs = processor(audio, sampling_rate=SAMPLE_RATE, language=lang, return_tensors="pt")
        else:
            inputs = processor(audio, sampling_rate=SAMPLE_RATE, return_tensors="pt")
        feats = inputs["input_features"].to(device).to(torch.float16)
        attn = inputs["attention_mask"].to(device)
        nlt = inputs.get("num_lookahead_tokens", 13)
        with torch.no_grad():
            gen = model.generate(input_features=feats, attention_mask=attn, num_lookahead_tokens=nlt, return_dict_in_generate=True)
        return processor.decode(gen.sequences[0], skip_special_tokens=True).strip()
    except Exception as e:
        log(f"Transcribe error: {e}")
        return ""

def audio_cb(indata, frames, time_info, status):
    with audio_lock: audio_buffer.append(indata[:, 0].copy())

def get_audio():
    with audio_lock:
        if not audio_buffer: return np.array([], dtype=np.float32)
        return np.concatenate(audio_buffer)

def clear_audio():
    with audio_lock: audio_buffer.clear()

def main():
    global last_text, last_typed_len
    log("Starting...")
    print("[INFO] Nemotron STT Sliding-Window starting...")
    threading.Thread(target=pause_watcher, daemon=True).start()
    threading.Thread(target=override_watcher, daemon=True).start()
    threading.Thread(target=hyprland_event_listener, daemon=True).start()
    threading.Thread(target=typing_worker, daemon=True).start()
    if not load_model(): 
        subprocess.run(["notify-send","Nemotron STT","Model load FAILED","-i","dialog-error","-t","2000"])
        return
    update_waybar()
    try:
        with open(PID_FILE, "w") as f: f.write(str(os.getpid()))
    except: pass
    subprocess.run(["notify-send","Nemotron STT","Ready","-t","1500"])
    
    stream = sd.InputStream(samplerate=SAMPLE_RATE, channels=CHANNELS,
                            blocksize=BLOCK_SIZE, callback=audio_cb, dtype=np.float32)
    stream.start()
    print(">>> Speak — text appears in real-time.")
    
    try:
        while True:
            if is_paused or (is_browser_focused and not smart_pause_override):
                clear_audio(); last_text = ""; last_typed_len = 0; time.sleep(0.2); continue
            audio = get_audio()
            if len(audio) < 4800:  # At least 0.3s
                time.sleep(0.05); continue
            text = transcribe(audio)
            if text and len(text) > last_typed_len:
                new_part = text[last_typed_len:]
                if new_part.strip():
                    typing_queue.put(new_part + " ")
                    log(f"Typed: +{len(new_part)} chars")
                last_typed_len = len(text)
            last_text = text or last_text
            time.sleep(0.15)
    except KeyboardInterrupt: pass
    except Exception as e: log(f"Fatal: {e}")
    finally:
        stream.stop(); stream.close()
        typing_queue.put(None)
        try: os.remove(PID_FILE)
        except: pass
        print("Stopped.")

if __name__ == "__main__":
    main()

import os
import sys
import subprocess
import threading
import queue
import time
import signal
import json
import socket
from RealtimeSTT import AudioToTextRecorder

# Force usage of GPU if available
os.environ["CT2_CUDA_ALLOW_TF32"] = "1"

# Global state for pausing
is_paused = False
is_browser_focused = False
smart_pause_override = False # New: Global override for smart pause
PAUSE_FILE = "/tmp/whisper_paused"
OVERRIDE_FILE = "/tmp/whisper_smart_pause_override"
STATUS_FILE = "/tmp/whisper_status.json"
recorder = None  # Global reference to allow background interruption

def update_waybar():
    """Update the status JSON for Waybar."""
    global is_paused, is_browser_focused, smart_pause_override
    state = "running"
    icon = "󰍬" # Microphone On
    tooltip = "Whisper STT: Active"
    
    # If override is active, we show a special "God Mode" state
    if smart_pause_override:
        icon = "󰍮" # Microphone with plus/override
        tooltip = "Whisper STT: Override Active (Global)"
        if is_paused:
            state = "paused"
            icon = "󰍭"
            tooltip = "Whisper STT: Paused (Manual)"
    elif is_paused or is_browser_focused:
        state = "paused"
        icon = "󰍭" # Microphone Paused
        tooltip = "Whisper STT: Paused (Manual)" if is_paused else "Whisper STT: Smart Paused (Brave)"
        
    status = {
        "text": icon,
        "class": state,
        "alt": state,
        "tooltip": tooltip
    }
    
    try:
        # Atomic write
        temp_status = STATUS_FILE + ".tmp"
        with open(temp_status, "w") as f:
            json.dump(status, f)
        os.rename(temp_status, STATUS_FILE)
        log_engine(f"Status file updated: {state} (Override: {smart_pause_override})")
    except Exception as e:
        log_engine(f"Waybar update failed: {e}")

def override_watcher():
    """Background thread that watches for the smart pause override file."""
    global smart_pause_override
    if os.path.exists(OVERRIDE_FILE):
        try: os.remove(OVERRIDE_FILE)
        except: pass
    
    last_state = False
    while True:
        current_state = os.path.exists(OVERRIDE_FILE)
        if current_state != last_state:
            smart_pause_override = current_state
            log_engine(f"Smart Pause Override: {'ENABLED' if smart_pause_override else 'DISABLED'}")
            update_waybar()
            last_state = current_state
        time.sleep(0.2)

def pause_watcher():
    """Background thread that watches for a pause file."""
    global is_paused, recorder
    # Ensure file doesn't exist at start
    if os.path.exists(PAUSE_FILE):
        try:
            os.remove(PAUSE_FILE)
        except:
            pass
        
    last_state = False
    while True:
        current_state = os.path.exists(PAUSE_FILE)
        if current_state != last_state:
            is_paused = current_state
            status_text = "PAUSED" if is_paused else "RESUMED"
            icon = "microphone-sensitivity-muted" if is_paused else "microphone-sensitivity-high"
            
            # INSTANT STOP: If we just paused, force the recorder to stop immediately
            if is_paused and recorder:
                try:
                    recorder.stop()
                except Exception:
                    pass

            log_engine(f"Manual Pause Change: {status_text}")
            update_waybar()
            
            subprocess.run([
                "notify-send", 
                "Whisper STT", 
                f"Status: {status_text}", 
                "-i", icon, 
                "-t", "1500",
                "-h", "string:x-canonical-private-synchronous:whisper-pause"
            ])
            last_state = current_state
        time.sleep(0.1)

def log_engine(msg):
    """Log to a temporary file for debugging."""
    try:
        with open("/tmp/whisper_engine.log", "a") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")
    except Exception:
        pass

def signal_handler(sig, frame):
    """Graceful shutdown on SIGTERM."""
    log_engine("Received termination signal.")
    if recorder:
        try:
            recorder.stop()
        except:
            pass
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)

CONFIG_FILE = os.path.join(os.path.dirname(__file__), "whisper_config.json")

def load_config():
    """Load configuration from JSON file."""
    defaults = {
        "smart_pause_enabled": True,
        "ignored_classes": ["brave-browser"]
    }
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, "r") as f:
                return {**defaults, **json.load(f)}
    except Exception as e:
        log_engine(f"Config load error: {e}")
    return defaults

def hyprland_event_listener():
    """Listen to Hyprland socket2 for real-time focus changes."""
    global is_browser_focused, recorder
    
    config = load_config()
    if not config.get("smart_pause_enabled"):
        log_engine("Smart Pause is disabled in config. Thread exiting.")
        return

    ignored_apps = config.get("ignored_classes", [])
    allowed_titles = config.get("allowed_titles", [])
    log_engine(f"Starting Smart Pause for: {ignored_apps} (Exceptions: {allowed_titles})")
    
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        # Fallback: Try to find signature in /tmp/hypr or /run/user/1000/hypr
        log_engine("HYPRLAND_INSTANCE_SIGNATURE not in env. Searching...")
        try:
            uid = os.getuid()
            paths = [f"/run/user/{uid}/hypr/", "/tmp/hypr/"]
            for p in paths:
                if os.path.exists(p):
                    dirs = [d for d in os.listdir(p) if len(d) > 30] # Signature is long hex
                    if dirs:
                        signature = dirs[0]
                        log_engine(f"Found signature: {signature}")
                        break
        except Exception as e:
            log_engine(f"Fallback search failed: {e}")

    if not signature:
        log_engine("CRITICAL: Could not find Hyprland signature.")
        return

    uid = os.getuid()
    sock_path = f"/run/user/{uid}/hypr/{signature}/.socket2.sock"
    if not os.path.exists(sock_path):
        sock_path = f"/tmp/hypr/{signature}/.socket2.sock"
    
    log_engine(f"Using socket path: {sock_path}")
    
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                client.connect(sock_path)
                log_engine("Connected to Hyprland Event Socket.")
                
                # Line-buffered reading is much more reliable
                with client.makefile('r') as f:
                    # Initial Check on startup
                    res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
                    if res.returncode == 0:
                        data = json.loads(res.stdout)
                        window_class = data.get("class", "")
                        window_title = data.get("title", "")
                        
                        # Logic: Block if app is ignored UNLESS title is allowed
                        app_ignored = (window_class in ignored_apps)
                        title_allowed = any(t in window_title for t in allowed_titles)
                        
                        is_browser_focused = (app_ignored and not title_allowed)
                        log_engine(f"Initial focus: {window_class} | {window_title} (Blocked: {is_browser_focused})")
                        update_waybar()

                    for line in f:
                        if "activewindow>>" in line:
                            try:
                                # Format is: activewindow>>[class],[title]
                                payload = line.split("activewindow>>")[1].strip()
                                parts = payload.split(",")
                                window_class = parts[0].strip()
                                window_title = ",".join(parts[1:]).strip() # Rejoin if title has commas
                                
                                # AUTO-FLOAT LOGIC: If scratchpad focused and not floating, fix it instantly.
                                if any(t in window_title for t in allowed_titles):
                                    # Double check floating status with hyprctl
                                    res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
                                    if res.returncode == 0:
                                        data = json.loads(res.stdout)
                                        if not data.get("floating", False):
                                            log_engine(f"Auto-Floating scratchpad: {window_title}")
                                            # Execute multiple commands to set the look
                                            subprocess.run(["hyprctl", "dispatch", "togglefloating", "active"], capture_output=False)
                                            subprocess.run(["hyprctl", "dispatch", "resizeactive", "exact", "400", "500"], capture_output=False)
                                            subprocess.run(["hyprctl", "dispatch", "centerwindow"], capture_output=False)
                                            subprocess.run(["hyprctl", "dispatch", "pin", "active"], capture_output=False)

                                # Logic: Block if app is ignored UNLESS title is allowed
                                app_ignored = (window_class in ignored_apps)
                                title_allowed = any(t in window_title for t in allowed_titles)
                                
                                new_focus = (app_ignored and not title_allowed)
                                
                                if new_focus != is_browser_focused:
                                    is_browser_focused = new_focus
                                    status = f"PAUSED ({window_class})" if is_browser_focused else "RESUMED"
                                    log_engine(f"Focus changed: {window_class} | {window_title} -> {status}")
                                    update_waybar()
                            except Exception as e:
                                log_engine(f"Parsing error: {e}")
        except Exception as e:
            log_engine(f"Socket error: {e}. Retrying...")
            time.sleep(2)

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

threading.Thread(target=typing_worker, daemon=True).start()

def main():
    print("[DEBUG] Script started (Event-Driven Smart Mode).")
    
    # Start background threads only after defining recorder
    threading.Thread(target=pause_watcher, daemon=True).start()
    threading.Thread(target=override_watcher, daemon=True).start()
    threading.Thread(target=hyprland_event_listener, daemon=True).start()

    print("\n[INFO] Initializing Whisper Turbo Model...")
    
    last_text = ""

    recorder_config = {
        "model": "large-v3-turbo",
        "device": "cuda",
        "compute_type": "float16",
        "language": "en",
        "post_speech_silence_duration": 0.7,
        "min_gap_between_recordings": 0.0,
        "input_device_index": None,
        "spinner": False,
        "use_microphone": True,
        "silero_sensitivity": 0.3,
        "webrtc_sensitivity": 3,
        "min_length_of_recording": 0.3,
        "beam_size": 5,
        "initial_prompt": "This is a continuous dictation session."
    }

    def process_text(text):
        nonlocal last_text
        # Logic: Pause only if manually paused OR (browser is focused AND override is NOT active)
        if is_paused or (is_browser_focused and not smart_pause_override):
            return 

        text = text.strip()
        if text:
            recorder.initial_prompt = f"Previous text: {last_text}. Continue the thought naturally."
            last_text = text
            text_queue.put(text + " ")

    try:
        global recorder
        recorder = AudioToTextRecorder(**recorder_config)
        update_waybar() # Set initial green state
        print("\n>>> System Ready! Speak into your microphone.")

        while True:
            # Logic: Pause only if manually paused OR (browser is focused AND override is NOT active)
            effective_pause = is_paused or (is_browser_focused and not smart_pause_override)
            
            if effective_pause:
                if getattr(recorder, 'is_recording', False):
                    recorder.stop()
                time.sleep(0.5)
                continue
            
            if not getattr(recorder, 'is_recording', False):
                recorder.start()

            try:
                recorder.text(process_text)
            except Exception as e:
                if not effective_pause:
                    print(f"[ERROR] Recorder error: {e}")
                time.sleep(0.1)

    except KeyboardInterrupt:
        pass
    finally:
        print("\nStopping...")
        text_queue.put(None)

if __name__ == "__main__":
    main()
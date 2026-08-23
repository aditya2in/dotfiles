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

# Global state for pausing & routing
is_paused = False
is_paused_by_voxtype = False  # The Blue Sign
is_top_bar_hovered = False   # Top bar mouse parking mute
last_voxtype_interrupt_time = 0  # Cooldown Timer
is_scratchpad_focused = False
smart_pause_override = False
PAUSE_FILE = "/tmp/whisper_paused"
VOXTYPE_PAUSE_FILE = "/tmp/whisper_paused_by_voxtype"
OVERRIDE_FILE = "/tmp/whisper_smart_pause_override"
STATUS_FILE = "/tmp/whisper_status.json"
CONFIG_FILE = os.path.join(os.path.dirname(__file__), "whisper_config.json")
recorder = None  # Global reference to allow background interruption

def log_engine(msg):
    """Log to a temporary file for debugging."""
    try:
        with open("/tmp/whisper_engine.log", "a") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")
    except Exception:
        pass

def load_config():
    """Load configuration from JSON file."""
    defaults = {
        "target_mode": "ghostty_background",
        "tmux_target_session": "K8",
        "allowed_titles": ["000_SCRATCHPAD_Brain_Dump"]
    }
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, "r") as f:
                return {**defaults, **json.load(f)}
    except Exception as e:
        log_engine(f"Config load error: {e}")
    return defaults

def is_cursor_on_top_bar(x, y):
    """Accurately checks if cursor is resting in the top bar zone of any of the 3 monitors."""
    # Left Vertical (0 <= x < 1080, top=0)
    if 0 <= x < 1080 and 0 <= y <= 28:
        return True
    # Center Ultrawide (1080 <= x < 4520, top=240 due to vertical offset)
    elif 1080 <= x < 4520 and 240 <= y <= 268:
        return True
    # Right Vertical (x >= 4520, top=0)
    elif x >= 4520 and 0 <= y <= 28:
        return True
    return False

def update_waybar():
    """Update the status JSON for Waybar."""
    global is_paused, is_paused_by_voxtype, is_top_bar_hovered, is_scratchpad_focused
    state = "running"
    icon = "󰍬"  # Microphone On
    tooltip = "Whisper STT: Active (Ghostty Target)"
    
    if is_paused:
        state = "paused"
        icon = "󰍭"
        tooltip = "Whisper STT: Paused (Manual)"
    elif is_paused_by_voxtype:
        state = "interrupted"
        icon = "󰍭"
        tooltip = "Whisper STT: Interrupted by VoxType"
    elif is_top_bar_hovered:
        state = "paused"
        icon = "󰍭"
        tooltip = "Whisper STT: Paused (Bar Hover)"
    elif is_scratchpad_focused:
        tooltip = "Whisper STT: Active (Scratchpad Focus)"
        
    status = {
        "text": icon,
        "class": state,
        "alt": state,
        "tooltip": tooltip
    }
    
    try:
        temp_status = STATUS_FILE + ".tmp"
        with open(temp_status, "w") as f:
            json.dump(status, f)
        os.rename(temp_status, STATUS_FILE)
        log_engine(f"Status updated: {state} (Manual: {is_paused}, VoxType: {is_paused_by_voxtype}, BarHover: {is_top_bar_hovered})")
    except Exception as e:
        log_engine(f"Waybar update failed: {e}")

def cursor_hover_watcher():
    """Polls cursor position to provide instant, zero-touch top-bar mute."""
    global is_top_bar_hovered
    last_hover_state = False
    
    while True:
        try:
            res = subprocess.run(["hyprctl", "cursorpos", "-j"], capture_output=True, text=True)
            if res.returncode == 0:
                pos = json.loads(res.stdout)
                hovered = is_cursor_on_top_bar(pos.get("x", 0), pos.get("y", 0))
                if hovered != last_hover_state:
                    is_top_bar_hovered = hovered
                    last_hover_state = hovered
                    update_waybar()
                    if hovered:
                        log_engine("Top bar hovered: STT paused.")
                    else:
                        log_engine("Top bar unhovered: STT resumed.")
        except Exception:
            pass
        time.sleep(0.12)

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
    """Background thread that watches for pause files."""
    global is_paused, is_paused_by_voxtype, last_voxtype_interrupt_time
    
    last_manual_state = False
    last_voxtype_state = False
    
    while True:
        manual_state = os.path.exists(PAUSE_FILE)
        voxtype_state = os.path.exists(VOXTYPE_PAUSE_FILE)
        
        if manual_state != last_manual_state or voxtype_state != last_voxtype_state:
            if last_voxtype_state is True and voxtype_state is False:
                last_voxtype_interrupt_time = time.time()
                log_engine(f"VoxType ended. Cooldown started at: {last_voxtype_interrupt_time}")

            is_paused = manual_state
            is_paused_by_voxtype = voxtype_state
            update_waybar()
            
            if manual_state != last_manual_state:
                status_text = "PAUSED" if is_paused else "RESUMED"
                icon = "microphone-sensitivity-muted" if is_paused else "microphone-sensitivity-high"
                subprocess.run(["notify-send", "Whisper STT", f"Status: {status_text}", "-i", icon, "-t", "1500", "-h", "string:x-canonical-private-synchronous:whisper-pause"])
            
            last_manual_state = manual_state
            last_voxtype_state = voxtype_state
            
        time.sleep(0.1)

def hyprland_event_listener():
    """Listen to Hyprland socket2 for real-time focus changes (to identify Scratchpad)."""
    global is_scratchpad_focused
    
    config = load_config()
    allowed_titles = config.get("allowed_titles", ["000_SCRATCHPAD_Brain_Dump"])
    last_scratchpad_launch_time = 0
    
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
                
                with client.makefile('r') as f:
                    res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
                    if res.returncode == 0:
                        try:
                            data = json.loads(res.stdout)
                            window_class = data.get("class", "")
                            window_title = data.get("title", "")
                            is_scratchpad_focused = (window_class == "obsidian" and any(t in window_title for t in allowed_titles))
                            log_engine(f"Initial focus: {window_class} | {window_title} (Scratchpad: {is_scratchpad_focused})")
                            update_waybar()
                        except: pass

                    for line in f:
                        if "activewindow>>" in line:
                            try:
                                payload = line.split("activewindow>>")[1].strip()
                                parts = payload.split(",")
                                socket_class = parts[0].strip()
                                socket_title = ",".join(parts[1:]).strip()
                                
                                # Scratchpad window tracking
                                if socket_class == "obsidian":
                                    is_scratch = any(t in socket_title for t in allowed_titles)
                                    is_scratchpad_focused = is_scratch
                                    
                                    # Auto-float & precision placement for Scratchpad
                                    res_clients = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True)
                                    if res_clients.returncode == 0:
                                        clients = json.loads(res_clients.stdout)
                                        scratchpad = next((c for c in clients if c.get("class") == "obsidian" and any(t in c.get("title") for t in allowed_titles)), None)
                                        
                                        if scratchpad and is_scratch:
                                            addr = scratchpad.get("address")
                                            curr_work = str(scratchpad.get("workspace", {}).get("name", ""))
                                            is_float = scratchpad.get("floating", False)

                                            if curr_work != "1":
                                                subprocess.run(["hyprctl", "dispatch", "movetoworkspace", f"1,address:{addr}"], capture_output=False)
                                            subprocess.run(["hyprctl", "dispatch", "resizewindowpixel", f"exact 860 560,address:{addr}"], capture_output=False)
                                            if not is_float:
                                                subprocess.run(["hyprctl", "dispatch", "togglefloating", f"address:{addr}"], capture_output=False)
                                                subprocess.run(["hyprctl", "dispatch", "movewindowpixel", f"exact 510 10,address:{addr}"], capture_output=False)
                                                subprocess.run(["hyprctl", "dispatch", "pin", f"address:{addr}"], capture_output=False)
                                        elif not scratchpad and is_scratch:
                                            current_time = time.time()
                                            if (current_time - last_scratchpad_launch_time) > 5.0:
                                                last_scratchpad_launch_time = current_time
                                                cmd = [
                                                    "/home/adityaws/.local/bin/obsidian",
                                                    "obsidian://open?vault=Obsidian&file=All%20Things%2FAgents%2FLearning_%26_HomeLab_OS%2FProject_K8s_-_KUBESTRONAUT%2FTasks_or_Projects_%28around_KUBESTRONAUT%29%2F2.%20Project_kubernetes%2F2.%20CKAD_Certification_Course_-_Certified_Kubernetes_Application_Developer_Course%2F000_SCRATCHPAD_Brain_Dump&paneType=window"
                                                ]
                                                subprocess.Popen(cmd)
                                else:
                                    is_scratchpad_focused = False
                                    
                                update_waybar()
                            except Exception as e:
                                log_engine(f"Parsing error: {e}")
        except Exception as e:
            log_engine(f"Socket error: {e}. Retrying...")
            time.sleep(2)

# Lane 2: The typing queue and worker with Direct Target Injection
text_queue = queue.Queue()

def inject_text(text):
    """
    Direct Background Target Injection (Way B):
    1. If Scratchpad is active -> type into Scratchpad via wtype.
    2. Otherwise -> send keys directly into Ghostty/Tmux (Session K8) in the background with ZERO focus stealing.
    """
    config = load_config()
    target_session = config.get("tmux_target_session", "K8")
    
    # 1. Scratchpad exception
    if is_scratchpad_focused:
        try:
            subprocess.run(["wtype", text], check=True)
            return
        except Exception as e:
            log_engine(f"wtype scratchpad error: {e}")

    # 2. Direct injection into target tmux session (K8)
    try:
        res = subprocess.run(["tmux", "send-keys", "-t", target_session, "-l", text], capture_output=True)
        if res.returncode == 0:
            return
    except Exception as e:
        log_engine(f"tmux K8 send error: {e}")

    # 3. Fallback: Find any attached tmux session
    try:
        res_sessions = subprocess.run(
            ["tmux", "list-sessions", "-F", "#{session_name} #{session_attached}"],
            capture_output=True, text=True
        )
        if res_sessions.returncode == 0:
            for line in res_sessions.stdout.strip().splitlines():
                parts = line.split()
                if len(parts) >= 2 and parts[1] == "1":
                    sname = parts[0]
                    res_inj = subprocess.run(["tmux", "send-keys", "-t", sname, "-l", text], capture_output=True)
                    if res_inj.returncode == 0:
                        return
    except Exception as e:
        log_engine(f"tmux fallback error: {e}")

    # 4. Fallback if no tmux session: type only if Ghostty is the active window
    try:
        res_win = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
        if res_win.returncode == 0:
            win_data = json.loads(res_win.stdout)
            if win_data.get("class") == "com.mitchellh.ghostty":
                subprocess.run(["wtype", text], check=True)
    except Exception as e:
        log_engine(f"wtype ghostty fallback error: {e}")

def typing_worker():
    """Background thread that dispatches text from the queue."""
    while True:
        text = text_queue.get()
        if text is None:
            break
        inject_text(text)
        text_queue.task_done()

threading.Thread(target=typing_worker, daemon=True).start()

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

def main():
    print("[DEBUG] Script started (Direct Ghostty Target Injection & Top-Bar Hover Mute Active).")
    
    threading.Thread(target=pause_watcher, daemon=True).start()
    threading.Thread(target=override_watcher, daemon=True).start()
    threading.Thread(target=cursor_hover_watcher, daemon=True).start()
    threading.Thread(target=hyprland_event_listener, daemon=True).start()

    print("\n[INFO] Initializing Whisper Turbo Model...")
    
    last_text = ""

    recorder_config = {
        "model": "/home/adityaws/AI_MODELS/dictation_models",
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
        current_time = time.time()
        cooldown_active = (current_time - last_voxtype_interrupt_time) < 1.5
        
        if is_paused or is_paused_by_voxtype or is_top_bar_hovered or cooldown_active:
            if cooldown_active and not is_paused_by_voxtype:
                log_engine(f"Cooldown active: Discarding overlap text: '{text[:20]}...'")
            return 

        text = text.strip()
        if text:
            recorder.initial_prompt = f"Previous text: {last_text}. Continue the thought naturally."
            last_text = text
            text_queue.put(text + " ")

    try:
        global recorder
        recorder = AudioToTextRecorder(**recorder_config)
        update_waybar()
        print("\n>>> System Ready! Speak into your microphone (Direct Ghostty Injection & Top-Bar Mute Active).")

        while True:
            if is_paused or is_paused_by_voxtype or is_top_bar_hovered:
                while not text_queue.empty():
                    try: text_queue.get_nowait(); text_queue.task_done()
                    except: break
                time.sleep(0.2)
                continue

            if not getattr(recorder, 'is_recording', False):
                recorder.start()

            try:
                recorder.text(process_text)
            except Exception as e:
                print(f"[ERROR] Recorder error: {e}")
                time.sleep(0.1)

    except KeyboardInterrupt:
        pass
    finally:
        print("\nStopping...")
        text_queue.put(None)

if __name__ == "__main__":
    main()

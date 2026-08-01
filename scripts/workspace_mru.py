#!/usr/bin/env python3
import os
import sys
import json
import socket
import subprocess

STATE_FILE = "/tmp/workspace_mru_state.json"

def get_current_workspace():
    try:
        out = subprocess.check_output(["hyprctl", "activeworkspace", "-j"]).decode()
        return json.loads(out)["id"]
    except Exception:
        return 1

def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"queue": [1], "index": 0, "cycling": False}

def save_state(state):
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(state, f)
    except Exception:
        pass

def run_daemon():
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        print("Error: HYPRLAND_INSTANCE_SIGNATURE not set")
        sys.exit(1)
    
    # Try XDG_RUNTIME_DIR first, fall back to /tmp
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    socket_path = f"{xdg_runtime}/hypr/{signature}/.socket2.sock"
    if not os.path.exists(socket_path):
        socket_path = f"/tmp/hypr/{signature}/.socket2.sock"
        
    if not os.path.exists(socket_path):
        print(f"Error: socket not found at {socket_path}")
        sys.exit(1)

    # Initialize state with current workspace
    curr = get_current_workspace()
    state = load_state()
    if curr not in state["queue"]:
        state["queue"].insert(0, curr)
    save_state(state)

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(socket_path)
    
    buffer = ""
    while True:
        data = s.recv(1024).decode()
        if not data:
            break
        buffer += data
        while "\n" in buffer:
            line, buffer = buffer.split("\n", 1)
            if line.startswith("workspace>>"):
                parts = line.split(">>")
                if len(parts) >= 2:
                    try:
                        ws_id = int(parts[1])
                    except ValueError:
                        continue
                    
                    state = load_state()
                    # If we are currently cycling, we don't update the history queue
                    # because we are just previewing. We only update queue when finalized.
                    if not state.get("cycling", False):
                        queue = state["queue"]
                        if ws_id in queue:
                            queue.remove(ws_id)
                        queue.insert(0, ws_id)
                        state["queue"] = queue
                        save_state(state)

def cycle():
    state = load_state()
    queue = state["queue"]
    
    # Refresh queue to ensure we only have active workspaces
    try:
        out = subprocess.check_output(["hyprctl", "workspaces", "-j"]).decode()
        active_ids = [ws["id"] for ws in json.loads(out) if ws["id"] > 0]
    except Exception:
        active_ids = queue
    
    # Clean queue: keep only active ones, keep order
    cleaned_queue = [x for x in queue if x in active_ids]
    # Add any active ones not in queue
    for aid in active_ids:
        if aid not in cleaned_queue:
            cleaned_queue.append(aid)
    
    if not cleaned_queue:
        cleaned_queue = [1]
        
    if not state.get("cycling", False):
        # Just started cycling
        state["cycling"] = True
        state["index"] = 1 % len(cleaned_queue) # Point to previous workspace
    else:
        state["index"] = (state["index"] + 1) % len(cleaned_queue)
        
    target_ws = cleaned_queue[state["index"]]
    state["queue"] = cleaned_queue
    save_state(state)
    
    # Switch workspace
    subprocess.run(["hyprctl", "dispatch", "workspace", str(target_ws)])

def reset():
    state = load_state()
    if state.get("cycling", False):
        state["cycling"] = False
        # Move the finalized workspace to the top of the queue
        curr = get_current_workspace()
        queue = state["queue"]
        if curr in queue:
            queue.remove(curr)
        queue.insert(0, curr)
        state["queue"] = queue
        state["index"] = 0
        save_state(state)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: workspace_mru.py [--daemon|--cycle|--reset]")
        sys.exit(1)
        
    mode = sys.argv[1]
    if mode == "--daemon":
        run_daemon()
    elif mode == "--cycle":
        cycle()
    elif mode == "--reset":
        reset()

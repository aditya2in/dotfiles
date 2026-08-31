#!/usr/bin/env python3
"""
Game & Hardware 1-Second Telemetry Daemon (gpuworker01)
Captures real-time GPU, CPU, RAM, NVMe metrics with immediate disk sync.
Automatically starts 1s high-resolution logging when Steam or a game runs.
"""

import sys
import os
import time
import datetime
import glob
import ctypes
import signal
import psutil

# ----------------- Configuration -----------------
LOG_DIR = os.path.expanduser("~/.local/share/gaming_telemetry")
POLL_INTERVAL_ACTIVE = 1.0   # 1 second during gameplay
POLL_INTERVAL_IDLE = 5.0     # 5 seconds when idle
MAX_LOG_AGE_DAYS = 14        # Auto-clean logs older than 14 days

GAME_PROCESS_NAMES = {
    "steam", "steamwebhelper", "witcher3", "witcher3.exe", "proton", 
    "wine", "wineserver", "wine64-preloader", "gamescope", "gamemoderun", 
    "heroic", "lutris", "cyberpunk2077.exe", "cs2", "dota2", 
    "rdr2.exe", "gta5.exe", "thecrew.exe", "thecrewmotorfest.exe"
}

# ----------------- Direct NVML C Binding -----------------
class Utilization(ctypes.Structure):
    _fields_ = [('gpu', ctypes.c_uint), ('memory', ctypes.c_uint)]

class Memory(ctypes.Structure):
    _fields_ = [('total', ctypes.c_ulonglong), ('free', ctypes.c_ulonglong), ('used', ctypes.c_ulonglong)]

class NVMLReader:
    def __init__(self):
        self.initialized = False
        self.handle = ctypes.c_void_p()
        try:
            self.nvml = ctypes.CDLL("libnvidia-ml.so.1")
            if self.nvml.nvmlInit() == 0:
                if self.nvml.nvmlDeviceGetHandleByIndex(0, ctypes.byref(self.handle)) == 0:
                    self.initialized = True
        except Exception:
            self.initialized = False

    def read_metrics(self):
        if not self.initialized:
            return {"temp": 0, "power": 0.0, "fan": 0, "clock_gfx": 0, "clock_mem": 0, "util": 0, "vram_used": 0, "vram_total": 0}
        
        temp = ctypes.c_uint()
        power = ctypes.c_uint()
        fan = ctypes.c_uint()
        clock_gfx = ctypes.c_uint()
        clock_mem = ctypes.c_uint()
        util = Utilization()
        mem = Memory()

        self.nvml.nvmlDeviceGetTemperature(self.handle, 0, ctypes.byref(temp))
        self.nvml.nvmlDeviceGetPowerUsage(self.handle, ctypes.byref(power))
        self.nvml.nvmlDeviceGetFanSpeed(self.handle, ctypes.byref(fan))
        self.nvml.nvmlDeviceGetClockInfo(self.handle, 0, ctypes.byref(clock_gfx))
        self.nvml.nvmlDeviceGetClockInfo(self.handle, 2, ctypes.byref(clock_mem))
        self.nvml.nvmlDeviceGetUtilizationRates(self.handle, ctypes.byref(util))
        self.nvml.nvmlDeviceGetMemoryInfo(self.handle, ctypes.byref(mem))

        return {
            "temp": int(temp.value),
            "power": round(power.value / 1000.0, 2),
            "fan": int(fan.value),
            "clock_gfx": int(clock_gfx.value),
            "clock_mem": int(clock_mem.value),
            "util": int(util.gpu),
            "vram_used": int(mem.used // (1024 * 1024)),
            "vram_total": int(mem.total // (1024 * 1024))
        }

    def close(self):
        if self.initialized:
            try:
                self.nvml.nvmlShutdown()
            except Exception:
                pass

# ----------------- Sysfs HWMon Sensor Mapping -----------------
class HWMonReader:
    def __init__(self):
        self.coretemp_pkg = None
        self.coretemp_cores = []
        self.nvme_temp = None
        self._discover_sensors()

    def _discover_sensors(self):
        for hwmon_dir in glob.glob("/sys/class/hwmon/hwmon*"):
            try:
                name_file = os.path.join(hwmon_dir, "name")
                if not os.path.exists(name_file):
                    continue
                with open(name_file, "r") as f:
                    name = f.read().strip()
                
                if name == "coretemp":
                    for tf in sorted(glob.glob(os.path.join(hwmon_dir, "temp*_input"))):
                        label_file = tf.replace("_input", "_label")
                        label = ""
                        if os.path.exists(label_file):
                            with open(label_file, "r") as lf:
                                label = lf.read().strip()
                        if "Package" in label or self.coretemp_pkg is None:
                            self.coretemp_pkg = tf
                        if "Core" in label:
                            self.coretemp_cores.append(tf)
                
                elif name == "nvme" and self.nvme_temp is None:
                    t1 = os.path.join(hwmon_dir, "temp1_input")
                    if os.path.exists(t1):
                        self.nvme_temp = t1
            except Exception:
                pass

    def _read_milli_c(self, path):
        if not path or not os.path.exists(path):
            return 0
        try:
            with open(path, "r") as f:
                return int(f.read().strip()) // 1000
        except Exception:
            return 0

    def read_metrics(self):
        pkg_temp = self._read_milli_c(self.coretemp_pkg)
        core_temps = [self._read_milli_c(p) for p in self.coretemp_cores]
        max_core = max(core_temps) if core_temps else pkg_temp
        nvme = self._read_milli_c(self.nvme_temp)
        return {
            "cpu_pkg_temp": pkg_temp,
            "cpu_core_max": max_core,
            "nvme_temp": nvme
        }

# ----------------- Process Detector -----------------
def detect_active_game():
    for proc in psutil.process_iter(['name', 'exe']):
        try:
            pname = (proc.info['name'] or '').lower()
            exe = os.path.basename(proc.info['exe'] or '').lower()
            
            # Check for Windows games (.exe) under Proton/Wine
            if pname.endswith('.exe') and not pname.startswith('system'):
                return proc.info['name']
            
            if pname in GAME_PROCESS_NAMES or exe in GAME_PROCESS_NAMES:
                if pname in ("steam", "steamwebhelper"):
                    return "Steam"
                return proc.info['name']
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue
    return None

# ----------------- Main Daemon Loop -----------------
def cleanup_old_logs():
    cutoff = time.time() - (MAX_LOG_AGE_DAYS * 86400)
    for logfile in glob.glob(os.path.join(LOG_DIR, "telemetry_*.csv")):
        try:
            if os.path.getmtime(logfile) < cutoff:
                os.remove(logfile)
        except Exception:
            pass

def main():
    if "--test-read" in sys.argv:
        nvml = NVMLReader()
        hwmon = HWMonReader()
        gpu = nvml.read_metrics()
        hw = hwmon.read_metrics()
        ram = psutil.virtual_memory()
        cpu_load = psutil.cpu_percent(interval=0.5)
        active_game = detect_active_game()
        print("=== Hardware Telemetry Test Sample ===")
        print(f"Timestamp (IST): {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Active Game:     {active_game or 'None (System Idle)'}")
        print(f"GPU Core Temp:   {gpu['temp']} °C")
        print(f"GPU Power Draw:  {gpu['power']} W")
        print(f"GPU Fan Speed:   {gpu['fan']} %")
        print(f"GPU GFX/Mem Clk: {gpu['clock_gfx']} / {gpu['clock_mem']} MHz")
        print(f"GPU Utilization: {gpu['util']} %")
        print(f"VRAM Used:       {gpu['vram_used']} / {gpu['vram_total']} MB")
        print(f"CPU Package:     {hw['cpu_pkg_temp']} °C (Max Core: {hw['cpu_core_max']} °C)")
        print(f"CPU Load:        {cpu_load} %")
        print(f"System RAM Used: {ram.used // (1024*1024)} / {ram.total // (1024*1024)} MB")
        print(f"NVMe SSD Temp:   {hw['nvme_temp']} °C")
        nvml.close()
        return

    os.makedirs(LOG_DIR, exist_ok=True)
    cleanup_old_logs()

    nvml = NVMLReader()
    hwmon = HWMonReader()

    running = True
    def sig_handler(signum, frame):
        nonlocal running
        running = False
    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    current_log_file = None
    current_fp = None

    headers = (
        "timestamp_ist,game_name,gpu_temp_c,gpu_power_w,gpu_fan_pct,"
        "gpu_clock_mhz,gpu_mem_clock_mhz,gpu_util_pct,vram_used_mb,vram_total_mb,"
        "cpu_pkg_temp_c,cpu_core_max_c,cpu_load_pct,ram_used_mb,ram_total_mb,nvme_temp_c\n"
    )

    try:
        while running:
            active_game = detect_active_game()
            
            if active_game:
                # Open new session file if not already recording
                if current_fp is None:
                    ts_str = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
                    current_log_file = os.path.join(LOG_DIR, f"telemetry_{ts_str}.csv")
                    current_fp = open(current_log_file, "a", buffering=1, encoding="utf-8")
                    current_fp.write(headers)
                    current_fp.flush()
                    os.fdatasync(current_fp.fileno())

                now_ist = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                gpu = nvml.read_metrics()
                hw = hwmon.read_metrics()
                ram = psutil.virtual_memory()
                cpu_load = psutil.cpu_percent(interval=None)

                line = (
                    f"{now_ist},{active_game},{gpu['temp']},{gpu['power']},{gpu['fan']},"
                    f"{gpu['clock_gfx']},{gpu['clock_mem']},{gpu['util']},{gpu['vram_used']},{gpu['vram_total']},"
                    f"{hw['cpu_pkg_temp']},{hw['cpu_core_max']},{cpu_load:.1f},"
                    f"{ram.used // (1024*1024)},{ram.total // (1024*1024)},{hw['nvme_temp']}\n"
                )
                current_fp.write(line)
                current_fp.flush()
                os.fdatasync(current_fp.fileno())

                time.sleep(POLL_INTERVAL_ACTIVE)
            else:
                # Game is not running -> close active session file
                if current_fp is not None:
                    try:
                        current_fp.flush()
                        os.fdatasync(current_fp.fileno())
                        current_fp.close()
                    except Exception:
                        pass
                    current_fp = None
                    current_log_file = None

                time.sleep(POLL_INTERVAL_IDLE)

    finally:
        if current_fp is not None:
            try:
                current_fp.flush()
                os.fdatasync(current_fp.fileno())
                current_fp.close()
            except Exception:
                pass
        nvml.close()

if __name__ == "__main__":
    main()

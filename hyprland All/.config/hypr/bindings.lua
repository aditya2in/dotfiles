-- ==============================================================================
-- Hyprland User Keybindings (Omarchy v4 Lua Architecture)
-- ==============================================================================
-- Keep only personal overrides and custom hotkeys here.
-- Omarchy automatically loads all default application and webapp bindings.
-- To view all active bindings: omarchy menu keybindings --print
-- ==============================================================================

-- 1. Custom Application Overrides
o.bind("SUPER + ALT + RETURN", "Tmux", "env WAYLAND_DISPLAY= DISPLAY=:1 wezterm start --always-new-process --cwd \"$(omarchy-cmd-terminal-cwd)\"")
o.bind("SUPER + SHIFT + W", "Typora", "uwsm-app -- typora --enable-wayland-ime")
o.bind("SUPER + SHIFT + T", "Activity", "omarchy-launch-tui btop")
o.bind("SUPER + Z", "Hyprshot Region", "hyprshot -m region")

-- 2. Scratchpad Window Manager
o.bind("SUPER + code:49", "Toggle Obsidian Scratch Pad", "bash /home/adityaws/DOTfiles/scripts/focus_obsidian_scratchpad.sh")

-- 3. Workspace Navigation Overrides
hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Toggle previous workspace", hl.dsp.focus({ workspace = "previous" }))
hl.unbind("SUPER_L")
hl.unbind("SUPER_R")

-- 4. AI Speech-to-Text Dictation Suite
-- Tier 1: Quick Prompt Submission
o.bind("F1", "Submit Prompt to Ghostty", "/home/adityaws/DOTfiles/scripts/speech_recognition/submit_to_ghostty.sh")

-- Tier 2: VoxType Dictation (Whisper.cpp GGML)
o.bind("F2", "VoxType Dictation", "/home/adityaws/DOTfiles/scripts/speech_recognition/VoxType/smart_voxtype.sh")
o.bind("SHIFT + F2", "Toggle VoxType Power", "/home/adityaws/DOTfiles/scripts/speech_recognition/VoxType/smart_voxtype.sh toggle-power")

-- Tier 3: NVIDIA Nemotron ASR Real-Time Streaming (0.6B FastConformer-RNNT)
o.bind("SHIFT + F4", "Toggle Nemotron Power", "/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh --power")
o.bind("F4", "Toggle Nemotron Pause", "/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh")
o.bind("CTRL + F4", "Toggle Nemotron Smart Pause Override", "/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh --toggle-override")

-- Tier 4: Whisper Turbo STT (Faster-Whisper Large-v3-Turbo)
o.bind("F7", "Toggle Whisper Turbo STT", "/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt/toggle_dictation.sh")
o.bind("F8", "Toggle Dictation Pause", "/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt/toggle_dictation.sh --pause")
o.bind("F6", "Toggle Smart Pause Override", "/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt/toggle_dictation.sh --toggle-override")

-- Tier 5: NVIDIA Parakeet 1.1B ASR Streaming Dictation (FastConformer-RNNT)
o.bind("SHIFT + F9", "Toggle Parakeet Power", "/home/adityaws/DOTfiles/scripts/speech_recognition/parakeet_dictation/toggle_parakeet.sh --power")
o.bind("F9", "Toggle Parakeet Pause", "/home/adityaws/DOTfiles/scripts/speech_recognition/parakeet_dictation/toggle_parakeet.sh")

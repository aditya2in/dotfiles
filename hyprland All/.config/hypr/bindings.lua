-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Application bindings
o.bind("SUPER + ALT + RETURN", "Tmux", "env WAYLAND_DISPLAY= DISPLAY=:1 wezterm start --always-new-process --cwd \"$(omarchy-cmd-terminal-cwd)\"")
o.bind("SUPER + RETURN", "Terminal", "ghostty")
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + F", "File manager", "uwsm-app -- nautilus --new-window")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", "uwsm-app -- nautilus --new-window \"$(omarchy-cmd-terminal-cwd)\"")
o.bind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", "omarchy-launch-or-focus-tui cliamp")
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + SHIFT + T", "Activity", "omarchy-launch-tui btop")
o.bind("SUPER + SHIFT + D", "Docker", "omarchy-launch-tui lazydocker")
o.bind("SUPER + SHIFT + G", "Signal", 'omarchy-launch-or-focus ^signal$ "uwsm-app -- signal-desktop"')
o.bind("SUPER + SHIFT + O", "Obsidian", 'omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian"')
o.bind("SUPER + SHIFT + W", "Typora", "uwsm-app -- typora --enable-wayland-ime")
o.bind("SUPER + SHIFT + SLASH", "Passwords", "uwsm-app -- 1password")

-- Web app URL bindings
o.bind("SUPER + SHIFT + A", "ChatGPT", 'omarchy-launch-webapp "https://chatgpt.com"')
o.bind("SUPER + SHIFT + ALT + A", "Grok", 'omarchy-launch-webapp "https://grok.com"')
o.bind("SUPER + SHIFT + C", "Calendar", 'omarchy-launch-webapp "https://app.hey.com/calendar/weeks/"')
o.bind("SUPER + SHIFT + E", "Email", 'omarchy-launch-webapp "https://app.hey.com"')
o.bind("SUPER + SHIFT + Y", "YouTube", 'omarchy-launch-webapp "https://youtube.com/"')
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", 'omarchy-launch-or-focus-webapp WhatsApp "https://web.whatsapp.com/"')
o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", 'omarchy-launch-or-focus-webapp "Google Messages" "https://messages.google.com/web/conversations"')
o.bind("SUPER + SHIFT + P", "Google Photos", 'omarchy-launch-or-focus-webapp "Google Photos" "https://photos.google.com/"')
o.bind("SUPER + SHIFT + X", "X", 'omarchy-launch-webapp "https://x.com/"')
o.bind("SUPER + SHIFT + ALT + X", "X Post", 'omarchy-launch-webapp "https://x.com/compose/post"')

-- AI Dictation (Whisper Turbo STT)
o.bind("F7", "Toggle Whisper Turbo STT", "/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt/toggle_dictation.sh")
o.bind("F8", "Toggle Dictation Pause", "/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt/toggle_dictation.sh --pause")
o.bind("F6", "Toggle Smart Pause Override", "/home/adityaws/DOTfiles/scripts/speech_recognition/whisper_turbo_stt/toggle_dictation.sh --toggle-override")
o.bind("F1", "VoxType Dictation", "/home/adityaws/DOTfiles/scripts/speech_recognition/VoxType/smart_voxtype.sh")
o.bind("SHIFT + F1", "Toggle VoxType Power", "/home/adityaws/DOTfiles/scripts/speech_recognition/VoxType/smart_voxtype.sh toggle-power")
o.bind("SUPER + code:49", "Toggle Obsidian Scratch Pad", "bash /home/adityaws/DOTfiles/scripts/focus_obsidian_scratchpad.sh")

-- Nemotron Dictation (NVIDIA Nemotron ASR Streaming)
o.bind("F9", "Toggle Nemotron STT", "/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh")
o.bind("SHIFT + F9", "Nemotron STT Start", "/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh --start")
o.bind("F10", "Toggle Nemotron Pause", "/home/adityaws/DOTfiles/scripts/speech_recognition/nemotron_dictation/toggle_nemotron.sh --pause")

-- Toggle to previously active workspace on SUPER + TAB
hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Toggle previous workspace", hl.dsp.focus({ workspace = "previous" }))

-- Unbind previous MRU release overrides
hl.unbind("SUPER_L")
hl.unbind("SUPER_R")

-- Extra Screenshot Bind
o.bind("SUPER + Z", "Hyprshot Region", "hyprshot -m region")

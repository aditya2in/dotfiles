-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 2,
    border_size = 2,
    ["col.active_border"] = { colors = { "rgba(33ccffff)", "rgba(00ff99ff)" }, angle = 45 },
    ["col.inactive_border"] = "rgba(595959ff)",
    layout = "dwindle",
  },
  decoration = {
    rounding = 0,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    dim_inactive = false,
    blur = {
      enabled = false,
    },
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aff)",
    },
  },
  animations = {
    enabled = false,
  },
  dwindle = {
    preserve_split = true,
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
  },
})

-- Force opaque windows rule overrides
o.window(".*", { tag = "-default-opacity" })
o.window(".*", { tag = "-terminal" })
o.window(".*", { opacity = "1.0 1.0 override" })

-- General App Mappings
o.window("(Alacritty|kitty|org.wezfurlong.wezterm|com.mitchellh.ghostty)", { workspace = "1" })
o.window("brave-browser", { workspace = "2" })
o.window("(md.obsidian.Obsidian|org.omarchy.wiremix)", { workspace = "3" })
o.window("steam", { workspace = "4" })

-- Stability Rules
o.window("(com.mitchellh.ghostty|brave-browser|obsidian)", { suppress_event = "maximize" })
o.window("com.mitchellh.ghostty", { focus_on_activate = false })
o.window({ class = "com.mitchellh.ghostty", workspace = "1" }, { fullscreen = 1 })
o.window({ class = "brave-browser", workspace = "2" }, { fullscreen = 0 })
o.window({ class = "md.obsidian.Obsidian", workspace = "3" }, { fullscreen = 0 })

-- Scratchpad Custom Look
o.window({ title = ".*000_SCRATCHPAD_Brain_Dump.*" }, { opacity = "1.0 0.1 override" })

-- Spacious Floating TUI App Sizing
o.window({ class = "org.omarchy.btop", tag = "floating-window" }, { size = { 1050, 700 } })
o.window({ class = "org.omarchy.nload", tag = "floating-window" }, { size = { 1050, 700 } })

-- Gaming Window Rules (Focus lock, true fullscreen, and low-latency tearing)
o.window("^(witcher3.exe|steam_app_.*|gamescope)$", {
  fullscreen = true,
  immediate = true,
  stay_focused = true,
})
o.window({ title = ".*Witcher 3.*" }, {
  fullscreen = true,
  immediate = true,
  stay_focused = true,
})





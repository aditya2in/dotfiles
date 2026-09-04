-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
-- Left Vertical Monitor (Straight)
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1, transform = 1 })

-- Center Ultrawide Monitor (3440x1440) - Centered vertically (Y=240) - 75Hz Native
hl.monitor({ output = "DP-2", mode = "3440x1440@75", position = "1080x240", scale = 1, transform = 0 })

-- Right Vertical Monitor (Shifted to X=4520 to accommodate Ultrawide)
hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "4520x0", scale = 1, transform = 3 })

-- Workspace Persistence Rules
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", default = true })

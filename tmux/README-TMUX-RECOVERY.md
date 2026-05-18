# Tmux Reliability & Emergency Recovery

This directory contains the configurations and scripts to ensure Tmux sessions survive system reboots and accidental blank overwrites.

## 🛠️ The Architecture

1. **Auto-Boot Service:** 
   We have enabled `set -g @continuum-boot 'on'` in `tmux.conf` and activated the systemd user service. When the computer boots, systemd starts Tmux in the background and automatically loads the last saved session from disk *before* a terminal window is opened.

2. **Conservative Saving:**
   The `tmux-continuum` save interval is set to 2 minutes (`set -g @continuum-save-interval '2'`). This provides a buffer window in case a blank session is accidentally started, preventing immediate overwrite of rich backups.

3. **Emergency Restore Script (`omarchy-restore-tmux`):**
   Located in `scripts/omarchy-restore-tmux`, this script acts as a safety net. If a blank session is saved over the good backup, running this command will scan the `~/.config/tmux/resurrect/` directory for the most recent "heavy" backup (files > 1KB), update the `last` symlink, and trigger the restore process.

## 🚀 How to use the Emergency Script

If you ever open a terminal and find your Tmux windows missing, run:
```bash
omarchy-restore-tmux
```

### Installation (If deploying to a new machine)
The script must be executable and available in your PATH:
```bash
ln -s ~/DOTfiles/tmux/scripts/omarchy-restore-tmux ~/.local/bin/omarchy-restore-tmux
chmod +x ~/.local/bin/omarchy-restore-tmux
```

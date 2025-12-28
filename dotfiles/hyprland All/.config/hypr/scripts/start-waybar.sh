# ... (rest of your script above this) ...

# Launch Waybar in the foreground initially, capturing all its output.
# Temporarily remove the '&' and redirect stderr to stdout to catch errors.
# We'll also pipe it to tee so you can see it in the terminal if you run the script manually.
# For exec-once, it will go to the log file.
# IMPORTANT: This will block the script and potentially Hyprland if Waybar doesn't exit.
# ONLY FOR DEBUGGING.
waybar 2>&1 | tee -a ~/waybar_startup_log.txt

# Do NOT add the final echo "Waybar launched..." here, as waybar won't background.
#
#
# ... (lines above) ...

# Export the PATH variable to include ~/.cargo/bin and other necessary paths
export PATH="$HOME/.cargo/bin:$PATH"

echo "$(date): Waybar startup script initiated." >> ~/waybar_startup_log.txt

# ... (rest of your script below) ...

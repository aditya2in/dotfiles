#!/bin/bash
# Watch Hyprland events and re-apply color temperature on reload/monitor connection

if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$(find /run/user/$(id -u)/hypr/ -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | head -n1)
fi
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
TEMP=4000 # Your preferred temperature (change to 3500 if preferred)

apply_temp() {
    # Ensure hyprsunset is running
    pgrep -x hyprsunset >/dev/null || { setsid uwsm-app -- hyprsunset >/dev/null 2>&1 & sleep 1; }
    # Re-apply temperature
    hyprctl hyprsunset temperature $TEMP >/dev/null 2>&1
}

# Apply on initial startup
apply_temp

# Listen for reload and monitor events
socat -U - "UNIX-CONNECT:$SOCKET" | while read -r event; do
    if [[ "$event" == configreloaded\>\>* || "$event" == monitoradded\>\>* || "$event" == monitoraddedv2\>\>* ]]; then
        sleep 0.5 # Let compositor finish loading
        apply_temp
    fi
done

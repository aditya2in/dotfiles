# waybarKillandRest.sh
echo "Script started at $(date)" # Keep for debugging
sleep 10
echo "Attempting to kill existing waybar instances..." # Keep for debugging
pkill -f waybar
echo "Launching waybar in background with setsid..." # Keep for debugging
# The crucial change: setsid before waybar
setsid waybar > /dev/null 2>&1 &
echo "Waybar launched (or attempted to launch) in background. Script finished at $(date)" # Keep for debugging

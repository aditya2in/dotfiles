#!/bin/bash

# -----------------------------------------------------------------------------
# Visual Break Countdown Locker
# -----------------------------------------------------------------------------
# This script displays a fullscreen visual countdown for the break.
# It is not a security lock, but a visual blocker to encourage taking a break.
#
# Usage: ./break_countdown_locker.sh <duration_in_seconds>
# -----------------------------------------------------------------------------

# --- Configuration ---
# Temporary file for the background image
TEMP_IMAGE="/tmp/pomodoro_break_screen.png"
# Pango font and style for the countdown text
# You can customize the font, size, and color here.
PANGO_FONT_DESC="Noto Sans Bold 150"
PANGO_COLOR="#eceff4" # A light color for good visibility

# --- Argument Check ---
if [ -z "$1" ]; then
    echo "Error: Duration in seconds is required." >&2
    exit 1
fi

# --- Main Logic ---
duration_seconds=$1

# Start swaybg in the background to display our image.
# We will kill it by its PID later.
swaybg -i "$TEMP_IMAGE" -m fill &
SWAYBG_PID=$!

# Function to clean up and exit
cleanup() {
    echo "DEBUG: Countdown finished or interrupted. Cleaning up." >&2
    kill "$SWAYBG_PID" 2>/dev/null
    rm -f "$TEMP_IMAGE"
    exit 0
}

# Trap signals to ensure cleanup happens if the script is interrupted
trap cleanup SIGINT SIGTERM

echo "DEBUG: Visual break locker started for $duration_seconds seconds. swaybg PID: $SWAYBG_PID" >&2

# --- Countdown Loop ---
current_time=$duration_seconds
while [ $current_time -gt 0 ]; do
    # Calculate remaining minutes and seconds for display
    minutes=$((current_time / 60))
    seconds=$((current_time % 60))
    
    # Format the time to always have two digits (e.g., 05:09)
    time_display=$(printf "%02d:%02d" $minutes $seconds)
    
    # Define the Pango markup for the text to be displayed
    pango_message="<span font_desc='${PANGO_FONT_DESC}' foreground='${PANGO_COLOR}'>Break Time\n${time_display}</span>"
    
    # Generate the PNG image with the message using pango-view
    # This overwrites the existing image file each time.
    pango-view --markup --text="$pango_message" \
        -o "$TEMP_IMAGE" \
        --width=1920 --height=1080 --align=center --background='rgba(30,30,46,0.95)' >/dev/null 2>&1

    # The swaybg process automatically reloads the image when it changes.
    
    sleep 1
    current_time=$((current_time - 1))
done

# --- Final Cleanup ---
cleanup

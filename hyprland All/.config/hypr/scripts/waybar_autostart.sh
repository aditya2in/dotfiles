#!/bin/bash

# Loop to keep Waybar running
while true; do
    waybar
    # If Waybar exits, wait a bit before trying to restart
    sleep 1
done

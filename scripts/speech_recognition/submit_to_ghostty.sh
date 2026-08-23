#!/bin/bash
echo "$(date '+%H:%M:%S') - submit_to_ghostty triggered" >> /tmp/submit_ghostty.log

# Send Enter to active attached pane in K8
tmux send-keys -t K8 Enter

# Quick visual confirmation on desktop
notify-send "AI Submit" "Sent Enter to Ghostty" -i input-keyboard -t 800 -h string:x-canonical-private-synchronous:ai-submit

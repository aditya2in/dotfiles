#!/bin/bash
# Send Enter (C-m) to active pane in Tmux session K8 with zero focus stealing
tmux send-keys -t K8 C-m

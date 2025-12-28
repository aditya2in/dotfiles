#!/bin/bash

# --- Configuration ---
# Set the duration to pull journal logs from. Adjust if you need more or less history.
# Default is 8 hours to cover your mentioned usage period and give some buffer.
LOG_HOURS_AGO=8
# -------------------

# Generate a timestamped filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="system_diag_logs_${TIMESTAMP}.txt"

echo "📊 Initiating comprehensive system log and diagnostics extraction..."
echo "💾 Logs will be saved to: $(pwd)/${LOG_FILE}"
echo "-----------------------------------------------------------"
echo "This script will require your sudo password for some commands."
echo "-----------------------------------------------------------"

# Start logging all output to the file
{ # This block allows redirecting all its output to the log file

    echo "--- System Diagnostics Log Start: ${TIMESTAMP} ---"
    echo ""

    echo "--- Kernel Messages (sudo dmesg) ---"
    echo "------------------------------------"
    sudo dmesg
    echo ""
    echo "--- End Kernel Messages ---"
    echo ""

    echo "--- Systemd Journal Logs (sudo journalctl --since \"${LOG_HOURS_AGO} hours ago\") ---"
    echo "------------------------------------------------------------------------------------"
    # Accessing systemd journal logs from the specified time in the past
    sudo journalctl --since "${LOG_HOURS_AGO} hours ago"
    echo ""
    echo "--- End Systemd Journal Logs (Past ${LOG_HOURS_AGO} hours) ---"
    echo ""

    echo "--- Systemd Journal Logs (sudo journalctl -b -1: Previous Boot) ---"
    echo "--------------------------------------------------------------------"
    # Accessing systemd journal logs from the previous boot.
    # This is useful if the system rebooted due to an issue.
    sudo journalctl -b -1
    echo ""
    echo "--- End Systemd Journal Logs (Previous Boot) ---"
    echo ""

    echo "--- Current Memory and Swap Usage (free -h) ---"
    echo "-----------------------------------------------"
    free -h
    echo ""
    echo "--- End Current Memory and Swap Usage ---"
    echo ""

    echo "--- Top Processes by Memory Usage (top -b -n 1 -o %MEM) ---"
    echo "-----------------------------------------------------------"
    # Captures a single snapshot of processes sorted by memory usage
    top -b -n 1 -o %MEM
    echo ""
    echo "--- End Top Processes by Memory Usage ---"
    echo ""

    echo "--- Swap Device Information (swapon -s) ---"
    echo "-------------------------------------------"
    swapon -s
    echo ""
    echo "--- End Swap Device Information ---"
    echo ""

    echo "--- Disk Space Usage (df -h) ---"
    echo "--------------------------------"
    df -h
    echo ""
    echo "--- End Disk Space Usage ---"
    echo ""

    echo "--- System Diagnostics Log End: $(date +"%Y%m%d_%H%M%S") ---"

} > "${LOG_FILE}" 2>&1 # Redirect stdout and stderr of the entire block to the log file

echo "-----------------------------------------------------------"
echo "✅ Comprehensive log extraction complete!"
echo "🎉 Your consolidated system diagnostics are saved to: $(pwd)/${LOG_FILE}"
echo "Please upload this file for analysis."

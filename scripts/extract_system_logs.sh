#!/bin/bash

# --- Configuration ---
# Set the duration to pull logs from. Adjust if you need more or less history.
# Default is 7 hours to cover your mentioned usage period.
LOG_HOURS_AGO=7
# -------------------

# Generate a timestamped filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="system_logs_${TIMESTAMP}.txt"

echo "📊 Extracting system logs from the last ${LOG_HOURS_AGO} hours..."
echo "💾 Logs will be saved to: $(pwd)/${LOG_FILE}"
echo "-----------------------------------------------------------"

# Start logging to the file
{ # This block allows redirecting all its output to the log file

    echo "--- System Log Extraction Start: ${TIMESTAMP} ---"
    echo ""

    echo "--- Kernel Messages (dmesg) ---"
    echo "-------------------------------"
    dmesg
    echo ""
    echo "--- End Kernel Messages ---"
    echo ""

    echo "--- Systemd Journal Logs (journalctl --since \"${LOG_HOURS_AGO} hours ago\") ---"
    echo "--------------------------------------------------------------------------------"
    # Using sudo for journalctl to ensure full access to all system logs.
    # It might prompt for your password if you haven't recently authenticated.
    sudo journalctl --since "${LOG_HOURS_AGO} hours ago"
    echo ""
    echo "--- End Systemd Journal Logs ---"
    echo ""

    echo "--- System Log Extraction End: $(date +"%Y%m%d_%H%M%S") ---"

} > "${LOG_FILE}" 2>&1 # Redirect stdout and stderr to the log file

echo "-----------------------------------------------------------"
echo "✅ Log extraction complete!"
echo "🎉 Your consolidated system logs are saved to: $(pwd)/${LOG_FILE}"
echo "Please upload this file for analysis."

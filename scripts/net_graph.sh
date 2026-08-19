#!/bin/bash
INTERFACE="eno1"
STATE_FILE="/tmp/net-speed-state"

curr_time=$(date +%s.%N)
read -r curr_rx curr_tx < <(awk "/$INTERFACE:/ {print \$2, \$10}" /proc/net/dev)

# Init state if missing
if [ ! -f "$STATE_FILE" ]; then
    echo "$curr_rx $curr_tx $curr_time" > "$STATE_FILE"
    echo '{"text": "󰇚 0K  󰕒 0K", "tooltip": "Initializing..."}'
    exit 0
fi

# Load previous state
read -r prev_rx prev_tx prev_time < "$STATE_FILE"

time_diff=$(awk "BEGIN {print $curr_time - $prev_time}")
if (( $(awk "BEGIN {print ($time_diff <= 0)}") )); then
    time_diff=2.0
fi

rx_speed=$(awk "BEGIN {print int(($curr_rx - $prev_rx) / $time_diff)}")
tx_speed=$(awk "BEGIN {print int(($curr_tx - $prev_tx) / $time_diff)}")
(( rx_speed < 0 )) && rx_speed=0
(( tx_speed < 0 )) && tx_speed=0

# Save state
echo "$curr_rx $curr_tx $curr_time" > "$STATE_FILE"

format_speed() {
    local bytes=$1
    if (( bytes < 1000 )); then
        # Round low speeds to 0K to prevent flickering
        echo "0K"
    elif (( bytes < 1000000 )); then
        # Round to nearest KB (e.g. 354300 -> 354K)
        echo "$(( (bytes + 500) / 1000 ))K"
    else
        # Round to nearest MB (e.g. 12500000 -> 13M)
        echo "$(( (bytes + 500000) / 1000000 ))M"
    fi
}

rx_fmt=$(format_speed $rx_speed)
tx_fmt=$(format_speed $tx_speed)

echo "{\"text\": \"󰇚 ${rx_fmt}  󰕒 ${tx_fmt}\", \"tooltip\": \"Network Live Flow (eno1)\nDown: ${rx_fmt}\nUp: ${tx_fmt}\"}"

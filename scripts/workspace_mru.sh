#!/usr/bin/env bash

STATE_FILE="/tmp/workspace_mru_state.json"

get_current_workspace() {
    local id
    id=$(hyprctl activeworkspace -j 2>/dev/null | jq '.id' 2>/dev/null)
    if [ -z "$id" ] || [ "$id" = "null" ]; then
        echo 1
    else
        echo "$id"
    fi
}

initialize_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"queue":[1],"index":0,"cycling":false}' > "$STATE_FILE"
    fi
}

run_daemon() {
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        echo "Error: HYPRLAND_INSTANCE_SIGNATURE not set" >&2
        exit 1
    fi

    # Detect socket path
    local xdg_runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local socket_path="$xdg_runtime/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    if [ ! -S "$socket_path" ]; then
        socket_path="/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    fi

    if [ ! -S "$socket_path" ]; then
        echo "Error: Socket not found at $socket_path" >&2
        exit 1
    fi

    initialize_state

    # Initialize queue with current workspace
    local curr
    curr=$(get_current_workspace)
    jq --argjson ws "$curr" '.queue = ([$ws] + (.queue - [$ws]))' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    # Listen to the Hyprland socket
    socat - UNIX-CONNECT:"$socket_path" | while read -r line; do
        if [[ "$line" =~ ^workspace\>\> ]]; then
            local ws_id
            ws_id=$(echo "$line" | cut -d'>' -f3)
            
            # Only update history when not actively cycling
            local cycling
            cycling=$(jq '.cycling' "$STATE_FILE")
            if [ "$cycling" = "false" ]; then
                jq --argjson ws "$ws_id" '.queue = ([$ws] + (.queue - [$ws]))' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
            fi
        fi
    done
}

cycle() {
    initialize_state

    # Get active workspaces list (greater than 0)
    local active_ws
    active_ws=$(hyprctl workspaces -j 2>/dev/null | jq -c '[.[].id | select(. > 0)]' 2>/dev/null)
    if [ -z "$active_ws" ] || [ "$active_ws" = "null" ]; then
        active_ws="[]"
    fi

    # Read current queue
    local queue
    queue=$(jq -c '.queue' "$STATE_FILE")

    # Clean the queue to keep only active workspaces, appending any new ones
    local new_queue
    new_queue=$(jq -n --argjson q "$queue" --argjson a "$active_ws" '
        ($q | map(select(. as $x | $a | contains([$x])))) as $filtered |
        $filtered + ($a | map(select(. as $x | $filtered | contains([$x]) | not)))
    ')

    local len
    len=$(echo "$new_queue" | jq '. | length')
    if [ "$len" -eq 0 ]; then
        new_queue="[1]"
        len=1
    fi

    local cycling
    cycling=$(jq '.cycling' "$STATE_FILE")
    local index
    index=$(jq '.index' "$STATE_FILE")

    if [ "$cycling" = "false" ]; then
        cycling="true"
        index=$(( 1 % len ))
    else
        index=$(( (index + 1) % len ))
    fi

    local target_ws
    target_ws=$(echo "$new_queue" | jq --argjson idx "$index" '.[$idx]')

    # Save state
    jq -n --argjson q "$new_queue" --argjson idx "$index" --argjson cy "$cycling" --argjson tg "$target_ws" \
        '{"queue":$q, "index":$idx, "cycling":$cy, "target":$tg}' > "$STATE_FILE"

    # Dispatch workspace switch
    hyprctl dispatch workspace "$target_ws"
}

reset_state() {
    initialize_state
    local cycling
    cycling=$(jq '.cycling' "$STATE_FILE")
    if [ "$cycling" = "true" ]; then
        local curr
        curr=$(jq '.target' "$STATE_FILE")
        if [ -z "$curr" ] || [ "$curr" = "null" ]; then
            curr=1
        fi
        jq --argjson ws "$curr" '.queue = ([$ws] + (.queue - [$ws])) | .cycling = false | .index = 0' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi
}

case "$1" in
    --daemon)
        run_daemon
        ;;
    --cycle)
        cycle
        ;;
    --reset)
        reset_state
        ;;
    *)
        echo "Usage: $0 [--daemon|--cycle|--reset]" >&2
        exit 1
        ;;
esac

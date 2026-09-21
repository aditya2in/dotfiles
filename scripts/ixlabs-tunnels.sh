#!/bin/bash
# ixlabs-tunnels.sh — manage iximiuz Labs tunnels (SSH into EVERY machine + kubectl)
#
# Usage:
#   ixlabs-tunnels.sh [PLAY_ID] start     # start all tunnels (auto-detects the running play)
#   ixlabs-tunnels.sh [PLAY_ID] stop      # stop every tunnel
#   ixlabs-tunnels.sh status              # what is running + the machine map
#   ixlabs-tunnels.sh [PLAY_ID] kubeconfig
#
# Machine map:
#   dev-machine  → localhost:2222 → ssh ixlabs
#   cplane-01    → localhost:2223 → ssh ixlabs-cp
#   node-01      → localhost:2224 → ssh ixlabs-n1
#   node-02      → localhost:2225 → ssh ixlabs-n2
#
# History:
#   2026-09-19  Created (single machine: 2222).
#   2026-09-19  v2 — all four machines, auto-detect play, richer status.

# NOTE: intentionally NOT `set -e` — pkill returns 1 when nothing matches.

KUBECONFIG_DIR="$HOME/.iximiuz/labctl/plays"
LOG_DIR="/tmp"
SSH_KEY="$HOME/.ssh/iximiuz_labs_user"

# machine -> local port
MACHINES=(dev-machine cplane-01 node-01 node-02)
declare -A PORT=( [dev-machine]=2222 [cplane-01]=2223 [node-01]=2224 [node-02]=2225 )
declare -A ALIAS=( [dev-machine]=ixlabs [cplane-01]=ixlabs-cp [node-01]=ixlabs-n1 [node-02]=ixlabs-n2 )

# ── helpers ────────────────────────────────────────────────────────────────
detect_play() {
  labctl playground list 2>/dev/null | grep -E 'RUNNING' | grep -oE '^[0-9a-f]{24}' | head -1
}

kubeconfig_path() {
  ls -1 "$KUBECONFIG_DIR"/"${1}"-*/kubeconfig 2>/dev/null | head -1
}

# ── arg parsing ───────────────────────────────────────────────────────────
#   `ixlabs-tunnels.sh <action>`            (no play id → auto-detect)
#   `ixlabs-tunnels.sh <PLAY_ID> <action>`  (explicit play id)
case "${1:-}" in
  status|start|stop|kubeconfig)
    PLAY_ID=""; ACTION="$1" ;;
  *)
    PLAY_ID="${1:-}"; ACTION="${2:-start}" ;;
esac

# ── actions ───────────────────────────────────────────────────────────────
case "$ACTION" in
  start)
    [ -z "$PLAY_ID" ] && PLAY_ID="$(detect_play)"
    if [ -z "$PLAY_ID" ]; then
      echo "✗ No running play found. Start one first (or pass a PLAY_ID)." >&2
      exit 1
    fi
    echo "▶ play: $PLAY_ID"
    echo

    # clean up any stale tunnels first (a play restart changes VM addresses,
    # and a stale kube-proxy keeps holding port 6443)
    pkill -f "labctl ssh-proxy" 2>/dev/null
    pkill -f "labctl kube-proxy" 2>/dev/null
    sleep 2

    # SSH tunnels — one per machine
    for m in "${MACHINES[@]}"; do
      p="${PORT[$m]}"
      log="$LOG_DIR/labctl-ssh-$m.log"
      ( setsid labctl ssh-proxy "$PLAY_ID" -m "$m" --address "localhost:$p" > "$log" 2>&1 < /dev/null & )
      printf "  ssh-proxy  %-12s localhost:%-5s → %s\n" "$m" "$p" "ssh ${ALIAS[$m]}"
    done

    # kubectl tunnel
    log="$LOG_DIR/labctl-kube-proxy.log"
    ( setsid labctl kube-proxy "$PLAY_ID" > "$log" 2>&1 < /dev/null & )
    echo "  kube-proxy             localhost:6443  → kubectl (kube-lab)"
    echo
    sleep 8

    echo "── kubectl ──"
    KUBECONF="$(kubeconfig_path "$PLAY_ID")"
    if [ -n "$KUBECONF" ]; then
      cp -f "$KUBECONF" "$HOME/.kube/ixlabs-k8s-omni.yaml" 2>/dev/null
      echo "  export KUBECONFIG=$HOME/.kube/ixlabs-k8s-omni.yaml"
      echo "  (copied to \$HOME/.kube/ixlabs-k8s-omni.yaml — used by \`kube-lab\`)"
    else
      echo "  kubeconfig not ready yet — check $LOG_DIR/labctl-kube-proxy.log"
    fi
    echo
    echo "── ssh ──"
    for m in "${MACHINES[@]}"; do
      echo "  ssh ${ALIAS[$m]}    → $m"
    done
    echo
    echo "SSH key: $SSH_KEY"
    echo "SSH config must contain Host blocks for each alias (see ~/.ssh/config)."
    ;;

  stop)
    pkill -f "labctl ssh-proxy" 2>/dev/null && echo "stopped ssh-proxies" || echo "ssh-proxies not running"
    pkill -f "labctl kube-proxy" 2>/dev/null && echo "stopped kube-proxy" || echo "kube-proxy not running"
    ;;

  status)
    echo "── tunnels ──"
    for m in "${MACHINES[@]}"; do
      if pgrep -f "labctl ssh-proxy.*-m $m" >/dev/null 2>&1; then
        printf "  ✓ %-12s localhost:%-5s ssh %s\n" "$m" "${PORT[$m]}" "${ALIAS[$m]}"
      else
        printf "  ✗ %-12s (not running)\n" "$m"
      fi
    done
    pgrep -f "labctl kube-proxy" >/dev/null 2>&1 \
      && echo "  ✓ kube-proxy   localhost:6443  kubectl" \
      || echo "  ✗ kube-proxy   (not running)"
    echo
    echo "── listeners ──"
    ss -ltn 2>/dev/null | grep -E ':(2222|2223|2224|2225|6443)' || echo "  (none)"
    echo
    echo "── running plays ──"
    labctl playground list 2>/dev/null | head -5
    ;;

  kubeconfig)
    [ -z "$PLAY_ID" ] && PLAY_ID="$(detect_play)"
    [ -z "$PLAY_ID" ] && { echo "✗ no running play" >&2; exit 1; }
    kubeconfig_path "$PLAY_ID"
    ;;

  *)
    echo "usage: $0 [PLAY_ID] {start|stop|status|kubeconfig}" >&2
    exit 1
    ;;
esac

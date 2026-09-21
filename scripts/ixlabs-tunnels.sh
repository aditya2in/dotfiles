#!/bin/bash
# ixlabs-tunnels.sh — manage iximiuz Labs tunnels (SSH into EVERY machine + kubectl)
#
# Usage:
#   ixlabs-tunnels.sh resume             # ONE COMMAND: restart the play if stopped,
#                                        #   rebuild all tunnels, refresh kubeconfig, verify
#   ixlabs-tunnels.sh [PLAY_ID] start    # (re)build tunnels for a running play
#   ixlabs-tunnels.sh [PLAY_ID] stop
#   ixlabs-tunnels.sh status
#   ixlabs-tunnels.sh [PLAY_ID] kubeconfig
#
# Machine map:
#   dev-machine  → localhost:2222 → ssh ixlabs
#   cplane-01    → localhost:2223 → ssh ixlabs-cp
#   node-01      → localhost:2224 → ssh ixlabs-n1
#   node-02      → localhost:2225 → ssh ixlabs-n2
#   cluster      → localhost:6443 → kubectl (kube-lab)
#
# History:
#   2026-09-19  Created (single machine).
#   2026-09-19  v2 — all four machines, auto-detect play, richer status.
#   2026-09-21  v3 — `resume` action (auto-restart stopped play + rebuild + verify);
#                    `start` now clears stale tunnels first (fixes 6443 port conflicts).

# NOTE: intentionally NOT `set -e` — pkill returns 1 when nothing matches.

KUBECONFIG_DIR="$HOME/.iximiuz/labctl/plays"
KUBECONFIG_OUT="$HOME/.kube/ixlabs-k8s-omni.yaml"
LOG_DIR="/tmp"

MACHINES=(dev-machine cplane-01 node-01 node-02)
declare -A PORT=( [dev-machine]=2222 [cplane-01]=2223 [node-01]=2224 [node-02]=2225 )
declare -A ALIAS=( [dev-machine]=ixlabs [cplane-01]=ixlabs-cp [node-01]=ixlabs-n1 [node-02]=ixlabs-n2 )

# ── helpers ────────────────────────────────────────────────────────────────
# Most recent play id (running or stopped), from `labctl playground list`
detect_play() {
  labctl playground list 2>/dev/null \
    | awk 'NR>1 && $1 ~ /^[0-9a-f]+$/ {print $1; exit}'
}

play_state() {
  labctl playground status "$1" 2>/dev/null | awk -F': *' '/^State:/{print $2; exit}'
}

kubeconfig_path() {
  ls -1 "$KUBECONFIG_DIR"/"${1}"-*/kubeconfig 2>/dev/null | head -1
}

wait_for_ssh() {
  local tries="${1:-12}"
  for _ in $(seq 1 "$tries"); do
    if ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
         ixlabs "true" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  return 1
}

start_tunnels() {
  local play="$1"
  echo "▶ play: $play"

  # clear stale tunnels (a play restart changes VM addresses; a stale
  # kube-proxy keeps holding 6443)
  pkill -f "labctl ssh-proxy" 2>/dev/null
  pkill -f "labctl kube-proxy" 2>/dev/null
  sleep 2

  for m in "${MACHINES[@]}"; do
    p="${PORT[$m]}"
    ( setsid labctl ssh-proxy "$play" -m "$m" --address "localhost:$p" \
        > "$LOG_DIR/labctl-ssh-$m.log" 2>&1 < /dev/null & )
    printf "  ssh-proxy  %-12s localhost:%-5s → ssh %s\n" "$m" "$p" "${ALIAS[$m]}"
  done
  ( setsid labctl kube-proxy "$play" > "$LOG_DIR/labctl-kube-proxy.log" 2>&1 < /dev/null & )
  echo "  kube-proxy             localhost:6443  → kubectl (kube-lab)"
  echo
  sleep 8

  local conf; conf="$(kubeconfig_path "$play")"
  if [ -n "$conf" ]; then
    cp -f "$conf" "$KUBECONFIG_OUT" && chmod 600 "$KUBECONFIG_OUT"
    echo "  kubeconfig → $KUBECONFIG_OUT"
  else
    echo "  ⚠ kubeconfig not ready — see $LOG_DIR/labctl-kube-proxy.log"
  fi
}

verify() {
  echo "── verify ──"
  for h in ixlabs ixlabs-cp ixlabs-n1 ixlabs-n2; do
    printf "  %-12s → " "$h"
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "$h" "hostname" 2>/dev/null || echo "✗"
  done
  printf "  %-12s → " "kubectl"
  kubectl --kubeconfig "$KUBECONFIG_OUT" get nodes --no-headers --request-timeout=10s 2>/dev/null \
    | awk '{print $1}' | tr '\n' ' ' | sed 's/ $//' || echo "✗"
  echo
}

# ── arg parsing ───────────────────────────────────────────────────────────
#   `ixlabs-tunnels.sh <action>`            (no play id → auto-detect)
#   `ixlabs-tunnels.sh <PLAY_ID> <action>`  (explicit play id)
case "${1:-}" in
  status|start|stop|kubeconfig|resume)
    PLAY_ID=""; ACTION="$1" ;;
  *)
    PLAY_ID="${1:-}"; ACTION="${2:-start}" ;;
esac

# ── actions ───────────────────────────────────────────────────────────────
case "$ACTION" in
  resume)
    [ -z "$PLAY_ID" ] && PLAY_ID="$(detect_play)"
    if [ -z "$PLAY_ID" ]; then
      echo "✗ No play found. Start one in iximiuz Labs first." >&2
      exit 1
    fi
    STATE="$(play_state "$PLAY_ID")"
    echo "▶ play $PLAY_ID · state: $STATE"
    if printf '%s' "$STATE" | grep -qi '^STOPPED'; then
      echo "↻ restarting the stopped play …"
      labctl playground restart "$PLAY_ID" >/dev/null 2>&1
      sleep 10
    fi

    start_tunnels "$PLAY_ID"
    echo
    echo "… waiting for the VMs to answer on SSH"
    wait_for_ssh 12 || echo "  ⚠ SSH not answering yet — give it a minute and run: kube-tunnels start"
    echo
    verify
    ;;

  start)
    [ -z "$PLAY_ID" ] && PLAY_ID="$(detect_play)"
    if [ -z "$PLAY_ID" ]; then
      echo "✗ No running play found. Start one first (or pass a PLAY_ID)." >&2
      exit 1
    fi
    start_tunnels "$PLAY_ID"
    echo
    echo "When the VMs are up:  ssh ixlabs   ·   kube-lab && kubectl get nodes"
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
    echo "usage: $0 [PLAY_ID] {resume|start|stop|status|kubeconfig}" >&2
    exit 1
    ;;
esac

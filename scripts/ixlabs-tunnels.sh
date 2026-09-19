#!/bin/bash
# ixlabs-tunnels.sh — start/stop iximiuz Labs SSH + kubectl tunnels for a play
#
# Usage:
#   ixlabs-tunnels.sh <PLAY_ID> start    # start ssh-proxy (:2222) + kube-proxy
#   ixlabs-tunnels.sh <PLAY_ID> stop     # stop both
#   ixlabs-tunnels.sh status             # show running tunnels + kubeconfig paths
#
# After `start`:
#   ssh ixlabs                                    # SSH into the VM (alias in ~/.ssh/config)
#   export KUBECONFIG=$(ixlabs-tunnels.sh kubeconfig <PLAY_ID>)
#   kubectl get nodes                             # local kubectl -> remote cluster
#
# History:
#   2026-09-19  Created. Wraps `labctl ssh-proxy` + `labctl kube-proxy`.

set -euo pipefail

# Accept: `status` alone, or `<PLAY_ID> <action>`
if [ "${1:-}" = "status" ]; then
  PLAY_ID=""; ACTION="status"
else
  PLAY_ID="${1:-}"; ACTION="${2:-start}"
fi

KUBECONFIG_DIR="$HOME/.iximiuz/labctl/plays"
SSH_LOG="/tmp/labctl-ssh-proxy.log"
KUBE_LOG="/tmp/labctl-kube-proxy.log"

kubeconfig_path() {
  local play="$1"
  ls -1 "$KUBECONFIG_DIR"/"${play}"-*/kubeconfig 2>/dev/null | head -1
}

case "$ACTION" in
  start)
    [ -z "$PLAY_ID" ] && { echo "usage: $0 <PLAY_ID> start" >&2; exit 1; }
    echo "starting ssh-proxy on localhost:2222 …"
    nohup labctl ssh-proxy "$PLAY_ID" --address localhost:2222 > "$SSH_LOG" 2>&1 < /dev/null &
    echo "starting kube-proxy (forwards 127.0.0.1:6443 → cluster) …"
    nohup labctl kube-proxy "$PLAY_ID" > "$KUBE_LOG" 2>&1 < /dev/null &
    sleep 8
    echo
    echo "── ssh ──"; grep -m1 "SSH proxy is running" "$SSH_LOG" || true
    echo "  → ssh ixlabs"
    echo
    echo "── kubectl ──"; grep -m1 "Kubeconfig saved to" -A1 "$KUBE_LOG" || true
    echo "  → export KUBECONFIG=$(kubeconfig_path "$PLAY_ID" 2>/dev/null || echo "$KUBECONFIG_DIR/<play>-cplane-01-laborant/kubeconfig")"
    ;;
  stop)
    pkill -f "labctl ssh-proxy" 2>/dev/null && echo "stopped ssh-proxy" || echo "ssh-proxy not running"
    pkill -f "labctl kube-proxy" 2>/dev/null && echo "stopped kube-proxy" || echo "kube-proxy not running"
    ;;
  status)
    pgrep -af "labctl ssh-proxy" || echo "ssh-proxy: not running"
    pgrep -af "labctl kube-proxy" || echo "kube-proxy: not running"
    ls -1 "$KUBECONFIG_DIR" 2>/dev/null | sed 's/^/kubeconfig: /' || true
    ;;
  kubeconfig)
    [ -z "$PLAY_ID" ] && { echo "usage: $0 <PLAY_ID> kubeconfig" >&2; exit 1; }
    kubeconfig_path "$PLAY_ID"
    ;;
  *)
    echo "usage: $0 <PLAY_ID> {start|stop|status|kubeconfig}" >&2
    exit 1
    ;;
esac

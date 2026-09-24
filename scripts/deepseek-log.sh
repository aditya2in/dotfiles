#!/bin/bash
# deepseek-log.sh — append the current DeepSeek API balance to the usage CSV.
#
# WHY THIS EXISTS
#   DeepSeek's public API exposes ONLY /user/balance (GET). There is NO usage /
#   token-history endpoint (verified 2026-09-24: /user/usage, /usage,
#   /user/token_usage, /billing/usage all return HTTP 404). Daily spend is
#   visible only in the private web dashboard (platform.deepseek.com/usage),
#   which has no stable API.
#   So the ONLY way to build real per-day history is to sample the balance
#   ourselves. This script does exactly that.
#
# HOW IT IS DRIVEN
#   systemd user units (see ~/DOTfiles/services/):
#     - deepseek-log.timer    -> login/boot + every 1 hour
#     - deepseek-logout.service -> on session logout (ExecStop)
#
# OUTPUT
#   ~/DOTfiles/deepseek/usage.csv   (header: timestamp_ist,balance_usd,tag)
#   The day-to-day DIFFERENCES are the real spend; idle days show no change.
#
# USAGE
#   deepseek-log.sh [tag]        # tag: login | hourly | logout | manual (default: manual)
#
# Exit codes: 0 ok · 1 no key · 2 request failed · 3 unparseable response
set -u

CSV_DIR="$HOME/DOTfiles/deepseek"
CSV="$CSV_DIR/usage.csv"
ENV_FILE="$HOME/.config/deepseek/env"
TAG="${1:-manual}"

# ── load the API key ──────────────────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  set -a; . "$ENV_FILE"; set +a
fi
if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  echo "deepseek-log: no DEEPSEEK_API_KEY (looked in $ENV_FILE)" >&2
  exit 1
fi

# ── fetch the balance ─────────────────────────────────────────────────────
resp=$(curl -sS --max-time 20 https://api.deepseek.com/user/balance \
         -H "Authorization: Bearer $DEEPSEEK_API_KEY" 2>/dev/null) || {
  echo "deepseek-log: request failed" >&2; exit 2; }

usd=$(printf '%s' "$resp" | jq -r '.balance_infos[0].total_balance // empty' 2>/dev/null)
if [ -z "$usd" ]; then
  echo "deepseek-log: could not parse balance from response" >&2
  exit 3
fi

# ── append to the CSV ─────────────────────────────────────────────────────
mkdir -p "$CSV_DIR"
if [ ! -f "$CSV" ]; then
  echo "timestamp_ist,balance_usd,tag" > "$CSV"
fi
ts=$(TZ=Asia/Kolkata date '+%Y-%m-%d %H:%M:%S')
echo "$ts,$usd,$TAG" >> "$CSV"
echo "deepseek-log: $ts  \$$usd  ($TAG)"

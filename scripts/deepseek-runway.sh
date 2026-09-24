#!/bin/bash
# deepseek-runway.sh — print the "Runway" report from the DeepSeek usage CSV.
#
# Reads ~/DOTfiles/deepseek/usage.csv (written by deepseek-log.sh) and derives
# the honest burn model:
#   * spend is measured from the DIFFERENCES between consecutive samples
#   * only NEGATIVE diffs count as spend; POSITIVE diffs are top-ups (reported,
#     never counted as negative spend)
#   * a "usage day" = a day whose total spend > 0; "idle days" cost $0.00
#   * gaps (long periods with no samples) are simply not averaged in
#   * confidence rises with the number of usable deltas
#
# Note: no ASCII box is drawn on purpose — box-drawing and ₹ are multi-byte,
# so byte-padding mis-aligns. Plain lines stay clean on any terminal.
#
# Usage: deepseek-runway.sh [csv-path]
set -u

CSV="${1:-$HOME/DOTfiles/deepseek/usage.csv}"
[ -f "$CSV" ] || { echo "deepseek-runway: no CSV yet at $CSV"; exit 1; }

rate=$(curl -sS --max-time 10 https://open.er-api.com/v6/latest/USD 2>/dev/null \
         | jq -r '.rates.INR // empty' 2>/dev/null)

awk -F, -v rate="${rate:-0}" '
NR==1 { next }
NF<2  { next }
{
  ts=$1; bal=$2+0
  if (first=="") first=ts
  last=ts; lastbal=bal; n++
  if (p!="") {
    d = bal - p
    day = substr(ts,1,10)
    if (d < -0.0001) { sp[day] += -d; tot += -d; deltas++ }
    else if (d > 0.0001) { top += d }
  }
  p = bal
}
END {
  udays=0; for (day in sp) udays++
  avg  = (udays>0) ? tot/udays : 0
  left = (avg>0)    ? lastbal/avg : 0
  inr  = (rate>0)   ? lastbal*rate : 0
  conf = (deltas>=10) ? "HIGH" : (deltas>=4 ? "MED" : "LOW")

  cells=14; filled=(left>=60)?cells:int((left>0 ? left : 0)/60*cells)
  bar=""
  for (i=0;i<cells;i++) bar = bar ((i<filled) ? "#" : "-")

  print ""
  print "💰 DEEPSEEK RUNWAY"
  print "──────────────────────────────────"
  printf "BALANCE     : $%.2f  (INR %.0f)\n", lastbal, inr
  printf "RATE        : 1 USD = INR %.2f\n", rate
  printf "USAGE-DAY   : $%.2f   (a day you actually used it)\n", avg
  printf "IDLE-DAY    : $0.00   (no usage = no cost)\n"
  printf "TOP-UPS     : $%.2f   (since logging began)\n", top
  printf "LEFT        : ~%.0f usage-days\n", left
  printf "RUNWAY      : [%s]\n", bar
  printf "SAMPLES     : %d   DELTAS: %d   CONFIDENCE: %s\n", n, deltas, conf
  print "──────────────────────────────────"
  if (udays>0)
    printf "  first: %s\n  last : %s\n  %d usage-day(s) over %d sample(s)\n\n", first, last, udays, n
  else
    print "  need >=2 usable samples to compute a rate\n"
}
' "$CSV"

#!/usr/bin/env bash
# list-sessions.sh — List all session IDs recorded in the JSONL log file.
#
# Usage:
#   list-sessions.sh [logfile]
#
# Arguments:
#   logfile  Path to the JSONL log file (default: .agent-cmd-history.jsonl)
#
# Requires: jq

set -euo pipefail

LOGFILE="${1:-.agent-cmd-history.jsonl}"

if [ ! -f "$LOGFILE" ]; then
  echo "Error: Log file not found: $LOGFILE" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

echo "Sessions in $LOGFILE:"
echo ""
printf "  %-24s  %-14s  %6s  %s\n" "SESSION ID" "AGENT" "CMDS" "TIME RANGE"
printf "  %-24s  %-14s  %6s  %s\n" "----------" "-----" "----" "----------"

jq -sr '
  group_by(.session)
  | map({
      session: .[0].session,
      agent: .[0].agent,
      count: length,
      first: (map(.timestamp) | sort | first),
      last: (map(.timestamp) | sort | last)
    })
  | sort_by(.first)
  | .[]
  | "\(.session)\t\(.agent)\t\(.count)\t\(.first) → \(.last)"
' "$LOGFILE" | while IFS=$'\t' read -r session agent count range; do
  printf "  %-24s  %-14s  %6s  %s\n" "$session" "$agent" "$count" "$range"
done

echo ""
TOTAL=$(jq -sr 'map(.session) | unique | length' "$LOGFILE")
echo "Total: $TOTAL session(s)"

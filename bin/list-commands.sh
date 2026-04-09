#!/usr/bin/env bash
# list-commands.sh — List all terminal commands from a specific agent session.
#
# Usage:
#   list-commands.sh <session-id> [logfile]
#
# Arguments:
#   session-id  The session ID to filter by (e.g. 2026-04-08-a3f2)
#   logfile     Path to the JSONL log file (default: .agent-cmd-history.jsonl)
#
# Requires: jq

set -euo pipefail

SESSION_ID="${1:-}"
LOGFILE="${2:-.agent-cmd-history.jsonl}"

if [ -z "$SESSION_ID" ]; then
  echo "Usage: list-commands.sh <session-id> [logfile]" >&2
  exit 1
fi

if [ ! -f "$LOGFILE" ]; then
  echo "Error: Log file not found: $LOGFILE" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

COUNT=0
while IFS= read -r line; do
  COUNT=$((COUNT + 1))
  CMD=$(echo "$line" | jq -r '.cmd')
  EXIT=$(echo "$line" | jq -r '.exit // "?"')
  TS=$(echo "$line" | jq -r '.timestamp')
  CWD=$(echo "$line" | jq -r '.cwd')
  printf "  %3d  [%s] [exit %s] %s\n      cwd: %s\n" "$COUNT" "$TS" "$EXIT" "$CMD" "$CWD"
done < <(jq -c "select(.session == \"$SESSION_ID\")" "$LOGFILE")

if [ "$COUNT" -eq 0 ]; then
  echo "No commands found for session: $SESSION_ID" >&2
  exit 1
fi

echo ""
echo "Total: $COUNT command(s) in session $SESSION_ID"

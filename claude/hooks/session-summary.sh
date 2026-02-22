#!/bin/bash
# Stop hook — log session summary when Claude Code session ends

LOG_DIR="$HOME/.claude/session-logs"
mkdir -p "$LOG_DIR"

input=$(cat)

# Extract fields from Stop event
if command -v jq >/dev/null 2>&1; then
    session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
    cwd=$(echo "$input" | jq -r '.cwd // "unknown"')
elif command -v python3 >/dev/null 2>&1; then
    session_id=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id','unknown'))" 2>/dev/null)
    cwd=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd','unknown'))" 2>/dev/null)
else
    session_id="unknown"
    cwd="$(pwd)"
fi

LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"

{
    echo "=== Session End ==="
    echo "Timestamp:  $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Session ID: $session_id"
    echo "Directory:  $cwd"
    echo ""
} >> "$LOG_FILE"

exit 0

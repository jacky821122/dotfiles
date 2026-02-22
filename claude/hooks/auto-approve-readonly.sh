#!/bin/bash
# PermissionRequest hook — auto-approve read-only tool operations

input=$(cat)

# Extract tool name
if command -v jq >/dev/null 2>&1; then
    tool_name=$(echo "$input" | jq -r '.tool_name // ""')
elif command -v python3 >/dev/null 2>&1; then
    tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
else
    exit 0
fi

case "$tool_name" in
    Read|Glob|Grep|LS|TodoRead)
        echo '{"decision": "approve", "reason": "Read-only operation"}'
        ;;
    *)
        exit 0
        ;;
esac

#!/bin/bash
# PostToolUse hook — run linter after Edit or Write and surface issues to Claude

input=$(cat)

# Extract file path from tool input
if command -v jq >/dev/null 2>&1; then
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
elif command -v python3 >/dev/null 2>&1; then
    file_path=$(echo "$input" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)
fi

[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

ext="${file_path##*.}"
output=""

case "$ext" in
    py)
        if command -v flake8 >/dev/null 2>&1; then
            output=$(flake8 --max-line-length=120 "$file_path" 2>&1) || true
        fi
        ;;
    js|jsx|mjs|cjs)
        if command -v eslint >/dev/null 2>&1; then
            output=$(eslint "$file_path" 2>&1) || true
        fi
        ;;
    ts|tsx)
        if command -v eslint >/dev/null 2>&1; then
            output=$(eslint "$file_path" 2>&1) || true
        fi
        ;;
    go)
        if command -v golint >/dev/null 2>&1; then
            output=$(golint "$file_path" 2>&1) || true
        fi
        ;;
    sh|bash)
        if command -v shellcheck >/dev/null 2>&1; then
            output=$(shellcheck "$file_path" 2>&1) || true
        fi
        ;;
esac

if [ -n "$output" ]; then
    echo "Linter output for $file_path:"
    echo "$output"
fi

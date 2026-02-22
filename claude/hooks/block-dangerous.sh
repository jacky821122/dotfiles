#!/bin/bash
# PreToolUse hook — block dangerous bash commands before execution

input=$(cat)

# Extract the command string from tool input
if command -v jq >/dev/null 2>&1; then
    cmd=$(echo "$input" | jq -r '.tool_input.command // ""')
elif command -v python3 >/dev/null 2>&1; then
    cmd=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)
else
    exit 0
fi

deny() {
    echo "{\"decision\": \"deny\", \"reason\": \"Dangerous command blocked: $1. Use with care.\"}"
    exit 0
}

# Broad recursive deletes
if echo "$cmd" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+(\/|~|\.\s*$|\.\/)'; then
    deny "rm -rf on root/home/current directory"
fi

# Force push
if echo "$cmd" | grep -qE 'git\s+push\s+.*(--force|-f)'; then
    deny "git push --force"
fi

# Hard reset
if echo "$cmd" | grep -qE 'git\s+reset\s+--hard'; then
    deny "git reset --hard"
fi

# git clean -f
if echo "$cmd" | grep -qE 'git\s+clean\s+.*-f'; then
    deny "git clean -f"
fi

# Disk operations
if echo "$cmd" | grep -qE '>\s*/dev/sd[a-z]|dd\s+if='; then
    deny "raw disk write operation"
fi

# chmod -R 777
if echo "$cmd" | grep -qE 'chmod\s+-R\s+777'; then
    deny "chmod -R 777"
fi

# Fork bomb
if echo "$cmd" | grep -qF ':(){ :|:&};:'; then
    deny "fork bomb"
fi

exit 0

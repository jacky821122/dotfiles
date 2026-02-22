#!/bin/bash
# SessionStart hook — runs when a new Claude Code session begins
# Output is shown as context to Claude

echo "=== Session Context ==="
echo "Directory: $(pwd)"
echo "Date: $(date)"

# Git context if available
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Branch: $(git branch --show-current 2>/dev/null)"
    echo "Recent commits:"
    git log --oneline -3 2>/dev/null
fi

# Note project CLAUDE.md presence
if [ -f "CLAUDE.md" ]; then
    echo "Project CLAUDE.md: present"
fi

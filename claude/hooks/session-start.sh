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

# Surface a handoff note left by a previous session in this directory (see /handoff skill).
# Output is injected as context for the model; the user does not see it (silent by design).
if [ -f "HANDOFF.md" ]; then
    echo "=== HANDOFF (from previous session) ==="
    echo "mtime: $(date -r HANDOFF.md '+%Y-%m-%d %H:%M' 2>/dev/null)"
    handoff_lines=$(wc -l < HANDOFF.md 2>/dev/null || echo 0)
    if [ "$handoff_lines" -gt 80 ]; then
        head -80 HANDOFF.md
        echo "... (truncated; $handoff_lines lines total — read HANDOFF.md in full if you need the rest)"
    else
        cat HANDOFF.md
    fi
    echo "=== end HANDOFF (may be stale — confirm with the user before trusting it) ==="
fi

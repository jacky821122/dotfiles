---
name: setup-hooks
description: Help configure Claude Code hooks in settings.json and hook scripts. Use when the user wants to add, modify, or understand hooks.
argument-hint: "[hook-type] [description-of-what-to-do]"
user-invocable: true
allowed-tools: Read, Edit, Write, WebFetch
---

Help the user configure Claude Code hooks.

Steps:
1. Read `~/.claude/settings.json` and `~/.claude/hooks/` to understand current setup
2. Fetch the official hooks documentation to understand available hook types and exact format
3. Based on $ARGUMENTS, add or modify the appropriate hook
4. Update the hook script under `~/.claude/hooks/` (symlinked to `~/dotfiles/claude/hooks/`)
5. Update `settings.json` to reference the hook script if needed

Available hook events:
SessionStart, UserPromptSubmit, PreToolUse, PermissionRequest, PostToolUse,
PostToolUseFailure, Notification, SubagentStart, SubagentStop, Stop,
TeammateIdle, TaskCompleted, ConfigChange, WorktreeCreate, WorktreeRemove,
PreCompact, SessionEnd

Hook script output format for PermissionRequest:
- Approve: `{"decision": "approve", "reason": "..."}`
- Deny: `{"decision": "deny", "reason": "..."}`
- Pass-through: exit 0 with no output

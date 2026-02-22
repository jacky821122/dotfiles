# Global Claude Instructions

## Working Style

- For non-trivial tasks, always start with plan mode to align on approach before writing code
- Keep conversation sessions clean: discuss and review here, dispatch subagents or worktrees for actual code changes
- Make minimal, targeted changes — don't refactor beyond what's asked, don't add unnecessary comments or type annotations
- After completing changes, do a brief self code review

## Useful Patterns

- Double ESC or /rewind to undo the last message (including code state)
- Use `!command` prefix in the input box to run bash commands and share output directly
- CLAUDE.md is hierarchical — use `@path/to/file` in project CLAUDE.md to reference shared rules
- Set up hooks for repetitive actions (see `~/.claude/skills/setup-hooks/`)

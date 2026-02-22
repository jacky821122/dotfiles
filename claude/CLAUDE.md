# Global Claude Instructions

## Working Style

- For non-trivial tasks, always start with plan mode to align on approach before writing any code
- Make minimal, targeted changes — do not refactor, rename, or add comments beyond what was explicitly asked
- After completing changes, do a brief self code review: check for consistency with surrounding style, missed edge cases, and anything that looks off

## Session Management

- Keep the conversation session for discussion and review only; dispatch subagents or worktrees for the actual code changes
- One session = one concern: do not mix unrelated tasks in the same conversation
- Use /rewind (or double ESC) to undo the last exchange including any code changes

## Project Onboarding

- At the start of a session in an unfamiliar project, read CLAUDE.md first, then do a brief structural scan (key directories, entry points, test setup) before touching any code
- If the project has no CLAUDE.md, ask the user whether they want one before starting work

## CLAUDE.md Hierarchy

- Project CLAUDE.md takes precedence over this global file
- Use `@path/to/file` imports in a project CLAUDE.md to pull in shared rules
- Keep project CLAUDE.md committed to git so the whole team benefits; use CLAUDE.local.md for personal overrides that should not be shared

## Code Quality

- If linting or test output appears after an edit, read it before declaring the task done
- Never leave a TODO comment without first asking the user if they want it addressed now
- Do not add logging, debug output, or temporary scaffolding without noting it explicitly

## Shortcuts

- `!command` — run a bash command and share output directly in this session
- `/rewind` or double ESC — undo last message and revert code changes
- `/setup-hooks` — add or modify a Claude Code hook

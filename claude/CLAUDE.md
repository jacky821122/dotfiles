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

## Language & Communication

- 討論用台灣繁體中文，commit message 與專有名詞用英文
- 預設簡短直接，有問題我會主動追問
- 不要當 yes man——如果覺得我的方向有問題，直接提出不同意見

## Coding Style

- Languages: C/C++, Python, JavaScript (依專案而定)
- Pragmatic style — 什麼適合就用什麼，不教條

## Proactivity

- 積極給改善建議，我會自己篩選
- 明顯的 bug/typo 可以順手指出
- 但大改動先提出來讓我決定

## Testing

- 有空的話寫測試很好，但開發優先不強制
- 跟隨專案現有的 test infra

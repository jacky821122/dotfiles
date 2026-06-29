---
name: handoff
description: Write a clean session handoff note to HANDOFF.md in the current directory so the next Claude Code session can pick up where this one left off. Use whenever the user wants to hand off, switch session, clear/clean the context window, or says things like "整理摘要給下段 session", "換 session", "清理 context", "做個 handoff", "交接", or invokes /handoff. The next session's SessionStart hook loads this file automatically (silently).
argument-hint: "[optional: focus or extra note for the next session]"
user-invocable: true
allowed-tools: Bash, Read, Write
---

# Session Handoff

Produce a clean, distilled handoff note for the **next** Claude Code session and write it to `HANDOFF.md` in the **current working directory** (overwrite — only the latest baton is kept).

This is global and project-agnostic. Do NOT touch any project's PLAN/ARCHITECTURE/README files. The only output is `HANDOFF.md`.

## Principles

- **Distill, don't dump.** Extract decisions and current state from this conversation. Deliberately DROP debug noise, tool output, abandoned detours, and dead ends — the user switches sessions precisely to shed that clutter.
- **The locked-decisions block is the most important part.** It tells the next session what NOT to re-litigate.
- **Keep it short.** Aim well under 80 lines. Long-term decision history belongs in the project's own docs, not here.
- **Overwrite, don't append.** `HANDOFF.md` holds exactly one handoff (the latest).

## Steps

1. Gather light context: `date '+%Y-%m-%d %H:%M'`, and if in a git repo, `git branch --show-current` and `git log --oneline -3`.

2. Mentally review this conversation and extract:
   - one-line background (what this work is)
   - locked decisions the next session must not reopen
   - current state (branch, latest relevant commit, what was just finished)
   - the concrete next step(s)
   - open questions still awaiting the user's call
   - whether you'd recommend the next session start in plan mode

3. Write `HANDOFF.md` in the current directory with exactly this structure (fill in; omit a section only if genuinely empty):

   ```
   # Handoff — <project/dir name> @ <YYYY-MM-DD HH:MM>
   > Written by /handoff. Read this, then confirm with the user before trusting it — it may be stale. Tell me when consumed so I can clear it.

   ## 一句話背景

   ## 🔒 已鎖定決策（不要重新討論）
   - ...

   ## 現況（branch / 最近 commit / 剛完成）

   ## 下一步

   ## 開放問題 / 待使用者拍板

   ## 建議下個 session 進 plan mode？ yes/no
   ```

4. Tell the user it's written. Remind them: just open a new session in this directory — the SessionStart hook loads `HANDOFF.md` automatically (silently, into the model's context). When they confirm it's consumed, offer to clear/overwrite it.

If the user passed an argument, fold it in as extra emphasis for the next session.

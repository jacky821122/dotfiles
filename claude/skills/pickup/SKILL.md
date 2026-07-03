---
name: pickup
description: Pick up the handoff note (HANDOFF.md) left by a previous Claude Code session, verify it against the real repo state, align with the user, then prepare to implement — and clear the stale baton once it's consumed. Use at the start of a session whenever the user wants to continue prior work or says things like "接棒", "接手上段", "接續之前", "繼續上一個 session", "延續 handoff", "開始實作剛剛交接的東西", or invokes /pickup. This is the receiving counterpart to /handoff. The SessionStart hook already injected HANDOFF.md into context (possibly truncated) — this skill turns that raw baton into a verified, aligned starting point.
argument-hint: "[optional: what to focus on this session]"
user-invocable: true
allowed-tools: Bash, Read, Write, EnterPlanMode
---

# Session Pickup

Receive the handoff note left by the previous session, verify it against reality, align with the user, then prepare to implement. Clear the stale baton once it has been consumed.

This is the receiving end of `/handoff`. The `/handoff` skill wrote `HANDOFF.md` in the working directory; the SessionStart hook injected it into this session's context (silently, and truncated to the first 80 lines if it's long). The note itself asks the next session to "confirm before trusting it — it may be stale" and to "clear it once consumed". This skill does exactly that.

## Principles

- **Trust, but verify.** The handoff describes the world as of its own timestamp. Between then and now, commits may have landed, the tree may have changed, or the previous session may have been wrong. Reconcile every concrete claim (branch, commit, "剛完成", files touched) against actual state before you act on it.
- **Honor the locked decisions.** The `🔒 已鎖定決策` block is the load-bearing part of the baton — it tells you what NOT to re-open. Respect it unless reality contradicts it. Don't re-litigate settled choices; that defeats the purpose of handing off.
- **Align before building.** The user switched sessions and may have half-paged-out the context themselves. A short, accurate restatement lets them catch drift before you write code.
- **The handoff is a safety baton — don't drop it early.** Deleting `HANDOFF.md` before the work is genuinely picked up loses the thread if this session goes sideways. Clear it only after it's consumed and the user says so.

## Steps

1. **Read the full handoff.** The SessionStart hook only injected the first 80 lines. Read `HANDOFF.md` in the current directory in full — the `下一步` and open-questions sections often sit near the bottom and are the whole point. If there is no `HANDOFF.md`, tell the user there's no baton to pick up and ask what they'd like to work on.

2. **Verify freshness against reality.** In parallel, gather:
   - `date '+%Y-%m-%d %H:%M'` — compare to the handoff's timestamp / mtime; flag if it's noticeably old.
   - `git branch --show-current`, `git log --oneline -5`, `git status --short` — check the claimed branch, latest commit, and "剛完成" against what's actually there.
   - Spot-check any files or paths the handoff claims it created or changed.

   Note every mismatch. A handoff that says "on branch X, just committed Y, tree clean" against a dirty tree or a different HEAD is a signal the baton is stale or someone else moved — surface it, don't paper over it.

3. **Distill and confirm with the user.** Before doing any work, restate concisely:
   - the one-line background and the concrete next step
   - the locked decisions you intend to honor
   - any staleness or mismatch you found in step 2, called out plainly
   - the open questions the handoff left for the user to decide

   Ask the user to confirm or correct. This is the "confirm before trusting" the handoff itself requested. If they passed an argument to `/pickup`, treat it as their focus for this session and weight your framing toward it.

4. **Offer to clear the baton.** Once the user confirms the handoff is understood and correct (it's now consumed), proactively offer to clear `HANDOFF.md` — so a later session doesn't pick up an outdated baton and act on it. Don't delete silently or unprompted; offer, and on the user's yes, `rm HANDOFF.md`. Mention that `/handoff` will write a fresh one whenever they next hand off. If the user would rather keep it a bit longer (e.g. until real progress supersedes it), respect that.

5. **Prepare to implement.** If the handoff's `建議下個 session 進 plan mode` is **yes**, enter plan mode (EnterPlanMode) to design the next step before touching code — this matches the previous session's judgment that the work is multi-file or needs architectural decisions. Otherwise, proceed directly into the next step. Either way you now have a verified, aligned starting point rather than a raw, possibly-stale note.

## Notes

- This skill is global and project-agnostic. The only file it may remove or overwrite is `HANDOFF.md`; never touch a project's own PLAN / ARCHITECTURE / README docs.
- Steps 3 and 4 are the heart of it: the baton is only worth as much as the alignment it produces. A silent "ok I read it" is not a pickup.

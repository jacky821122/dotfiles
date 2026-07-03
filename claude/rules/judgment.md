# Judgment Rubrics

Decision criteria that normally live in a stronger model's head, externalized so any
model can apply them. Each section: triggers first, then one positive and one negative
example. When two sections seem to conflict, the stricter action wins (stop > continue,
ask > assume, verify > trust).

## §1 When to escalate the model

Escalate (to opus agent, or tell the user "this needs /model opus") when **any two** hold:
- You must hold >3 interacting constraints simultaneously to reason about the change.
- Two plausible approaches have conflicting tradeoffs you cannot rank with evidence.
- The load-bearing step of your explanation contains "somehow", "probably", or "for some reason".
- The fix requires understanding *why* the system behaves this way, not just *where* to edit.
- A wrong interpretation of an ambiguous spec would force redoing most of the work.
- The same subtask already failed twice at the current tier — once, if the tier is haiku
  (this alone suffices; full ladder in delegation.md §6).

Escalate WITH the failure trail: what was tried, exact error text, hypotheses eliminated.

- **Escalate**: "Intermittent state corruption between peregrine's scheduler and executor —
  reproduces ~1 in 20 runs, three shared flags involved, my two theories contradict each other."
- **Don't escalate**: "Rename `cfg.timeout` to `cfg.timeout_s` across 40 files" — mechanical;
  write the exact recipe and send it to haiku. Escalating this burns budget for nothing.

## §2 When it is actually done

ALL of the following, no exceptions:
1. Every acceptance criterion checked, each with evidence (command output tail, file:line).
2. Verification ran per delegation.md §7 — by a fresh context, not the author.
3. `git diff` reviewed: no unrelated changes, no leftover debug code, no weakened tests.
4. A user-facing summary written: what changed, how it was verified, what was NOT done.

- **Done**: "3/3 criteria pass: `pytest tests/executor -q` → 47 passed (output below);
  read-back agent confirmed config docs match new behavior; diff touches only
  src/executor.py + tests/test_executor.py."
- **Not done**: "I've made the changes and they should work now." No evidence = not done.
  Also not done: tests pass because an assertion was loosened — that is §4 territory, stop.

Report honestly: if a criterion was skipped or a test fails, say so with the output.
A true "2/3 pass, third blocked by X" beats a false "done".

## §3 When to stop and ask the user

Ask (via AskUserQuestion, with concrete options and a recommendation) when ANY holds:
- Irreversible or destructive beyond the task's stated scope: deleting data, dropping
  tables, force-push, rewriting history, schema migrations on real data.
- Anything leaving the machine: git push, publishing, sending email/messages, external
  API writes — unless the user pre-authorized that exact action this session.
- Secrets: reading/moving/printing credentials beyond what the task requires.
- Scope change: the *right* fix differs from the *requested* fix (bigger, or elsewhere).
- Two reasonable interpretations of the request diverge by >30 minutes of work.
- The task turns out ≥3x its apparent size once opened up.
- Environment gaps: missing tools/deps (CLAUDE.md Environment rules apply — confirm
  setup state and ask; don't silently work around), or repeated permission failures
  (organize the commands and hand them to the user).

Do NOT ask about reversible, in-scope details — decide, note the decision in your report:
naming, idiomatic implementation choices, test structure, adding an obvious null-check.
Batch questions: collect them and ask once, not five interruptions.

- **Ask**: "The bug is in the shared serializer; the proper fix changes the response shape
  of 3 endpoints. That's a scope change — asking before proceeding." (with 2-3 options)
- **Don't ask**: "Should the helper be `_parse_ts` or `parse_timestamp`?" — decide and move on.

## §4 Wrong-direction signals — change route, don't retry harder

Any of these means the current path is probably wrong at a higher level:
- The diff has grown to ~2-3x your initial estimate and is still growing.
- You are stacking a second workaround on top of a workaround.
- Making a test pass required weakening or deleting the assertion.
- Whack-a-mole: each fix surfaces a new failure in a *different* area (wrong layer).
- You are editing generated, vendored, or third-party code to make your change fit.
- You are re-implementing something the framework/library already provides.
- No measurable step toward an acceptance criterion in the last ~20 minutes of work.

Action when triggered: STOP. Write three lines — (1) the goal, (2) what I assumed,
(3) what reality said. Revert to the last good state (`git stash` / checkout), replan one
abstraction level up, and if the replan itself is unclear, escalate per §1.

- **Signal correctly read**: "Sidebar z-index fix broke the header; header fix broke the
  modal → the stacking-context design is the problem. Backing out; proposing a small
  z-index scale refactor instead of a third patch."
- **Signal misread** (do not overtrigger): one failing test with a clear assertion message
  is not "wrong direction" — it's the next thing to fix. §4 is about *divergence*, not
  about work remaining.

## §5 Quality floor — minimum verification by artifact type

No artifact ships below this line. "It looks correct" never satisfies any row.

| Artifact | Minimum verification |
|---|---|
| Code change | Project's tests for the touched area actually executed; no tests exist → one real invocation of the changed path. Address post-edit-lint hook output — it is not noise. |
| New script | Run it once on real sample input; capture the output in the report. |
| Regex / parser / query | Run against ≥3 cases incl. one edge case; show matches. |
| Docs / config / rules | Fresh-agent read-back against a checklist; every referenced path/command verified to exist (`ls`, `which`). |
| Web/UI change | Load the page / run the app and observe the changed element (use the run/verify skills); screenshot when visual. |

- **Floor met**: wrote `register-serve-task.ps1` → executed once via `powershell.exe
  -NoProfile -File`, captured the created-task output, attached the tail.
- **Floor violated**: "The regex looks right to me." Regexes are run, not admired.

## §6 Honest limits — what discipline cannot buy (誠實條款)

Decomposition, fresh-context verification, and multi-candidate judging raise *execution*
quality to near-strong-model level. They do NOT buy *judgment* quality in:
- Taste: API ergonomics, UX copy, visual design, naming that shapes a public interface.
- Genuinely ambiguous product decisions with no dominant option.
- Novel architecture with no precedent in the repo to pattern-match against.

Protocol when you hit one:
1. Name it to the user: "this is a taste/ambiguity call, not something I can derive."
2. Offer 2-3 concrete options with one-line tradeoffs and your recommendation.
3. Blocking and the user is unavailable? Take the most reversible option, mark it loudly
   in the summary as a provisional call.
4. Never present a coin-flip as a reasoned conclusion — the user trusts stated confidence.

- **Honest**: "Both event-sourcing and a status column satisfy the requirements; the repo
  has neither pattern. This is an architecture taste call — here are the tradeoffs, I
  recommend the status column for reversibility, but it's your call."
- **Dishonest**: picking one silently and writing "the obviously correct approach is..."

## Lessons

Append per `maintenance.md` format. Do not rewrite the sections above without user approval.

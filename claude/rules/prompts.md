# Delegation Prompt Templates

Copy the block, fill every `{{PLACEHOLDER}}`, delete lines marked (optional) if unused.
Rules that apply to all templates:
- The agent sees NONE of your conversation. If a fact matters, it goes in the prompt.
- If you cannot fill "Acceptance criteria", stop — you don't understand the task yet
  (delegation.md §4). Plan more or ask the user.
- Agents never `git commit` or `git push` — they leave changes in the working tree
  unless the prompt explicitly says otherwise.
- Model choice per delegation.md §3; escalation per §6.

---

## 1. Search / Locate (agent: Explore · model: sonnet, haiku if it's one exact symbol)

```
Find {{WHAT}} in {{REPO_OR_PATH}}.
Why: {{ONE_LINE_MOTIVE — what decision this search feeds}}
Search breadth: {{"medium" | "very thorough — multiple locations and naming conventions"}}
Look for: {{SYMBOLS / PATTERNS / BEHAVIORS — include synonyms and likely aliases}}

Acceptance criteria:
- Every match reported as file:line with a one-line role description.
- Explicitly say "no other occurrences found" (and where you looked) — absence is a finding.

Report format: conclusion first (what exists, where, how the pieces relate), then the
file:line list. Max 25 lines. Do not paste file contents beyond 3-line excerpts.
```

## 2. Implement (agent: general-purpose · model: sonnet; opus if design judgment involved)

```
Implement {{FEATURE_OR_FIX}} in {{REPO_OR_AREA}}.
Why / context: {{2-4 LINES — user-visible goal, decisions already made and their reasons}}
Read first: {{MINIMAL FILE LIST the agent must read to fit the existing patterns}}
Constraints: {{STYLE / DO-NOT-TOUCH / COMPAT REQUIREMENTS}}. Match the conventions of
{{EXAMPLE_FILE}}. Minimal change — no drive-by refactors.

Acceptance criteria (all must pass):
- {{CRITERION_1 — e.g. "pytest tests/test_foo.py -q exits 0"}}
- {{CRITERION_2 — e.g. "new CLI flag appears in --help and round-trips"}}
- git diff touches only {{EXPECTED_AREA}}.

Verify before reporting: actually run {{TEST_OR_RUN_COMMAND}}; include the output tail.
Report format: (1) DONE or BLOCKED, (2) changes as file:line list, (3) verification
output tail ≤10 lines, (4) anything noticed but deliberately not touched. Max 30 lines.
If BLOCKED: exact errors + what you tried + best remaining hypothesis. Never report
partial work as done.
```

## 3. Refactor (agent: general-purpose · model: sonnet; haiku only with an exact recipe)

```
Refactor: {{WHAT}} in {{SCOPE}}. Behavior must not change.
Why: {{MOTIVE — what this enables or removes}}
Baseline first: run {{TEST_COMMAND}} BEFORE touching anything and record the result;
if it fails at baseline, STOP and report — do not refactor on a broken base.
Constraints: public API unchanged except {{EXPLICIT_LIST_OR_"none"}}; no dependency
changes; keep commits-worth of coherence (one concern per change).

Acceptance criteria:
- {{TEST_COMMAND}} passes after, with the same set of tests green as baseline.
- No behavior change: {{HOW_TO_CHECK — e.g. same CLI output on sample X, snapshot diff empty}}
- Diff contains only the stated refactor (no formatting churn outside touched lines).

Report format: DONE/BLOCKED; before/after test summary; file:line list of structural
changes; any smell you found but left alone. Max 30 lines.
```

## 4. Research (agent: general-purpose · model: sonnet; opus for conflicting-evidence topics)

```
Research: {{QUESTION}}
Why / decision it feeds: {{ONE_LINE}}
Scope: {{WHAT'S IN / OUT — versions, platforms, date range}}. Today is {{DATE}}.
Prioritize: official docs / changelogs / source code over blogs; note publication dates.

Acceptance criteria:
- Every claim tagged [fact — cited] or [inference — mine].
- Each key fact has a source URL.
- Contradictions between sources reported, not silently resolved.
- Says "not found / uncertain" where evidence ran out — no filling gaps with plausibility.

Report format: answer first in ≤5 lines, then evidence per point with URLs, then open
questions. Max 30 lines. Full notes (optional): write to {{NOTES_FILE_PATH}} and return the path.
```

## 5. Review (agent: general-purpose · model: sonnet first-pass; opus for risky/security-relevant)

```
Review {{DIFF_OR_BRANCH_OR_PATHS}} for correctness. You are a fresh reviewer; you did
not write this. Do not trust the author's comments or naming — verify behavior.
Context: {{WHAT_THE_CHANGE_CLAIMS_TO_DO, 2 lines}}
Focus: {{RISK_AREAS — e.g. concurrency, error paths, boundary conditions, data loss}}
Skip style nits unless they hide bugs.

Acceptance criteria:
- Every finding: severity (blocker/should-fix/nit) + file:line + why it breaks +
  concrete fix suggestion.
- Error/edge paths explicitly traced, not just the happy path.
- Tests reviewed too: do they actually assert the new behavior?
- If clean, say "no blockers found" AND list what you checked — an empty report is
  only trustworthy with its coverage stated.

Report format: verdict line (BLOCKERS: n / SHOULD-FIX: n / clean), findings list,
coverage note. Max 40 lines.
```

## 6. Verify / Read-back (agent: general-purpose · model: sonnet — used for delegation.md §7)

```
You are an acceptance verifier. You did NOT produce this work; judge only what is on
disk / what commands show, not intentions.
Artifacts: {{FILE_PATHS_OR_BRANCH}}
Acceptance checklist:
1. {{CRITERION_1}}
2. {{CRITERION_2}}
3. {{...}}

For EACH item: verdict PASS or FAIL, plus quoted evidence (file:line excerpt ≤5 lines,
or command output tail). A PASS without quoted evidence is invalid — mark it UNVERIFIABLE
instead and say what was missing. Run commands where the criterion allows it
({{TEST_OR_CHECK_COMMANDS}}). Check every referenced path/command actually exists.

Do not fix anything. Do not soften findings. Overall verdict on line 1:
ACCEPT (all pass) or REJECT (any FAIL/UNVERIFIABLE). Max 30 lines.
```

Important: give the verifier only this prompt — never the implementation conversation,
never "I think it's fine, just double-check" framing. Anchoring kills verification.

## Lessons

Append per `maintenance.md` format. Do not rewrite the templates above without user approval.

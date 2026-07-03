# Harness Diagnosis — 2026-07-03

Snapshot audit of this Claude Code environment, written by Fable 5 as the evidence base
for the rules in this directory. Numbers below are real, measured from session transcripts.
Re-run the audit with the procedure at the bottom when this file is >3 months old.

**Method**: aggregated 5 recent large transcripts under `~/.claude/projects/`
(Antares x2, peregrine, quests, AI-conversation-archive; Jun 21 - Jul 3, 2026) with `jq`:
tool-call histograms, tool_result sizes, per-call token usage, model mix, sidechain counts.

---

## Finding 1 — Monolithic marathon sessions, everything on the max-price model

**Evidence**:
- Antares session `fe70d095` (Jul 3): 437 API calls, **82.3M cache-read tokens**,
  avg ~188k tokens of context carried per call, 100% claude-opus-4-8.
- peregrine session `897635fe` (Jul 2): 476 API calls, **81.3M cache-read tokens**,
  avg ~171k/call, 100% opus.
- All 5 sampled sessions: 100% Opus, zero model tiering. Live settings `model` had
  drifted to `claude-fable-5[1m]` while the repo default is `opusplan` (Opus for plan
  mode, Sonnet for execution) — the tiering the repo intended was not actually running.

**Why it matters**: cost ≈ context-mass x turns x model-weight. In a 450-turn session,
every 10k tokens of dead weight in context is re-read ~450 times ≈ 4-5M extra cache-read
tokens. On a Max subscription this is what exhausts the rate-limit window.

**Fix (applied/written)**:
- Default model set back to `opusplan` (live settings.json fixed this session; repo copy
  already correct — bootstrap re-applies it).
- Model assignment matrix + delegation thresholds → `delegation.md`.
- Session hygiene rule (handoff at task boundaries instead of 400-turn monoliths)
  → CLAUDE.md Operating Core.

## Finding 2 — Zero delegation: all bulk work runs in (and stays in) the main context

**Evidence**:
- `"isSidechain":true` count across all 5 transcripts: **0**. The Agent tool is never used.
- All scanning/reading/editing happens in the main thread: 62-84 Bash + 20-47 Edit +
  8-31 Read calls per session, every byte of which is context for hundreds of later turns.
- Same file Read **12 times** in one session (`Antares/src/antares/lab/factor_ga.py`) —
  re-reading after edits instead of trusting the edit result.
- Screenshots/PNGs read directly into main context (`/tmp/shots/*.png`, Antares Jul 2) —
  each image occupies ~1-1.5k tokens in every subsequent turn.

**Why it matters**: tool results that enter the main context are paid for on *every*
subsequent API call. A subagent pays for its reading once and returns only conclusions.
(Counterweight: a subagent cold-start costs roughly 10-20k tokens of its own system prompt
and briefing — delegation pays off for bulk work, not for single small lookups.)

**Fix (written)**: delegation doctrine with concrete spawn/don't-spawn thresholds,
report contract, escalation ladder → `delegation.md`; fill-in templates → `prompts.md`;
no-re-read and range-read discipline → `delegation.md` anti-patterns.

## Finding 3 — No externalized definition-of-done or verification loop

**Evidence** (structural, softer than 1-2):
- No acceptance criteria, verification requirements, or done-definition exist anywhere in
  the config; "done" is whatever the model in the moment feels is done.
- Marathon sessions (437-476 turns, 41-62 Edits) show long fix-adjust-fix tails
  consistent with churn rather than converging on checked criteria.

**Why it matters**: this is the failure mode that gets *worse* as models get weaker.
Opus with the user watching converges anyway; Sonnet/Haiku unattended will declare
victory early, self-certify, and churn. Judgment must live in files, not in the model.

**Fix (written)**: done/escalate/stop/wrong-direction rubrics with examples →
`judgment.md`; verification-never-self-certified rule → `delegation.md` §7 +
`prompts.md` Verify template.

---

## Secondary observations (not top-3, worth knowing)

- **Bootstrap merge semantics**: `bootstrap.sh` overwrites local `model`, `hooks`,
  `permissions` from the repo copy on every run. The repo is the source of truth;
  editing only the live `~/.claude/settings.json` for those keys silently reverts at
  next bootstrap.
- **GitHub MCP server** (~30 tools) duplicates the `gh` CLI that CLAUDE.md already
  prefers. Tools are deferred (near-zero context cost), and the `pr-review` skill uses
  them — leave installed; not a leak.
- **Statusline** runs `npx -y ccstatusline@latest` — a network fetch and unpinned
  supply-chain surface on every session, zero token cost. Optional: pin a version.
- **Hooks are lean and good** (session-start ~15 lines of output; block-dangerous;
  post-edit-lint). post-edit-lint can dump long linter output on messy files —
  acceptable, monitor.
- **Memory feature unused**: project memory dirs are empty as of 2026-07. Project-level
  durable facts should start going into per-project memory (see letter, item 3).
- **NAS constraint**: one machine runs Claude Code locked at 2.1.25 (newer versions hang).
  Rules in this directory must not assume features newer than that on the NAS; verify the
  Agent tool's capabilities there before relying on them.
- **AskUserQuestion usage is healthy** (4-5/session) — the user genuinely answers.
  Weaker models should ask *more*, not less, when criteria in `judgment.md` §3 are met.

## Honest limits — what these rules can and cannot compensate

Can compensate (execution quality): cost discipline, focus, verification rigor,
error-recovery, consistent reporting. Decomposition + fresh-context verification +
multi-candidate judging genuinely lift weak-model output.

Cannot compensate (judgment quality): taste (API ergonomics, UX copy, visual design),
genuinely ambiguous product decisions, novel architecture with no precedent in the repo.
Protocol when hit: `judgment.md` §6 — name it, offer options with a recommendation,
escalate to opus max-effort, or state plainly that the call needs the user. Never dress
up a coin-flip as analysis.

## Re-audit procedure

```bash
# biggest recent transcripts
ls -lS ~/.claude/projects/*/*.jsonl | head -8
# per file ($f): tool mix / result mass / model mix / delegation & interrupts
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$f" | sort | uniq -c | sort -rn | head
jq -r 'select(.type=="user") | .message.content[]? | select(.type?=="tool_result") | (.content | if type=="array" then (map(.text? // "") | join("")) elif type=="string" then . else "" end) | length' "$f" | awk '{n++;s+=$1;if($1>10000)b++} END{printf "results=%d chars=%d over10k=%d\n",n,s,b}'
jq -r 'select(.type=="assistant") | .message.usage? | select(.) | [(.input_tokens//0),(.cache_read_input_tokens//0),(.output_tokens//0)] | @tsv' "$f" | awk -F'\t' '{i+=$1;cr+=$2;o+=$3;n++} END{printf "calls=%d in=%d cache_read=%d out=%d\n",n,i,cr,o}'
jq -r 'select(.type=="assistant") | .message.model // empty' "$f" | sort | uniq -c
grep -c '"isSidechain":true' "$f"
```
Compare against this file's numbers; if cache-read per session hasn't dropped materially,
the delegation rules are not being followed — see `letter-to-future-sessions.md`,
「這套制度最可能的退化方式」 item 1.

# Model Dispatch & Delegation Rules

Why this exists: the 2026-07 audit (`diagnosis-2026-07.md`) measured ~80M cache-read
tokens per session — 400+ turns each carrying ~180k tokens of context, 100% on Opus,
zero delegation. On a Max subscription the budget is the rolling rate-limit window, and
cost ≈ context-mass x turns x model-weight. These rules cut all three factors.

## §0 Decision flow (route every piece of work through this)

1. Is it a decision, a plan, or a conversation with the user? → main session does it.
2. Is it bulk (see §1 triggers)? → delegate with the triad (§4), using a template from `prompts.md`.
3. Is it small and the location is known? → main session does it directly.
4. Is it finished work needing acceptance? → fresh verifier agent (§7), never the author.
5. Did the same approach just fail twice? → stop; escalate or replan (§6), never a third identical try.

## §1 The commander rule

The main session plans, delegates, integrates, decides, and talks to the user.
It does not do bulk work itself, because everything that enters the main context is
re-paid on every later turn (450-turn session → one 10k-token file read costs ~4.5M
cache-read tokens over its lifetime).

Delegate when ANY of these holds:
- Finding something across >3 files or unknown locations → Explore agent
- Expected reading >~300 lines to answer a single question
- Any web research beyond fetching one known URL
- Repo-wide survey ("how is X handled everywhere", inventories, dependency maps)
- Batch mechanical edits across >5 files
- Independent verification of completed work (§7 — always)

Do it yourself (do NOT spawn) when:
- The target file/lines are known and total reading is <~300 lines
- One command with short output answers it
- It's iterative design work with the user (plan mode, question rounds)

Spawn overhead is real: each agent cold-starts (~10-20k tokens of its own system prompt
+ your briefing) and knows nothing you don't tell it. Spawning an agent to read one
small file costs more than reading it.

## §2 Agent types

Check the current session's system-reminder list — types vary by version. Typical set:
- **Explore** — read-only search/scan; returns locations and conclusions, cheapest for "find/where/how many".
- **Plan** — implementation planning, architecture options.
- **general-purpose** — full tools; implementation, research, batch edits, verification.
- **claude-code-guide** — questions about Claude Code / Agent SDK / Claude API features.
  Use it instead of guessing harness behavior; check for an already-running one first.
If a type listed here is missing in the session, fall back to general-purpose.
Depth is 1: commander → agents. Agents do not spawn agents.
NAS caveat: the NAS runs Claude Code locked at 2.1.25 — verify the Agent tool and its
`model` param exist there before building a plan around them.

## §3 Model assignment

Environment models as of 2026-07 (verify with `/model` if in doubt):
Haiku 4.5 (`claude-haiku-4-5-20251001`), Sonnet 4.6 (`claude-sonnet-4-6`),
Opus 4.8 (`claude-opus-4-8`) — ID formats genuinely differ (some carry date suffixes);
never construct an ID by analogy. Prefer the Agent tool aliases: `haiku` | `sonnet` | `opus`.
Default session model is `opusplan` (Opus in plan mode, Sonnet executing) — keep it.

- **haiku** — mechanical work with a known pattern: bulk renames, apply-this-exact-recipe
  edits, format fixes, extract-a-list-from-files, simple lookups. Must receive an exact
  recipe and examples, not an open problem.
- **sonnet** (default) — anything with a clear spec: search synthesis, standard
  implementation, tests, refactors with a defined target, first-pass review, read-back
  verification.
- **opus** — judgment-heavy: ambiguous debugging, architecture, cross-cutting design,
  security-sensitive review, final review of high-risk changes, anything already failed
  twice at sonnet (§6).

Budget note (Max subscription): list-price input ratio Haiku:Sonnet:Opus ≈ 1:3:5
(early-2026 prices); subscription quota weighting is unpublished but Opus drains the
window several times faster than Sonnet. Prefer sonnet-parallel over opus-serial.
If the harness warns about approaching limits: downshift models, defer batch work.

Effort: session-wide only — `/effort` command (levels: low | medium | high | xhigh | max,
verified on CC 2.1.183) or the `effortLevel` key in `~/.claude/settings.json` (persistent
default; currently medium). Reserve max for the hardest work. The Agent tool has NO
per-agent effort param (verified on CC 2.1.183); control agent depth via model choice
and prompt scope instead.

## §4 The delegation triad — every Agent prompt contains all three

1. **Goal + why**: the outcome wanted, plus enough motive/context that the agent can make
   sane micro-decisions without you.
2. **Acceptance criteria**: checkable statements — "all tests in tests/foo pass",
   "returns file:line for every match", "build exits 0". Never vibes ("works well").
3. **Report format**: what to return, max length, where long artifacts go.

If you cannot write the acceptance criteria, you do not understand the task yet —
go back to planning. Do not delegate your confusion.
Templates with all three built in: `~/.claude/rules/prompts.md`.

## §5 Report contract (include in every delegation prompt)

Agent side:
- Verdict/answer first, then evidence as `file:line` references, then recommended next
  action if relevant. Max ~30 lines.
- Long output (logs, research notes, generated code) → write to a file, return the path.
- Quote ≤10 lines per excerpt; never paste whole files back.
- Cannot meet the acceptance criteria? Say BLOCKED explicitly, return the failure trail
  (what you tried, exact error text, hypotheses eliminated), and stop. No padding,
  no partial success dressed as success.

Commander side:
- Relay the agent's conclusions to the user — agent output is never shown to them directly.
- To continue with an existing agent's context, use SendMessage (if the session offers it)
  instead of cold-starting a new agent and re-briefing.

## §6 Escalation & de-escalation ladder

- haiku fails once → resend to **sonnet** (same prompt + haiku's failure attached).
- sonnet fails the same subtask twice → send to **opus** WITH the full failure trail:
  what was tried, exact errors, hypotheses eliminated. Escalating without the trail makes
  the expensive model rediscover everything.
- Once opus (or the user) cracks it and the same pattern applies elsewhere → write the
  solution as an exact recipe and batch-apply with **haiku/sonnet** (de-escalation).
- Hard cap (= the two-strike rule, CLAUDE.md Core #4): nothing gets a third identical
  attempt. After two failures of one approach at a tier (one failure, if the tier is
  haiku), the next attempt must change something structural: the model tier (this ladder),
  the approach itself, or asking the user. A model escalation resets the attempt count at
  the new tier. If even opus fails twice, the approach is wrong, not the model — replan
  per `judgment.md` §4.
- If the main session itself is out of depth (`judgment.md` §1): tell the user plainly
  "this needs `/model opus`" (or spawn an opus agent and hand it the full context).

## §7 Verification is never self-certified

- Whoever produced the work does not judge its acceptance.
- Files/docs/rules → a fresh sonnet agent reads them back against the acceptance checklist
  and must quote evidence per item (template: `prompts.md`, template 6 "Verify / Read-back").
- Code → run the real thing: tests, build, or one actual invocation of the changed path.
  "It should work" is not verification (`judgment.md` §5).
- High-risk judgment → second opinion from opus, or generate 2-3 candidates and have a
  separate judge agent pick with reasons.
- Give the verifier the acceptance criteria and artifact paths, NOT the implementer's
  chat history — no anchoring on what the author believed.

## §8 Parallelism & session shape

- Independent subtasks → spawn agents in parallel in one message; cap ~3 concurrent
  (beyond that, integration review becomes the bottleneck).
- Long independent work → background agents (`run_in_background`) if available; check
  their result before relying on it.
- Session hygiene: at a task boundary where most context is stale, `/handoff` + fresh
  session (CLAUDE.md Operating Core #5). A 400-turn monolith is a failure signal even
  when each turn looks productive.

## §9 Anti-patterns (each observed in this environment or predicted for weak models)

- Spawning an agent to read one known small file. Just read it.
- Delegating without acceptance criteria ("look into X and report back").
- Escalating to opus without the failure trail.
- Using opus for mechanical batch work.
- Agent chains (agent spawns agent). Depth is 1.
- Re-reading a file right after your own successful Edit "to double-check" — the harness
  errors loudly on failed edits; trust it. (2026-07 audit: one file re-read 12x in a session.)
- Reading screenshots/images into the main context when an agent can look and report —
  every image costs ~1-1.5k tokens on every subsequent turn.
- Retrying a permission-denied tool call verbatim. A denial is the user saying no —
  adjust the approach or ask.

## Lessons

Append per `maintenance.md` format. Do not rewrite the sections above without user approval.

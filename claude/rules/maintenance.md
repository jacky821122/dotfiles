# Rules Maintenance Protocol

How any future session — including weak models — updates the files in this directory
without degrading them. Scope: everything under `~/.claude/rules/`, `~/.claude/CLAUDE.md`,
`settings.json`, `hooks/`, `skills/` (all git-tracked in `~/dotfiles/claude/`, most
symlinked into `~/.claude/`).

## §1 Edit rights

**Self-serve** (do it, then mention it in your report to the user):
- Append a dated entry to a file's `## Lessons` section (format in §3).
- Fix factual rot with evidence: a referenced path/command/agent-type/model that no longer
  exists (verify with `ls` / `which` / the session's system-reminder lists, quote the
  evidence in the Lesson you add alongside the fix).
- Typo fixes that cannot change meaning.

**Ask the user first** (show the exact proposed diff, wait for approval):
- Changing or deleting any existing rule, threshold, or template.
- Adding a new rule outside a Lessons section.
- Anything in `CLAUDE.md`, `settings.json`, `hooks/`, `bootstrap.sh`.
- Deleting or renaming files.
- Changing the model matrix or escalation ladder in `delegation.md`.

When unsure which bucket applies: it's the ask-first bucket.

## §2 Edit procedure (every time, no exceptions)

1. Backup: `cp <file> ~/.claude/backups/<name>.$(date +%Y-%m-%d).bak`
   (`~/.claude/backups/` is machine-local, exists already).
2. Make the edit (Edit tool, minimal diff).
3. Read back the changed section; confirm every path/command referenced still resolves.
4. These files are git-tracked: leave changes uncommitted for the user, or commit with
   their conventions (`feat(claude): ...` / `docs(claude): ...`) if asked. **Never push
   without explicit instruction.**

## §3 Lesson format

Append to the target file's `## Lessons` section, newest last:

```
- [YYYY-MM-DD] Trigger: <what happened, 1 line>. Rule: <what to do differently, imperative>.
  Evidence: <command/file:line/session ref, 1 line>.
```

One lesson = one fact. No essays. If a lesson contradicts a rule in the body, do NOT
edit the body — flag the contradiction to the user (ask-first bucket).

## §4 Where does a new fact belong? (three layers — do not mix)

| Fact type | Destination |
|---|---|
| Global behavior rule ("always verify X before Y") | The matching `rules/*.md` Lessons section |
| Project-specific fact ("peregrine tests need the .env from ...") | That project's `CLAUDE.md`, or its memory dir (`MEMORY.md` + memory files) if the harness provides one |
| Machine-specific fact (IPs, mounts, GPU, quirks) | `~/.claude/CLAUDE.local.md` (never in git — it may hold internal addresses) |

Litmus test: "would this line be true on another machine / in another repo?" —
if machine-bound → CLAUDE.local.md; if repo-bound → project level; only if universally
true here → global rules.

## §5 Size budgets & consolidation

- `CLAUDE.md` ≤ 90 lines. Each `rules/*.md` ≤ 250 lines. A `Lessons` section > 15 entries
  triggers consolidation.
- Consolidation = propose to the user: merge recurring lessons into the rule body, drop
  stale ones, keep the file under budget. Never silently discard lessons.
- Adding always-loaded content to `CLAUDE.md` needs a strong reason: every line there is
  paid for in every session of every project (see `diagnosis-2026-07.md`, Finding 1).

## §6 Fact rot & periodic checks

- At use time: before relying on an agent type, tool, command, or model ID named in these
  files, confirm it exists in the current session (system-reminder lists, `--help`, `/model`).
  Missing → fall back per the file's own fallback note, then self-serve-fix the reference (§1).
- Harness questions (does Claude Code support X? what does this setting do?) → spawn the
  `claude-code-guide` agent instead of guessing or trusting stale memory.
- `diagnosis-*.md` older than 3 months → offer the user a re-audit using its
  "Re-audit procedure" section; write results as a new dated diagnosis file, keep the old
  one (history matters), and update the CLAUDE.md index line.

## §7 Multi-machine notes (why editing here affects everywhere)

- `bootstrap.sh` re-applies `model`, `hooks`, `permissions` from the repo's
  `claude/settings.json` into the machine's live `settings.json` on every run — for those
  keys the **repo copy is the source of truth**; fix both or fix the repo and re-run bootstrap.
- `CLAUDE.md`, `hooks/`, `skills/`, `rules/` are symlinks — editing the live path edits
  the repo working tree directly. There is no "local-only" edit of these; that's what
  `CLAUDE.local.md` is for.
- The NAS runs Claude Code pinned at 2.1.25: never add a rule that hard-depends on newer
  harness features without a stated fallback.

## Lessons

Append per §3. Do not rewrite the sections above without user approval.

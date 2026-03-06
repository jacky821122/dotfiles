---
name: commit
description: Generate conventional commit messages from staged changes. Use this skill whenever the user wants to commit, write a commit message, stage and commit, or says things like "commit this", "help me commit", "what should my commit message be", or invokes /commit. Always use this skill instead of guessing a commit message yourself.
argument-hint: "[optional: extra context or scope hint]"
user-invocable: true
allowed-tools: Bash, Read
---

# Commit Message Generator

Generate a conventional commit message from the current staged diff.

## Steps

1. Run `git diff --cached` to see staged changes. If nothing is staged, run `git status` and tell the user what's unstaged — suggest `git add` commands but do NOT stage anything without asking.

2. Analyze the diff:
   - What files changed? What's the nature of the change?
   - Is this one logical change or multiple unrelated ones?

3. If the staged changes clearly belong to multiple independent concerns, recommend splitting into separate commits. Briefly explain why (easier to revert, clearer history). Let the user decide.

4. Generate a commit message in conventional commit format.

## Format

```
type(scope): short description

Optional body in English explaining the "why", not the "what".
```

**Types**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`, `ci`

**Scope**: the affected module/component/directory. Omit if the change is truly cross-cutting.

**Description**: imperative mood, lowercase, no period, ≤72 chars total for the first line.

**Body**: only add if the "why" isn't obvious from the diff. Keep it in English.

## Examples

**Example 1:**
Diff: Added JWT authentication middleware to API routes
Output:
```
feat(auth): add JWT middleware to protected routes
```

**Example 2:**
Diff: Fixed null pointer in user service when email is missing
Output:
```
fix(user): handle missing email in user lookup
```

**Example 3:**
Diff: Updated README and added docstrings to three functions
Output: Suggest splitting — docs and code changes are separate concerns.

## Existing commit style in this repo

Look at `git log --oneline -10` to match the existing scope conventions before generating. For example if the repo uses `feat(claude):` or `fix(bootstrap):`, follow that pattern.

## After generating

Present the message clearly, then ask: "Want me to run `git commit` with this message, or edit it first?"

Only run `git commit` if the user explicitly confirms.

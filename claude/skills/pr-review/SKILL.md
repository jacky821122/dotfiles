---
name: pr-review
description: Review GitHub pull requests using the GitHub MCP tools. Use this skill whenever the user wants to review a PR, do code review, look at a pull request, check what's in a PR, or comment on a PR. Trigger on PR URLs, PR numbers, or phrases like "review this PR", "code review", "look at PR #123", "give me feedback on this PR". Always use this skill when GitHub PR review is needed.
argument-hint: "<PR URL or PR number> [optional: focus area]"
user-invocable: true
allowed-tools: mcp__github__get_pull_request, mcp__github__get_pull_request_files, mcp__github__get_pull_request_comments, mcp__github__get_pull_request_reviews, mcp__github__get_pull_request_status, mcp__github__create_pull_request_review, mcp__github__add_issue_comment, Read, Bash
---

# PR Review

Structured code review using GitHub MCP tools.

## Setup

Parse the PR reference from `$ARGUMENTS` or the conversation:
- Full URL: extract `owner`, `repo`, `pull_number`
- `#123` or just `123`: ask for the repo if not clear from context, or check `git remote -v`

## Step 1: Gather context

Run these in parallel:
- `get_pull_request` — title, description, author, base branch, merge status
- `get_pull_request_files` — changed files and diffs
- `get_pull_request_status` — CI checks
- `get_pull_request_comments` — inline comments already left
- `get_pull_request_reviews` — reviews already submitted

Read the PR description carefully — understanding the intent is essential for good review.

## Step 2: Review the diff

Go through each changed file. Think about:

### Logic & Correctness
- Does the code do what the PR description says it does?
- Are there edge cases not handled? (null/empty/boundary values, concurrent access, error paths)
- Are there off-by-one errors, wrong conditions, or incorrect logic?

### Security
- Any injection risks (SQL, command, XSS)?
- Secrets or credentials in code?
- Overly broad permissions or access control issues?
- Unvalidated external input?

### Performance
- N+1 queries or unnecessary loops?
- Missing indexes for new DB queries?
- Large allocations in hot paths?

### Readability & Maintainability
- Are function/variable names clear?
- Is complex logic explained with comments?
- Is the change consistent with the surrounding codebase style?

### Tests
- Are there tests for the new behavior?
- Do the tests actually cover the edge cases?
- Are tests fragile or tightly coupled to implementation?

## Step 3: Structure the review

Organize findings by severity:

**Critical** — Must fix before merging (correctness bugs, security issues, data loss risk)
**Major** — Should fix (significant logic issues, missing error handling, performance problems)
**Minor** — Nice to fix (style, naming, small improvements)
**Nit** — Optional (personal preference, no functional impact)

## Step 4: Output format

Present your review in this structure:

```
## PR Review: <title>

**Summary**: <1-2 sentence overall assessment>

**Verdict**: Approve / Request changes / Comment

### Critical
- <file:line> — <issue and suggested fix>

### Major
- <file:line> — <issue and suggested fix>

### Minor / Nit
- <file:line> — <brief note>

### Positives
- <what was done well — always include something if warranted>
```

## Step 5: Post the review (optional)

Ask the user: "Want me to post this review to GitHub?"

If yes, use `create_pull_request_review` with:
- `event`: `"APPROVE"`, `"REQUEST_CHANGES"`, or `"COMMENT"`
- `body`: the review summary
- `comments`: array of inline comments for specific lines

For individual comments without a formal review, use `add_issue_comment`.

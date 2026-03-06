---
name: debug
description: Structured debugging workflow. Use this skill whenever the user pastes an error message, stack trace, or says their code is broken, something isn't working, there's a bug, or asks to debug. Trigger on error output, exception traces, test failures, or any "why is this happening" question about unexpected behavior. Always use this skill rather than immediately diving into code changes.
argument-hint: "[paste error or describe the problem]"
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# Debug

A structured debugging process. The goal is to understand the problem before touching code — jumping to fixes without understanding root cause wastes time and often introduces new bugs.

## The Process

### 1. Read the full error

Don't skim. Read the entire error message and stack trace. Extract:
- **Error type**: what kind of failure is this? (TypeError, segfault, 404, assertion, etc.)
- **Error message**: the exact text — often contains the root cause directly
- **Location**: file + line number where it was thrown
- **Call stack**: the chain of calls leading to the error

If the error was pasted in the conversation, work from that. If it's in a log file, read it.

### 2. Locate the source

Read the file and line number from the stack trace. Understand the immediate context — what is the code at that location trying to do?

### 3. Trace the call stack

Follow the stack upward. Identify where the problematic data or state originates, not just where it explodes. The error site is often not where the bug is.

### 4. Check context

Before hypothesizing, gather relevant context:
- What are the actual values at runtime? (Look for logs, add debug prints if needed)
- What are the types? (Type errors often mean something upstream returned None/null/wrong type)
- What changed recently? (`git log --oneline -10` or `git diff HEAD~1` can help)
- Is this reproducible? Always/sometimes/once?

### 5. Form a hypothesis

State your hypothesis clearly:
> "I think the bug is X because Y. Evidence: Z."

Don't state it as fact — state it as a testable hypothesis. If you have multiple candidates, rank them by probability.

### 6. Validate before fixing

Verify the hypothesis before changing code:
- Can you add a print/log to confirm the bad value?
- Does the error make sense given the hypothesis?
- Is there a simpler explanation?

Only after confirming the hypothesis should you propose a fix.

### 7. Fix and verify

Make the minimal fix. Then explain how to verify it worked (run specific test, reproduce the original trigger, check the log).

---

## Anti-patterns to avoid

- Don't change code speculatively ("let's try this and see"). State a hypothesis first.
- Don't fix symptoms instead of root cause.
- Don't ignore parts of the stack trace because they look unfamiliar — they often contain the real clue.
- If the error comes from a library/framework, the bug is almost always in the calling code, not the library itself. Check how it's being called.

## Format for your analysis

Present your findings like this:

```
Error: <type + message>
Location: <file:line>
Root cause hypothesis: <what you think is wrong and why>
Evidence: <what in the stack/code supports this>
Proposed fix: <minimal change>
Verification: <how to confirm it's fixed>
```

If you're uncertain between multiple hypotheses, list them ranked by likelihood before asking the user for more info.

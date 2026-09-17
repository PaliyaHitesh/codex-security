---
name: validation
description: Use when the user explicitly asks whether one or more candidate security findings are actually valid (true positive vs. false positive), independent of running a full scan. Do not use as the primary trigger for full PR, commit, branch, patch, or repository scans.
---

# Finding Validation

Determine whether one or more candidate security findings are real by shelling
out to the published `@openai/codex-security` CLI's `validate` command. This
skill is a thin relay: the CLI performs the validation. Never reimplement
validation logic here.

## When to use

Use this when the user hands you a specific candidate finding (freeform text, a
file describing it, or a saved finding identifier) and asks "is this real?" /
"is this a false positive?" — independent of running a whole scan.

Do not use this to trigger a full repository, diff, or deep scan — those already
validate their own findings as part of scanning (see `security-scan`,
`security-diff-scan`, `deep-security-scan`).

## Workflow

1. Get the finding text (or a file/identifier containing it) from the user.
2. Run:

   ```bash
   npx @openai/codex-security validate "<finding text or file path>"
   ```

   Repeat the positional argument to validate multiple findings in one call.
3. **Do not pass `--json` or `--format json`/`--format jsonl` to this command —
   the CLI explicitly rejects structured output for `validate`** (also true of
   `login`, `logout`, and `serve`). Relay its plain-text output to the user
   as-is; do not attempt to parse it as JSON or reformat it into a JSON
   structure yourself.
4. Present the CLI's verdict and reasoning verbatim (or lightly summarized —
   never reworded in a way that changes the verdict).

## Hard rules

- Never call `validate` with `--json`/`--format json`/`--format jsonl` — it will
  fail. This is a documented, intentional CLI restriction, not a bug to work
  around.
- Never upgrade or downgrade the CLI's verdict based on your own judgment —
  relay exactly what it reports.
- Only `--auth`, `--effort`, and `--codex` options exist besides the finding
  text itself; don't invent others.

---
name: fix-finding
description: Use only when the user explicitly asks to fix and verify a validated or plausible security vulnerability. Do not use for ordinary bug fixes, correctness or design review findings, general validation, or full PR, commit, branch, patch, or repository scans.
---

# Fix Finding

Patch a security finding by shelling out to the published `@openai/codex-security`
CLI's `patch` command. This skill is a thin relay: the CLI implements, applies,
and reports on the fix. Never hand-write the patch yourself in place of running
this command — the CLI's patch flow includes its own verification gates that a
manual edit would bypass.

## When to use

Use this only when the user explicitly asks to fix (and verify) a security
finding — from a scan, a saved finding identifier, or a Linear issue. Do not use
it for ordinary bug fixes or design-review feedback with no security finding
attached, and don't use it as a substitute for `verify-fix` when the user only
wants verification of an *existing* fix.

## Workflow

1. Identify the finding(s) to patch:
   - Freeform finding text or a file describing it (positional argument).
   - A saved finding from a scan: `--scan <scanId>` (optionally `--severity
     <level>` to patch only findings at or above that level).
   - Linear issues: `--linear-issue <id-or-url>` (repeatable) or
     `--linear-project <project>` (optionally `--linear-filter <json>`).
2. Run:

   ```bash
   npx @openai/codex-security patch [<finding text or file>] \
     [--scan <scanId>] [--severity <level>] \
     [--linear-issue <id>]... [--linear-project <project>] \
     [--create-pr] \
     --json
   ```

   - `--create-pr` opens a pull request with the patch instead of leaving it as
     local working-tree changes; only pass it when the user wants a PR opened.
   - Don't mix saved-finding inputs (`--scan`/finding identifiers) with Linear
     inputs (`--linear-issue`/`--linear-project`) in the same call — the CLI
     rejects that combination.
   - If the user wants a combined risk assessment of the resulting patch, that's
     `--assess-patch-risk` — see `assess-patch-risk` for when to use it instead
     of/alongside this flag.
3. The CLI applies the fix, runs its own verification gates, and reports
   `applied`, `filesChanged`, and per-finding patch results in its JSON output.
   Relay this outcome; don't independently declare the finding "fixed" beyond
   what the CLI reports.
4. If the CLI reports the patch did not fully verify, say so plainly — do not
   round up a partial or failed result to "fixed."

## Hard rules

- Never claim a finding is "fixed" beyond exactly what the CLI's output states.
- Never hand-edit the vulnerable code yourself as a substitute for running
  `patch` — you'd skip the CLI's own verification gates.
- Never broaden the change into unrelated cleanup — that's the CLI's
  responsibility to scope correctly, and not something to second-guess or
  extend after the fact.
- After patching, if the user wants independent confirmation the fix holds
  against the original finding, use `verify-fix` — don't assume `patch`'s own
  verification is the only checkpoint they want.

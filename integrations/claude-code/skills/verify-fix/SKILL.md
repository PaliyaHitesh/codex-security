---
name: verify-fix
description: Use only when the user explicitly requests verification that a security fix remediates a reported vulnerability. Do not invoke automatically while implementing fixes, reviewing ordinary code changes, or running tests. Do not use for non-security fixes, candidate finding validation, or full repository scans.
---

# Verify Fix

Verify that a security fix actually remediates a reported vulnerability, without
changing the repository, by shelling out to the published `@openai/codex-security`
CLI's `verify-fix` command. This skill is a thin, read-only relay.

## When to use

Use this only when the user explicitly asks to confirm a fix holds — after
`fix-finding`, after a manual fix, or to double-check a fix someone else made.

Do not use this automatically while implementing a fix yourself, during
ordinary code review, or as a substitute for `validation` (which asks whether a
*candidate* finding is real, not whether a fix works).

## Workflow

1. Identify what to verify:
   - Freeform finding text or a file (positional argument).
   - Saved findings from a scan: `--scan <scanId>` (optionally `--severity
     <level>`).
   - Linear issues: `--linear-issue <id-or-url>` (repeatable) or
     `--linear-project <project>` (optionally `--linear-filter <json>`).
2. Run:

   ```bash
   npx @openai/codex-security verify-fix [<finding text or file>] \
     [--scan <scanId>] [--severity <level>] \
     [--linear-issue <id>]... [--linear-project <project>] \
     --json
   ```

   Don't mix saved-finding inputs with Linear inputs in the same call.
3. The JSON output's `results[]` gives each finding's verification `status`:
   `fixed`, `still_vulnerable`, or `inconclusive`, with supporting `evidence`.
   Relay this exactly.

## Hard rules

- This command is read-only — it never creates, modifies, or deletes
  repository files, applies patches, or touches issue trackers. If verification
  requires a code change, that's `fix-finding`, not this.
- **Never upgrade an `inconclusive` result to `fixed`.** Report it exactly as
  `inconclusive` along with whatever evidence-gap explanation the CLI gives.
- Never infer a stronger verdict than the evidence supports, and never
  substitute a different vulnerability's evidence for the one being checked.

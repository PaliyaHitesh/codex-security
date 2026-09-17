---
name: security-diff-scan
description: Review a pull request, commit, branch diff, or working-tree patch for security vulnerabilities. Use when there is a specific diff, changeset, or set of pending changes to review. Do not use for a full repository or path audit with no diff (use security-scan) or for deep, multi-pass scans (use deep-security-scan).
---

# Security Diff Scan

Run a Codex Security scan scoped to a Git diff by shelling out to the published
`@openai/codex-security` CLI. This skill is a thin relay: the CLI performs the
audit end-to-end. Never reimplement scanning or validation logic here.

## When to use

Use this when the user wants a security review of a PR, commit, branch diff, or
their own pending (staged/unstaged) changes — anything expressed as "review this
diff / PR / commit" rather than "scan the whole repo."

Do not use this for a scan with no diff in scope (`security-scan`) or for a deep,
multi-pass scan (`deep-security-scan`, which also accepts `--diff`/`--working-tree`
if the user wants both deep *and* diff-scoped).

## Prerequisites

Same as `security-scan`: confirm `npx @openai/codex-security info --json` succeeds
before starting, and don't proceed past a missing-credential error.

## Workflow

1. Identify what's being reviewed:
   - **Committed changes** (a PR, commit range, or branch diff): use `--diff BASE`.
     `BASE` is any Git ref — e.g. `origin/main`, a commit SHA, or `HEAD~1`.
     `--head REF` overrides the diff's head (default: `HEAD`).
   - **Uncommitted changes** (staged + unstaged in the working tree): use
     `--working-tree`. `--base REF` overrides its comparison point (default:
     `HEAD`).
2. Run the scan:

   ```bash
   # committed diff
   npx @openai/codex-security scan <repository> --diff <base-ref> [--head <head-ref>] --json

   # working-tree changes
   npx @openai/codex-security scan <repository> --working-tree [--base <base-ref>] --json
   ```

   Do not combine `--diff` and `--working-tree` in the same invocation, and don't
   add `--path` alongside a diff scope unless the user explicitly wants the diff
   further narrowed to specific paths.
3. Let the scan run to completion; do not poll or attempt to cancel it.
4. Read the completed scan's artifacts (`scanDir` from the JSON output) —
   `scan-manifest.json`, `findings.json`, `coverage.json`, `report.md` — the
   same as `security-scan`.
5. Summarize findings by severity, report `coverage.completeness` honestly, and
   point to `report.md` for full detail.
6. Suggest next steps: `fix-finding` / `verify-fix` for confirmed findings,
   `track-findings` to file them.

## Hard rules

- Never claim "no vulnerabilities" when coverage is partial.
- Never invent flags beyond `--diff`, `--head`, `--working-tree`, `--base`,
  `--path`, `--json` documented here.
- A diff scan only reasons about the changed surface — say so if the user seems
  to expect a full-repository audit, and redirect them to `security-scan` or
  `deep-security-scan` instead of silently broadening scope.

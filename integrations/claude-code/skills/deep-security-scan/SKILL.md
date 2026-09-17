---
name: deep-security-scan
description: Use when the user asks for a deep, exhaustive, multi-pass, or variance-reducing repository-wide or scoped-path security scan. Runs repeated Standard scans and aggregates their validated findings. Do not use for PRs, commits, branch diffs, or working-tree diffs unless the user also wants a deep scan of that diff.
---

# Deep Security Scan

Run a Codex Security Deep scan by shelling out to the published
`@openai/codex-security` CLI with `--mode deep`. Deep mode runs repeated
independent Standard-scan passes and aggregates their validated findings — the
CLI owns that orchestration entirely. This skill never reimplements it.

## When to use

Use this only when the user explicitly asks for something *more* than a single
standard pass: "deep scan," "exhaustive audit," "reduce variance," "run this
multiple times and aggregate," or similar. A plain "scan this repo" request is
`security-scan`, not this.

Deep mode still accepts `--diff`/`--working-tree` scope if the user wants a deep,
multi-pass review of a diff specifically rather than the whole repository.

## Prerequisites

Same as `security-scan`: confirm `npx @openai/codex-security info --json`
succeeds and don't proceed past a missing-credential error. Deep scans consume
significantly more time and API cost than Standard — mention this to the user
before starting, especially if they haven't set `--max-time-hours` or
`--max-cost`.

## Workflow

1. Determine the target: repository root, optional `--path` scope, or a diff
   scope (`--diff`/`--working-tree`, same semantics as `security-diff-scan`).
2. Run the scan:

   ```bash
   npx @openai/codex-security scan <repository> --mode deep \
     [--path <scoped-path>]... \
     [--workers N] [--subagents N] \
     [--stop-after-no-new N] [--max-discovery-runs N] \
     [--max-time-hours H] \
     --json
   ```

   - Only pass `--workers`, `--subagents`, `--stop-after-no-new`,
     `--max-discovery-runs`, or `--max-time-hours` when the user gives a
     specific value — leave the rest at the CLI's defaults.
   - `--max-time-hours` accepts up to 96; if the user wants a hard time box,
     set it explicitly rather than letting a deep scan run unbounded.
   - Never add flags beyond the ones listed here without confirming with the
     user first.
3. Deep scans can run for a long time. Let the CLI run to completion — do not
   poll for progress in a loop or attempt to cancel it; the CLI documents scans
   as CLI-only precisely because the tool can't cancel an in-flight run.
4. Read the completed scan's artifacts (`scanDir` from the JSON output) the
   same way as `security-scan`: `scan-manifest.json`, `findings.json`,
   `coverage.json`, `report.md`.
5. Summarize findings by severity, report `coverage.completeness` honestly
   (deep scans can still finish with `partial` coverage under a time or cost
   cap — say so plainly), and point to `report.md` for full detail.
6. Suggest next steps: `fix-finding` / `verify-fix`, `track-findings`.

## Hard rules

- Never claim "no vulnerabilities" when coverage is partial, including when a
  deep scan stopped early due to `--max-time-hours` or a cost cap.
- Never invent flags beyond `--mode deep`, `--path`, `--diff`, `--working-tree`,
  `--head`, `--base`, `--workers`, `--subagents`, `--stop-after-no-new`,
  `--max-discovery-runs`, `--max-time-hours`, `--json`.
- Warn the user about time/cost before starting an unbounded deep scan; don't
  silently pick a time or cost cap on their behalf.

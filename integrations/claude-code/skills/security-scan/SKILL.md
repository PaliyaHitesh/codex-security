---
name: security-scan
description: Use for a standard, single-pass security audit of an entire repository or a scoped path with no diff to review. This is the default repository scan. Do not use for PR, commit, branch, or working-tree diffs (use security-diff-scan), or for deep, multi-pass scans (use deep-security-scan).
---

# Security Scan

Run a standard Codex Security scan of a repository (or a scoped path inside it) by
shelling out to the published `@openai/codex-security` CLI. This skill is a thin
relay: the CLI performs the audit end-to-end. Never reimplement scanning, finding
validation, or severity scoring here — report exactly what the CLI returns.

## When to use

Use this for "scan this repo", "audit this codebase for vulnerabilities", or "scan
`src/payments`" requests with no diff, commit, branch, or PR in scope.

Do not use this for:
- Diffs, PRs, commits, branches, or working-tree changes — use `security-diff-scan`.
- Deep, exhaustive, multi-pass scans — use `deep-security-scan`.
- Explaining an *already-completed* scan's coverage or a specific finding's
  attack path — use `finding-discovery` / `attack-path-analysis` / `threat-model`.

## Prerequisites

Confirm the CLI is usable before starting:

```bash
npx @openai/codex-security info --json
```

If this fails, the user needs to authenticate first — `npx @openai/codex-security login`
(interactive/ChatGPT) or set `OPENAI_API_KEY` (CI/headless). Do not attempt to work
around a missing credential; surface the exact CLI error and stop.

## Workflow

1. Determine the repository root (default: current directory) and any explicit
   scope the user gave (a package, folder, or submodule).
2. Run the scan:

   ```bash
   npx @openai/codex-security scan <repository> [--path <scoped-path>]... --mode standard --json
   ```

   - Omit `--mode standard` if the user didn't specify a mode — `standard` is
     already the CLI default.
   - Repeat `--path` once per scoped location; each is repository-relative.
   - Never add `--diff`, `--working-tree`, `--mode deep`, or any flag not listed
     in this skill or confirmed with the user — those change the scan you're
     running into a different one (see the sibling skills above).
   - `--format md` is explicitly rejected for scan results by the CLI; stick to
     `--json` (or no format flag, for the interactive dashboard) here.
3. The CLI prints live progress to stderr and, with `--json`, a final JSON object
   to stdout containing the scan outcome. Let it run to completion — do not poll
   or cancel a running scan; scans are CLI-only in this tool for exactly that
   reason (the MCP transport can't cancel in-flight commands).
4. Read the completed scan's on-disk artifacts before summarizing: the JSON
   output's `scanDir` holds `scan-manifest.json`, `findings.json`,
   `coverage.json`, and (once finalized) `report.md`.
5. Summarize for the user:
   - Scan ID and scan directory.
   - Finding counts by `severity.level` (critical/high/medium/low), each with
     the finding's `title` and `locations`.
   - `coverage.completeness` — report it verbatim (`complete`, `partial`, etc.).
     **Never say "no vulnerabilities found" or otherwise imply a clean bill of
     health when coverage is partial** — say what was and wasn't covered instead.
   - The path to `report.md` for full detail.
6. Suggest natural next steps based on what came back: `fix-finding` and
   `verify-fix` for confirmed findings, `track-findings` to file them, or
   `attack-path-analysis` / `threat-model` to explain the results further.

## Hard rules

- Never claim "no vulnerabilities" when coverage is partial or a scan errored
  partway through — report exactly what the CLI's `coverage.json` says.
- Never invent CLI flags. If a user asks for behavior this skill's documented
  flags don't cover, say so and point at `npx @openai/codex-security scan --help`
  rather than guessing a flag name.
- Never scan a repository the user hasn't pointed you at, and never widen an
  explicit `--path` scope on your own.

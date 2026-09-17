---
name: finding-discovery
description: Use to explain what an already-completed Codex Security scan actually covered — which surfaces were reviewed, which were skipped or deferred, and why. Do not use to start a new scan or discover new findings; redirect to security-scan or security-diff-scan for that.
---

# Finding Discovery (Scan Coverage Explainer)

There is no standalone "run discovery" CLI command — discovery is an internal
phase of the `scan` command itself, driven entirely by the CLI. This skill's job
is narrower and read-only: explain the coverage of a scan that has **already
completed**, by reading its saved artifacts.

## When to use

Use this when the user asks things like "what did that scan actually look at?",
"did it check the auth module?", "why didn't it flag X?", or "what's not
covered?" about a scan that has already run.

Do not use this to kick off new discovery or a new scan — redirect to
`security-scan` (no diff), `security-diff-scan` (a diff), or `deep-security-scan`
(multi-pass) instead, and explain that discovery happens automatically as part
of those.

## Workflow

1. Identify the scan. If the user gives a scan ID or "the last scan," resolve it:

   ```bash
   npx @openai/codex-security scans show [scanId] --json
   ```

   Omitting `scanId` returns the latest completed scan. `scans show` returns
   the scan's saved configuration and result, including its `scanDir`.
2. Read `coverage.json` from that scan's directory (`<scanDir>/coverage.json`).
   It reports:
   - `mode` (e.g. `repository`, `scoped_path`) and `inventoryStrategy`.
   - `completeness` (`complete`, `partial`, etc.) — relay this exactly.
   - `includePaths` / `excludePaths` — what was in and out of scope.
   - `surfaces[]` — named areas with a `disposition` (e.g. `reported`) and any
     `receiptRefs`.
   - `explicitExclusions[]` and `deferred[]` — call these out explicitly if the
     user asks about a specific area and it shows up here.
3. Cross-reference `scan-manifest.json` in the same directory for the scan's
   resolved `target` and `scope` (what repository/revision/paths were actually
   scanned) if the user's question is about scope rather than coverage detail.
4. Answer the user's specific question using only what these files say. If the
   area they're asking about isn't mentioned anywhere in `coverage.json`, say
   that plainly rather than guessing why.

## Hard rules

- Never claim a surface was reviewed, or that "nothing was found there,"
  without pointing to what `coverage.json` actually says about it.
- Never claim "no vulnerabilities" for a `partial` completeness — describe the
  actual scope limitation instead.
- This skill does not run a scan, discover new candidates, or modify anything —
  it only reads and explains artifacts from a scan that already finished. If no
  completed scan exists yet, say so and redirect to `security-scan` /
  `security-diff-scan` / `deep-security-scan`.

---
name: attack-path-analysis
description: Use to explain a specific finding's attack path — how it traces from source to sink, and why it was scored at its severity — from an already-completed Codex Security scan. Do not use as the primary trigger for a new scan; that scan performs its own attack-path analysis internally.
---

# Attack Path Analysis (Finding Explainer)

There is no standalone "run attack-path analysis" CLI command — it's an internal
phase of the `scan` command, performed automatically for every finding a scan
reports. This skill's job is read-only: explain a specific finding's already-
computed attack path and severity rationale from a completed scan's artifacts.

## When to use

Use this when the user asks "why is this rated high severity?", "how would an
attacker actually exploit this?", or "walk me through the source-to-sink path"
about a finding from a scan that has already run.

Do not use this to kick off a new scan — attack-path analysis happens
automatically as part of `security-scan`, `security-diff-scan`, and
`deep-security-scan`.

## Workflow

1. Identify the scan and finding. Resolve the scan:

   ```bash
   npx @openai/codex-security scans show [scanId] --json
   ```
2. Get the finding data, either from that scan's `findings.json`
   (`<scanDir>/findings.json`) directly, or exported:

   ```bash
   npx @openai/codex-security export <scanDir> --export-format json --output -
   ```
3. Locate the specific finding by `findingId`/`occurrenceId`, title, or file
   location. Each finding record includes:
   - `severity.level` and `severity.score` (plus `scoringSystem`, e.g. CVSS).
   - `confidence.level` and `confidence.rationale`.
   - `taxonomy.category` / `taxonomy.cwe`.
   - `locations[]` with `path`, `startLine`/`endLine`, and `role` (e.g. `sink`).
   - `remediation`, `remediationTests`, `preventiveControls`.
   - `validation` and `attackPath` (present when the scan recorded structured
     validation/attack-path detail beyond the summary fields above).
4. Explain the path using exactly this evidence: what the source is, what
   control (if any) is missing or bypassed, what the sink does, and why that
   maps to the reported severity/confidence. If the finding's stored data is
   thin (e.g. `validation`/`attackPath` are `null`), say so rather than
   inventing detail the scan didn't record.

## Hard rules

- Never claim reachability, exploitability, or a severity level beyond what the
  finding record actually states — quote its fields.
- Never re-score or re-validate the finding yourself; that's the CLI's job
  during scanning (`security-scan`/`security-diff-scan`/`deep-security-scan`) or
  `validation` for a standalone candidate.
- If no completed scan or matching finding exists, say so and redirect the user
  to run a scan or check the finding identifier.

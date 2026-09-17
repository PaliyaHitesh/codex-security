---
name: threat-model
description: Use to surface a repository's threat model as recorded by an already-completed Codex Security scan. Do not use as the primary trigger for a new scan; there is no standalone CLI command that generates a threat model outside of a scan.
---

# Threat Model (Scan Artifact Explainer)

There is no standalone "generate a threat model" CLI command. A threat model is
produced internally as part of a scan and saved to disk alongside that scan's
other artifacts. This skill's job is read-only: surface the threat-model
artifact a completed scan already wrote.

## When to use

Use this when the user asks to see, summarize, or discuss the threat model for
a repository that has an already-completed Codex Security scan.

Do not use this to generate a fresh threat model outside of a scan — none of
the published CLI commands produce one standalone. If no scan has run yet,
redirect to `security-scan`, `security-diff-scan`, or `deep-security-scan`
(threat-modeling happens automatically as part of each).

If the user instead wants durable, forward-looking scanning guidance for the
repository (what should and shouldn't be treated as in-scope, what security
properties must hold), that's `define-security-policy`, not this skill.

## Workflow

1. Resolve the scan:

   ```bash
   npx @openai/codex-security scans show [scanId] --json
   ```
2. Look for the scan's threat-model artifact under its `scanDir`. Scan-level
   context artifacts (including the threat model) live under
   `<scanDir>/artifacts/01_context/`; check `threat_model.md` there first, and
   fall back to whatever `scans show`'s output points at for that scan if the
   directory layout differs (published output-directory layouts can vary by
   scan mode and version — trust what's actually on disk over an assumed path).
3. Present that document's content to the user directly (summarized if long),
   rather than reconstructing a threat model from `findings.json` or your own
   analysis.

## Hard rules

- Never fabricate a threat model when the artifact doesn't exist — say plainly
  that this scan didn't record one, and suggest re-running a scan if the user
  wants one.
- Never claim the threat model reflects the current state of the repository if
  the scan it came from is stale (check the scan's `completedAt` and mention
  it if the user seems to be relying on this being current).

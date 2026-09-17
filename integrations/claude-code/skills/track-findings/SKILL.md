---
name: track-findings
description: Track validated Codex Security findings from a completed scan as Linear issues, or hand off GitHub issue creation to the user's own gh CLI. Use for one finding or an explicitly selected batch. Always dry-run and get explicit approval before any write; one destination per run. Do not use it for scans or fixes. Jira is out of scope for this integration.
---

# Track Findings

File validated findings from a completed Codex Security scan as tracked issues.
This skill has a narrower scope than the Codex-native version: it supports
Linear via the CLI's `publish` command, and hands GitHub off to the user's own
`gh` CLI since no `publish --to github` destination exists. Jira is entirely
out of scope — there is no CLI path or generic connector for it here.

## When to use

Use this when the user wants specific, already-validated findings from a
completed scan filed as tracked issues. Do not use it to run a scan or to fix
anything — that's `security-scan`/`security-diff-scan`/`deep-security-scan` and
`fix-finding`.

## Selecting findings

Require an explicit selection from the user — never treat "track the findings"
as permission to file every finding in a scan. Cap any batch at 25 findings.

## Linear

1. Preview first, always:

   ```bash
   npx @openai/codex-security publish scan <scanDir> --to linear \
     --linear-team <team-id> \
     [--finding-id <id>]... \
     [--linear-project <project-id>] [--linear-assignee <email-or-id>] \
     --dry-run --json
   ```

   `--linear-team` (or `CODEX_SECURITY_LINEAR_TEAM`) is required. Repeat
   `--finding-id` once per selected, deduplicated finding. `--skip-existing`
   skips findings already published to this exact destination, if the user
   wants that.
2. Show the user the exact preview payload (issue titles/bodies as the dry run
   would create them) and get their explicit approval.
3. Only after approval, rerun the identical command without `--dry-run` to
   actually publish.

## GitHub

There is no `publish --to github` destination in the CLI. Do not invent one.
Instead:

1. Pull the finding's detail from the completed scan (`findings.json` via
   `scans show`/`export`, as in `attack-path-analysis`).
2. Draft the issue title/body from that finding's data (never invent detail
   the scan didn't record) and show it to the user for approval.
3. Only after approval, hand off to the user's own authenticated `gh` CLI:

   ```bash
   gh issue create --repo <owner/repo> --title "<title>" --body-file <tmpfile>
   ```

   Write the approved body to a temporary file rather than inlining it on the
   command line — never pass finding content through shell interpolation.

## Jira

Out of scope for this integration — there is no CLI command or generic
connector for it here (the Codex-native skill's Jira support is specific to
that host's Atlassian Rovo app). Tell the user this plainly if they ask.

## Hard rules

- **One destination, one approval gate, per run.** Never publish to more than
  one destination in the same run, and never skip the dry-run/preview-and-
  approve step before a real write.
- Never treat an unqualified "track the findings" request as permission to
  file every finding in a scan — require an explicit selection, capped at 25.
- Never silently turn a request for private/limited disclosure into a public
  GitHub issue — confirm the target repository's visibility with the user
  first if it isn't obviously private.
- Never fabricate finding detail in an issue body — pull it from the scan's
  own `findings.json`/`export` output.
- Do not retry a create you're unsure succeeded — check first (Linear: rerun
  with `--dry-run` to compare; GitHub: `gh issue list`/`gh issue view`) before
  creating a duplicate.

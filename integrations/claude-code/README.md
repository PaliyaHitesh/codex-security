# Codex Security — Claude Code Plugin

A Claude Code Plugin that brings `@openai/codex-security`'s workflows —
scanning, validation, patching, triage, hardening proposals, and reporting —
into Claude Code as Skills. The same skill files are opencode-compatible
without any conversion step.

Unlike the Codex-native plugin at `plugins/codex-security/` (which drives
Codex-host-specific MCP tools), every skill here is a thin wrapper that shells
out to the published CLI (`npx @openai/codex-security ...`), reads its output,
and presents it. No scan, validation, or patch logic is reimplemented — the
CLI remains the single source of truth for all of it.

## Prerequisites

- Node.js 22.13.0 or later.
- Authentication: `npx @openai/codex-security login` (interactive/ChatGPT), or
  set `OPENAI_API_KEY` for CI/headless use.
- Optional: an authenticated `gh` CLI, for the GitHub-issue path in
  `track-findings`.

## Install in Claude Code

`claude plugin install` only installs from a configured marketplace, not from
a bare filesystem path — so for local development, register this checkout as
a marketplace first, then install from it:

```bash
claude plugin marketplace add ./integrations/claude-code
claude plugin install codex-security@codex-security
```

The first command reads `integrations/claude-code/.claude-plugin/marketplace.json`
(a self-contained, single-plugin marketplace pointing at `.`) and registers it
under the name `codex-security`. The second installs the `codex-security`
plugin from it. Once this plugin is published to a public marketplace, it can
instead be added by that marketplace's name.

Verify with `claude plugin list` (expect `codex-security@codex-security`,
scope `user`) or `claude plugin details codex-security@codex-security` (expect
all 15 skills listed under "Component inventory"). Installed skills are
available as `/codex-security:<skill-name>`, e.g. `/codex-security:security-scan`.

## Install in opencode

opencode implements the same Agent Skills standard as Claude Code and reads
skills directly from `.opencode/skills/<name>/SKILL.md` (or `.claude/skills/`).
Symlink this plugin's `skills/` directory into a project rather than copying
it, so the two hosts always see the same content:

```bash
integrations/claude-code/scripts/link-opencode.sh /path/to/your/project
# equivalent to:
#   ln -s /path/to/codex-security/integrations/claude-code/skills \
#         /path/to/your/project/.opencode/skills/codex-security
```

No build step, sync tooling, or format conversion is involved.

## Skill catalog

| Skill | Nature | Primary CLI command |
|---|---|---|
| `security-scan` | Thin CLI relay | `scan [repo] [--path]... --json` |
| `security-diff-scan` | Thin CLI relay | `scan [repo] --diff BASE` / `--working-tree --json` |
| `deep-security-scan` | Thin CLI relay | `scan [repo] --mode deep [--workers N] [--max-time-hours H] --json` |
| `finding-discovery` | Read-only explainer | `scans show` + `coverage.json`/`scan-manifest.json` |
| `validation` | Thin CLI relay (plain text) | `validate <finding\|file>` — never `--json` |
| `attack-path-analysis` | Read-only explainer | `scans show` + `export`/`findings.json` |
| `threat-model` | Read-only explainer | `scans show` + `<scanDir>/artifacts/01_context/threat_model.md` |
| `fix-finding` | Thin CLI relay | `patch <finding\|scan\|linear> [--create-pr] --json` |
| `verify-fix` | Thin CLI relay | `verify-fix <finding\|scan\|linear> --json` |
| `assess-patch-risk` | Mixed | Mode A: `patch --assess-patch-risk --json`. Mode B (external diff/PR/commit range): `git`/`gh` + Claude's own analysis — no CLI command exists for this. |
| `propose-security-hardening` | Claude-native authorship | `scans show`/`export` for evidence; the hardening analysis is Claude's own reasoning |
| `define-security-policy` | Thin CLI relay + approval gate | `policy [repo] [--path]` — draft only, never writes `SECURITY.md` without explicit approval |
| `track-findings` | Mixed, reduced scope | Linear via `publish scan --to linear --dry-run` → approve → rerun; GitHub via handoff to the user's own `gh issue create`; Jira out of scope |
| `triage-finding` | Claude-native static analysis | Optional `import github` for alert intake; verdicts come from Claude's own source tracing |
| `vulnerability-writeup` | Claude-native authorship | `scans show`/`export` for evidence when starting from a scan, or works directly from user-supplied notes |

## Design notes

**Phase-only skills, resolved individually.** Four of the Codex-native skills
describe themselves as internal scan *phases*, not standalone actions.
Checking the CLI's actual command surface resolved each on its merits:

- `finding-discovery`, `attack-path-analysis`, `threat-model` have no
  standalone CLI command — they're read-only explainers over an
  **already-completed** scan's saved artifacts, and redirect to
  `security-scan`/`security-diff-scan`/`deep-security-scan` for new discovery.
- `validation` maps to the real `validate` command. Note: `validate` (like
  `login`, `logout`, and `serve`) explicitly rejects `--json`/`--format json`/
  `--format jsonl` — the skill relays plain-text output rather than parsing
  JSON.

**Scope reductions versus the Codex-native skills**, both intentional and
documented rather than silently patched over:

- `assess-patch-risk` Mode B (assessing an already-existing external diff, PR,
  or commit range) has no CLI command backing it. The skill binds the diff via
  plain `git`/`gh` and performs the impact analysis directly instead of
  calling `patch`/`scan`.
- `track-findings` drops Jira entirely (the Codex-native skill's Jira support
  is specific to that host's Atlassian Rovo app, with no CLI or generic
  equivalent here) and GitHub tracking hands off to the user's own `gh issue
  create` rather than a `publish --to github` destination, which doesn't exist
  in the CLI.

**Hard rules carried over** from the Codex-native skills wherever they still
apply: never claim "no vulnerabilities" on partial coverage; never upgrade an
`inconclusive` `verify-fix` result to `fixed`; never write `SECURITY.md`
without explicit user approval of the exact drafted text; one destination and
one approval gate per `track-findings` run; never claim a hardening proposal
"fixes" anything until implemented and revalidated.

## Manual verification checklist

This tree is pure Markdown/JSON with no compiled code or test harness. Run
this checklist at creation and again after any skill-content change:

1. `claude plugin marketplace add ./integrations/claude-code && claude plugin
   install codex-security@codex-security`; confirm all 15 skills appear under
   `/codex-security:*` (or via `claude plugin details codex-security@codex-security`).
2. `npx @openai/codex-security info --json` — confirms the environment can run
   the CLI before testing any skill.
3. Against a small, disposable fixture repo with one obvious, synthetic
   vulnerability (never a real or private repo):
   - `security-scan`: run the skill; also sanity-check with
     `codex-security scan . --mock --json` once to validate output-shape
     parsing without spending credits.
   - `security-diff-scan`: introduce one intentional change, run against
     `--diff HEAD~1`.
   - `validation`: hand it a freeform finding string; confirm the skill relays
     plain text rather than attempting JSON parsing.
   - `fix-finding` then `verify-fix`: fix the fixture's known bug, then
     confirm `verify-fix` reaches `status: fixed`.
   - `finding-discovery` / `attack-path-analysis` / `threat-model`: run each
     against the completed scan's ID; confirm correct artifact resolution and
     a correct decline/redirect when no scan exists yet.
   - `define-security-policy`: confirm it drafts but never writes
     `SECURITY.md` without explicit approval.
   - `assess-patch-risk`: test Mode A (`--assess-patch-risk` on the fixture's
     finding) and Mode B (an already-existing `git diff` range) separately;
     confirm the right mode is picked and Mode B never calls `patch`/`scan`.
   - `track-findings`: dry-run only, against a disposable Linear team/scratch
     repo; confirm no write happens without a second explicit approval.
   - `triage-finding` / `vulnerability-writeup` / `propose-security-hardening`:
     feed each a small synthetic finding/disclosure snippet; confirm output
     structure matches the documented format.
4. opencode parity: run `scripts/link-opencode.sh` against a scratch project,
   launch opencode, and confirm the same 15 skills are discoverable with
   unchanged frontmatter.

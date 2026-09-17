---
name: define-security-policy
description: Define, review, or update SECURITY.md guidance for a repository or component, describing what Codex Security should review, what's out of scope, and which security properties must hold. Never writes SECURITY.md to the repository without the user's explicit approval of the drafted content.
---

# Define Security Policy

Draft `SECURITY.md` guidance by shelling out to the published
`@openai/codex-security` CLI's `policy` command. This skill is a thin relay for
drafting — it never installs the result into the repository on its own.

## When to use

Use this when the user wants to define, review, or update what future Codex
Security scans should treat as in-scope, out-of-scope, or a hard security
requirement for a repository or a specific component.

## Workflow

1. Determine scope: whole repository (default) or a specific component via
   `--path <component-dir>`. Add `--knowledge-base <file-or-dir>` (repeatable)
   for architecture/threat-model context the draft should account for.
2. Run:

   ```bash
   npx @openai/codex-security policy <repository> [--path <component>] \
     [--knowledge-base <file>]... --json
   ```

   Add `--headless` to skip interactive owner questions when running
   non-interactively. `--output-dir <dir>` saves the draft outside the
   repository checkout — prefer this over letting the draft land inside the
   repository directly, since the point is owner review before anything is
   committed.
3. The command **saves a draft outside the checkout — it does not install it or
   run a scan.** Present the drafted content to the user for review. If nested
   policies already exist, mention that root and nested `SECURITY.md` files
   compose from root to leaf, with the policy closest to the code taking
   precedence — don't blindly overwrite a more specific existing policy.
4. **Only after the user explicitly approves the exact drafted content**, write
   or update `SECURITY.md` in the repository yourself (a plain file write) —
   never do this automatically as part of running `policy`.

## Hard rules

- **Never write, overwrite, or commit `SECURITY.md` in the repository without
  the user's explicit approval of the exact drafted text.** The CLI itself
  already refuses to do this for you; do not work around that by writing the
  file yourself before approval.
- Never treat `.github/SECURITY.md` or `docs/SECURITY.md` as generic scanner
  guidance, or overwrite either while drafting a root policy — they may serve
  a different purpose (e.g. vulnerability-disclosure instructions).
- Never turn an inference into suppression authority — confirm material scope,
  severity, or accepted-risk decisions with the repository owner; if the owner
  is unavailable, mark the decision unresolved rather than guessing.
- Never copy sensitive finding details into the drafted policy document.

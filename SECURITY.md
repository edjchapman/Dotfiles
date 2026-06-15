# Security Policy

This repo is a single-user dotfiles configuration. The threat model is small but real: it holds age-encrypted secrets, declares my macOS security posture (FileVault, firewall, sudo settings), and bootstraps a fresh Mac on first run. Defects in either category are worth fixing quickly.

## Reporting a vulnerability

**Do not open a public GitHub issue.** Use one of the private channels below.

1. **GitHub private vulnerability reporting** (preferred): <https://github.com/edjchapman/dotfiles/security/advisories/new>. Stays inside GitHub, threads with discussion, supports attachments.
2. **Email**: edchapman88@gmail.com. Subject line `SECURITY: dotfiles - <short description>`.

Acknowledgement target: within 72 hours. Fix target: depends on severity and exploitability; a working triage will be visible in the advisory.

## What's in scope

- Plaintext credentials, age keys, or other secrets discoverable in commit history, in the rendered `$HOME` files, or in any artifact a third party can access.
- Defects in `run_once_*` or `run_onchange_*` scripts that weaken macOS hardening (FileVault, firewall, SIP, sudo, gatekeeper).
- Template logic that produces a `$HOME` file with credentials owned `world-readable`, or that writes to a path outside the intended scope.
- Pre-commit hook or CI bypasses that allow secret leaks past `gitleaks` / `ggshield`.
- Anything in `.chezmoiignore` that, if missed, would deploy a sensitive file to `$HOME` or to a fork.

## What's out of scope

- Personal preferences in `Brewfile.tmpl`, `dot_zshrc`, or macOS defaults (`run_onchange_03-macos-defaults.sh`). Open a discussion if you disagree with a choice — it's not a vulnerability.
- The age recipient committed in `.chezmoi.toml.tmpl`. The recipient is public by design; only the private key in `~/.config/chezmoi/key.txt` matters for decryption.
- Anything in `docs/`, `standups/`, `CLAUDE.md`, `AGENTS.md` — non-deployed metadata.

## Secret rotation

If you discover a leaked secret, the rotation procedure is in [`docs/runbooks/secret-rotation.md`](docs/runbooks/secret-rotation.md). It covers:

- Rotating a single secret (AWS key, GitHub PAT) by editing the plaintext source, re-encrypting via `chezmoi add --encrypt`, and verifying `git diff` shows only the encrypted blob change.
- Rotating the age key itself (full re-encryption of every `.age` file in the repo, key redistribution, backup procedure).

The pre-commit hooks (`gitleaks`, `ggshield`) and the monthly full-history `audit.yml` workflow are the layered defences against accidental leaks. If you find a way to bypass them, that's a high-severity report.

## Supported versions

Only the `main` branch is maintained. Releases are tagged for narrative reference, but old tags receive no backports.

# Changelog

All notable changes to this repo are recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org/spec/v2.0.0.html). Unreleased changes accumulate at the top until the next release is cut.

## [Unreleased]

## [1.2.0] — 2026-06-15

The agentic and self-healing release. The day-to-day surface collapses behind a single `mac` alias, drift detection covers Brewfile, macOS defaults, security baseline, and external pins, and CI grows from 6 to 12 required checks.

### Added

- `mac` alias as the single remediation entry point — refreshes the drift check, summarises what's pending across `$HOME`, Brewfile, macOS defaults, and security baseline, then walks through fixing it.
- `chezmoi-fix` engine with `--alert` mode for clickable remediation from the daily notification.
- `chezmoi-brew-record` and a journaled brew → Brewfile sync loop for interactive `brew install/uninstall/upgrade`.
- `chezmoi-defaults-audit` for macOS defaults drift, including a `--drift` view that lists unreadable entries.
- `chezmoi-security-audit` covering FileVault, SIP, firewall, age key permissions, and file mode checks.
- Weekly VS Code and `mas` health checks; broader brew audit beyond the original bundle check.
- `plist` XML validation as a required CI check (11 → 12 checks).
- `git sync` alias that auto-prunes `[gone]` squash-merged branches.
- `bats-core` test harness for `mac` and related shell logic.
- Project-scoped Claude Code config (`.claude/settings.json`, `agents/`, `commands/`, `rules/`); `AGENTS.md` and `CLAUDE.md` agent briefs.
- `docs/runbooks/branch-protection.md`, `docs/runbooks/recover-from-drift.md`, and an "Back up the age key" section in `secret-rotation.md`.
- `auto-rebase.yml` workflow to keep open PRs current as `main` advances.
- `BOT_PAT` for bot-driven workflows (anti-recursion guard for self-update PRs).
- Daily standup logs (`standups/`), `chezmoi-ignored` from `$HOME` deployment.

### Changed

- Repo-wide refactor optimising for agentic development; project-scoped Claude config separated from the global symlinked `claude-code-config` repo.
- `mac` banner UX reworked: status lines now group drift sources, summarise count, and quote the exact command to run.
- `update-brew` workflow retired (superseded by the local `brewup` daily background task that appends to `~/.cache/brewup.log`).
- Brewfile regrouping: `zoom` under Productivity, `windsurf` cask renamed to `devin-desktop`, deprecated `tldr` replaced with `tlrc`, `poppler` declared to clear brew-extras drift.

### Fixed

- Pre-commit propagates `make-lint` and `ggshield` exit codes — detected secrets now actually block commits (previously the hook reported success).
- Drift detection no longer counts chezmoi warnings, brew-extras false positives, or oh-my-zsh cache files as drifted state.
- `chezmoi-brew-record` detects cask vs formula per-name (previously confused multi-tap collisions).
- GPG path resolution and Brewfile extras coverage.
- `zshrc` refreshes the drift cache after `chezmoi apply` so the next shell banner reflects the new clean state.

### Security

- Age recipient key rotated; every `.age` blob in the repo re-encrypted under the new recipient.

## [1.1.0] — 2026-04-21

CI/CD foundation.

### Added

- GitHub Actions CI workflow running on push to `main` and on pull requests.
- `make lint` unified target for local and CI use.
- Headless template validation with `chezmoi execute-template --override-data` to inject template variables without interactive prompts.
- CI status badge in the README.

### Fixed

- Iterative refinement of CI template validation: `--dry-run` → `execute-template --source` → final `--override-data` approach for reliable headless runs.

## [1.0.0] — 2026-04-20

Initial public release.

### Added

- Chezmoi-managed dotfiles: `Brewfile`, shell config, gitconfig, macOS defaults — all templated and version-controlled.
- macOS automation: Dock layout, Finder preferences, keyboard/trackpad settings, screenshots, Touch ID for sudo, energy settings.
- Security hardening: macOS privacy & security defaults, GPG commit signing, age encryption for secrets, `ggshield` pre-commit hooks, restricted file permissions, `HIST_IGNORE_SPACE` for shell history hygiene.
- Privacy stack: Brave, DuckDuckGo, NordVPN, LuLu outbound firewall, ProtonMail, a 2FA checklist.
- Developer tooling: pinned oh-my-zsh external, GNU/modern CLI replacements, architecture-aware gitconfig credential helpers, Claude Code config via chezmoi symlinks.
- Brewfile audit pass: version refresh, deprecated package replacement, 18 unused apps removed.
- Setup README with design principles, repo structure, step-by-step provisioning guide, GPG key instructions.
- MIT license.

[Unreleased]: https://github.com/edjchapman/dotfiles/compare/1.2.0...HEAD
[1.2.0]: https://github.com/edjchapman/dotfiles/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/edjchapman/dotfiles/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/edjchapman/dotfiles/releases/tag/1.0.0

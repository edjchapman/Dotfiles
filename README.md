# Dotfiles

[![CI](https://github.com/edjchapman/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/edjchapman/dotfiles/actions/workflows/ci.yml)

Reproducible, privacy-hardened macOS configuration managed with [chezmoi](https://www.chezmoi.io/). One command bootstraps a clean Mac into a fully configured environment: shell, packages, git, encrypted secrets, macOS preferences, Dock, firewall, and Claude Code config.

## Day-to-day

| When | Command |
|---|---|
| Shell says "run `mac`" | `mac` |
| Change a config | `chezmoi cd` → edit → `chezmoi diff` → `chezmoi apply` |
| Pull updates from another machine | `chezmoi update` |
| Inspect today's brew upgrade output | `brewlog` |

`mac` is the one entry point for anything the system has flagged. It refreshes the drift check, summarises what's pending across home files, brew packages, macOS defaults, and security baseline, then walks you through fixing it. If nothing is wrong it says so and exits.

## What runs automatically

| What | When | Where to look |
|---|---|---|
| **Homebrew upgrades** (`brew upgrade && brew doctor && brew cleanup`) | Once per day, on first shell of the day | `brewlog` (or `tail ~/.cache/brewup.log`) |
| Drift detection | Every new shell + 09:30 daily notification | Shell banner; `mac` to act |
| Brew install tracking | Every interactive `brew install/uninstall/...` | Shell banner shows pending count; `mac` merges into `Brewfile.tmpl` |
| Weekly draft PR for stale external pins | Mondays | GitHub Actions: `update-externals` |
| Monthly full-history secret scan | First of the month | GitHub Actions: `audit` |

Nothing auto-merges. Nothing auto-applies to `$HOME`. Updates land as draft PRs for you to review.

## Bootstrap a new Mac

See [`docs/runbooks/new-machine.md`](docs/runbooks/new-machine.md).

## Add or rotate a secret

```bash
chezmoi add --encrypt <path>
```

Full procedure: [`docs/runbooks/secret-rotation.md`](docs/runbooks/secret-rotation.md).

## Recover from drift

Just run `mac`. Detail: [`docs/runbooks/recover-from-drift.md`](docs/runbooks/recover-from-drift.md).

## Verification (when you change this repo)

```bash
make ci          # lint, fmt, template matrix, secret scan, brew bundle check
chezmoi diff     # preview before deploying
chezmoi apply    # deploy
```

## More

- [`CLAUDE.md`](CLAUDE.md) — agent brief: architecture, safety rules, template variables
- [`docs/decisions/`](docs/decisions) — Architecture Decision Records
- [`AGENTS.md`](AGENTS.md) — short brief for non-Claude agents

## License

MIT. See [`LICENSE`](LICENSE).

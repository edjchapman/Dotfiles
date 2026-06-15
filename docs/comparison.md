# Comparison with other dotfiles repositories

The repos below are well-known macOS-leaning dotfiles projects. The comparison is on dimensions this repo cares about — not a quality judgment of the others, which are excellent at what they do.

## Dimensions

| Repo | Stars | Templating | Encrypted secrets | Self-healing | Agent-ready | License |
|---|---|---|---|---|---|---|
| **[edjchapman/dotfiles](https://github.com/edjchapman/dotfiles)** | — | ✓ chezmoi, 4-cell matrix-tested | ✓ age | ✓ `mac` + drift banner + daily LaunchAgent | ✓ CLAUDE.md, AGENTS.md, project-scoped Claude config | MIT |
| [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) | 32k+ | ✗ shell + macOS defaults | ✗ | ✗ | ✗ | MIT |
| [holman/dotfiles](https://github.com/holman/dotfiles) | 9k+ | ✗ topic-folder convention | ✗ | ✗ | ✗ | MIT |
| [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) | 9k+ | ✗ rcm-managed | ✗ | ✗ | ✗ | MIT |
| [paulirish/dotfiles](https://github.com/paulirish/dotfiles) | 7k+ | ✗ shell + git config | ✗ | ✗ | ✗ | MIT |
| [nicknisi/dotfiles](https://github.com/nicknisi/dotfiles) | 4k+ | ✗ install.sh + symlinks | ✗ | ✗ | ✗ | MIT |

Star counts are approximate as of mid-2026 and rounded down; check the linked repo for the current figure.

## What each dimension means

- **Templating**: the same source can produce different output based on machine context (work vs personal, Apple Silicon vs Intel). "Matrix-tested" means a CI step renders all 4 combinations on every commit, catching cross-platform template bugs before merge.
- **Encrypted secrets**: credential files (AWS keys, GitHub PATs, etc.) can live in the source tree without being readable from the git history. This repo uses [age](https://github.com/FiloSottile/age) via chezmoi's `encrypted_*` filename prefix.
- **Self-healing**: when `$HOME` drifts from the source state (manual edit, package install outside the Brewfile, macOS preference changed via System Settings), the repo notices and walks you through reconciling it. Other repos generally treat the source as write-only — they install, they don't reconcile.
- **Agent-ready**: the repo includes documentation structured for LLM agents — a project brief (`CLAUDE.md`, `AGENTS.md`), explicit dangerous-ops lists, path-scoped rule files (`.claude/rules/*.md`), and project-scoped Claude Code config that ships with the repo.

## Per-repo notes

### mathiasbynens/dotfiles

The original-flavor influential one. Macro-philosophy: a `.macos` script of `defaults write` commands, hand-curated `Brewfile`, careful zsh config, `bootstrap.sh` to install. Optimized for being copy-pasted by other developers building their own setups.

What this repo does differently: collapses the install machinery and the runtime configuration into one chezmoi-managed tree, adds matrix-tested templates so the same source can serve both a personal and a work machine, and adds drift detection so the system tells you when it's out of sync.

### holman/dotfiles

Topic-folder convention: `ruby/`, `node/`, `git/`, each with its own `install.sh` and config. `script/bootstrap` discovers and runs them. Strong fit for "I want to opt in to specific topics on each new machine."

What this repo does differently: opt-in/opt-out per-topic is replaced by a single boolean `machine_type` prompt at init time. The repo trades flexibility (every topic configurable per-machine) for simplicity (two configurations: personal and work).

### thoughtbot/dotfiles

Maintained by a consulting firm; opinionated toward Ruby/JavaScript developers. Uses [rcm](https://github.com/thoughtbot/rcm) to symlink dotfiles into `$HOME`. Has a clear contribution culture.

What this repo does differently: chezmoi instead of rcm gives templating and encryption that rcm doesn't. The personal-Mac scope keeps the config opinionated in a way a consulting firm's shared repo can't be.

### paulirish/dotfiles

Smaller, personal-engineer flavor. Shell aliases, git config, macOS defaults. Lower ceremony.

What this repo does differently: similar ethos at the surface, but the underlying infrastructure (matrix CI, drift detection, encrypted secrets, runbooks) is heavier — appropriate when the repo is also the source of truth for your work machine's compliance posture.

### nicknisi/dotfiles

`install.sh` + symlinks; well-documented; a good walk-through for someone learning dotfile management.

What this repo does differently: jumps a tier — past install scripts into chezmoi's templating-and-state model. If you're following nicknisi's setup-by-following-along approach and looking for the next step, the chezmoi-based pattern here is one of the directions to go.

## Why these repos and not others

This list is a representative sample of popular Mac-focused dotfiles repos. Repos that target Linux (thoughtbot's Linux variants, many Nix-based setups), repos that bundle their own framework (Prezto, oh-my-zsh themselves), and dotfiles managed via tools like [stow](https://www.gnu.org/software/stow/) or [yadm](https://yadm.io/) are in scope for comparison but were excluded for length.

If you maintain a dotfiles repo you'd like added or have a correction, [open a discussion](https://github.com/edjchapman/dotfiles/discussions).

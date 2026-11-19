---
title: Cheatsheet
description: One-page printable command reference for chezmoi, the mac drift helper, maintenance, brew sync, age operations, and the git/PR workflow.
tags:
    - reference
---

# Cheatsheet

One-page command reference. Print-friendly (the print stylesheet hides nav and chrome).

## Drift remediation

| Goal | Command |
|---|---|
| Refresh drift cache + summary + walk through fix | `mac` (alias for `chezmoi-fix`) |
| Print the pending menu from the cache — no refresh, no prompt | `mac --menu` |
| Re-run every check and show drift state, no fix | `chezmoi-drift-check --full` |
| Drop drift cache and start fresh | `rm -rf ~/.cache/chezmoi-drift` |

## Maintenance

| Goal | Command |
|---|---|
| Run the daily Homebrew upgrade now | `brewup` |
| Follow today's upgrade output | `brewlog` |
| Report reclaimable disk space (deletes nothing) | `disk-cleanup` |
| Reclaim it | `disk-cleanup --apply` |

## Network

| Goal | Command |
|---|---|
| One-line router / internet / HTTPS snapshot, to compare before and after a change | `net-check [label]` |
| Sample router and internet ping every 10 s for 30 min, then report the share over 100 ms | `net-check --watch [label]` |

## chezmoi

| Goal | Command |
|---|---|
| Preview every change `apply` would make | `chezmoi diff` |
| Apply | `chezmoi apply` |
| Apply a single file | `chezmoi apply ~/.zshrc` |
| Pull the source repo and apply | `chezmoi update` |
| Silent if no drift; report drift if any | `chezmoi verify` |
| Capture an edited file in `$HOME` back to source | `chezmoi re-add <path>` |
| Add a NEW file as encrypted | `chezmoi add --encrypt <path>` |
| Open source-tree directory | `chezmoi cd` |
| Run init prompts again | `chezmoi init --apply edjchapman` |
| Force-refresh externals (oh-my-zsh) | `chezmoi apply --refresh-externals` |
| Show data accessible to templates | `chezmoi data` |
| Test-render a single template | `chezmoi execute-template < some_file.tmpl` |
| State DB inspection | `chezmoi state dump` |
| Wipe a specific state bucket (last resort) | `chezmoi state delete-bucket --bucket=<name>` |
| Doctor (sanity check the chezmoi install) | `chezmoi doctor` |

## Brewfile sync

| Goal | Command |
|---|---|
| Merge the brew inbox journal into `Brewfile.tmpl` | `chezmoi-brew-sync` |
| List the pending actions as TSV — no prompts, no writes | `chezmoi-brew-sync --plan` |
| Inspect the journal | `cat ~/.cache/chezmoi-brew-inbox/journal.ndjson` |
| Empty the journal (lose pending entries) | `: > ~/.cache/chezmoi-brew-inbox/journal.ndjson` |

## age operations

| Goal | Command |
|---|---|
| Show public recipient from the private key | `age-keygen -y ~/.config/chezmoi/key.txt` |
| Re-encrypt an `.age` blob in the source | `chezmoi add --encrypt <path-in-home>` |
| Decrypt for inspection (rarely needed) | `age -d -i ~/.config/chezmoi/key.txt <file>.age` |
| Generate a new keypair | `age-keygen -o /tmp/new-key.txt` |

!!! danger "Never print the private key"
    Don't `cat ~/.config/chezmoi/key.txt` into terminals you don't trust. The key starts with `AGE-SECRET-KEY-` and is dot-leak-bait. See [secret rotation](runbooks/secret-rotation.md).

## git / PR workflow

| Goal | Command |
|---|---|
| Fast-forward the current branch to its upstream; prune `[gone]` and merged branches | `git sync` |
| New branch off main | `git switch -c <name>` |
| Open PR | `gh pr create --fill` |
| Watch a PR's checks | `gh pr checks --watch` |
| List my open PRs | `gh pr list -A @me` |
| Merge a PR (squash) | `gh pr merge --squash --delete-branch` |
| View PR review threads | `gh api repos/edjchapman/dotfiles/pulls/<N>/comments` |

## Make targets

| Goal | Target |
|---|---|
| Lint, format check, template matrix, bats, audit | `make ci` |
| Every commit hook, including the ones `make ci` skips | `pre-commit run --all-files` |
| Just the linters | `make lint` |
| Just shfmt format check | `make fmt-check` |
| Render the 4-cell template matrix | `make verify-templates` |
| Quick single-render check (for pre-commit) | `make verify-templates-quick` |
| Run the bats unit tests | `make test-bats` |
| Security/secret audit | `make audit` |
| Full drift check / remediation menu (machine only) | `make drift` / `make fix` |

## Pre-commit hooks (this repo)

| Hook | What it catches |
|---|---|
| `check-merge-conflict` | Unresolved `<<<<<<< HEAD` markers |
| `check-yaml` / `check-toml` | Syntax errors |
| `check-added-large-files` | Accidentally committed large files |
| `end-of-file-fixer` | Missing trailing newline |
| `trailing-whitespace` / `mixed-line-ending` | Stray spaces at line ends; CRLF line endings |
| `shfmt` | Shell formatting |
| `yamllint` | YAML style violations |
| `gitleaks` | Common secret patterns (AWS, GitHub, etc.) |
| `markdownlint-cli2` | Markdown style |
| `shellcheck-via-make` | Shell linting (template-aware) |
| `check-bash4-isms` | Bash 4 constructs in scripts that must run under macOS's bash 3.2 |
| `chezmoi-execute-template` | Template renders for at least one cell |
| `codespell` | Common typos |
| `mkdocs-config-validate` | mkdocs.yml syntax + plugin names |
| `check-mermaid-fences` | Mermaid block declarations |
| `check-docs-nav` | Orphan docs pages |
| `check-requirements-sorted` | docs/requirements.txt alphabetised |
| `check-root-mirrors` | Root-file mirror includes intact |
| `check-codex-mirrors` | A Codex command port that has drifted from its `.claude/commands` source |

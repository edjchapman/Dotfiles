---
title: Gotchas
description: Lessons learned the hard way. Common pitfalls when working with chezmoi, age, the drift system, and macOS scripts.
tags:
    - reference
---

# Gotchas

Things that have bitten the maintainer and would bite a new contributor — collected so they don't bite anyone again. Each entry is short. The fix is usually obvious once you know the rule.

## Source-of-truth violations

!!! danger "Don't edit `$HOME` files directly"
    Editing `~/.zshrc` or `~/.gitconfig` directly works *until* the next `chezmoi apply` silently overwrites it. Always edit the source (`dot_zshrc`, `dot_gitconfig.tmpl`) in this repo, then `chezmoi apply`.

    **Why**: chezmoi treats the source as truth. Anything in `$HOME` is just the rendered output. The mental model is "the repo IS the dotfiles, not a backup of them."

!!! warning "`chezmoi re-add` is the one exception"
    If you absolutely must edit in `$HOME` first (rare — usually because a TUI dropped a config there), use `chezmoi re-add <file>` to pull the change back into the source. **Don't** mix re-add with subsequent edits in the source on the same file — you'll lose track of which side has the latest content.

## Secret-handling traps

!!! danger "Always use `--encrypt` for any file with credentials"
    `chezmoi add ~/.zshrc.local` (no flag) commits plaintext. Once committed, it's in git history forever. Use `chezmoi add --encrypt ~/.zshrc.local`.

    **Why**: `gitleaks` and `ggshield` pre-commit hooks catch most patterns, but not all. The `--encrypt` flag is the deterministic guard.

!!! danger "The age recipient is *public* but the key is *private*"
    The `recipient = "age1..."` line in `.chezmoi.toml.tmpl` is committed and visible on GitHub. That's intentional — it identifies who can decrypt. The matching private `key.txt` is what unlocks it; **never** commit that file or anything generated from it.

!!! warning "Losing the key locks you out permanently"
    No key = no decryption = none of the `*.age` blobs in this repo are usable. Back up the key **before** you need to. Four strategies are in the [secret rotation runbook](runbooks/secret-rotation.md#back-up-the-age-key).

## Template and rendering traps

!!! warning "Templates only render at apply time"
    `chezmoi status` does NOT re-render. If you edit a template, you must `chezmoi diff` (which renders) to see the actual change.

!!! warning "A broken template can brick your shell"
    If `dot_zshrc.tmpl` renders to invalid shell syntax, your next `chezmoi apply` writes a broken `~/.zshrc`, and your next terminal session may fail to start. Always:

    1. `make verify-templates` first
    2. `chezmoi diff` and read every line
    3. Only then `chezmoi apply`

!!! info "ShellCheck doesn't understand template syntax"
    `{{ if eq .machine_type "personal" }}` is opaque to ShellCheck. The repo's `make lint` target strips template directives before piping to ShellCheck, so syntax inside template conditionals isn't actually checked. Be extra careful in template-only branches.

!!! info "Whitespace control matters in templates"
    `{{- ... -}}` trims surrounding whitespace; `{{ ... }}` does not. Forgetting the dashes leaves blank lines that can break TOML/YAML rendering.

## Drift detection traps

!!! warning "The drift cache can be ahead of reality"
    The shell banner reads `~/.cache/chezmoi-drift/state` (cheap, instant). If you fix drift via direct `chezmoi apply`, the cache doesn't auto-update — the banner may still show pending. Run `mac` (which rewrites the cache) to clear.

!!! info "Brew journal is async"
    The `brew` wrapper records `install/uninstall` events to `~/.cache/brewup.log` *but* doesn't immediately update `Brewfile.tmpl`. You must run `chezmoi-brew-sync` (interactive) to merge the journal into source.

!!! tip "Use `mac` instead of remembering which helper to run"
    There are ~6 helpers (`chezmoi-drift-check`, `chezmoi-brew-sync`, `chezmoi-defaults-audit`, `chezmoi-security-audit`, `chezmoi-brew-record`, `chezmoi-fix`). You don't need to remember which one to run — `mac` figures it out for you.

## CI / branch protection traps

!!! warning "Self-update PRs are draft-only by design"
    `update-externals.yml` opens drafts so they don't auto-merge. Don't change this — the review step is the whole point of the channel.

!!! warning "Branch protection requires ALL 13 checks"
    Including the new `docs checks passed` aggregate. If you push a docs change and the docs job fails, `main` cannot accept the PR until it's fixed.

!!! info "Squash merges only — no merge commits"
    Repo settings disable `merge-commit` and `rebase-merge`. Trying to merge any other way will fail at the merge step.

## macOS-specific traps

!!! warning "`sudo` is only allowed in `run_once_after_05-macos-sudo.sh`"
    Every other script must avoid `sudo`. The chezmoi state DB doesn't track sudo prompts well, and putting `sudo` in `run_onchange_*` means it re-prompts on every apply.

!!! info "LaunchAgent doesn't fire when screen is locked"
    The daily 09:30 drift notification can be deferred up to 12 hours if the Mac is asleep or screen-locked. If the schedule matters, prefer cron via `launchd` `StartCalendarInterval` (already configured).

!!! info "App Store apps need `mas` to install via Brewfile"
    `mas` is in the Brewfile and lets `mas` lines work. But you must be signed in to the App Store first. The new-machine runbook covers this.

## CLI / workflow traps

!!! warning "`gh pr merge --rebase` is disabled at the repo level"
    The repo only allows squash merges. The `--rebase` and `--merge` flags will fail at the API call.

!!! tip "`git sync` auto-prunes `[gone]` branches"
    Since 2026-06-15, the alias detects branches squash-merged and deleted upstream, and prunes them locally. Don't manually `git branch -D` — let `git sync` do it.

!!! warning "Don't `--no-verify` past the pre-commit hooks"
    `git commit --no-verify` bypasses every secret-scan and lint hook. If a hook is genuinely wrong, fix it. The hooks exist to stop secret leaks — the cost of bypassing is much higher than the cost of fixing the hook.

## See also

- [Troubleshooting](troubleshooting.md) — when you have an error, this is where the *fix* lives.
- [FAQ](faq.md) — questions instead of pitfalls.
- [Architecture](architecture.md) — why the system is shaped the way it is.

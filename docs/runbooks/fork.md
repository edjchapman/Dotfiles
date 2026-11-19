---
title: Fork this repo
description: The five maintainer-specific things to change before this dotfiles repo works on your own Mac — age recipient, encrypted blobs, git identity, Claude Code config clone, and personal Brewfile entries.
tags:
    - runbook
---

# Runbook: fork this repo for your own Mac

The repo is one person's machine config, not a template. Its secrets are encrypted to the maintainer's age key, so the bootstrap one-liner fails at the decrypt step for anyone else. Fork it, change the five things below, then apply.

!!! info "How far this is tested"
    Tested on 19 Nov 2026 against a scratch copy of the repo with a throwaway age key. Unchanged, `chezmoi diff` stops at "no identity matched any of the recipients". With steps 2–5 applied it renders all 43 targets with no decryption error, and none of the maintainer's name, email or key appear in the output.

    Not exercised: the `chezmoi init` prompts, the Homebrew install, the macOS defaults, or the script that asks for your password. Read your own first `chezmoi diff` before you apply.

## What is specific to the maintainer

| What | Where | What to do |
|---|---|---|
| Age recipient | `.chezmoi.toml.tmpl` (`recipient = "age1…"`) | Replace with your own public key |
| Encrypted secrets | `encrypted_private_dot_zshrc.local.age`, `dot_aws/encrypted_private_config.age` | Delete; add your own later |
| Git identity | `dot_gitconfig.tmpl`, the `[user]` block | Replace the name and email |
| Claude Code config | `run_onchange_after_07-claude-global-symlinks.sh` | Delete, or point at your own repo |
| Packages and apps | `Brewfile.tmpl` | Remove what you don't want |

## Prerequisites

- macOS, with [Homebrew](https://brew.sh/) installed.
- `brew install chezmoi age`
- A GitHub account, and a fork of `edjchapman/dotfiles`.

## Steps

### 1. Clone your fork where chezmoi expects it

```bash
git clone https://github.com/<you>/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
```

Don't run `chezmoi init --apply` yet — that applies before you have changed anything.

### 2. Generate your age key and swap the recipient

```bash
mkdir -p ~/.config/chezmoi
age-keygen -o ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

`age-keygen` prints a public key starting `age1`. Put it in `.chezmoi.toml.tmpl` as the `recipient`. Back the private key up somewhere other than this Mac: without it your own secrets are unrecoverable. See [Secret rotation](secret-rotation.md#back-up-the-age-key).

### 3. Remove the maintainer's secrets

```bash
git rm encrypted_private_dot_zshrc.local.age dot_aws/encrypted_private_config.age
```

Nothing breaks without them: `~/.zshrc` sources `~/.zshrc.local` only if it exists. Add your own once the first apply has succeeded:

```bash
chezmoi add --encrypt ~/.zshrc.local
```

### 4. Set your git identity

In `dot_gitconfig.tmpl`, replace the `name` and `email` in the `[user]` block. The signing key is not hard-coded — it comes from the prompt in step 7.

### 5. Decide what to do about Claude Code config

`run_onchange_after_07-claude-global-symlinks.sh` clones the maintainer's `claude-code-config` repo and symlinks `~/.claude/{CLAUDE.md,settings.json,agents,commands,rules,skills}` into it. Unless you want someone else's global Claude Code config:

```bash
git rm run_onchange_after_07-claude-global-symlinks.sh
```

Or change the clone URL in that script to a repo of your own with the same layout.

### 6. Trim the Brewfile and the machine-specific scripts

`Brewfile.tmpl` installs every package on the maintainer's Mac. Delete the lines you don't want. Entries inside `{{ if eq .machine_type "personal" }}` blocks are skipped when you answer `work` in step 7. The `mas` lines need you to be signed in to the App Store.

These scripts also encode personal choices. Read them before the first apply and edit to taste:

| Script | What it sets |
|---|---|
| `run_onchange_03-macos-defaults.sh` | Dock, Finder, keyboard, privacy and app preferences |
| `run_onchange_04-dock-layout.sh.tmpl` | Which apps are in the Dock |
| `run_onchange_05-login-items.sh` | Which apps open at login |
| `dot_config/chezmoi/scripts/executable_macos-sudo.sh` | Firewall, Touch ID for `sudo`, energy and auto-update settings; asks for your password |
| `dot_config/iterm2/private_com.googlecode.iterm2.plist` | The maintainer's iTerm2 preferences, including a profile working directory of `/Users/ed`. Delete it or replace it with your own export |

### 7. Initialise, preview, apply

```bash
chezmoi init          # prompts for machine type and GPG key ID; writes your config
chezmoi diff          # read every line
chezmoi apply
```

If `chezmoi diff` fails with "no identity matched any of the recipients", an `*.age` file encrypted to the maintainer's key is still in the source — go back to step 3.

### 8. Commit and push to your fork

```bash
git commit -am "chore: adapt for my machine"
git push
```

From then on a new Mac is the same two steps the maintainer uses: place your key in `~/.config/chezmoi/key.txt`, then

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <you>
```

## What you can leave for later

- **Repo identity.** `mkdocs.yml`, the README badges and `.lychee.toml` name `edjchapman/dotfiles` and the maintainer's docs domain. Nothing on your Mac depends on them.
- **CI.** The workflows run in your fork as they are. `BOT_PAT` is optional; they fall back to `GITHUB_TOKEN`.
- **The docs.** The runbooks describe the maintainer's machine. [New machine bootstrap](new-machine.md) is still a fair picture of what the first apply does.

## See also

- [New machine bootstrap](new-machine.md) — what the first apply runs, in order.
- [Secret rotation](secret-rotation.md) — adding secrets and backing up your key.
- [FAQ](../faq.md) — why this repo is not a template repository.

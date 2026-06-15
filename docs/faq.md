# FAQ

## Why chezmoi, not stow / yadm / a bare git repo in `$HOME`?

Full reasoning in [ADR-0001](decisions/0001-chezmoi-as-source-of-truth.md). In one sentence: chezmoi gives you templating, encryption, idempotent scripts, external pinning, and drift detection in a single tool. Doing all of those with stow + bash + git-crypt + manual SHA-tracking is doable but bespoke.

## How do I bootstrap a clean Mac with this repo?

Full procedure: [`docs/runbooks/new-machine.md`](runbooks/new-machine.md). Short version: drop your age private key in `~/.config/chezmoi/key.txt`, then:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply edjchapman
```

(Replace `edjchapman` with your own fork's owner.)

## What happens if I lose my age key?

The `*.age` blobs in the repo become undecryptable. The underlying secrets (AWS keys, GitHub PATs, etc.) are mostly *re-issuable* upstream — annoying, not fatal. Back up the key before this happens — see "Back up the age key" in [`docs/runbooks/secret-rotation.md`](runbooks/secret-rotation.md) for strategies.

## Can I fork this for my own use?

Yes, with two caveats:

1. The age recipient in `.chezmoi.toml.tmpl` is mine. You'll need to generate your own keypair (`age-keygen -o ~/.config/chezmoi/key.txt`) and create your own `*.age` blobs from scratch — you can't decrypt mine.
2. `Brewfile.tmpl` includes personal-only entries gated on `{{ if eq .machine_type "personal" }}` (Steam, Tidal, etc.). Strip or replace what doesn't apply.

The right fork pattern is **clone → adapt → re-encrypt with your key**, not "template-instantiate". That's why this repo is not flagged as a template repository — see [ADR-0004](decisions/0004-rebrand-public-showcase.md).

## Does this work on Linux?

Not by design. The repo assumes macOS: `brew`, `defaults write`, `dockutil`, `mas`, Touch ID for sudo, LaunchAgents, FileVault, all of it. A Linux-targeted fork could keep the chezmoi structure and replace the macOS-specific scripts with `apt` / `dnf` / `nix` equivalents, but that's a heavy lift — close to a rewrite.

## How does drift detection work?

Three layers:

1. **Every shell startup**: a banner runs `chezmoi-drift-check` and reports if any of (`$HOME` files, Brewfile, macOS defaults, security baseline, external pins) is out of sync.
2. **Daily at 09:30**: a LaunchAgent (`com.user.chezmoi-drift.plist.tmpl`) fires `chezmoi-fix --alert`, which produces a clickable macOS notification.
3. **On demand**: typing `mac` runs the same check, summarises what's drifted, and walks you through fixing each source.

Full story: [`docs/runbooks/recover-from-drift.md`](runbooks/recover-from-drift.md).

## Why is `mac` the only command I need?

It's not, strictly — `chezmoi diff`, `chezmoi apply`, `chezmoi cd`, and the per-tool aliases (`brewlog`, `chezmoi-security-audit`, `chezmoi-defaults-audit`) are all still useful for power use. But `mac` is the **single entry point when something is drifted**. It refreshes the check, summarises every pending source of drift, and walks through fixing each. If nothing is wrong it says so and exits. That collapses the day-to-day cognitive load to one alias.

## How is this different from a Brewfile and a git repo of dotfiles?

A `Brewfile` plus a git repo handles package installs and config-file storage. This repo adds, on top of that:

- **Templating**: same source supports `personal` / `work` and `arm64` / `amd64` without branching.
- **Encryption**: secrets live in the repo (encrypted), not in a separate password manager you have to sync.
- **Idempotency**: scripts re-run safely; `chezmoi apply` is the only deploy primitive.
- **Drift detection**: when `$HOME` falls out of sync with the source, you know.
- **CI**: every change is matrix-tested across four `machine_type × arch` combinations before merge.
- **Self-update PRs**: external pins refresh as draft PRs you review, not silent auto-updates.

In other words: a Brewfile + dotfiles repo is the starting point; this is what that looks like after ~2 years of accreting safety nets.

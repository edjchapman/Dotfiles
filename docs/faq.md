# FAQ

## Why chezmoi, not stow / yadm / a bare git repo in `$HOME`?

Full reasoning in [ADR-0001](decisions/0001-chezmoi-as-source-of-truth.md). In one sentence: chezmoi gives you templating, encryption, idempotent scripts, external pinning, and drift detection in a single tool. Doing all of those with stow + bash + git-crypt + manual SHA-tracking is doable but bespoke.

## How do I bootstrap a clean Mac with this repo?

It depends whose Mac it is:

- **Yours** — the repo's secrets are encrypted to the maintainer's key, so `init --apply edjchapman` fails at the decrypt step for anyone else. Fork it first: [Fork this repo](runbooks/fork.md).
- **The maintainer's** — place the age private key in `~/.config/chezmoi/key.txt`, then run the one-liner in [New machine bootstrap](runbooks/new-machine.md).

## What happens if I lose my age key?

The `*.age` blobs in the repo become undecryptable. The underlying secrets (AWS keys, GitHub PATs, etc.) are mostly *re-issuable* upstream — annoying, not fatal. Back up the key before this happens — see "Back up the age key" in [`docs/runbooks/secret-rotation.md`](runbooks/secret-rotation.md) for strategies.

## Can I fork this for my own use?

Yes. Five things are specific to the maintainer and must change first: the age recipient, the two encrypted blobs, the git identity, the Claude Code config clone, and the personal Brewfile entries. [Fork this repo](runbooks/fork.md) walks through each.

The right fork pattern is **fork → adapt → re-encrypt with your key**, not "template-instantiate". That's why this repo is not flagged as a template repository — see [ADR-0004](decisions/0004-rebrand-public-showcase.md).

## Does this work on Linux?

Not by design. The repo assumes macOS: `brew`, `defaults write`, `dockutil`, `mas`, Touch ID for sudo, LaunchAgents, FileVault, all of it. A Linux-targeted fork could keep the chezmoi structure and replace the macOS-specific scripts with `apt` / `dnf` / `nix` equivalents, but that's a heavy lift — close to a rewrite.

## How does drift detection work?

`chezmoi-drift-check` measures five drift signals (`$HOME` files, missing brew packages, extra brew packages, macOS defaults, security baseline) and writes them to a cache. Four triggers re-run it:

1. **Every shell startup**: the banner reads the cache and names what is pending; if the cache is older than 4 hours, a refresh runs in the background.
2. **Daily at 09:30**: a LaunchAgent (`com.user.chezmoi-drift`) runs the full check and posts a macOS notification if there is drift.
3. **After `brew`, `mas` and `chezmoi apply`**: shell wrappers refresh the cache so the banner reflects what you just did.
4. **On demand**: typing `mac` runs the same check, summarises what's drifted, and walks you through fixing each source.

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

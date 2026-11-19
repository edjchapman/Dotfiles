---
description: Bring this chezmoi environment up to date — sync the source repo, then report pending update PRs, stale pins, drift and outdated brew packages.
allowed-tools: Bash(git status:*), Bash(git sync), Bash(git fetch:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git rev-list:*), Bash(git ls-remote:*), Bash(git -C:*), Bash(gh pr list:*), Bash(chezmoi diff:*), Bash(chezmoi verify), Bash(chezmoi-drift-check:*), Bash(brew outdated:*), Read, Grep
---

Update the environment in the order below. The order matters: the source repo is synced first so every later check reads the current source state.

The only thing this command mutates is the source repo's git state (step 1). Everything that changes `$HOME` or the installed packages is handed to the user at the end.

## 1. Sync the source repo

1. Run `git status -sb` and note the branch and `git rev-parse HEAD`.
2. On `main`: run `git sync` (fast-forward only, autostashes local edits, prunes merged branches). If it refuses because the branch has diverged, stop and report — do not rebase, reset or merge by hand.
3. On any other branch: run `git fetch --prune origin` only, and report how far the branch and local `main` are behind `origin/main` (`git rev-list --count`). Do not switch branches.
4. List what arrived with `git log --oneline <old-HEAD>..HEAD`, or say "already up to date".

## 2. Pending update PRs

Run `gh pr list --state open --json number,title,isDraft,headRefName,statusCheckRollup`.

Call out the self-update PRs — branches `chore/weekly-externals-update`, `chore/weekly-precommit-update`, `chore/weekly-mas-availability`, `chore/weekly-vscode-health` — and the release-please PR, each with its draft state and check result. Do not mark ready, merge or close any of them; ask first.

## 3. External pins

Compare the oh-my-zsh SHA pinned in `.chezmoiexternal.toml` with `git ls-remote https://github.com/ohmyzsh/ohmyzsh refs/heads/master`. A stale pin with no open `chore/weekly-externals-update` PR is worth flagging; a stale pin with one is already handled.

Then check the global Claude config clone, read-only: `git -C ~/Development/claude-code-config fetch --quiet` followed by `git -C ~/Development/claude-code-config status -sb`. Report ahead/behind and whether the tree is dirty. Never pull there — it is a working clone with its own workflow.

## 4. Drift between source and `$HOME`

1. Run `chezmoi-drift-check --full` (exit 0 clean, 1 drift, 2 a check could not run). On exit 2, report which check failed rather than treating the counts as real.
2. Run `chezmoi diff --exclude=externals` and summarise per file: name, change type, one-line nature of the change.
   - `encrypted_*.age` targets: say "encrypted secret changed", never show the diff body.
   - `run_once_*` / `run_onchange_*` scripts: flag them — applying runs them, with side effects.
3. If the diff is empty, run `chezmoi verify` to confirm zero drift.

## 5. Homebrew currency

Run `brew outdated` and report the count and names. Report `BREWUP_FAILED` from the drift check too — a failed daily `brewup` is why packages stay outdated. Do not upgrade anything.

## Report

Finish with one table — area, state, action needed — covering: source repo, update PRs, external pins, claude-code-config, `$HOME` drift, brew.

Then list the commands for the user to run in their own terminal, only the ones that apply:

| Situation | Command |
|---|---|
| Source changes waiting to deploy | `make apply` |
| `$HOME` edited locally, brew extras, or mixed-direction drift | `mac` |
| Outdated packages or a failed daily upgrade | `brewup` |
| Stale oh-my-zsh pin, no update PR open | `gh workflow run update-externals.yml` |

If nothing needs doing, say "environment is up to date" and stop.

Hard rules: never run `chezmoi apply`, `chezmoi update`, `chezmoi re-add`, `make apply` or any `brew` command that installs or upgrades — they are denied here by design. Never switch branches or discard local changes to make the sync succeed.

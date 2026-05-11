# Runbook: recover from drift

`chezmoi verify` exits non-zero, or `chezmoi diff` shows changes you didn't make. This is "drift" — `$HOME` no longer matches the source state.

## How drift surfaces

Three machine-resident signals run automatically; you don't need to remember to check:

- **Shell banner.** A new zsh prints a one-line yellow banner (e.g. `drift: home: 1, brew-extra: 1 …`) when `~/.cache/chezmoi-drift/state` shows non-zero counts. `export CHEZMOI_DRIFT_QUIET=1` silences the banner only — the cache still refreshes in the background and the daily launchd notification still fires.
- **Daily macOS notification.** The launchd agent `com.user.chezmoi-drift` (loaded from `~/Library/LaunchAgents/com.user.chezmoi-drift.plist`) runs at 09:30 and posts a Notification Center alert if drift is found. Logs at `~/Library/Logs/chezmoi-drift.log`.
- **`brew` / `mas` wrapper.** After `brew install/uninstall/reinstall/tap/untap` (or `mas install/uninstall/purchase`), the wrapper appends an event to `~/.cache/chezmoi-brew-inbox/journal.ndjson` and refreshes the drift cache asynchronously. The shell banner on the next session shows the pending count; `chezmoi-brew-sync` is the interactive merge tool that updates `Brewfile.tmpl` after your review. See [`brew-sync.md`](brew-sync.md).

The single source of truth is the script `~/.local/bin/chezmoi-drift-check` — `make drift` is a shortcut for `chezmoi-drift-check --full`.

The summary line breaks down as:

| Field | Meaning | Typical fix |
|---|---|---|
| `home: N` | N files chezmoi manages differ from source. | `chezmoi diff` → either `chezmoi apply` (source wins) or `chezmoi re-add` (target wins). |
| `brew-missing: N` | N entries in `Brewfile.tmpl` not installed on this machine (typically because something was uninstalled outside the Brewfile flow). | `brew bundle install --file=<(chezmoi execute-template < $(chezmoi source-path)/Brewfile.tmpl)` — `chezmoi apply` only re-runs the brew script when `Brewfile.tmpl` content changed, so it won't help here unless you also edit the Brewfile. |
| `brew-extra: N` | N packages installed locally but not in `Brewfile.tmpl`. | Either add them to `Brewfile.tmpl` (right group) or `brew uninstall`. |
| `ERROR: …` | A check could not be run. Counts in the same line may be incomplete. | Re-run `chezmoi-drift-check --full` directly to see the underlying error message; common causes are a broken `Brewfile.tmpl` template or a missing age key for `chezmoi status`. |

## Diagnose

```bash
chezmoi diff --exclude=externals
```

Three possible causes per file:

| Symptom | Cause | Fix |
|---|---|---|
| Source ahead | The repo was updated on another machine and `chezmoi update` hasn't run here. | `chezmoi diff` then `chezmoi apply` (or `make apply`). |
| Target ahead | You (or an installer) edited the file in `$HOME` directly. | `chezmoi re-add <file>` if the edit should win. Otherwise `chezmoi apply <file>` to discard. |
| Both changed | A merge — both source and target diverged from the last apply. | Inspect both versions, decide manually. |

## Resolve, file by file

```bash
# Pull source-side changes into $HOME (target loses):
chezmoi apply ~/.zshrc

# Push target-side changes into source (source loses):
chezmoi re-add ~/.zshrc

# Or keep both — diff and patch manually:
chezmoi diff ~/.zshrc > /tmp/patch
$EDITOR /tmp/patch
# … then apply selectively.
```

## When `chezmoi verify` errors with "no identity matched"

The age key is missing or unreadable.

```bash
ls -la ~/.config/chezmoi/key.txt   # must be 600 and readable
```

If absent, see [`new-machine.md`](new-machine.md) step 1 and re-transfer from another machine.

## When externals are stale

```bash
chezmoi apply --refresh-externals --dry-run    # preview
chezmoi apply --refresh-externals              # actually fetch
```

The weekly `update-externals.yml` workflow opens a PR if upstream has moved past the pinned SHA. If you need an immediate refresh (e.g. a security patch in `oh-my-zsh`), bump the SHA in `.chezmoiexternal.toml` and PR it manually.

## Last resort

If state is so confused that `chezmoi diff` is unreadable:

```bash
chezmoi cd
git status                          # is the source clean?
chezmoi state delete-bucket --bucket=entryState   # forget chezmoi's view of $HOME
chezmoi apply --dry-run             # rebuild the picture
```

Only run `chezmoi apply` (no dry-run) once the diff looks correct.

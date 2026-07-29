---
paths:
    - ".chezmoi.toml.tmpl"
    - ".chezmoiexternal.toml"
    - ".chezmoiignore"
    - ".chezmoiversion"
---

# Chezmoi config files

These four files steer chezmoi itself. Mistakes here have repo-wide blast radius (every machine on next apply). Treat changes with extra care.

## `.chezmoi.toml.tmpl` — init prompts and encryption

Defines the prompt-once values stored in chezmoi's per-machine state:

- `machine_type` — `personal` or `work` (chosen at `chezmoi init`)
- `gpg_signing_key` — GPG key ID or empty

Also declares the age recipient. **The recipient is public and committed.** The matching private key (`~/.config/chezmoi/key.txt`) is not.

If you change the recipient, every `*.age` file must be re-encrypted (see [`docs/runbooks/secret-rotation.md`](../../docs/runbooks/secret-rotation.md)).

## `.chezmoiexternal.toml` — pinned externals

External archives and git repos pulled in at apply time:

- `oh-my-zsh` — pinned commit SHA, refreshed weekly. To bump it, replace the SHA. The
  weekly `update-externals.yml` workflow opens a draft PR doing this automatically.

`claude-code-config` is **not** an external. It's an actively-developed working clone at
`~/Development/claude-code-config` — a git-repo external would `git pull --rebase` into
the working tree at apply time and fail whenever it's dirty. It's bootstrapped (cloned if
missing) and symlinked into `~/.claude/` by `run_onchange_after_07-claude-global-symlinks.sh`;
updates flow through the normal git workflow in that repo.

## `.chezmoiignore` — what stays in source

Controls which **target paths** do NOT deploy to `$HOME`. Two rules govern it:

- chezmoi **auto-ignores every source entry beginning with `.`** (except `.chezmoi*`), so dot-prefixed repo files — `.github`, `.gitattributes`, `.gitleaks.toml`, `.pre-commit-config.yaml`, `.yamllint.yaml`, `.claude`, the repo's own `.editorconfig`, … — never deploy whether or not they're listed here. Entries for them are redundant (documentation at most).
- **Non-dot top-level files must be listed explicitly**, or they land in `$HOME` on next apply. These are the entries that actually matter: `LICENSE`, `Makefile`, `README.md`, `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `docs`, `mkdocs.yml`, `site`, `assets`, `tests`, `scripts`, `standups`, and `Brewfile` (the *rendered* target — **not** `Brewfile.tmpl`; `.chezmoiignore` matches post-render target paths).

Because it matches **target** paths, a `dot_foo` source (→ `~/.foo`) is suppressed by a `.foo` entry. That is exactly why the repo's `dot_editorconfig` must **not** be shadowed by an `.editorconfig` entry here.

After editing, **verify with `chezmoi diff`**:

```bash
chezmoi diff | grep '^diff --git'
```

If a new top-level file appears in the diff, the ignore list is missing it.

## `.chezmoiversion` — minimum required chezmoi version

Bump only when adopting features from a newer chezmoi release. Document the reason in the commit message.

## Workflow for any change here

1. Edit the file.
2. `make verify-templates` if `.chezmoi.toml.tmpl` was edited.
3. `chezmoi diff` end-to-end. Read every line.
4. If anything unexpected appears, stop — do not apply. Investigate first.

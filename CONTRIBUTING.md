# Contributing

This is a personal dotfiles repo: opinionated, scoped to one person's Mac, and not a general-purpose framework. PRs are welcome anyway — bug reports, doc fixes, ideas, and forks-with-improvements all help.

For ideas, ergonomics, and "would you accept a PR for X" questions, open a **discussion** rather than an issue. For confirmed bugs or concrete asks, an issue is fine.

## Before you open a PR

Read [`CLAUDE.md`](CLAUDE.md) — it's the agent brief, but the same rules apply to humans:

- **Never** edit files in `$HOME` directly. Edit the source state in this repo, then `chezmoi apply`.
- **Never** commit secrets unencrypted. Use `chezmoi add --encrypt <path>`.
- **Never** push to `main` — it's protected. All changes land via squash-merged PR.
- **Never** bypass pre-commit hooks. They exist to catch secret leaks before they reach git.

## Local verification

Every PR must pass [13 CI checks](docs/runbooks/branch-protection.md) on `main`. Reproduce them locally before pushing:

```bash
make ci          # lint, fmt-check, verify-templates matrix, audit, doctor, verify
chezmoi diff     # preview what would change in $HOME
```

If `chezmoi diff` shows files you didn't intend to touch, stop and investigate — `.chezmoiignore` is probably missing an entry. Per [`.claude/rules/chezmoi-config.md`](.claude/rules/chezmoi-config.md), every new top-level repo-metadata file (docs, CI config, lint config, governance) must be added to `.chezmoiignore` so it doesn't deploy to `$HOME`.

## Template changes

Templates render against `personal/work × arm64/amd64`. Validate all four combinations:

```bash
make verify-templates
```

Or for a single template:

```bash
chezmoi execute-template \
  --init --source="$(pwd)" \
  --override-data '{"machine_type":"work","gpg_signing_key":"test"}' \
  < some_file.tmpl
```

## Branch and commit conventions

- Branch off `main`. Name branches descriptively (`feat-<short-name>`, `fix-<short-name>`, `docs-<short-name>`).
- Commits inside the branch are throwaway — the PR squashes to one commit using the PR title and body. Write a Conventional Commits PR title (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`).
- Resolve every inline review thread before merging — `required_conversation_resolution` is enabled.
- The branch must be up to date with `main` before merge (`strict: true`). CI re-runs on the merge candidate.

## Where to look

- [`README.md`](README.md) — what the repo is, why it exists, how to bootstrap a Mac.
- [`CLAUDE.md`](CLAUDE.md) — agent brief: full command reference, dangerous-ops list, template vars.
- [`AGENTS.md`](AGENTS.md) — short brief for non-Claude agents.
- [`docs/runbooks/`](docs/runbooks) — new-machine bootstrap, secret rotation, drift recovery, brew sync, branch protection.
- [`docs/decisions/`](docs/decisions) — architecture decision records (chezmoi choice, age encryption, machine-type templating, public-showcase rebrand).
- [`SECURITY.md`](SECURITY.md) — how to report a vulnerability.
- [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) — community expectations.

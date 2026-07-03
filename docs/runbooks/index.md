# Runbooks

Operational procedures for the day-to-day and infrequent-but-important tasks. Each runbook is self-contained — you should be able to execute it without reading anything else first.

## Day-to-day

- [Recover from drift](recover-from-drift.md) — when `$HOME` falls out of sync with the source state and `mac` flags it.
- [Brew sync](brew-sync.md) — merging interactive `brew install/uninstall` events back into `Brewfile.tmpl` so they survive the next bootstrap.

## Infrequent

- [New machine bootstrap](new-machine.md) — taking a clean macOS install to fully configured. End-to-end procedure.
- [Secret rotation](secret-rotation.md) — rotating a single secret (AWS key, GitHub PAT) or the age key itself. Includes "Back up the age key" strategies.
- [Branch protection](branch-protection.md) — the 13 required CI checks on `main`, how to recreate the protection rules if they're disabled, and how to add new required checks.

## When to write a new runbook

A new runbook is warranted when:

- The procedure has more than three steps **and** is infrequent enough that you'll forget it between runs.
- The procedure has a safety-critical step (secret handling, destructive `chezmoi` action) that benefits from a checklist.
- An operational pattern recurs across multiple machines (new bootstrap, drift recovery) and you want one canonical source.

For everything else, an [ADR](../decisions/index.md) or a comment in the code is usually the right home.

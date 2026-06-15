# ADR 0004: Rebrand for public showcase, no rename

- **Status:** Accepted
- **Date:** 2026-06-15

## Context

The repo had reached production-grade maturity by release `1.2.0`: matrix-tested templates across `personal/work × arm64/amd64`, drift detection from the shell banner with a single `mac` remediation entry point, age-encrypted secrets with layered pre-commit and CI scanning, weekly draft PRs for external pin refreshes, and first-class Claude Code project-scoped configuration. The capability is unusual for a dotfiles repo — closer to small ops infrastructure than a personal config dump.

The README, by contrast, was a 63-line operational reference written for someone who already knew chezmoi: a single CI badge at the top, two command tables, links into the runbooks. No hero, no demo, no comparison, no FAQ, no narrative for why the approach is worth copying. No social preview image. Discussions disabled. No issue templates. No Pages site. No CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / CHANGELOG.

A rebrand was needed to close the gap between what the repo *is* and what a cold visitor *perceives* on landing.

## Decision

Rebrand the repo for a public showcase audience. Specifically:

1. **Keep the slug `edjchapman/dotfiles`.** Do not rename.
2. **Rewrite the README** with a hero, demo, comparison table, FAQ, and feature highlights deep-linking to the existing runbooks and ADRs.
3. **Enable Discussions, add issue templates, add a social preview image, set up a GitHub Pages site** at `edjchapman.github.io/dotfiles` using mkdocs-material, expand the topics list.
4. **Add governance files** (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CHANGELOG.md`).
5. **Do not flag the repo as a template repository.**

## Rationale

### Why no rename

- The slug is already discoverable, embedded in `chezmoi init edjchapman/dotfiles` instructions, baked into existing badge URLs, and referenced from the `claude-code-config` external. Renaming would force coordinated edits across all of those, plus break links anyone has shared. GitHub's slug redirect helps but isn't free — old badge images break, old API queries 404 until cached redirects propagate.
- A "project name" different from `dotfiles` would imply this is a tool to install separately, which it isn't — it's a single-machine source of truth that other people would fork rather than depend on.
- The brand is the README, the social preview, the topics, the description — not the slug. All of those can change without coordination cost.

### Why mkdocs-material for Pages

- The existing `docs/runbooks/` and `docs/decisions/` are already markdown with the right heading hierarchy. mkdocs-material's nav config maps 1:1 onto them without restructuring.
- Dark-mode toggle, instant navigation, full-text search, table-of-contents auto-generation. All matter for a showcase audience landing on `edjchapman.github.io/dotfiles` for the first time.
- Rejected alternatives: **Jekyll** (zero-config but stock theme is dated and feels like a default-GitHub site rather than an intentional one); **vanilla HTML** (every page becomes hand-maintained); **Docusaurus** (heavier toolchain, React-y polish that overshoots a dotfiles audience).

### Why not flag as a template repository

- The age recipient committed in `.chezmoi.toml.tmpl` is keyed to one person's private key. A template-instantiated copy would inherit that recipient and could not decrypt anything.
- The `Brewfile.tmpl` contains personal-only entries under `{{ if eq .machine_type "personal" }}` (Steam, Tidal, etc.) that would be irrelevant to anyone else.
- The right pattern for someone copying this approach is `fork → strip what doesn't apply → re-encrypt with their own age key`, not `use as template → fill in placeholders`. Template-flag would imply the latter.

### Why hero as SVG-source + PNG-served

- SVG diffs cleanly in PRs (text-based), so future tweaks can be reviewed.
- GitHub's inline image renderer is more reliable on PNG than SVG across dark/light mode and across the GitHub mobile app. The PNG is the served artifact; the SVG is the source of truth.
- Source files live under `assets/branding/`; `assets` is added to `.chezmoiignore` in the same PR as the assets themselves, so they never deploy to `$HOME`.

### Why `vhs` (by Charm) for the demo, not asciinema

- `vhs` produces deterministic recordings from a `.tape` script file. Re-running the tape produces identical output. The tape is committed alongside the rendered gif, so future edits go through normal review.
- asciinema requires manual capture and post-processing through `svg-term-cli` to get an embeddable artifact. No way to review the source script in a PR — it's an opaque cast file.
- Demos are run against `HOME=/tmp/demo` fixtures, never the real `~/edjchapman/`, so frames never leak personal paths.

## Alternatives rejected

- **Rename to a "project-style" name** (e.g. `homestate`, `macbase`) — rejected for the reasons in *Why no rename* above. The cost (coordination, broken links, naming-discussion overhead) exceeds the marginal-discoverability benefit.
- **Just polish the README, skip Pages / Discussions / governance files** — rejected because half-measures here are visible. A README hero without a Pages site to deep-link into looks unfinished; Discussions without issue templates means contributors hit the wrong surface.
- **Auto-generate the CHANGELOG from `gh release` notes** — rejected because the three current releases are narrative-heavy (especially `1.2.0`, which collapsed 40+ PRs into a coherent "agentic + self-healing" theme). Auto-generation would lose the editorial framing.

## Consequences

- **More surfaces to maintain.** A Pages site has its own build (deploys via `actions/deploy-pages@v4` on `docs/**` push). New runbooks or ADRs must be added to `docs/mkdocs.yml` nav. Issue templates need occasional review when the underlying field set shifts.
- **More inbound traffic potential.** Discussions, Pages, and a social preview lower the barrier for outside engagement. Filed issues and PRs may rise; the contribution policy in `CONTRIBUTING.md` explicitly frames the repo as personal-scoped to set expectations.
- **`assets/` becomes a new top-level concern.** It's now in `.chezmoiignore`. Future PRs adding visual assets (hero updates, new diagrams) should not need to touch `.chezmoiignore` again unless a new top-level directory is introduced.
- **Self-update workflow surface unchanged.** The weekly `update-externals.yml` draft PR for `oh-my-zsh` and the monthly `audit.yml` full-history scan are unaffected. Pages deploy is a new workflow but is not on the required-checks list for branch protection — it's deploy-only, not a gate.
- **Future ADRs.** When the rebrand evolves (e.g. adopting a project name later, or switching Pages framework), this ADR becomes the reference for what was decided in `2026-06-15` and why.

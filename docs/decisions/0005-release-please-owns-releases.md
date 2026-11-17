# ADR 0005: release-please cuts releases and writes the changelog

- **Status:** Accepted. Supersedes one rejected alternative of [ADR-0004](0004-rebrand-public-showcase.md); the rest of ADR-0004 stands.
- **Date:** 2026-11-17

## Context

[ADR-0004](0004-rebrand-public-showcase.md) added `CHANGELOG.md` and rejected auto-generating it, because the first releases were narrative-heavy and generation would lose the editorial framing.

That left two manual steps: writing the changelog and cutting the release. The writing happened; the cutting did not.

- Seven releases were cut by hand, the last being `2.0.1` on 2026-06-23.
- No release followed for five months, while 126 commits merged and `[Unreleased]` kept growing.
- The changelog entries for `1.3.0` to `2.0.1` were backfilled after their tags, so the tagged trees never described themselves.
- The README release badge showed `2.0.1` throughout.

Nothing prompted a release, so none happened.

## Decision

From `2.1.0` onward, [release-please](https://github.com/googleapis/release-please) owns the version, the tag, the GitHub release and `CHANGELOG.md`.

- **Mechanism.** `.github/workflows/release-please.yml` runs on every push to `main` and keeps one draft release PR open. Merging that PR publishes the release.
- **Input.** The squash-merged PR title is the changelog entry. `feat` bumps minor, `fix` bumps patch, `!` bumps major.
- **Visible types.** `feat`, `fix`, `security`, `perf` and `revert` appear in the changelog and can trigger a release. Every other type is hidden and triggers nothing.
- **Hand edits.** `CHANGELOG.md` is no longer edited by hand. Entries up to `2.1.0` stay as written.
- **Tags.** Bare (`2.2.0`), matching the existing ones.

## Rationale

- **A release becomes a merge.** The step that failed was remembering to cut one. A standing PR turns it into a decision that is already waiting.
- **The inputs already existed.** The repo is squash-merge only with Conventional Commits PR titles, which is exactly what release-please reads.
- **It keeps the human gate.** The release PR is a draft, like every other bot PR here. Nothing publishes without a merge.
- **Tags describe themselves.** The changelog entry lands in the release commit, so it is in the tagged tree.

## Alternatives rejected

- **Keep the hand-written changelog (ADR-0004's position).** Rejected on the evidence above: the editorial quality was real, but it depended on a step nobody was prompted to take.
- **Tag-triggered workflow that publishes `[Unreleased]` as the notes.** Keeps the editorial changelog, but still relies on someone remembering to push a tag.
- **Stay manual, with a scheduled reminder.** A nudge leaves the same manual step in place, and adds a notification to ignore.

## Consequences

- **The editorial framing is gone.** An entry is one PR title with a link, not a paragraph. A narrative summary can still be added to the GitHub release after it is published.
- **PR titles carry more weight.** A wrong type hides a change or bumps the wrong version part. The fix is a `BEGIN_COMMIT_OVERRIDE` block in the merged PR's body, which release-please reads on its next run.
- **Hidden work is invisible.** `chore`, `docs` and `refactor` changes, including `chore(brew)` package adoptions, never reach the changelog and never trigger a release on their own.
- **`CHANGELOG.md` is unlinted.** Generated entries break two markdownlint rules, so the file is excluded rather than letting lint block a release PR. It also now mixes two formats, split at `2.1.0`.
- **Releases depend on `BOT_PAT`.** If it expires, the workflow fails with a message naming the secret. If it is deleted, the fallback token opens the release PR but CI does not run on it.
- **Reversal is cheap.** Delete the workflow and its two config files, restore an `[Unreleased]` heading, and resume hand edits.

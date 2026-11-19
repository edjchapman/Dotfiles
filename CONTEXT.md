# Glossary

Canonical vocabulary for this repo. Terms are added as they are resolved in
design sessions — if a term here conflicts with how you're about to use a word,
the glossary wins or the glossary gets changed; never both meanings at once.

The reader-facing glossary published on the docs site is `docs/glossary.md`. It
must define any term from here that a published page uses, and may not
contradict this file.

## Zsh environment

The full shell-adjacent management surface deployed by this repo, not just the
zsh dotfiles. It comprises:

- the shell startup files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`)
- the machine-local secrets file (`~/.zshrc.local`) as *sourced* by the shell
- the pinned `oh-my-zsh` external
- the `chezmoi-*` helper commands on PATH that the shell startup path and
  wrappers invoke
- the test suite covering those helpers

Distinct from the narrower "zsh dotfiles" (the three startup files alone).

## Drift signal

A named count of the ways the machine differs from the source in one area:
home files, missing brew packages, extra brew packages, macOS defaults, or the
security baseline. A signal says *what* differs, never *when* it was measured.

## Drift trigger

An event that causes the drift signals to be re-measured: a new shell finding
its last measurement stale, the daily schedule, a wrapped command finishing, or
the user asking directly. Triggers decide *when*; signals say *what*. "Signal"
and "loop" are not synonyms for a trigger.

## Audit protocol

The contract every audit honours so the drift check can consume any of them the
same way: one quiet run reports how many checks passed, drifted and were
skipped, and tells "found drift" apart from "could not run". A reply that breaks
the contract counts as a failed check, never as a number.

## Taint domain

A group of drift signals whose checks share one substrate, so a failure in any
one check makes every count in the group untrustworthy. A tainted domain's
counts are suppressed everywhere (banner, summary, state file) — the named
check error is the whole signal; a number that might be fabricated is never
shown, caveated or otherwise.

The brew signals (`brew-missing`, `brew-extra`) form one taint domain — their
checks share brew, the formulae API, and the rendered Brewfile. The `home`,
`defaults`, and `security` signals each stand alone.

# Glossary

Canonical vocabulary for this repo. Terms are added as they are resolved in
design sessions — if a term here conflicts with how you're about to use a word,
the glossary wins or the glossary gets changed; never both meanings at once.

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

## Taint domain

A group of drift signals whose checks share one substrate, so a failure in any
one check makes every count in the group untrustworthy. A tainted domain's
counts are suppressed everywhere (banner, summary, state file) — the named
check error is the whole signal; a number that might be fabricated is never
shown, caveated or otherwise.

The brew signals (`brew-missing`, `brew-extra`) form one taint domain — their
checks share brew, the formulae API, and the rendered Brewfile. The `home`,
`defaults`, and `security` signals each stand alone.

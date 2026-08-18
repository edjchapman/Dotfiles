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

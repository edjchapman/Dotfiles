#!/usr/bin/env bash
# Strip Go-template actions ({{ ... }}) from a chezmoi .tmpl file, emitting the
# surrounding shell on stdout so a shell-aware tool can lint or scan it.
#
# Single source of truth for the strip: the Makefile's `lint` target pipes
# .sh.tmpl files through here before ShellCheck, and check-bash4-isms.sh does
# the same before its pattern scan. They must agree — a construct one of them
# strips and the other keeps is a hole in whichever is stricter.
#
# Line-preserving by design: the substitution runs per line and never deletes
# one, so `grep -n` line numbers from the stripped text still point at the
# right line of the original file.
#
# The class is [^{}]* rather than .* — non-greedy in effect. A greedy .* spans
# from the FIRST {{ to the LAST }} on a line, so real shell sitting between two
# actions ({{ if x }}v=${1,,}{{ end }}) vanished along with them and reached no
# linter at all. Template-only logic *inside* {{ }} is still unchecked, which is
# expected; shell *outside* it must not be.
#
# Kept bash-3.2-safe: called from a pre-commit hook, so its own `env bash`
# resolves to /bin/bash during the bootstrap window (docs/gotchas.md).
set -euo pipefail

if (($# != 1)); then
    echo "usage: strip-template-actions.sh <file>" >&2
    exit 2
fi

sed -E 's/\{\{[^{}]*\}\}//g' "$1"

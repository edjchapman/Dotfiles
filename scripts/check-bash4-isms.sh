#!/usr/bin/env bash
# Guards chezmoi-deployed scripts against bash-4-only constructs — see
# docs/gotchas.md's "env bash is bash 3.2 during the bootstrap window" for
# why. Deliberately excludes scripts/*.sh: those are pre-commit/dev tooling
# that never runs during the chezmoi bootstrap window, a different risk
# class (see scripts/check-mermaid-fences.sh's TODO(bash-3.2) comment for a
# known instance).
#
# Kept 3.2-safe itself: this is a `language: system` pre-commit hook, so its
# own `#!/usr/bin/env bash` resolves the same way (see check-root-mirrors.sh's
# header comment for the same caveat).
#
# Usage: check-bash4-isms.sh [scan-root]
# Defaults to the repo root, which is how pre-commit invokes it. The optional
# argument exists so tests/audits.bats can point the real script at a scratch
# directory instead of planting probe files inside the chezmoi source state —
# a probe left behind by an interrupted run is deployable by the next
# `chezmoi apply` and shows up as drift in `chezmoi verify`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STRIP="$SCRIPT_DIR/strip-template-actions.sh"

SCAN_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$SCAN_ROOT"

# bash-4-only constructs guarded against:
#   ${v,,} ${v,} ${v^^} ${v^}  - case-modifying parameter expansion. The name
#                                class is [A-Za-z_0-9]+ (not the usual
#                                identifier shape) so POSITIONAL parameters
#                                are covered: ${1,,} is the exact construct
#                                this repo's normalize_bool had, and a
#                                leading-digit-excluding class missed it.
#                                [@*] covers ${@,,}.
#   declare/local/typeset/     - associative arrays. Matches -A anywhere in a
#   readonly -A                  flag cluster (-Ag, -gA) and each of the four
#                                builtins that accept it, not just
#                                `declare -A`. All four are pinned by the
#                                must-catch loop in tests/audits.bats.
#   readarray / mapfile        - builtin, in command position. The preceding
#                                class includes ( and ` so $(mapfile …) and
#                                backtick calls are caught, not just
#                                line-leading ones.
# Full-line comments are filtered out below so a comment that merely mentions
# one of these doesn't false-positive the guard.
# tests/audits.bats pins this pattern's coverage in both directions — every
# construct above, plus near-miss negatives (${v//,/;}, `declare -a`,
# `grep -A 3`) that must NOT trip it. Extend the tests alongside the pattern.
# shellcheck disable=SC2016  # the $ and ${ here are literal regex, not expansion
PATTERN='\$\{[#!]?([A-Za-z_0-9]+|[@*])(\[[^]]*\])?(,,?|\^\^?)|(^|[;&|(`{[:space:]])(declare|typeset|local|readonly)[[:space:]]+-[A-Za-z]*A|(^|[;&|(`{[:space:]])(readarray|mapfile)([[:space:]]|$)'

fail=0

# $1 = display path (for the report); $2 = path to actually grep — a
# template-stripped process-substitution path for a .tmpl file, the file
# itself otherwise.
check_file() {
    local path=$1 real=$2
    local hits
    hits=$(grep -nE "$PATTERN" "$real" | grep -vE '^[0-9]+:[[:space:]]*#') || true
    if [[ -n $hits ]]; then
        echo "bash-4-only construct in $path:" >&2
        echo "  ${hits//$'\n'/$'\n'  }" >&2
        fail=1
    fi
}

# Every executable_* file (chezmoi's naming convention for a deployed,
# executable script, any directory) plus the root run_once_*/run_onchange_*
# scripts — templated or not, same stripping rule either way so an
# executable_*.tmpl (chezmoi allows the combination, none exist today) isn't
# scanned with raw {{ }} syntax still in it.
while IFS= read -r -d '' file; do
    case "$file" in
        # Same strip helper the Makefile's `lint` target pipes .sh.tmpl files
        # through before ShellCheck — one definition of the strip so the two
        # scans can't disagree. Template-only logic inside {{ }} is unchecked
        # by both; shell outside it is checked by both.
        *.tmpl) check_file "$file" <("$STRIP" "$file") ;;
        *) check_file "$file" "$file" ;;
    esac
done < <(find . -not -path './.git/*' -type f \
    \( -name 'executable_*' -o -path './run_once_*' -o -path './run_onchange_*' \) -print0)

exit "$fail"

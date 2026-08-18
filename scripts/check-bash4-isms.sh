#!/usr/bin/env bash
# Guards chezmoi-deployed scripts against bash-4-only constructs. `env bash`
# resolves to /bin/bash 3.2 on a fresh macOS machine until `brew bundle`
# installs Homebrew bash (see executable_chezmoi-defaults-audit's
# normalize_bool for the bug this class caused) — so anything chezmoi runs
# before that point must stay 3.2-compatible.
#
# Scope: every executable_* file (chezmoi's naming convention for a deployed,
# executable script — regardless of which directory it lives under) plus the
# root run_once_*/run_onchange_* scripts. Deliberately excludes scripts/*.sh:
# those are pre-commit/dev tooling that never runs during the chezmoi
# bootstrap window, a different risk class (tracked separately —
# scripts/check-mermaid-fences.sh's `mapfile` is a known instance).
#
# Kept 3.2-safe itself: this is a `language: system` pre-commit hook, so its
# own `#!/usr/bin/env bash` resolves the same way (see check-root-mirrors.sh's
# header comment for the same caveat).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# bash-4-only constructs guarded against:
#   ${var,,} ${var,} ${var^^} ${var^}  - case-modifying parameter expansion
#   readarray / mapfile                 - builtin (anchored to command position)
#   declare -A                          - associative arrays
# Full-line comments are filtered out below so a comment that merely mentions
# one of these doesn't false-positive the guard.
PATTERN='\$\{[A-Za-z_][A-Za-z_0-9]*(\[[^]]*\])?(,,|,|\^\^|\^)|(^|[;&|[:space:]])(readarray|mapfile)\b|declare[[:space:]]+-A\b'

fail=0

# $1 = display path (for the report); $2 = path to actually grep — a
# template-stripped process-substitution path for .sh.tmpl, the file itself
# otherwise.
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

while IFS= read -r -d '' file; do
    check_file "$file" "$file"
done < <(find . -name 'executable_*' -not -path './.git/*' -print0)

while IFS= read -r -d '' file; do
    case "$file" in
        *.sh.tmpl) check_file "$file" <(sed -E 's/\{\{.*\}\}//g' "$file") ;;
        *) check_file "$file" "$file" ;;
    esac
done < <(find . -maxdepth 1 -type f \( -name 'run_once_*' -o -name 'run_onchange_*' \) -print0)

exit "$fail"

#!/usr/bin/env bash
# Verify each docs/{changelog,contributing,security,code-of-conduct}.md file
# is a thin include-markdown wrapper pointing at the matching root file.
# Catches: someone renamed/moved the root file but forgot to update the mirror.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

declare -A MIRRORS=(
    ["docs/changelog.md"]=CHANGELOG.md
    ["docs/contributing.md"]=CONTRIBUTING.md
    ["docs/security.md"]=SECURITY.md
    ["docs/code-of-conduct.md"]=CODE_OF_CONDUCT.md
)

fail=0
for mirror in "${!MIRRORS[@]}"; do
    source_file="${MIRRORS[$mirror]}"

    # Mirror not yet created — skip silently (we add them in Phase 5).
    [[ -f "$mirror" ]] || continue

    if [[ ! -f "$source_file" ]]; then
        echo "ERROR: $mirror points at missing source $source_file" >&2
        fail=1
        continue
    fi

    if ! grep -qE "include-markdown.*['\"]\\.\\./${source_file}['\"]" "$mirror"; then
        echo "ERROR: $mirror does not include-markdown ../${source_file}" >&2
        echo "  Expected a line like: {% include-markdown \"../${source_file}\" %}" >&2
        fail=1
    fi
done

exit "$fail"

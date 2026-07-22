#!/usr/bin/env bash
# Verify each docs/{changelog,contributing,security,code-of-conduct}.md file
# is a thin include-markdown wrapper pointing at the matching root file.
# Catches: someone renamed/moved the root file but forgot to update the mirror.
#
# Kept portable to macOS's system bash 3.2 (no `declare -A`): this is a
# `language: system` pre-commit hook, so `#!/usr/bin/env bash` resolves against
# the ambient PATH — which on a fresh Mac (this repo bootstraps such machines)
# is /bin/bash 3.2 before Homebrew's bash 5 lands.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# "mirror source" pairs — the 3.2-safe equivalent of an associative array.
MIRRORS=(
    "docs/changelog.md CHANGELOG.md"
    "docs/contributing.md CONTRIBUTING.md"
    "docs/security.md SECURITY.md"
    "docs/code-of-conduct.md CODE_OF_CONDUCT.md"
)

fail=0
for pair in "${MIRRORS[@]}"; do
    read -r mirror source_file <<<"$pair"

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

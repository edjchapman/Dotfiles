#!/usr/bin/env bash
# Ensure docs/requirements.txt entries are alphabetised so Dependabot diffs
# stay tidy and merge conflicts are minimised. Comments and blank lines are
# preserved at their current positions (the check only orders requirement
# lines among themselves).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

FILE=docs/requirements.txt
[[ -f "$FILE" ]] || exit 0

# Extract non-comment, non-blank lines; verify they're sorted.
grep -vE '^\s*(#|$)' "$FILE" >/tmp/req-actual.$$
LC_ALL=C sort -f /tmp/req-actual.$$ >/tmp/req-sorted.$$

if ! diff -q /tmp/req-actual.$$ /tmp/req-sorted.$$ >/dev/null; then
    echo "ERROR: $FILE entries not alphabetised. Diff (- actual, + expected):" >&2
    diff /tmp/req-actual.$$ /tmp/req-sorted.$$ >&2 || true
    rm -f /tmp/req-actual.$$ /tmp/req-sorted.$$
    exit 1
fi

rm -f /tmp/req-actual.$$ /tmp/req-sorted.$$

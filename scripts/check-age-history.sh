#!/usr/bin/env bash
# Verify that every historical blob of every *.age path ever committed is
# valid age ciphertext (binary or ASCII-armored header). Guards the core
# public-repo invariant: no revision of an encrypted file was ever plaintext.
# Requires full history — in CI, checkout with fetch-depth: 0.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

if git rev-parse --is-shallow-repository | grep -q true; then
    echo "ERROR: shallow clone — history is incomplete. Fetch full history first." >&2
    exit 1
fi

fail=0
checked=0

while IFS= read -r path; do
    while IFS= read -r commit; do
        blob=$(git rev-parse --verify -q "$commit:$path" 2>/dev/null) || continue
        # `head -c` closes the pipe early; mask the resulting SIGPIPE exit.
        header=$(git cat-file blob "$blob" | head -c 34 || true)
        checked=$((checked + 1))
        case "$header" in
            "age-encryption.org/v1"*) ;;
            "-----BEGIN AGE ENCRYPTED FILE-----") ;;
            *)
                echo "NOT AGE CIPHERTEXT: $commit:$path" >&2
                fail=1
                ;;
        esac
    done < <(git rev-list --all -- "$path")
done < <(git log --all --name-only --pretty=format: -- '*.age' | grep -v '^$' | sort -u)

if [ "$checked" -eq 0 ]; then
    echo "ERROR: no *.age blobs found in history — path filter or history is broken." >&2
    exit 1
fi

if [ "$fail" -eq 0 ]; then
    echo "OK: all $checked historical *.age blobs are valid age ciphertext."
fi
exit "$fail"

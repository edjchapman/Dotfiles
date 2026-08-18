#!/usr/bin/env bats
# Tests for the audit helpers (chezmoi-defaults-audit, chezmoi-security-audit):
# bash-3.2 portability of normalize_bool, plus the grep -c counting shape.
# The function is extracted with sed and driven directly, same pattern as
# brew-sync.bats and the brewup() tests.
#
# The broader bash-4-ism class is guarded by scripts/check-bash4-isms.sh, a
# pre-commit hook, not a bats test here — see docs/gotchas.md's "env bash is
# bash 3.2 during the bootstrap window" for why a bats assertion of that
# shape would only be advisory.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    DEFAULTS_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-defaults-audit"
    SECURITY_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-security-audit"

    WORKDIR="$(mktemp -d)"
    sed -n '/^normalize_bool()/,/^}/p' "$DEFAULTS_AUDIT" >"$WORKDIR/normalize_bool.bash"
    grep -q 'normalize_bool()' "$WORKDIR/normalize_bool.bash"
}

teardown() {
    rm -rf "$WORKDIR"
}

# Run normalize_bool under a specific bash binary. The value under test is
# passed as a real argument (bash -c's $0/$1), never interpolated into the
# command string — safe for any value, including one containing a quote.
run_normalize_bool() { # <bash-binary> <value>
    run "$1" -c 'source "$0"; normalize_bool "$1"' "$WORKDIR/normalize_bool.bash" "$2"
}

@test "normalize_bool maps every -bool spelling to 1/0" {
    for v in true TRUE yes 1; do
        run_normalize_bool bash "$v"
        [ "$status" -eq 0 ]
        [ "$output" = "1" ]
    done
    for v in false NO no 0; do
        run_normalize_bool bash "$v"
        [ "$status" -eq 0 ]
        [ "$output" = "0" ]
    done
    run_normalize_bool bash "weird"
    [ "$output" = "weird" ]
}

@test "normalize_bool runs under macOS system bash 3.2" {
    # The fresh-machine path: `env bash` resolves to /bin/bash until brew
    # bundle installs Homebrew bash, and bash 3.2 has no ${var,,} expansion —
    # which threw "bad substitution" and turned every boolean into a false
    # mismatch. Gated on the actual version, not just presence: /bin/bash is
    # bash 5 on Linux runners, which would make this pass without exercising
    # the 3.2 path it exists to pin.
    [ -x /bin/bash ] || skip "/bin/bash not present"
    /bin/bash --version | head -1 | grep -q 'version 3' \
        || skip "/bin/bash is not bash 3.x ($(/bin/bash --version | head -1))"
    run_normalize_bool /bin/bash TRUE
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "pending-updates count never carries a second line" {
    # grep -c prints its count (including 0) before a non-zero no-match exit,
    # so an `|| echo 0` fallback appended a second line: pending="0\n0".
    # Advisory only (see file header) — this asserts on source text, not
    # behaviour, and bats isn't a required check.
    run grep -n 'grep -c.*|| echo' "$SECURITY_AUDIT"
    [ "$status" -ne 0 ]
}

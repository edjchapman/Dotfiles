#!/usr/bin/env bats
# Tests for the audit helpers (chezmoi-defaults-audit, chezmoi-security-audit):
# bash-3.2 portability of the pieces that run on a fresh machine, plus the
# grep -c counting shape. Functions are extracted with sed and driven directly,
# same pattern as brew-sync.bats and the brewup() tests.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    DEFAULTS_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-defaults-audit"
    SECURITY_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-security-audit"

    TMPHOME="$(mktemp -d)"
    sed -n '/^normalize_bool()/,/^}/p' "$DEFAULTS_AUDIT" >"$TMPHOME/normalize_bool.bash"
    grep -q 'normalize_bool()' "$TMPHOME/normalize_bool.bash"
}

teardown() {
    rm -rf "$TMPHOME"
}

# Run normalize_bool under a specific bash binary.
nb() { # <bash-binary> <value>
    run "$1" -c "source '$TMPHOME/normalize_bool.bash'; normalize_bool '$2'"
}

@test "normalize_bool maps every -bool spelling to 1/0" {
    for v in true TRUE yes 1; do
        nb bash "$v"
        [ "$status" -eq 0 ]
        [ "$output" = "1" ]
    done
    for v in false NO no 0; do
        nb bash "$v"
        [ "$status" -eq 0 ]
        [ "$output" = "0" ]
    done
    nb bash "weird"
    [ "$output" = "weird" ]
}

@test "normalize_bool runs under macOS system bash 3.2" {
    # The fresh-machine path: `env bash` resolves to /bin/bash until brew
    # bundle installs Homebrew bash, and bash 3.2 has no ${var,,} expansion —
    # which threw "bad substitution" and turned every boolean into a false
    # mismatch. Meaningful on macOS (/bin/bash is 3.2); elsewhere it still
    # pins the function to whatever /bin/bash is.
    [ -x /bin/bash ] || skip "/bin/bash not present"
    nb /bin/bash TRUE
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "no bash-4-only expansions in the audit helpers" {
    # Both scripts must stay runnable by /bin/bash 3.2 (fresh machine, before
    # brew bundle). Guards the class, not just the one fixed instance.
    run grep -nE '\$\{[A-Za-z_0-9]+(\[[^]]*\])?(,,|\^\^)|readarray|mapfile|declare -A' \
        "$DEFAULTS_AUDIT" "$SECURITY_AUDIT"
    [ "$status" -ne 0 ]
}

@test "pending-updates count never carries a second line" {
    # grep -c prints its count (including 0) before a non-zero no-match exit,
    # so an `|| echo 0` fallback appended a second line: pending="0\n0".
    run grep -n 'grep -c.*|| echo' "$SECURITY_AUDIT"
    [ "$status" -ne 0 ]
}

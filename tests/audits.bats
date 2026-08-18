#!/usr/bin/env bats
# Tests for the audit helpers (chezmoi-defaults-audit, chezmoi-security-audit)
# and for scripts/check-bash4-isms.sh, the pre-commit hook that guards the
# bash-3.2 bootstrap window. See docs/gotchas.md's "env bash is bash 3.2
# during the bootstrap window" for the background.
#
# normalize_bool is extracted with sed and driven directly, same pattern as
# brew-sync.bats and the brewup() tests.
#
# The guard tests below drive the real script end-to-end against a scratch
# file rather than asserting on its source text: a source-text assertion in
# bats is only advisory (bats isn't a required check on `main`), whereas
# these pin what the hook — which IS required — actually catches.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    DEFAULTS_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-defaults-audit"
    SECURITY_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-security-audit"
    GUARD="$REPO_ROOT/scripts/check-bash4-isms.sh"

    WORKDIR="$(mktemp -d)"
    sed -n '/^normalize_bool()/,/^}/p' "$DEFAULTS_AUDIT" >"$WORKDIR/normalize_bool.bash"
    grep -q 'normalize_bool()' "$WORKDIR/normalize_bool.bash"

    # Scratch file inside the repo — the guard sweeps by name, so it must live
    # where find(1) will reach it. Named to sort clear of real scripts and
    # removed in teardown even if a test fails.
    PROBE="$REPO_ROOT/dot_local/bin/executable_zz-bats-probe"
}

teardown() {
    rm -rf "$WORKDIR"
    rm -f "$PROBE"
}

# Run normalize_bool under a specific bash binary. The value under test is
# passed as a real argument (bash -c's $0/$1), never interpolated into the
# command string — safe for any value, including one containing a quote.
run_normalize_bool() { # <bash-binary> <value>
    run "$1" -c 'source "$0"; normalize_bool "$1"' "$WORKDIR/normalize_bool.bash" "$2"
}

# Write one line of shell into the probe file and run the real guard over the
# repo. Exit 1 means the guard flagged something.
run_guard_over() { # <line-of-shell>
    printf '#!/usr/bin/env bash\n%s\n' "$1" >"$PROBE"
    run "$GUARD"
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
    # it throws "bad substitution". Gated on the actual version, not just
    # presence: /bin/bash is bash 5 on Linux runners, which would make this
    # pass without exercising the 3.2 path it exists to pin.
    [ -x /bin/bash ] || skip "/bin/bash not present"
    /bin/bash --version | head -1 | grep -q 'version 3' \
        || skip "/bin/bash is not bash 3.x ($(/bin/bash --version | head -1))"
    run_normalize_bool /bin/bash TRUE
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "bash-4 guard catches every construct it claims to" {
    # Regression pin. An earlier pattern anchored the parameter name to
    # [A-Za-z_]..., which silently missed ${1,,} — the *exact* construct
    # removed from normalize_bool. The guard could not have caught a verbatim
    # reintroduction of the bug it exists to prevent.
    local c
    for c in 'v=${1,,}' 'v=${2^^}' 'v=${varname,,}' 'v=${var^}' 'v=${var,}' \
        'v=${arr[@],,}' 'v=${@,,}' 'declare -A m' 'declare -Ag m' \
        'declare -gA m' 'local -A m' 'typeset -A m' 'mapfile -t a' \
        'readarray -t a' 'x=$(mapfile -t a)'; do
        run_guard_over "$c"
        [ "$status" -eq 1 ] || {
            echo "guard MISSED: $c"
            return 1
        }
    done
}

@test "bash-4 guard does not fire on 3.2-legal near misses" {
    # The other direction: a guard that flags legal code gets disabled, so
    # pin the near misses too — comma/caret expansions that aren't case
    # modification, non-A flag clusters, and `-A` as an ordinary CLI flag.
    local c
    for c in 'v=${var//,/;}' 'v=${var#,}' 'v=${var%,}' 'v=${var:-,}' \
        'v="a,b,c"' 'declare -a arr' 'declare -r x' 'declare -i n' \
        'local -r y' 'v=${var}' 'v=${1}' 'v=${1:-default}' \
        'my_mapfile=1' 'grep -A 3 pattern'; do
        run_guard_over "$c"
        [ "$status" -eq 0 ] || {
            echo "guard FALSE-POSITIVE on: $c"
            echo "$output"
            return 1
        }
    done
}

@test "bash-4 guard strips template syntax before scanning" {
    # An executable_*.tmpl (chezmoi permits the combination) must be scanned
    # with {{ }} removed, exactly as Makefile:24 does for ShellCheck.
    rm -f "$PROBE"
    PROBE="$REPO_ROOT/dot_local/bin/executable_zz-bats-probe.tmpl"
    printf '#!/usr/bin/env bash\n{{ if true }}\nv=${1,,}\n{{ end }}\n' >"$PROBE"
    run "$GUARD"
    [ "$status" -eq 1 ]
}

@test "pending-updates count never carries a second line" {
    # grep -c prints its count (including 0) before a non-zero no-match exit,
    # so an `|| echo 0` fallback appended a second line: pending="0\n0".
    # Advisory source-text check; the file must exist for it to mean anything.
    [ -f "$SECURITY_AUDIT" ]
    run grep -n 'grep -c.*|| echo' "$SECURITY_AUDIT"
    [ "$status" -eq 1 ]
}

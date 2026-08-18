#!/usr/bin/env bats
# Tests for the audit helpers (chezmoi-defaults-audit, chezmoi-security-audit)
# and for scripts/check-bash4-isms.sh, the pre-commit hook that guards the
# bash-3.2 bootstrap window. See docs/gotchas.md's "env bash is bash 3.2
# during the bootstrap window" for the background.
#
# normalize_bool is extracted with sed and driven directly, same pattern as
# brew-sync.bats and the brewup() tests.
#
# Every test here drives real code rather than asserting on source text: a
# source-text assertion in bats is only advisory (bats isn't a required check
# on `main`), and it pins one spelling of a bug rather than the behaviour.
#
# Hermetic, like brew-sync.bats: nothing is written inside the chezmoi source
# state. The guard takes a scan-root argument so its probe files live in a
# temp dir — a probe left behind by an interrupted run would otherwise be
# deployable by the next `chezmoi apply` and show as `chezmoi verify` drift.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    DEFAULTS_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-defaults-audit"
    SECURITY_AUDIT="$REPO_ROOT/dot_local/bin/executable_chezmoi-security-audit"
    GUARD="$REPO_ROOT/scripts/check-bash4-isms.sh"

    WORKDIR="$(mktemp -d)"
    sed -n '/^normalize_bool()/,/^}/p' "$DEFAULTS_AUDIT" >"$WORKDIR/normalize_bool.bash"
    grep -q 'normalize_bool()' "$WORKDIR/normalize_bool.bash"

    # Scratch scan root handed to the guard as its argument. The guard sweeps
    # by name, so probes must be named executable_* to be reached.
    SCANROOT="$WORKDIR/scan"
    mkdir -p "$SCANROOT"
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

# Write shell into a probe file in the scratch scan root and run the real
# guard over it. Exit 1 means the guard flagged something.
run_guard_over() { # <shell-body> [probe-basename]
    PROBE_NAME="${2:-executable_zz-bats-probe}"
    rm -f "$SCANROOT"/executable_*
    printf '#!/usr/bin/env bash\n%s\n' "$1" >"$SCANROOT/$PROBE_NAME"
    run "$GUARD" "$SCANROOT"
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
    #
    # Asserting the probe path appears in the report, not just a non-zero
    # exit: the guard scans a whole tree, so a bare status check would pass on
    # a hit in some *other* file and prove nothing about the construct.
    local c
    for c in 'v=${1,,}' 'v=${2^^}' 'v=${varname,,}' 'v=${var^}' 'v=${var,}' \
        'v=${arr[@],,}' 'v=${@,,}' 'declare -A m' 'declare -Ag m' \
        'declare -gA m' 'local -A m' 'typeset -A m' 'readonly -A m' \
        'mapfile -t a' 'readarray -t a' 'x=$(mapfile -t a)'; do
        run_guard_over "$c"
        [ "$status" -eq 1 ] || {
            echo "guard MISSED: $c"
            return 1
        }
        [[ $output == *"$PROBE_NAME"* ]] || {
            echo "guard fired without naming the probe for: $c"
            echo "$output"
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
    # with {{ }} removed, exactly as the Makefile's `lint` target does for
    # ShellCheck — both go through scripts/strip-template-actions.sh.
    run_guard_over '{{ if true }}
v=${1,,}
{{ end }}' executable_zz-bats-probe.tmpl
    [ "$status" -eq 1 ]
    [[ $output == *"$PROBE_NAME"* ]]
}

@test "bash-4 guard sees shell between two template actions on one line" {
    # The strip used to be greedy (`{{.*}}`), so it spanned from the first
    # {{ to the last }} on a line and deleted the real shell in between —
    # this exact line reached neither the guard nor ShellCheck.
    run_guard_over '{{ if true }}v=${1,,}{{ end }}' executable_zz-bats-probe.tmpl
    [ "$status" -eq 1 ]
    [[ $output == *"$PROBE_NAME"* ]]
}

@test "bash-4 guard defaults its scan root to the repo and passes clean" {
    # The no-argument form is how pre-commit invokes it. Also proves the
    # repo is currently free of the whole construct class.
    run "$GUARD"
    [ "$status" -eq 0 ]
}

@test "pending-updates count is a single line when nothing matches" {
    # grep -c prints its count (including 0) before a non-zero no-match exit,
    # so an `|| echo 0` fallback appended a second line: pending="0\n0".
    # Behavioural, not source-text: the real assignment is lifted out of the
    # script and run against a cache with no matching lines, so any fallback
    # spelling that re-introduces the second line fails here.
    local assignment
    assignment="$(grep -E '^[[:space:]]*pending=\$\(grep -c' "$SECURITY_AUDIT")"
    [ -n "$assignment" ]

    printf 'Software Update found the following new or updated software:\n' \
        >"$WORKDIR/su-cache"
    {
        printf 'SU_CACHE="$1"\n'
        printf '%s\n' "$assignment"
        printf 'printf "%%s" "$pending"\n'
    } >"$WORKDIR/pending.bash"

    run bash "$WORKDIR/pending.bash" "$WORKDIR/su-cache"
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

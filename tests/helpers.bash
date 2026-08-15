#!/usr/bin/env bash
# Shared bats fixtures. `load helpers` from any suite in this directory.
#
# Lives here rather than in one suite because two files now need the same
# drift-state fixture: mac.bats drives chezmoi-fix from it, and drift-check.bats
# drives both the --brief fast path and the dot_zshrc banner block from it. A
# second copy would recreate, inside the test suite, exactly the two-renderings-
# of-one-truth problem these tests exist to guard against.

# Write a drift state file with named overrides; missing count fields default
# to 0. Requires $XDG_CACHE_HOME/chezmoi-drift to exist.
#
#   write_state home=2 brew_extra=5 summary='drift: ...'
#   write_state home=2 banner='home 2'      # pin the composed banner
#   write_state home=2 legacy=1             # omit banner + drift_total entirely
#
# `drift_total` defaults to the sum of the five count fields, so a fixture is
# self-consistent without the caller restating it. `banner` defaults to empty
# and is *not* derived: re-implementing the writer's composition rules here
# would mean the suite could agree with itself while disagreeing with the
# shipped script. Tests that assert on banner content state it explicitly.
#
# `legacy=1` writes a state file in the pre-S1 schema — neither new field
# present. That is the fixture for the backwards-compatibility path: the cache
# TTL is 4h, so such a file exists in the wild after every upgrade.
write_state() {
    local home_drift=0 brew_missing=0 brew_extra=0 brew_extra_names="" defaults_drift=0
    local security_drift=0 brewup_failed=0 had_error=0 checked_at summary="drift: clean"
    local banner="" drift_total="" legacy=0
    checked_at=$(date +%s)
    while (($# > 0)); do
        case "$1" in
            home=*) home_drift=${1#home=} ;;
            brew_missing=*) brew_missing=${1#brew_missing=} ;;
            brew_extra=*) brew_extra=${1#brew_extra=} ;;
            extra_names=*) brew_extra_names=${1#extra_names=} ;;
            defaults=*) defaults_drift=${1#defaults=} ;;
            security=*) security_drift=${1#security=} ;;
            brewup=*) brewup_failed=${1#brewup=} ;;
            error=*) had_error=${1#error=} ;;
            summary=*) summary=${1#summary=} ;;
            banner=*) banner=${1#banner=} ;;
            drift_total=*) drift_total=${1#drift_total=} ;;
            checked_at=*) checked_at=${1#checked_at=} ;;
            legacy=*) legacy=${1#legacy=} ;;
        esac
        shift
    done
    [[ -n $drift_total ]] \
        || drift_total=$((home_drift + brew_missing + brew_extra + defaults_drift + security_drift))

    cat >"$XDG_CACHE_HOME/chezmoi-drift/state" <<EOF
HOME_DRIFT=$home_drift
BREW_MISSING=$brew_missing
BREW_EXTRA=$brew_extra
BREW_EXTRA_NAMES='$brew_extra_names'
DEFAULTS_DRIFT=$defaults_drift
SECURITY_DRIFT=$security_drift
BREWUP_FAILED=$brewup_failed
HAD_ERROR=$had_error
CHECKED_AT=$checked_at
summary='$summary'
EOF
    if ((legacy == 0)); then
        cat >>"$XDG_CACHE_HOME/chezmoi-drift/state" <<EOF
banner='$banner'
drift_total=$drift_total
EOF
    fi
}

#!/usr/bin/env bats
# Tests for chezmoi-drift-check's `brew bundle cleanup` output parser, via the
# --parse-cleanup test hook (stdin → "<count>\t<space-joined names>"). No
# chezmoi or brew required.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    DRIFT_CHECK="$REPO_ROOT/dot_local/bin/executable_chezmoi-drift-check"
}

@test "modern block output: counts package names, not header lines" {
    run "$DRIFT_CHECK" --parse-cleanup <<'EOF'
Would uninstall formulae:
restic
Would uninstall casks:
google-chrome
obsidian
steam
whatsapp
Run `brew bundle cleanup --force` to make these changes.
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '5\trestic google-chrome obsidian steam whatsapp')" ]
}

@test "modern block output: blank line ends a block, next header restarts" {
    run "$DRIFT_CHECK" --parse-cleanup <<'EOF'
Would uninstall formulae:
restic

Would uninstall casks:
obsidian
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '2\trestic obsidian')" ]
}

@test "legacy inline output still counts" {
    run "$DRIFT_CHECK" --parse-cleanup <<'EOF'
Would uninstall google-chrome
Would untap homebrew/cask-fonts
Would remove obsidian
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '3\tgoogle-chrome homebrew/cask-fonts obsidian')" ]
}

@test "cache-path cleanups are not packages" {
    run "$DRIFT_CHECK" --parse-cleanup <<'EOF'
Would remove: /Users/ed/Library/Caches/Homebrew/foo--1.2.3.tar.gz (1.2MB)
Would remove: /Users/ed/Library/Caches/Homebrew/bar--4.5.tar.gz (900KB)
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '0\t')" ]
}

@test "mixed modern blocks and cache paths: only packages counted" {
    run "$DRIFT_CHECK" --parse-cleanup <<'EOF'
Would uninstall casks:
steam
whatsapp
Would remove: /Users/ed/Library/Caches/Homebrew/baz--2.0.tar.gz (3MB)
EOF
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '2\tsteam whatsapp')" ]
}

@test "empty input yields zero" {
    run "$DRIFT_CHECK" --parse-cleanup </dev/null
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '0\t')" ]
}

@test "state file writer includes BREW_EXTRA_NAMES" {
    # The atomic state write must persist the names so chezmoi-fix can offer
    # per-package adopt/uninstall. Grep the source (behavioural test would need
    # chezmoi + brew).
    run grep -n "BREW_EXTRA_NAMES=%q" "$DRIFT_CHECK"
    [ "$status" -eq 0 ]
}

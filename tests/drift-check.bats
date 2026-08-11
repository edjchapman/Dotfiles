#!/usr/bin/env bats
# Tests for chezmoi-drift-check's `brew bundle cleanup` output parser, via the
# --parse-cleanup test hook (stdin → "<count>\t<space-joined names>"). No
# chezmoi or brew required.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    DRIFT_CHECK="$REPO_ROOT/dot_local/bin/executable_chezmoi-drift-check"
    ZSHRC="$REPO_ROOT/dot_zshrc"
    CHEZMOI_FIX="$REPO_ROOT/dot_local/bin/executable_chezmoi-fix"
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

@test "empty-directory sweeps are not packages" {
    # Real `brew bundle cleanup` output (2026-08): empty-directory lines have
    # `(` after "remove", slipping past the colon guard and yielding a phantom
    # package literally named "(empty" per line.
    run "$DRIFT_CHECK" --parse-cleanup <<'EOF'
Would `brew cleanup`:
Would remove: /Users/ed/Library/Caches/Homebrew/xz--5.8.3 (770.8KB)
Would remove: /Users/ed/Library/Caches/Homebrew/Cask/lulu--4.4.3.dmg (7.3MB)
Would remove (empty directory): /opt/homebrew/lib/gio/modules
Would remove (empty directory): /opt/homebrew/lib/gio
Run `brew bundle cleanup --force` to make these changes.
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

@test "state file writer includes BREWUP_FAILED" {
    run grep -n "BREWUP_FAILED=%s" "$DRIFT_CHECK"
    [ "$status" -eq 0 ]
}

@test "brewup marker path agrees across writer and both readers" {
    # dot_zshrc writes the marker; drift-check and chezmoi-fix read it. These
    # live in three separate files with no shared constant, so a path edit in
    # one is silently a no-op signal. Pin the literal in all three.
    local marker='$HOME/.cache/brewup.failed'
    run grep -F -- "$marker" "$ZSHRC"
    [ "$status" -eq 0 ]
    run grep -F -- "$marker" "$DRIFT_CHECK"
    [ "$status" -eq 0 ]
    run grep -F -- "$marker" "$CHEZMOI_FIX"
    [ "$status" -eq 0 ]
}

@test "brewup daily stamp is written unconditionally" {
    # Regression guard. Stamping only inside the success branch turned any
    # persistent upgrade failure into one brewup per new shell instead of one
    # per day. The stamp must not be the body of `if brewup; then`.
    run bash -c "grep -A1 'if brewup; then' '$ZSHRC' | grep -c 'BREWUP_STAMP'"
    [ "$output" = "0" ]
}

@test "brewup runs doctor and cleanup even when upgrade fails" {
    # The old `return 1` on upgrade failure skipped both. Assert the failure
    # path sets a return code rather than returning early.
    run bash -c "sed -n '/^brewup()/,/^}/p' '$ZSHRC' | grep -c 'return 1'"
    [ "$output" = "0" ]
    run bash -c "sed -n '/^brewup()/,/^}/p' '$ZSHRC' | grep -c 'command brew cleanup'"
    [ "$output" = "1" ]
}

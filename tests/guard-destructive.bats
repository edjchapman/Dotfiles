#!/usr/bin/env bats
# Tests for the git-push branch of .claude/hooks/guard-destructive.sh: feature
# pushes are allowed; force-pushes and pushes to main/master are blocked (exit 2).
# A temp git repo on a known branch makes the hook's current-branch check
# (git rev-parse in $CLAUDE_PROJECT_DIR) deterministic. No chezmoi/network needed.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    GUARD="$REPO_ROOT/.claude/hooks/guard-destructive.sh"

    TMPREPO="$(mktemp -d)"
    git -C "$TMPREPO" init -q -b main
    git -C "$TMPREPO" config user.email test@example.com
    git -C "$TMPREPO" config user.name test
    git -C "$TMPREPO" commit -q --allow-empty -m init
    git -C "$TMPREPO" checkout -q -b feature-x
    export CLAUDE_PROJECT_DIR="$TMPREPO"
}

teardown() {
    rm -rf "$TMPREPO"
}

# Feed a command to the hook as a PreToolUse payload; exit 0 = allow, 2 = block.
guard() {
    printf '{"tool_input":{"command":"%s"}}' "$1" | bash "$GUARD"
}

@test "allows pushing a feature branch" {
    run guard "git push -u origin feature-x"
    [ "$status" -eq 0 ]
}

@test "allows -u (set-upstream) without force" {
    run guard "git push -u origin feature-x"
    [ "$status" -eq 0 ]
}

@test "allows an implicit push while on a feature branch" {
    run guard "git push"
    [ "$status" -eq 0 ]
}

@test "allows a branch name that merely contains 'main'" {
    run guard "git push -u origin fix/main-menu"
    [ "$status" -eq 0 ]
}

@test "passes through an unrelated git command" {
    run guard "git status"
    [ "$status" -eq 0 ]
}

@test "blocks --force" {
    run guard "git push --force origin feature-x"
    [ "$status" -eq 2 ]
}

@test "blocks --force-with-lease" {
    run guard "git push --force-with-lease origin feature-x"
    [ "$status" -eq 2 ]
}

@test "blocks -f" {
    run guard "git push -f origin feature-x"
    [ "$status" -eq 2 ]
}

@test "blocks clustered force flag -uf" {
    run guard "git push -uf origin feature-x"
    [ "$status" -eq 2 ]
}

@test "blocks clustered force flag -fu" {
    run guard "git push -fu origin feature-x"
    [ "$status" -eq 2 ]
}

@test "blocks pushing to main" {
    run guard "git push origin main"
    [ "$status" -eq 2 ]
}

@test "blocks a HEAD:main refspec" {
    run guard "git push origin HEAD:main"
    [ "$status" -eq 2 ]
}

@test "blocks a fully-qualified refs/heads/main refspec" {
    run guard "git push origin refs/heads/main"
    [ "$status" -eq 2 ]
}

@test "blocks an implicit push while on main" {
    git -C "$TMPREPO" checkout -q main
    run guard "git push"
    [ "$status" -eq 2 ]
}

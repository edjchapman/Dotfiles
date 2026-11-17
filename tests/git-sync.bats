#!/usr/bin/env bats
#
# Tests for the `git sync` alias in dot_gitconfig.tmpl, run against scratch
# repos. The alias is read out of the template itself (template actions
# stripped, then parsed by git), so the tests exercise the shipped text.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    WORK="$(mktemp -d)"

    # Isolate from the machine's own git config: signing, hooks and
    # pull.rebase must not leak into the scratch repos.
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid

    "$REPO_ROOT/scripts/strip-template-actions.sh" "$REPO_ROOT/dot_gitconfig.tmpl" >"$WORK/gitconfig"
    SYNC_ALIAS="$(git config -f "$WORK/gitconfig" --get alias.sync)"

    # upstream: one commit on trunk. clone: tracks it.
    git init -q -b trunk "$WORK/upstream"
    commit_file upstream f one
    git clone -q "$WORK/upstream" "$WORK/clone"
}

teardown() {
    rm -rf "$WORK"
}

commit_file() {
    echo "$3" >"$WORK/$1/$2"
    git -C "$WORK/$1" add "$2"
    git -C "$WORK/$1" commit -q -m "$3"
}

sync_clone() {
    run git -C "$WORK/clone" -c alias.sync="$SYNC_ALIAS" sync
}

@test "git sync: fast-forwards to the upstream and keeps an uncommitted edit" {
    commit_file upstream g two
    echo dirty >>"$WORK/clone/f"

    sync_clone
    [ "$status" -eq 0 ]
    [ "$(git -C "$WORK/clone" rev-parse HEAD)" = "$(git -C "$WORK/upstream" rev-parse HEAD)" ]
    [ "$(git -C "$WORK/clone" status --short)" = " M f" ]
}

@test "git sync: refuses a branch that has diverged from its upstream" {
    commit_file upstream g two
    commit_file clone h local
    local before
    before=$(git -C "$WORK/clone" rev-parse HEAD)

    sync_clone
    [ "$status" -ne 0 ]
    [ "$(git -C "$WORK/clone" rev-parse HEAD)" = "$before" ]
}

@test "git sync: deletes a local branch whose upstream is gone" {
    git -C "$WORK/upstream" branch feature
    git -C "$WORK/clone" fetch -q
    git -C "$WORK/clone" branch -q --track feature origin/feature
    git -C "$WORK/upstream" branch -q -D feature

    sync_clone
    [ "$status" -eq 0 ]
    run git -C "$WORK/clone" rev-parse --verify --quiet refs/heads/feature
    [ "$status" -ne 0 ]
}

@test "git sync: updates from the fetched upstream ref, not through git pull" {
    # `git pull` fetches a second time and then reads FETCH_HEAD. A fetch
    # running in the same clone at that moment (an IDE's background fetch)
    # leaves two for-merge lines there, and with pull.rebase=true pull dies:
    # "Cannot rebase onto multiple branches". The race itself needs a second
    # process, so this pins the step that makes the alias immune to it.
    [[ "$SYNC_ALIAS" != *"git pull"* ]]
    [[ "$SYNC_ALIAS" == *"git merge --ff-only --autostash @{u}"* ]]
}

#!/usr/bin/env bats
# Tests for scripts/check-codex-mirrors.sh, which keeps the Codex ports under
# .agents/skills/source-command-*/ in step with .claude/commands/*.md.
#
# Each test builds a scratch tree and passes it as the script's root argument,
# so nothing here depends on the real commands except the first test, which
# asserts the repo as committed is in sync.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    CHECK="$REPO_ROOT/scripts/check-codex-mirrors.sh"
    TREE="$(mktemp -d)"
    mkdir -p "$TREE/.claude/commands" "$TREE/.agents/skills"
}

teardown() {
    rm -rf "$TREE"
}

# write_command <name> <description> <body>
write_command() {
    printf -- '---\ndescription: %s\nallowed-tools: Read\n---\n\n%s\n' "$2" "$3" \
        >"$TREE/.claude/commands/$1.md"
}

# write_mirror <name> <description-as-written-in-yaml> <body> [skill-name]
write_mirror() {
    local dir="$TREE/.agents/skills/source-command-$1"
    mkdir -p "$dir"
    printf -- '---\nname: "%s"\ndescription: %s\n---\n\n# source-command-%s\n\nUse this skill.\n\n## Command Template\n\n%s\n' \
        "${4:-source-command-$1}" "$2" "$1" "$3" >"$dir/SKILL.md"
}

@test "the repo's own mirrors are in sync" {
    run "$CHECK" "$REPO_ROOT"
    [ "$status" -eq 0 ]
}

@test "a matching command and mirror pass" {
    write_command demo "Do a thing." "Run the thing."
    write_mirror demo '"Do a thing."' "Run the thing."
    run "$CHECK" "$TREE"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "blank-line differences are not drift" {
    write_command demo "Do a thing." $'Steps:\n1. one\n2. two'
    write_mirror demo '"Do a thing."' $'Steps:\n\n1. one\n2. two\n'
    run "$CHECK" "$TREE"
    [ "$status" -eq 0 ]
}

@test "a command without a mirror fails and is named" {
    write_command demo "Do a thing." "Run the thing."
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *".claude/commands/demo.md has no Codex mirror"* ]]
}

@test "a mirror whose command was deleted fails" {
    write_mirror gone '"Old."' "Old body."
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"source-command-gone/ mirrors .claude/commands/gone.md, which does not exist"* ]]
}

@test "an edited command body fails and shows the changed line" {
    write_command demo "Do a thing." "Run the new thing."
    write_mirror demo '"Do a thing."' "Run the old thing."
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"body differs"* ]]
    [[ "$output" == *"-Run the new thing."* ]]
    [[ "$output" == *"+Run the old thing."* ]]
}

@test "a description mismatch fails" {
    write_command demo "Do a new thing." "Run the thing."
    write_mirror demo '"Do a thing."' "Run the thing."
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"description differs"* ]]
}

@test "a description with escaped quotes in the mirror still matches" {
    write_command demo 'Say "hi" to it.' "Run the thing."
    write_mirror demo '"Say \"hi\" to it."' "Run the thing."
    run "$CHECK" "$TREE"
    [ "$status" -eq 0 ]
}

@test "a wrong skill name fails" {
    write_command demo "Do a thing." "Run the thing."
    write_mirror demo '"Do a thing."' "Run the thing." "source-command-other"
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *'frontmatter name must be "source-command-demo"'* ]]
}

@test "a mirror without the Command Template heading fails" {
    write_command demo "Do a thing." "Run the thing."
    mkdir -p "$TREE/.agents/skills/source-command-demo"
    printf -- '---\nname: "source-command-demo"\ndescription: "Do a thing."\n---\n\nRun the thing.\n' \
        >"$TREE/.agents/skills/source-command-demo/SKILL.md"
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing the"* ]]
}

@test "a hand-ported command may differ in body but not in description" {
    write_command add-secret "Encrypt it." 'Secret at $ARGUMENTS.'
    write_mirror add-secret '"Encrypt it."' "Secret at the path they gave."
    run "$CHECK" "$TREE"
    [ "$status" -eq 0 ]

    write_command add-secret "Encrypt it differently." 'Secret at $ARGUMENTS.'
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"description differs"* ]]
}

@test "every failure is reported in one run, not just the first" {
    write_command one "One." "Body one."
    write_command two "Two." "Body two."
    write_mirror two '"Two."' "Body two, edited."
    write_mirror gone '"Old."' "Old body."
    run "$CHECK" "$TREE"
    [ "$status" -eq 1 ]
    [[ "$output" == *"one.md has no Codex mirror"* ]]
    [[ "$output" == *"source-command-two/SKILL.md: body differs"* ]]
    [[ "$output" == *"source-command-gone/"* ]]
}

@test "a tree with no commands and no mirrors passes" {
    run "$CHECK" "$TREE"
    [ "$status" -eq 0 ]
}

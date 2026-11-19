#!/usr/bin/env bash
# Verify each .agents/skills/source-command-<name>/SKILL.md (the Codex port of
# a Claude Code slash command) still matches .claude/commands/<name>.md.
# Catches: a command added or edited without its mirror, a mirror left behind
# after its command is deleted, and a name or description that no longer
# matches.
#
# Bodies are compared with blank lines dropped: .agents/ is markdownlinted and
# .claude/ is not, so a mirror legitimately gains blank lines around lists.
#
# Usage: check-codex-mirrors.sh [repo-root]   (defaults to the git toplevel)
#
# Kept portable to macOS's system bash 3.2, for the reason given in
# check-root-mirrors.sh.

set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

COMMANDS=.claude/commands
SKILLS=.agents/skills
PREFIX=source-command-
HEADING='## Command Template'

# Ports reworded on purpose: only existence, name and description are checked.
#   add-secret — Codex has no $ARGUMENTS substitution, and its guard hook
#                differs from Claude Code's deny rule, so two lines differ.
HAND_PORTED=" add-secret "

fail=0
err() {
    echo "ERROR: $1" >&2
    fail=1
}

# Value of a frontmatter key, with YAML double-quoting undone.
field() {
    local value
    value=$(awk -v key="$2" '
        /^---$/ { n++; next }
        n == 1 && index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }
    ' "$1")
    case "$value" in
        \"*\") printf '%s' "$value" | sed -e 's/^"//' -e 's/"$//' -e 's/\\"/"/g' -e 's/\\\\/\\/g' ;;
        *) printf '%s' "$value" ;;
    esac
}

command_body() {
    awk 'n >= 2 { print } /^---$/ && n < 2 { n++ }' "$1" | sed '/^[[:space:]]*$/d'
}

skill_body() {
    awk -v heading="$HEADING" 'found { print } $0 == heading { found = 1 }' "$1" | sed '/^[[:space:]]*$/d'
}

for src in "$COMMANDS"/*.md; do
    [[ -e "$src" ]] || continue
    name=$(basename "$src" .md)
    mirror="$SKILLS/$PREFIX$name/SKILL.md"

    if [[ ! -f "$mirror" ]]; then
        err "$src has no Codex mirror at $mirror"
        continue
    fi

    if [[ "$(field "$mirror" name)" != "$PREFIX$name" ]]; then
        err "$mirror: frontmatter name must be \"$PREFIX$name\""
    fi

    if [[ "$(field "$mirror" description)" != "$(field "$src" description)" ]]; then
        err "$mirror: description differs from $src"
    fi

    if ! grep -qxF -- "$HEADING" "$mirror"; then
        err "$mirror: missing the \"$HEADING\" heading that introduces the command body"
        continue
    fi

    case "$HAND_PORTED" in
        *" $name "*) continue ;;
    esac

    if ! body_diff=$(diff -u -L "$src" -L "$mirror" <(command_body "$src") <(skill_body "$mirror")); then
        err "$mirror: body differs from $src (blank lines ignored)"
        echo "$body_diff" >&2
    fi
done

for dir in "$SKILLS/$PREFIX"*/; do
    [[ -d "$dir" ]] || continue
    name=$(basename "$dir")
    name=${name#"$PREFIX"}
    if [[ ! -f "$COMMANDS/$name.md" ]]; then
        err "$dir mirrors $COMMANDS/$name.md, which does not exist"
    fi
done

if [[ "$fail" -ne 0 ]]; then
    echo "Copy the command body under \"$HEADING\" in its SKILL.md, or delete the orphaned mirror." >&2
fi

exit "$fail"

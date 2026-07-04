#!/bin/bash
# Global Claude Code config — symlink ~/.claude/{CLAUDE.md,settings.json,agents,commands,rules,skills}
# into the claude-code-config external (cloned to ~/.config/claude-code-config by .chezmoiexternal.toml).
#
# chezmoi run_onchange_after: runs after the external is in place, on first apply of a fresh
# machine and again whenever this file changes. (A plain run_after would self-heal on every
# apply, but shows as a perpetual pending "R" line in `chezmoi status`, tripping the drift
# banner.) The actual symlinking is delegated to the config repo's own scripts/setup-global.sh
# (single source of truth); this wrapper only invokes it when a link is missing or wrong.
# To repair broken symlinks between content changes, run setup-global.sh directly.
#
# Why a run script and not dot_claude/symlink_* sources: .chezmoiignore must ignore the target
# path `.claude` to keep this repo's project-scoped .claude/ out of $HOME, and that same target
# path is where these symlinks live — chezmoi cannot manage both under one name.

set -euo pipefail

repo="$HOME/.config/claude-code-config"
setup="$repo/scripts/setup-global.sh"

if [[ ! -x "$setup" ]]; then
    echo "claude-code-config external not present at $repo — skipping ~/.claude symlinks." >&2
    exit 0
fi

# expected: ~/.claude/<link> -> $repo/<target>
links=(
    "CLAUDE.md:home/CLAUDE.md"
    "settings.json:settings.json"
    "agents:agents"
    "commands:commands"
    "rules:rules"
    "skills:skills"
)

for entry in "${links[@]}"; do
    link="$HOME/.claude/${entry%%:*}"
    target="$repo/${entry#*:}"
    if [[ "$(readlink "$link" 2>/dev/null)" != "$target" ]]; then
        exec "$setup"
    fi
done

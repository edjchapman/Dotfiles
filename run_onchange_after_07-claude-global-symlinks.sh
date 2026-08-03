#!/bin/bash
# Global Claude Code config — symlink ~/.claude/{CLAUDE.md,settings.json,agents,commands,rules,skills}
# into the claude-code-config working clone at ~/Development/claude-code-config.
#
# The repo is an actively-developed checkout, NOT a chezmoi external: a git-repo external
# would `git pull --rebase` into the working tree at apply time and fail whenever it is
# dirty. Updates flow through the normal git workflow in that repo; this script only
# bootstraps a clone on a fresh machine and keeps the symlinks wired.
#
# chezmoi run_onchange_after: runs on first apply of a fresh machine and again whenever
# this file changes. (A plain run_after would self-heal on every apply, but shows as a
# perpetual pending "R" line in `chezmoi status`, tripping the drift banner.) The actual
# symlinking is delegated to the config repo's own scripts/setup-global.sh (single source
# of truth); this wrapper only invokes it when a link is missing or wrong.
# To repair broken symlinks between content changes, run setup-global.sh directly.
#
# Why a run script and not dot_claude/symlink_* sources: .chezmoiignore must ignore the target
# path `.claude` to keep this repo's project-scoped .claude/ out of $HOME, and that same target
# path is where these symlinks live — chezmoi cannot manage both under one name.

set -euo pipefail

repo="$HOME/Development/claude-code-config"
setup="$repo/scripts/setup-global.sh"

# ACCEPTED RISK (clone + later exec of an external repo). The clone runs only on a
# fresh machine (no .git present); thereafter $repo is a working clone this user
# controls via normal git, and the exec below runs that LOCAL setup-global.sh — not
# whatever is on the remote. At bootstrap the trust reduces to "my GitHub account is
# intact", which already gates the entire dotfiles apply (chezmoi runs the whole
# source tree), so pinning this one repo would only defend the narrow case of it
# being compromised in isolation. Documented in SECURITY.md ("Accepted risks").
if [[ ! -d "$repo/.git" ]]; then
    echo "claude-code-config not found at $repo — cloning." >&2
    git clone https://github.com/edjchapman/claude-code-config.git "$repo"
fi

if [[ ! -x "$setup" ]]; then
    echo "claude-code-config present but $setup missing or not executable — skipping ~/.claude symlinks." >&2
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

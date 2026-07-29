#!/usr/bin/env bash
# PreToolUse hook for Bash — defence-in-depth on top of permissions.deny.
# Reads the Claude Code hook payload from stdin (JSON) and refuses
# destructive chezmoi/git/sudo commands with a readable explanation.
#
# Exit codes:
#   0 → allow tool call
#   2 → block tool call (stderr is shown to the agent)

set -euo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" | /usr/bin/sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n1)

if [ -z "$cmd" ]; then
    exit 0
fi

block() {
    printf 'BLOCKED by .claude/hooks/guard-destructive.sh\n\n%s\n' "$1" >&2
    exit 2
}

case "$cmd" in
    *"chezmoi apply"*)
        block "Refusing 'chezmoi apply'. Always run 'chezmoi diff' first and surface the diff to the user for explicit approval. If approved, the user should run 'make apply' themselves in their terminal."
        ;;
    *"chezmoi re-add"*)
        block "Refusing 'chezmoi re-add'. This pulls \$HOME content back into the source state and can clobber template logic. Ask the user to run it manually after reviewing 'chezmoi diff'."
        ;;
    *"chezmoi add "*)
        if printf '%s' "$cmd" | grep -q -- '--encrypt'; then
            exit 0
        fi
        block "Refusing 'chezmoi add' without --encrypt. If this file contains secrets, re-run with --encrypt. If it is non-secret, ask the user to confirm and run it themselves."
        ;;
    *"git push"*)
        # Feature-branch pushes are allowed; force-pushes and pushes to the
        # protected default branch (main/master) are not. permissions.deny only
        # matches command prefixes, so the real parsing lives here. Force detection
        # covers --force* and clustered short flags (-f, -uf, -fu); the main/master
        # check covers plain, HEAD:, and refs/heads/ refspecs, plus an implicit
        # `git push` while checked out on main/master (below).
        if printf '%s' "$cmd" | grep -qE -- '--force|(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$)'; then
            block "Refusing force-push. It can rewrite remote history; run it yourself if you truly need to."
        fi
        if printf '%s' "$cmd" | grep -qE -- '(^|[[:space:]]|:|/)(main|master)([[:space:]]|:|$)'; then
            block "Refusing to push to main/master. Push a feature branch and open a PR instead."
        fi
        _branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [ "$_branch" = "main" ] || [ "$_branch" = "master" ]; then
            block "Refusing 'git push' while on '$_branch'. Switch to a feature branch and open a PR."
        fi
        exit 0
        ;;
    *"git commit --no-verify"* | *"git commit -n "*)
        block "Refusing to bypass pre-commit hooks. The hooks exist to catch leaked secrets; fix the underlying issue instead."
        ;;
    *"sudo "* | "sudo")
        block "Refusing 'sudo'. Privilege escalation belongs to the one-time bootstrap script (run_once_after_05-macos-sudo.sh), not agent territory."
        ;;
    *"rm -rf /"* | *"rm -rf ~"* | *"rm -rf \$HOME"*)
        block "Refusing destructive 'rm -rf' against root or \$HOME."
        ;;
esac

exit 0

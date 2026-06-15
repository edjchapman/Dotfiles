# vhs script — render with:
#   brew install vhs
#   vhs assets/demo/bootstrap.tape
#
# Produces assets/demo/bootstrap.gif (committed alongside this file).
#
# Staged recording: hidden setup defines a `mac` shim function so the visible
# portion never touches the real chezmoi state or the real Homebrew. The
# curl-pipe-sh bootstrap line is typed for visual effect only, then erased
# without executing.

Output assets/demo/bootstrap.gif

Set FontSize 14
Set Width 1100
Set Height 600
Set Theme "GitHub Dark"
Set PlaybackSpeed 0.7
Set TypingSpeed 35ms

# Hidden setup: clean prompt, define mac() shim with the drift-summary output,
# clear screen so the recording opens on an empty prompt.
Hide
Type 'export PS1="$ "'
Enter
Type "mac() {"
Enter
Type "  cat <<'DEMO'"
Enter
Type "─── drift summary ──────────────────────────────────────────"
Enter
Type "  ✓ \$HOME files          in sync"
Enter
Type "  ✓ Brewfile             in sync"
Enter
Type "  ✓ macOS defaults       in sync"
Enter
Type "  ✓ security baseline    in sync (FileVault, SIP, firewall, keys, perms)"
Enter
Type "  ✓ external pins        in sync (oh-my-zsh, claude-code-config)"
Enter
Type ""
Enter
Type "No drift detected."
Enter
Type "DEMO"
Enter
Type "}"
Enter
Type "clear"
Enter
Show

# 1. Show the bootstrap one-liner being typed. Cancel with Ctrl+U so it never
# executes — purely visual.
Type `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply edjchapman`
Sleep 1500ms
Ctrl+u
Sleep 400ms

# 2. The day-to-day surface: mac.
Type "mac"
Sleep 500ms
Enter
Sleep 3500ms

# vhs script — render with:
#   brew install vhs
#   vhs assets/demo/bootstrap.tape
#
# Produces assets/demo/bootstrap.gif (committed alongside this file).
# Runs against a fake HOME=/tmp/demo so no real ~/edjchapman paths appear.

Output assets/demo/bootstrap.gif

Set FontSize 14
Set Width 1100
Set Height 600
Set Theme "GitHub Dark"
Set PlaybackSpeed 0.6
Set TypingSpeed 30ms

# Setup — run silently so the recording starts on a clean prompt.
Hide
Type "export HOME=/tmp/demo && mkdir -p $HOME && cd $HOME && clear"
Enter
Sleep 200ms
Show

# 1. Bootstrap one-liner.
Type `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply edjchapman`
Sleep 600ms
Enter
Sleep 1500ms
Type "# clones source, fetches externals, runs brew bundle,"
Sleep 200ms
Enter
Type "# applies macOS defaults, decrypts secrets, deploys $HOME"
Sleep 200ms
Enter
Sleep 1500ms

# 2. Drift check (clean state — what most days look like).
Type "mac"
Sleep 500ms
Enter
Sleep 2500ms

# 3. The day something drifts: mac walks you through fixing it.
Type "# (when drift is detected, mac shows a menu — pick a fix, done)"
Sleep 400ms
Enter
Sleep 1500ms

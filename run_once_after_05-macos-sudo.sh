#!/bin/bash
# macOS Settings — commands requiring sudo (one-time bootstrap)
# chezmoi run_once_after: runs once during initial setup, after all other scripts.
#
# The actual logic lives in the deployed script so there is a single source of truth.
# This wrapper just execs it. Re-run the settings manually anytime with:
#   ~/.config/chezmoi/scripts/macos-sudo.sh

set -euo pipefail

script="$HOME/.config/chezmoi/scripts/macos-sudo.sh"
if [[ -x "$script" ]]; then
    exec "$script"
else
    echo "macos-sudo.sh not found at $script — skipping sudo settings." >&2
    exit 0
fi

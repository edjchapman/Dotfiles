#!/bin/bash
# Install Homebrew if not present
# chezmoi run_once: only runs on first setup

set -euo pipefail

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    # ACCEPTED RISK: unpinned curl-to-bash of Homebrew's canonical installer, once
    # at fresh-machine bootstrap. Rationale (and why not pinned) in SECURITY.md →
    # "Accepted risks". Do not "fix" by freezing an unreviewed SHA.
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        echo "ERROR: Homebrew installation failed."
        exit 1
    fi

    # Add to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed."
fi

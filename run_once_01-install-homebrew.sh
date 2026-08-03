#!/bin/bash
# Install Homebrew if not present
# chezmoi run_once: only runs on first setup

set -euo pipefail

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    # ACCEPTED RISK (curl|bash of unpinned HEAD). This is the canonical Homebrew
    # installer, fetched over HTTPS, and it runs exactly once at fresh-machine
    # bootstrap. Pinning to a commit SHA without also reading that revision only
    # buys reproducibility, not security — and the trust extended here is the same
    # trust Homebrew gets for every formula it installs afterward. Documented in
    # SECURITY.md ("Accepted risks"). Do not "fix" by freezing an unreviewed SHA.
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

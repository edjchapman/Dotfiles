#!/bin/bash
# macOS Settings — commands requiring sudo
# Single source of truth for the sudo-settings logic. Invoked once at bootstrap by
# run_once_after_05-macos-sudo.sh (which execs this file), and re-runnable manually:
#   ~/.config/chezmoi/scripts/macos-sudo.sh

set -euo pipefail

echo ""
echo "============================================================"
echo " macOS sudo settings (firewall, Touch ID, energy, updates)"
echo " This requires your password. Press Ctrl-C to skip."
echo "============================================================"
echo ""

# Acquire sudo upfront; skip gracefully if no password is provided (e.g. non-interactive)
if ! sudo -v; then
    echo "Skipping sudo settings (no password provided)."
    exit 0
fi

# =============================================================================
# Firewall
# =============================================================================

sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Remote Apple Events is intentionally NOT enforced here: `systemsetup
# -setremoteappleevents off` requires Full Disk Access for the calling terminal
# and silently no-ops without it. It's a legacy feature, off by default; its
# state is monitored read-only by chezmoi-security-audit instead.

# =============================================================================
# Accounts & disk encryption
# =============================================================================

# Disable the Guest account
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# Assert FileVault is on (report only — never force-enable non-interactively,
# which would generate a recovery key and force a reboot)
if fdesetup status | grep -q "FileVault is On"; then
    echo "FileVault: on."
else
    echo "FileVault: OFF — enable it in System Settings > Privacy & Security."
fi

# =============================================================================
# Touch ID for sudo
# =============================================================================

# Use pam_tid.so via sudo_local (survives macOS updates)
if [[ ! -f /etc/pam.d/sudo_local ]]; then
    if [[ -f /etc/pam.d/sudo_local.template ]]; then
        sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
        sudo sed -i '' 's/^#auth       sufficient     pam_tid.so/auth       sufficient     pam_tid.so/' /etc/pam.d/sudo_local
        echo "Touch ID for sudo: enabled."
    else
        echo "Touch ID for sudo: template not found, skipping."
    fi
else
    echo "Touch ID for sudo: already configured."
fi

# =============================================================================
# Energy Settings
# =============================================================================

# Display sleep: 10 minutes
sudo pmset -a displaysleep 10

# System sleep: 30 minutes on battery, never on AC
sudo pmset -b sleep 30
sudo pmset -c sleep 0

# Disable Power Nap (background syncing while sleeping)
sudo pmset -a powernap 0

# =============================================================================
# Software Updates — ensure automatic updates are enabled
# =============================================================================

sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true

echo ""
echo "Done. Firewall, stealth mode, Guest account off, Touch ID sudo, energy, and auto-updates active."

#!/bin/bash
# macOS Defaults — non-sudo settings
# chezmoi run_onchange: re-runs when this file changes

set -euo pipefail

echo "Applying macOS defaults..."

# =============================================================================
# Dock
# =============================================================================

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Set Dock icon size
defaults write com.apple.dock tilesize -int 48

# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false

# Don't auto-rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Hot corners: bottom-right = Quick Note (14)
# (other corners left unset — configure in System Settings if wanted)
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# =============================================================================
# Finder
# =============================================================================

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show warning before changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search the current folder by default instead of the whole Mac
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Expand the Save and Print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Don't scatter .DS_Store files on network shares or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Unhide ~/Library (filesystem flag; re-running just re-clears an already-clear flag)
chflags nohidden "$HOME/Library" 2>/dev/null || true

# =============================================================================
# Keyboard
# =============================================================================

# Fast key repeat rate (2 = very fast, default ~6)
defaults write NSGlobalDomain KeyRepeat -int 2

# Short delay before key repeat starts (15 = short, default ~25)
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable smart quotes and dashes (use straight quotes — essential for coding)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable auto-period with double-space
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Enable key repeat in every app (disables the press-and-hold accent picker) —
# essential for editors and Vim-style navigation
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Full keyboard access: Tab moves between all controls, not just text boxes (default 2)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# =============================================================================
# Trackpad
# =============================================================================

# Enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# =============================================================================
# Screenshots
# =============================================================================

# Save screenshots to ~/Downloads instead of Desktop
defaults write com.apple.screencapture location "$HOME/Downloads"

# Use PNG format
defaults write com.apple.screencapture type png

# Disable shadow in window screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# =============================================================================
# Menu Bar Clock
# =============================================================================

# Show day, date and time in the menu bar (no seconds — cleaner).
# ShowSeconds is declared explicitly so the source stays authoritative; flip to
# true if you want a ticking clock.
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm"
defaults write com.apple.menuextra.clock ShowDate -int 1
defaults write com.apple.menuextra.clock ShowSeconds -bool false

# =============================================================================
# Menu Bar / Control Center modules
# =============================================================================
# NOTE: Control Center module modes are stored PER-HOST, so they require
# -currentHost. Writing them to the standard domain silently no-ops.
# Modes: 2 = show in menu bar, 8 = don't show, 18 = always show, 24 = show when active.

# Hide the fast-user-switcher (single-user Mac — menu-bar clutter)
defaults -currentHost write com.apple.controlcenter UserSwitcher -int 8

# Always show the battery percentage
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

# Show the Sound control only when active
defaults -currentHost write com.apple.controlcenter Sound -int 24

# =============================================================================
# Privacy & Security (non-sudo)
# =============================================================================

# Require a password immediately after sleep / screensaver.
# NOTE: on macOS 14+ (verified inert on 26.x) these standard-domain
# com.apple.screensaver keys are NOT honored — the effective lock setting moved to
# a per-host / managed location. They are kept as a harmless best-effort (they do
# apply on older macOS and via MDM configuration profiles), but the AUTHORITATIVE
# control is System Settings ➜ Lock Screen ➜ "Require password after screen saver
# begins or display is off: Immediately". This write alone does not enforce it.
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Disable AirDrop discoverability
defaults write com.apple.sharingd DiscoverableMode -string "Off"

# Disable Apple analytics & telemetry
defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory" AutoSubmit -bool false 2>/dev/null || true
defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory" ThirdPartyDataSubmit -bool false 2>/dev/null || true

# Disable Siri data sharing
defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2

# Disable personalized ads
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false

# Disable Spotlight web suggestions
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true

# Disable Siri suggestions and lock screen access
defaults write com.apple.Siri SiriCanLearnFromAppBlacklist -string "()"
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri LockscreenEnabled -bool false

# DuckDuckGo as default Safari search
defaults write com.apple.Safari SearchProviderShortName -string "DuckDuckGo" 2>/dev/null || true

# Don't auto-open "safe" downloads (archives, PDFs, disk images) after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false 2>/dev/null || true

# =============================================================================
# iTerm2 — load preferences from chezmoi-managed directory
# =============================================================================

defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# =============================================================================
# Restart affected services
# =============================================================================

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall ControlCenter 2>/dev/null || true

echo ""
echo "macOS defaults applied."
echo "Some changes require a logout or restart to take effect."

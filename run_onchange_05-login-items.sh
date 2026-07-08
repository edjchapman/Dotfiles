#!/bin/bash
# Login items — declare the ideal startup set (idempotent).
#
# Reconciles macOS "Open at Login" to a fixed set via System Events. osascript
# needs a one-time Automation permission grant for the controlling terminal
# (macOS prompts on first run; deny-safe via `|| true`). Apps must be installed
# first (Brewfile / mas) — any that are missing are skipped, not failed.
#
# Re-runs whenever this file's content hash changes; the reconcile is idempotent,
# so applying twice in a row makes no further change.

set -euo pipefail

# Apps that SHOULD launch at login (security tools + sync + keep-awake).
DESIRED_APPS=(
    "/Applications/LuLu.app"
    "/Applications/NordVPN.app"
    "/Applications/Google Drive.app"
    "/Applications/Amphetamine.app"
)

# Login items that must NOT be present (removed if found).
# Caffeine duplicates Amphetamine (and is unmanaged); Fing kept installed but
# no longer auto-starts.
REMOVE_NAMES=(
    "Caffeine"
    "Fing"
)

if ! command -v osascript >/dev/null 2>&1; then
    echo "osascript unavailable, skipping login items."
    exit 0
fi

echo "Reconciling login items..."

# Current login item names as a single string (empty if none / permission denied).
current=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || true)

# Remove unwanted items.
for name in "${REMOVE_NAMES[@]}"; do
    if [[ "$current" == *"$name"* ]]; then
        osascript -e "tell application \"System Events\" to delete login item \"$name\"" 2>/dev/null || true
        echo "  removed: $name"
    fi
done

# Add desired items (skip if already present or the app isn't installed).
for app in "${DESIRED_APPS[@]}"; do
    name=$(basename "$app" .app)
    if [[ ! -d "$app" ]]; then
        echo "  skip (not installed): $name"
        continue
    fi
    if [[ "$current" == *"$name"* ]]; then
        continue
    fi
    if osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app\", hidden:false}" >/dev/null 2>&1; then
        echo "  added: $name"
    else
        echo "  could not add (grant Automation access to your terminal): $name"
    fi
done

echo "Login items reconciled."

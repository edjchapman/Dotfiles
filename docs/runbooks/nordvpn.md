# NordVPN settings

NordVPN has no macOS CLI, and most of its settings aren't in a file chezmoi can safely manage. Chezmoi sets a few preferences and checks for the `Shield` extension. The rest is the manual checklist below, which you should run after installing or reinstalling the app.

## What chezmoi manages

| Setting | Value | Set by |
|---|---|---|
| `helpUsImprove` | `false` | `run_onchange_03-macos-defaults.sh` |
| `isAnalyticsConsentAllowed` | `false` | `run_onchange_03-macos-defaults.sh` |
| `isEngagementMeasurementConsentAllowed` | `false` | `run_onchange_03-macos-defaults.sh` |
| `startOnBoot` | `true` | `run_onchange_03-macos-defaults.sh` |
| Login item | Present | `run_onchange_05-login-items.sh` |

These key names are undocumented and were read from the app's preferences at version 10.14.1, so an update could rename them. Turning these keys off doesn't prove that data collection has stopped.

## Manual checklist

1. **Sign in.** Do this in the app. Don't store account details in this repo.
2. **Leave `Shield` off.** Go to System Settings ➜ General ➜ Login Items & Extensions ➜ Endpoint Security Extensions, switch off **NordVPN protection**, then restart. [Troubleshooting](../troubleshooting.md) explains why.
3. **Check Threat Protection is off.** Switching off `Shield` stops the app's Protect features, so the app should show them as off.
4. **Set the kill switch and protocol.** Choose these in the app. Their values aren't recorded here because they aren't in the preferences plist.
5. **Restart the app, then verify.** Use the commands below.

## Verify

```bash
chezmoi-defaults-audit --drift
chezmoi-security-audit --drift
systemextensionsctl list | grep -i nordvpn
```

- **Defaults audit:** no `com.nordvpn.macos` key should be listed under Drift. If one is, the app has reset or stopped honouring it, so check the key still exists before reapplying.
- **Security audit:** `NordVPN Shield off` should not be listed under Failures.
- **`systemextensionsctl`:** `Shield` should show `[activated disabled]`, or there should be no matching line.

## Don't manage these with chezmoi

- **The whole preferences plist:** it holds timestamps, counters and device IDs, so it would drift constantly and put personal data in the repo.
- **`meshnetEnabled`, `connectOnDemand`, `enableCustomDNS` and the Threat Protection keys:** these may need the app to change system state as well, which writing the preference wouldn't do.
- **`~/Library/Application Support/com.nordvpn.macos`:** this is the app's private data, including what looks like an encrypted database.

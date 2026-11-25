# ArchiveTune for iOS

A native SwiftUI rewrite of the ArchiveTune Android app's local music experience. The Android project remains the upstream reference; this is a separate iOS implementation, not an Android APK wrapper.

## Current iOS features

- Native SwiftUI interface with Home, Discover, Library, Stats, and Settings tabs.
- Import local audio files using the iOS Files picker.
- Copy imported audio into the app's private Documents directory so it remains available offline.
- Read title, artist, album, duration, and embedded artwork metadata.
- Play local tracks with `AVPlayer`, including a queue, previous/next, shuffle, repeat, and playback-speed controls.
- Background audio and Lock Screen / Control Center remote playback commands.
- Synced or plain lyrics from LRCLIB.
- Local listening history and play statistics.
- Full JSON backup and restore, including the imported audio files.
- Dark, light, and system appearance settings.

## Requirements

- macOS with Xcode 15.4 or newer (Xcode 16 recommended).
- iOS 17.0 or newer deployment target.
- An Apple Developer signing team to export an installable device IPA.

## Open in Xcode

1. Unzip this project on a Mac.
2. Open `ArchiveTune.xcodeproj`.
3. Select the `ArchiveTune` scheme and an iPhone simulator to run it without signing.
4. For a real device, choose your Development Team under **Signing & Capabilities** and change the bundle identifier if it is already in use.

The default bundle identifier is `moe.rukamori.archivetune.ios`. You must use an identifier you are allowed to sign.

## Build an IPA from Windows (GitHub Actions)

You do not need Xcode installed on your Windows PC. The included workflow runs Xcode on a GitHub-hosted macOS runner and uploads the finished IPA as a downloadable workflow artifact.

### What you need first

- A GitHub account and a repository containing this project.
- An Apple Developer team with an **Apple Distribution** certificate exported as a password-protected `.p12` file.
- An **Ad Hoc** provisioning profile for this app's bundle ID. It must include the iPhone/iPads you want to install the IPA on and use the same Apple Developer team and distribution certificate.
- A bundle ID that you control. Do not use the example `moe.rukamori.archivetune.ios` unless it is registered to your team.

### Add the signing files to GitHub

In your repository, open **Settings → Secrets and variables → Actions**.

Add these repository secrets:

- `IOS_DISTRIBUTION_P12_BASE64` — the `.p12` certificate file encoded as Base64.
- `IOS_DISTRIBUTION_P12_PASSWORD` — the password used when exporting the `.p12` file.
- `IOS_PROVISIONING_PROFILE_BASE64` — the `.mobileprovision` file encoded as Base64.

Add these repository variables under the **Variables** tab:

- `IOS_TEAM_ID` — your 10-character Apple Developer Team ID.
- `IOS_BUNDLE_ID` — the exact bundle ID registered in the provisioning profile.

On Windows PowerShell, encode each file and copy the Base64 value to the matching GitHub secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\AppleDistribution.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\ArchiveTune_AdHoc.mobileprovision")) | Set-Clipboard
```

Run one command at a time and paste each copied value into its matching GitHub secret. Never commit certificates, provisioning profiles, passwords, or API keys to the repository.

### Run the cloud build

1. Push the project, including `.github/workflows/build-ios-ipa.yml`, to your GitHub repository's `main` branch.
2. Open the repository's **Actions** tab.
3. Select **Build ArchiveTune IPA**, then choose **Run workflow**.
4. When it finishes, open the run and download the `ArchiveTune-iOS-IPA` artifact. It contains `ArchiveTune.ipa`.

The workflow uses a GitHub-hosted macOS 15 runner. It signs an Ad Hoc IPA, which can only be installed on devices included in that provisioning profile. Apple provisioning profiles connect an app ID, signing certificate, and registered devices. See Apple's [development provisioning profile guide](https://developer.apple.com/help/account/provisioning-profiles/create-a-development-provisioning-profile/) and [Xcode signing guide](https://help.apple.com/xcode/mac/current/en.lproj/dev1bf96f17e.html).

### Build on a Mac instead

If you later have access to a Mac with Xcode 15.4 or newer, you can still run:

```bash
cd ArchiveTune-iOS
DEVELOPMENT_TEAM=YOUR_TEAM_ID ./scripts/build_ipa.sh
```

For simulator-only testing, open the project in Xcode and press Run; no device IPA signing is needed.

## Important platform differences

ArchiveTune's Android app is a large Kotlin/Jetpack Compose project. Android playback, account, extraction, USB, notification, widget, Auto, and module APIs do not run on iOS. This rewrite uses Apple frameworks for the local audio experience. It does not reuse the Android APK or execute Kotlin on iOS.

Online YouTube Music content is opened through the official YouTube Music service. This project intentionally does not extract protected streams or bypass YouTube's playback controls. Full YouTube Music account/library sync and online native playback require a supported provider integration/backend and are not implemented in this build.

See [PORT_STATUS.md](PORT_STATUS.md) for a feature-by-feature list of what is and is not ported.

## License and attribution

ArchiveTune is licensed under GPL-3.0. The original project is by Rukamori and contributors. This iOS rewrite is distributed under the same license; see `LICENSE` and the upstream repository at https://github.com/rukamori/ArchiveTune.

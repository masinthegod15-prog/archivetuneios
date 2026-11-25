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

- The iOS app targets iOS 17.0 or newer.
- For a Windows-only workflow, use a GitHub account and the included GitHub Actions workflow. The actual Xcode build runs on a hosted macOS runner.
- For personal testing, an unsigned IPA can be installed using a Windows sideloading tool and a free Apple Account. A paid Apple Developer Program membership is not required for this personal-testing route.

## Build an IPA from Windows (free personal testing)

1. Upload the full project to a GitHub repository, including the hidden `.github` folder.
2. Open **Actions → Build ArchiveTune IPA (Free Sideloading)** and choose **Run workflow**. The workflow also runs automatically on pushes to `main`.
3. Download the `ArchiveTune-unsigned-IPA` artifact from the completed run.
4. Follow [WINDOWS_BUILD.md](WINDOWS_BUILD.md) to install the unsigned IPA on your own iPhone with AltServer / AltStore.

No Apple signing secrets or repository variables are required. The sideloading tool signs the app for personal testing using your Apple Account. Free-account provisioning expires periodically, so the app must be refreshed or reinstalled. This is not App Store distribution.

See [WINDOWS_BUILD.md](WINDOWS_BUILD.md) for the full process and limitations.

## Important platform differences

ArchiveTune's Android app is a large Kotlin/Jetpack Compose project. Android playback, account, extraction, USB, notification, widget, Auto, and module APIs do not run on iOS. This rewrite uses Apple frameworks for the local audio experience. It does not reuse the Android APK or execute Kotlin on iOS.

Online YouTube Music content is opened through the official YouTube Music service. This project intentionally does not extract protected streams or bypass YouTube's playback controls. Full YouTube Music account/library sync and online native playback require a supported provider integration/backend and are not implemented in this build.

See [PORT_STATUS.md](PORT_STATUS.md) for a feature-by-feature list of what is and is not ported.

## License and attribution

ArchiveTune is licensed under GPL-3.0. The original project is by Rukamori and contributors. This iOS rewrite is distributed under the same license; see `LICENSE` and the upstream repository at https://github.com/rukamori/ArchiveTune.

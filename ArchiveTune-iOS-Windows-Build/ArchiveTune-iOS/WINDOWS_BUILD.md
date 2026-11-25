# ArchiveTune iOS: Windows build guide

This project is a native iOS app, so it cannot be compiled on Windows directly. The included GitHub Actions workflow uses a hosted macOS runner to run Xcode remotely.

## Required Apple signing files

For a directly installable Ad Hoc IPA, you need:

1. An Apple Developer team and a bundle ID registered to that team.
2. An Apple Distribution certificate with its private key, exported as a password-protected `.p12` file.
3. An Ad Hoc provisioning profile for the bundle ID that includes the target iPhone/iPad devices and the distribution certificate.

The certificate and profile must belong to the same team. The profile must match the `IOS_BUNDLE_ID` repository variable.

## GitHub Actions settings

Repository → Settings → Secrets and variables → Actions.

**Secrets**

- `IOS_DISTRIBUTION_P12_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`

**Variables**

- `IOS_TEAM_ID`
- `IOS_BUNDLE_ID`

PowerShell Base64 commands (run each separately):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\AppleDistribution.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\ArchiveTune_AdHoc.mobileprovision")) | Set-Clipboard
```

Do not put signing files or secret values in Git commits or public messages.

## Run the build

Push the project to GitHub, then select **Actions → Build ArchiveTune IPA → Run workflow**. Download the `ArchiveTune-iOS-IPA` artifact from the completed workflow run.

A successful build is not guaranteed until the Apple signing files are valid and the iOS source compiles with the selected Xcode version. This environment cannot run Xcode itself, so the first cloud run is the actual compiler check.

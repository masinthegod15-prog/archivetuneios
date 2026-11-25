# ArchiveTune iOS: free Windows build and personal sideload guide

You do not need a paid Apple Developer Program membership or Apple signing secrets to build a test IPA. GitHub Actions uses a hosted macOS runner to compile the app without signing it. A sideloading app on your Windows PC can then sign and install that IPA to your own iPhone using your regular Apple Account.

## 1. Upload this project to GitHub

1. Create a GitHub repository.
2. Upload the contents of this folder, including the hidden `.github` folder and `.github/workflows/build-ios-ipa.yml`.
3. Make sure the workflow file is visible at `.github/workflows/build-ios-ipa.yml` in the repository.

## 2. Build the unsigned IPA

1. Open the repository's **Actions** tab.
2. Select **Build ArchiveTune IPA (Free Sideloading)**.
3. Click **Run workflow**.
4. Wait for the macOS job to finish. If it fails, open the failed step and read the Xcode error.
5. Download the artifact named **ArchiveTune-unsigned-IPA**. It contains `ArchiveTune-unsigned.ipa`.

No Apple Developer Team ID, distribution certificate, provisioning profile, GitHub secrets, or GitHub variables are needed for this build.

## 3. Install it from Windows with AltServer / AltStore

Follow the current official AltStore Windows instructions: https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows

The official instructions currently require Apple's Windows device components (iTunes and iCloud), AltServer, and a USB or Wi-Fi connection to the iPhone. Download iTunes and iCloud from Apple's download pages as directed by AltStore's guide.

After AltStore is installed:

1. Keep AltServer running on the Windows PC.
2. Connect and trust the iPhone, or use the configured Wi-Fi sync connection.
3. Hold **Shift** while clicking the AltServer tray icon and choose **Sideload .ipa…** (if that menu item is present in your AltServer version).
4. Select `ArchiveTune-unsigned.ipa` and follow the prompts to sign and install it with your Apple Account.
5. On the iPhone, follow any trust / Developer Mode prompts shown by iOS and AltStore.

Never give your Apple Account password to another person or paste it into GitHub secrets. Enter account credentials only in the official software you chose to use, and ask a parent/guardian for help with account security or device restrictions.

## Free-account limitations

Apple's free Personal Team provisioning is for personal development/testing, not public distribution. Apple says Personal Team App IDs and device registrations expire after 7 days, provisioning profiles expire after 7 days, and up to 3 apps can be installed per device under those limits. AltStore says apps installed with AltStore expire after 7 days unless refreshed; refresh requires AltServer running on the same network or a USB connection. You may need to reinstall or refresh the app periodically.

This method is for installing the app on your own test device. It does not publish ArchiveTune on the App Store or create a permanent public distribution IPA.

## App requirements and limitations

- This project targets iOS 17.0 or newer.
- The GitHub workflow only builds the app; it does not install it on your phone.
- A successful Xcode build is not guaranteed until the hosted macOS runner compiles the current source.
- This iOS rewrite currently focuses on local music playback and does not include every Android integration. See `PORT_STATUS.md`.

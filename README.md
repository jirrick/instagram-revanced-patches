# 📸 Instagram ReVanced Patches

Dedicated, lightweight, and up-to-date [ReVanced](https://revanced.app) patches specifically tailored for **Instagram**.

Tested & compatible with Instagram **443.0.0.48.82** (Android 9.0+, ARM64 & x86_64).

---

## 📱 Quick Setup (ReVanced Manager)

In ReVanced Manager 2.x:

1. Open the **Patches** tab (bottom bar) and tap **Add patches**.
2. Choose **Remote**, tap **Next**, and enter this URL:

```text
https://bluecxt.github.io/instagram-revanced-patches/patches.json
```

3. When patching Instagram, select patches from this bundle only and leave the official bundle's Instagram patches off, so the two don't clash.

> Using a fork? Its URL is `https://<your-github-user>.github.io/instagram-revanced-patches/patches.json`, once GitHub Pages is enabled for the `gh-pages` branch (Settings → Pages → Deploy from a branch).

---

## ✨ Features & Included Patches

- 🚫 **Hide Ads (`Hide ads`)** : Complete ad-blocker eliminating sponsored items from the **Main Feed**, **Reels**, and **Stories** without startup or runtime crashes.
- 💾 **Download Media (`Download media`)** : Adds a "Download" option to the "..." menu of posts, carousels, Reels and stories. Files are saved to one folder with a subfolder per account (`Pictures/Instagram/<username>/` by default, configurable with the *Download folder* option).
- 🔒 **Disable Swipe Navigation (`Disable swipe navigation`)** : Prevents accidental horizontal swiping between feed, camera, and DMs.
- 🔍 **Hide Explore Feed (`Hide explore feed`)** : Hides algorithmic explore grid/reels in the search tab.
- 🧭 **Hide Navigation Buttons (`Hide navigation buttons`)** : Allows customizing and hiding navigation bar tabs (e.g. Reels or Create buttons).
- 🧹 **Hide Suggested Content (`Hide suggested content`)** : Removes suggested posts, suggested reels, and suggested threads from your home feed.
- 🚫 **Disable Analytics (`Disable analytics`)** : Blocks periodic tracking and telemetry requests.
- ⏳ **Remove Build Expired Popup (`Remove build expired popup`)** : Disables the lockout dialog when running older or alpha builds.
- 🔗 **Sanitize Sharing Links (`Sanitize sharing links`)** : Strips tracking query parameters (`igsh`, etc.) from shared URLs.
- 👁️ **Anonymous Story Viewing (`Anonymous story viewing`)** : View stories without notifying the poster or appearing in viewer lists.
- ⏸️ **Disable Story Auto-Flipping (`Disable story auto flipping`)** : Keeps stories on screen until you manually advance.
- 🎨 **Location Sticker Redesign (`Enable location sticker redesign`)** : Unlocks full redesigned style set for location stickers.
- 🛠️ **Enable Developer Menu (`Enable developer menu`)** : Exposes internal developer options in settings.
- 📸 **Remove Screenshot Restriction (`Remove screenshot restriction`)** : Allows taking screenshots/screen recordings anywhere in the app, including disappearing media and Vanish Mode.
- 🔕 **Prevent Screenshot Detection (`Prevent screenshot detection`)** : Prevents Instagram from detecting when a screenshot is taken and stops sending notifications to the sender.

---

## 💻 Using ReVanced CLI (Command Line)

1. Download the latest `.rvp` bundle from [Releases](https://github.com/bluecxt/instagram-revanced-patches/releases).
2. Download [ReVanced CLI](https://github.com/ReVanced/revanced-cli/releases).
3. Obtain the recommended Instagram APK (443.0.0.48.82). If you download a bundle (`.apkm`, `.xapk`), merge it into a single APK first, e.g. with [APKEditor](https://github.com/REAndroid/APKEditor).
4. Run the patcher:

```bash
java -jar revanced-cli.jar patch \
  -p patches-*.rvp \
  -o instagram-patched.apk \
  --exclusive -e "Hide ads" -e "Download media" \
  instagram.apk
```

5. Install `instagram-patched.apk` on your device (the CLI signs it). Keep the keystore it creates: updates only install over an app signed with the same key.

---

## 🛠️ Building from Source

### Prerequisites
- JDK 17
- Android SDK (build-tools)

### Build the `.rvp` Patch Bundle
```bash
./gradlew :patches:buildAndroid
```
The compiled bundle with Dalvik bytecode will be output to:
```
patches/build/libs/patches-<version>.rvp
```

A containerized toolchain (build, decompile, patch, install over Wireless debugging) and notes on porting the patches to new Instagram versions are in [MAINTAINING.md](MAINTAINING.md).

---

## 📜 License
GPL-3.0 License. Based on the open-source [ReVanced Patches](https://gitlab.com/ReVanced/revanced-patches) project.

# Recipe Book

A phone-friendly clickable recipe book packaged as a small Android app.

## Open In A Browser

The browser/iPhone version lives at:

- `docs/index.html`

GitHub Pages can publish that file as a normal website link for family members on iPhone, iPad, Android, or desktop.

## Install on Android

Download the latest APK from GitHub Releases:

- `Recipe.Book.apk`

Open it on your Android phone or tablet. Android may ask you to allow installing apps from your browser, Google Drive, or file manager.

## Update Across Devices

For automatic update checks on Android, use Obtainium:

1. Install Obtainium from <https://obtainium.imranr.dev>.
2. Add the public update-only repository as an app source:

   `https://github.com/ItsBertoYo/recipe-book-app-updates`

3. Use GitHub as the source and `Recipe.Book\.apk` as the APK filter if Obtainium asks.

After that, each new GitHub Release can be installed as an app update.

The source repository stays private. The public update-only repository contains APK release files only.

## Cookbook File

The cookbook HTML lives at:

- `cookbook/Recipe Book.html`
- `docs/index.html`

The Android app bundles that file inside the APK so it can open offline.

## Rebuild The APK

From this folder on the desktop:

```powershell
.\scripts\build-apk.ps1
```

The rebuilt APK will be saved to:

- `dist/Recipe.Book.apk`

To build, commit, push, and publish a new Obtainium update release:

```powershell
.\scripts\release-apk.ps1
```

## Notes

This is a personal sideload APK, not a Play Store app. iPhones and iPads cannot install APK files; use the shared HTML version for Apple devices.

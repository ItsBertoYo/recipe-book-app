# Recipe Book

A phone-friendly clickable recipe book packaged as a small Android app.

## Install on Android

Download the latest APK from GitHub Releases:

- `Recipe.Book.apk`

Open it on your Android phone or tablet. Android may ask you to allow installing apps from your browser, Google Drive, or file manager.

## Update Across Devices

For automatic update checks on Android, use Obtainium:

1. Install Obtainium from <https://obtainium.imranr.dev>.
2. Add this GitHub repository as an app source.
3. Choose the latest release APK when prompted.

After that, each new GitHub Release can be installed as an app update.

## Cookbook File

The cookbook HTML lives at:

- `cookbook/Recipe Book.html`

The Android app bundles that file inside the APK so it can open offline.

## Rebuild The APK

From this folder on the desktop:

```powershell
.\scripts\build-apk.ps1
```

The rebuilt APK will be saved to:

- `dist/Recipe.Book.apk`

## Notes

This is a personal sideload APK, not a Play Store app. iPhones and iPads cannot install APK files; use the shared HTML version for Apple devices.

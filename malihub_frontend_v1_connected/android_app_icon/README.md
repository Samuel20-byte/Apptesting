# Malihub app icon — install instructions

These files give Malihub the same wallet mark used on the Login screen as
its actual home-screen / launcher icon (on LDPlayer, on a real phone, and
in the app switcher on your Windows desktop while LDPlayer is running).

Malihub is mobile-only (Android/iOS) — there's no separate native Windows
desktop build. "Appears on my desktop" is covered because LDPlayer's
Android home screen — where this icon shows up — runs inside a window on
your Windows desktop.

## What's in this folder

```
android_app_icon/
  app/src/main/res/
    mipmap-mdpi/    ic_launcher.png  ic_launcher_round.png  ic_launcher_foreground.png
    mipmap-hdpi/    ...
    mipmap-xhdpi/   ...
    mipmap-xxhdpi/  ...
    mipmap-xxxhdpi/ ...
  malihub_icon_master_1024.png   (flat 1024x1024 master — for a future Play Store
                                   listing or iOS icon; not needed for Android)
```

Modern Android (8.0+, which LDPlayer's Android 9 is) uses "adaptive icons":
a background color layer plus a separate foreground glyph layer, so the
system can mask it into a circle, squircle, or whatever shape a launcher
wants. That's why there are three PNGs per density instead of one.

## How to install these into your existing project

Your Flutter project already has an `android/` folder with this same
structure — these files are drop-in replacements.

1. **Copy the icon files.** For each density folder (`mdpi`, `hdpi`, `xhdpi`,
   `xxhdpi`, `xxxhdpi`), copy the three PNGs into the matching folder in
   your project:
   ```
   android_app_icon/app/src/main/res/mipmap-xxxhdpi/*.png
     → your_project/android/app/src/main/res/mipmap-xxxhdpi/
   ```
   (Repeat for all five densities.) Overwrite the existing files when asked.

2. **Set the background color.** Open (or create)
   `android/app/src/main/res/values/colors.xml` in your project. Make sure
   it contains:
   ```xml
   <resources>
       <color name="ic_launcher_background">#1F8A4C</color>
   </resources>
   ```
   If the file already exists with a different hex value for
   `ic_launcher_background`, just change that value — don't delete
   anything else in the file.

3. **Confirm the adaptive icon XML exists.** Check
   `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` — it should
   already exist from your project setup and look like this. If it doesn't
   exist, create it:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
       <background android:drawable="@color/ic_launcher_background"/>
       <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
   </adaptive-icon>
   ```
   Do the same for `ic_launcher_round.xml` in the same folder if present.

4. **Rebuild clean.** Android caches icon resources aggressively:
   ```
   flutter clean
   flutter pub get
   flutter run
   ```

5. **If the old icon still shows on LDPlayer:** uninstall the app from
   LDPlayer first (long-press the icon → Uninstall), then reinstall. Some
   launchers cache the icon by package name and won't refresh on a plain
   reinstall over the old one.

## iOS note

You're developing on Windows, and building for iOS requires a Mac with
Xcode — so a full iOS icon set isn't included here since there's nothing
to use it with yet. The `malihub_icon_master_1024.png` file is a flat,
full-bleed square (no rounding, no transparency) suitable as a starting
point for iOS's `AppIcon.appiconset` whenever that becomes relevant.

# Releasing Dechen Study as Android and iOS Apps

This guide covers the steps to build and publish the Dechen Study app so people can download it on Android and iOS.

## What’s Already Set Up

- **App identity**: Bundle ID `com.dechen.study`, display name “Dechen Study”
- **Android**: Release signing is configured to use `android/key.properties` when that file exists
- **App icon**: Generated from `web/favicon.svg` only (see “Updating the app icon” below)
- **Secrets**: App uses `.env` or `--dart-define` for Supabase; ensure production credentials are set for release builds

---

## 1. Android

### 1.1 Create a release keystore (one-time)

From the project root:

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Use a strong password and store it safely. You’ll need it for `key.properties` and for future app updates.

### 1.2 Configure signing

```bash
cp key.properties.example key.properties
```

Edit `android/key.properties` and set:

- `storePassword` = the keystore password you chose
- `keyPassword` = the key password (often the same as store password)
- `keyAlias` = `upload`
- `storeFile` = `upload-keystore.jks` (or the path to your `.jks` file)

Do not commit `key.properties` or `*.jks` (they are in `.gitignore`).

### 1.3 Build

**For Google Play (recommended):**

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

**For direct install (e.g. your own website):**

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 1.4 Publish

- **Google Play**: Go to [Google Play Console](https://play.google.com/console), create an app (or use an existing one), upload the `.aab`, then complete store listing, content rating, privacy policy, and any other required sections before submitting for review.
- **Direct**: Host the `.apk` on a website and share the link. Users may need to allow “Install from unknown sources” (or equivalent) in their device settings.

---

## 2. iOS

### 2.1 Apple Developer account

Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year) if you haven’t already.

### 2.2 Configure signing in Xcode

1. Open **`ios/Runner.xcworkspace`** in Xcode (use the `.xcworkspace` file, not the `.xcodeproj`).
2. Select the **Runner** target and open the **Signing & Capabilities** tab.
3. Select your **Team** and enable **Automatically manage signing** (or configure provisioning profiles manually).
4. Confirm the **Bundle Identifier** is `com.dechen.study` (it is already set in the project).

### 2.3 Build

From the project root:

```bash
flutter build ipa
```

Alternatively, in Xcode: **Product → Archive**, then **Distribute App**.

### 2.4 Publish

- **App Store**: In [App Store Connect](https://appstoreconnect.apple.com), create an app with bundle ID `com.dechen.study`, upload the IPA (via Xcode Organizer or command line), fill in the store listing, privacy details, etc., then submit for review.
- **TestFlight only**: Use the same IPA; in App Store Connect, open your app and use the TestFlight tab to add testers. No public App Store listing is required for TestFlight.

---

## 3. Before Your First Submission

- **Environment / secrets**: Ensure the app is built with your production Supabase URL and anon key (e.g. in the bundled `.env` or via `--dart-define` in CI).
- **Privacy policy and terms**: Both stores often require a URL; host a page and add the link in the store listing.
- **Screenshots and assets**: Prepare required screenshots and any store-specific graphics per each store’s guidelines.

---

## 4. Updating the app icon

The app icon is generated from **`web/favicon.svg`** only.

**After editing the SVG:**

```bash
npm run generate-app-icon
```

This converts the SVG to PNG (with the correct background) and regenerates Android and iOS launcher icons. You can also run the steps manually:

```bash
npx @resvg/resvg-js-cli --fit-width 1024 --background "#F4ECDD" web/favicon.svg assets/icons/app_icon.png
dart run flutter_launcher_icons
```

---

## 5. Quick reference

| Goal                    | Command |
|-------------------------|--------|
| Android AAB (Play Store)| `flutter build appbundle --release` |
| Android APK (direct)    | `flutter build apk --release` |
| iOS IPA                 | `flutter build ipa` |
| Check tooling           | `flutter doctor` |

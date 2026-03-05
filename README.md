# Dechen Study

Dechen Study is a Flutter app for studying Buddhist texts with guided reading, daily practice, quiz modes, and optional Supabase-backed analytics/auth.

## Tech Stack

- Flutter (Dart)
- Supabase (`supabase_flutter`)
- Playwright (production smoke tests)
- iOS/Android via native Flutter targets

## Prerequisites

- Flutter stable (Dart 3+)
- Xcode + CocoaPods (for iOS builds)
- Android Studio SDK (for Android builds)
- Node.js 18+ (for Playwright)

## Setup

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Install Playwright dependencies:

```bash
npm install
npx playwright install chromium
```

3. Create a local `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_public_key
SUPABASE_URL_TEST=https://your-test-project.supabase.co
SUPABASE_ANON_KEY_TEST=your_test_anon_public_key
```

Notes:
- `SUPABASE_URL_TEST` and `SUPABASE_ANON_KEY_TEST` are optional.
- If Supabase keys are missing, the app still runs, but backend-dependent features (for example auth/analytics) are disabled.

4. For local web analytics page (`web/analytics.html`), sync `.env` to `web/supabase_config.js`:

```bash
bash scripts/sync_supabase_config.sh
```

## Run Locally

Web:

```bash
flutter run -d chrome --dart-define=APP_ENV=test
```

iOS Simulator:

```bash
flutter run -d ios --dart-define=APP_ENV=test
```

Android emulator/device:

```bash
flutter run -d android --dart-define=APP_ENV=test
```

## Testing

Static analysis:

```bash
flutter analyze
```

Unit/widget tests:

```bash
flutter test
```

Coverage:

```bash
flutter test --coverage
```

## Playwright E2E

This suite runs browser smoke checks against a deployed environment.

Default base URL is configured in `playwright.config.js`.

Run:

```bash
npm run test:e2e
```

Headed run:

```bash
npm run test:e2e:headed
```

UI mode:

```bash
npm run test:e2e:ui
```

Override target URL:

```bash
BASE_URL=https://your-deployment.example npm run test:e2e
```

## Build

Production web build:

```bash
flutter build web --release --dart-define=APP_ENV=prod
```

Android Play Store bundle:

```bash
flutter build appbundle --release
```

Android APK:

```bash
flutter build apk --release
```

## iOS Build and Release (CLI)

### One-time signing setup

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select target `Runner` -> `Signing & Capabilities`.
3. Enable `Automatically manage signing` and choose your Apple Developer Team.
4. Ensure Apple certificates/profiles are available in Xcode account settings.

### 1) Build archive

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
flutter build ipa --release --export-method app-store --no-codesign
```

Archive output:

`build/ios/archive/Runner.xcarchive`

### 2) Export signed IPA

Create `ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
```

Export:

```bash
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates
```

IPA output:

`build/ios/ipa/*.ipa`

### 3) Upload to App Store Connect (used by TestFlight)

Create `ios/UploadOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>upload</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
```

Upload:

```bash
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/upload \
  -exportOptionsPlist ios/UploadOptions.plist \
  -allowProvisioningUpdates
```

After upload, the build appears in App Store Connect and can be enabled in TestFlight after processing.

## CI

GitHub Actions (`.github/workflows/flutter.yml`) runs on push/PR to `main`:

- `flutter pub get`
- `flutter analyze`
- `flutter test --coverage`
- `flutter build web --release`

On `main`, it also deploys web output to GitHub Pages.

## Useful Docs

- `docs/APP_RELEASE.md`
- `docs/USAGE_STATISTICS_SETUP.md`
- `e2e/README.md`

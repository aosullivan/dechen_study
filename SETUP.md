# Environment Setup Guide

## Quick Start Checklist

- [ ] Flutter installed (3.0+)
- [ ] Supabase account created
- [ ] Project initialized in Supabase
- [ ] Database schema deployed
- [ ] Supabase credentials added to app
- [ ] Dependencies installed
- [ ] App running locally

## Step-by-Step Setup

### 1. Flutter Installation

If you don't have Flutter installed:

```bash
# macOS
brew install flutter

# Or download from https://flutter.dev/docs/get-started/install
```

Verify installation:
```bash
flutter doctor
```

### 2. Clone/Initialize Project

If starting from this code:
```bash
cd study_app
flutter pub get
```

### 3. Supabase Setup

1. **Create Project**
   - Go to https://supabase.com
   - Click "New Project"
   - Choose a name, database password, and region

2. **Deploy Database Schema**
   - Open Supabase dashboard
   - Go to SQL Editor
   - Copy contents of `supabase_schema.sql`
   - Paste and click "Run"

3. **Configure Authentication**
   - Go to Authentication > Providers
   - Enable Email provider
   - Go to Authentication > Email Templates
   - Customize confirmation email (optional)
   - Go to Authentication > URL Configuration
   - Add redirect URL: `io.supabase.studyapp://login-callback/` (mobile) and your web URL

4. **Get API Keys**
   - Go to Project Settings > API
   - Copy:
     - Project URL (like `https://xxxxx.supabase.co`)
     - `anon` public key

### 4. Configure App

Open `lib/main.dart` and update:

```dart
await Supabase.initialize(
  url: 'YOUR_PROJECT_URL_HERE',
  anonKey: 'YOUR_ANON_KEY_HERE',
);
```

**IMPORTANT**: Don't commit these credentials to GitHub! For production, use environment variables or a config file that's in `.gitignore`.

### 5. Run the App

Web (easiest for testing):
```bash
flutter run -d chrome
```

iOS Simulator:
```bash
flutter run -d ios
```

Android Emulator:
```bash
flutter run -d android
```

### 6. Create Test Account

1. Run the app
2. Click "Sign Up"
3. Enter email and password
4. Check your email for confirmation link
5. Click confirmation link
6. Sign in

### 7. Add Sample Data (Optional)

The schema includes sample data. If you want to add your own:

1. Go to Supabase Table Editor
2. Open `chapters` table
3. Add chapters
4. Open `sections` table  
5. Add sections (link to chapter IDs)

## Platform-Specific Configuration

### iOS Deep Linking (for email confirmation)

Edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.studyapp</string>
    </array>
  </dict>
</array>
```

### Android Deep Linking

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="io.supabase.studyapp"
    android:host="login-callback" />
</intent-filter>
```

## Development Tips

### Hot Reload
Press `r` in the terminal to hot reload
Press `R` to hot restart

### Debugging
Use VS Code or Android Studio with Flutter extensions

### Testing on Real Devices

iOS:
```bash
flutter run --release
```

Android:
```bash
flutter build apk
# Install the APK from build/app/outputs/flutter-apk/
```

## Troubleshooting

**Can't connect to Supabase**
- Check your internet connection
- Verify URL and anon key are correct
- Check Supabase project is not paused

**Email confirmation not working**
- Check spam folder
- Verify email provider is enabled in Supabase
- Check redirect URLs are configured

**Build errors**
```bash
flutter clean
flutter pub get
flutter run
```

**Web build fails**
Make sure you have the web folder:
```bash
flutter create . --platforms=web
```

## Next Steps

1. Upload your study text
2. Customize colors/fonts
3. Test all features
4. Deploy to production
5. Share with users!

## Production Deployment

### Web
```bash
flutter build web --release
```
Deploy `build/web` to:
- Netlify
- Vercel  
- Firebase Hosting
- GitHub Pages

### Mobile
- iOS: Use Xcode to archive and upload to App Store
- Android: `flutter build appbundle` and upload to Play Store

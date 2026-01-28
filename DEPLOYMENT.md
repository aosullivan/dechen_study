# Deployment Guide

## Deploying to Production

### Prerequisites

- [ ] Supabase project in production mode
- [ ] Custom domain (optional but recommended)
- [ ] App tested thoroughly in development

## Web Deployment

### Option 1: Netlify (Recommended for simplicity)

1. **Build the app**
   ```bash
   flutter build web --release
   ```

2. **Create Netlify account** at https://netlify.com

3. **Deploy**
   - Drag and drop `build/web` folder to Netlify
   - Or connect GitHub repo for automatic deployments
   - Set build command: `flutter build web --release`
   - Set publish directory: `build/web`

4. **Configure custom domain** (optional)
   - Go to Domain settings
   - Add your domain
   - Update DNS records as instructed

5. **Update Supabase redirect URLs**
   - Add your production URL to Supabase Authentication > URL Configuration

### Option 2: Vercel

1. **Build**
   ```bash
   flutter build web --release
   ```

2. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

3. **Deploy**
   ```bash
   cd build/web
   vercel
   ```

### Option 3: Firebase Hosting

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Firebase**
   ```bash
   firebase init hosting
   # Select build/web as public directory
   # Configure as single-page app: Yes
   ```

3. **Build and deploy**
   ```bash
   flutter build web --release
   firebase deploy
   ```

### Option 4: GitHub Pages

1. **Enable GitHub Pages** in repo settings

2. **Build**
   ```bash
   flutter build web --release --base-href "/repo-name/"
   ```

3. **Deploy** (automated via GitHub Actions in `.github/workflows/flutter.yml`)
   - Just push to main branch
   - Or manually copy `build/web` to `gh-pages` branch

## Mobile Deployment

### iOS App Store

1. **Requirements**
   - Apple Developer account ($99/year)
   - Mac with Xcode
   - Provisioning profiles and certificates

2. **Prepare app**
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. **Update app configuration**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Set Bundle Identifier (e.g., com.yourdomain.studyapp)
   - Set Team
   - Update version and build number

4. **Configure deep linking**
   - Add Associated Domains capability
   - Add your domain for universal links
   - Configure in Supabase dashboard

5. **Build**
   ```bash
   flutter build ios --release
   ```

6. **Archive and Upload**
   - In Xcode: Product > Archive
   - Upload to App Store Connect
   - Submit for review

### Android Play Store

1. **Requirements**
   - Google Play Developer account ($25 one-time)

2. **Create keystore**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

3. **Configure signing**
   Create `android/key.properties`:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=/path/to/upload-keystore.jks
   ```

   Update `android/app/build.gradle`:
   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

4. **Update app details**
   - Edit `android/app/src/main/AndroidManifest.xml`
   - Set application ID in `android/app/build.gradle`
   - Update app name, icons, etc.

5. **Build**
   ```bash
   flutter build appbundle --release
   ```

6. **Upload to Play Console**
   - Create app in Google Play Console
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Fill in store listing details
   - Submit for review

## Environment Variables (Production)

For security, don't hardcode credentials. Use environment variables:

### Create config file (not in git)

`lib/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
}
```

### Build with environment variables

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxx
```

## Post-Deployment Checklist

- [ ] Test authentication (signup, login, email confirmation)
- [ ] Test all features (read, daily section, quiz)
- [ ] Verify deep linking works (email confirmation)
- [ ] Check responsive design on different screen sizes
- [ ] Test on actual devices (iOS and Android)
- [ ] Monitor Supabase usage and quotas
- [ ] Set up error tracking (Sentry, Firebase Crashlytics)
- [ ] Configure analytics (optional)
- [ ] Add privacy policy and terms of service
- [ ] Test performance and optimize if needed

## Monitoring and Maintenance

### Supabase Dashboard
Monitor:
- Database usage
- API requests
- Active users
- Error logs

### Analytics (Optional)

Add Firebase Analytics or similar:
```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^10.8.0
```

### Error Tracking

Add Sentry:
```yaml
dependencies:
  sentry_flutter: ^7.14.0
```

```dart
// main.dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_SENTRY_DSN';
  },
  appRunner: () => runApp(MyApp()),
);
```

## Updating the App

### Web
1. Make changes
2. Build: `flutter build web --release`
3. Deploy (automatic if using CI/CD)

### Mobile
1. Make changes
2. Increment version in `pubspec.yaml`
3. Build and upload to stores
4. Submit for review

## Backup Strategy

1. **Database backups**
   - Supabase provides daily backups
   - Enable Point-in-Time Recovery for production

2. **Code backups**
   - Use Git
   - Push to GitHub regularly
   - Tag releases

3. **User data**
   - Export user data periodically
   - Store securely

## Scaling Considerations

As your app grows:

1. **Supabase**
   - Upgrade to Pro plan if needed
   - Monitor performance
   - Add database indexes for slow queries

2. **CDN**
   - Use CDN for web assets
   - Consider image optimization

3. **Rate limiting**
   - Implement rate limiting for API calls
   - Use Supabase Edge Functions if needed

## Security Best Practices

- ✅ Enable Row Level Security (RLS) on all tables
- ✅ Use HTTPS only
- ✅ Validate all user inputs
- ✅ Keep dependencies updated
- ✅ Monitor for security vulnerabilities
- ✅ Use environment variables for secrets
- ✅ Implement proper error handling
- ✅ Add logging for suspicious activities

## Cost Optimization

1. **Supabase Free Tier**
   - 500MB database
   - 1GB file storage
   - 2GB bandwidth
   - Good for testing and small apps

2. **Supabase Pro** ($25/month)
   - 8GB database
   - 100GB file storage
   - 250GB bandwidth
   - Daily backups
   - Point-in-time recovery

3. **Optimization tips**
   - Minimize API calls
   - Cache data when possible
   - Compress images
   - Use pagination for large datasets

## Support and Documentation

- Supabase docs: https://supabase.com/docs
- Flutter docs: https://docs.flutter.dev
- Your app documentation: Keep README.md updated
- User support: Set up email or forum

## Rollback Plan

If something goes wrong:

1. **Web**: Revert to previous deploy
2. **Mobile**: Can't rollback, but can push emergency update
3. **Database**: Restore from backup if needed
4. **Always test thoroughly before deploying!**

# Quick Reference - Study App

## Essential Commands

### Development

```bash
# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator  
flutter run -d android

# Hot reload (while running)
# Press 'r' in terminal

# Hot restart (while running)
# Press 'R' in terminal

# Check for issues
flutter doctor

# Analyze code
flutter analyze

# Format code
dart format .

# Clean build artifacts
flutter clean
```

### Building

```bash
# Build for web
flutter build web --release

# Build iOS
flutter build ios --release

# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build with environment variables
flutter build web --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxx
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Deployment

```bash
# Deploy to Firebase Hosting
firebase deploy

# Deploy to Netlify (CLI)
netlify deploy --prod --dir=build/web

# Deploy to Vercel
vercel --prod
```

## Supabase Commands (SQL Editor)

### View all chapters
```sql
SELECT * FROM chapters ORDER BY chapter_number;
```

### View all sections
```sql
SELECT s.*, c.chapter_number, c.title as chapter_title
FROM sections s
JOIN chapters c ON s.chapter_id = c.id
ORDER BY c.chapter_number, s.order_index;
```

### View user progress
```sql
SELECT * FROM user_progress;
```

### View daily completions
```sql
SELECT * FROM daily_progress ORDER BY date DESC;
```

### Reset user progress (for testing)
```sql
DELETE FROM daily_progress WHERE user_id = 'USER_ID';
UPDATE user_progress SET current_section_index = 0 WHERE user_id = 'USER_ID';
```

### Add chapter
```sql
INSERT INTO chapters (chapter_number, title) 
VALUES (1, 'Introduction');
```

### Add section
```sql
INSERT INTO sections (chapter_id, content, order_index) 
VALUES (1, 'Your section text here...', 0);
```

### Count total sections
```sql
SELECT COUNT(*) as total_sections FROM sections;
```

## Project Structure

```
study_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   └── text_data.dart          # Data models
│   └── screens/
│       ├── splash_screen.dart      # Loading screen
│       ├── home_screen.dart        # Main navigation
│       ├── auth/
│       │   └── login_screen.dart   # Login/signup
│       └── study/
│           ├── read_text_screen.dart       # Full text view
│           ├── daily_section_screen.dart   # Daily feature
│           └── quiz_screen.dart            # Quiz feature
├── web/
│   ├── index.html                  # Web entry point
│   └── manifest.json               # PWA manifest
├── tools/
│   ├── import_text.dart            # Data import script
│   └── example_text.txt            # Example format
├── pubspec.yaml                    # Dependencies
├── supabase_schema.sql            # Database schema
├── README.md                       # Main documentation
├── SETUP.md                        # Setup guide
├── DEPLOYMENT.md                   # Deployment guide
└── ARCHITECTURE.md                 # Design document
```

## Common Issues & Solutions

### "Supabase is not initialized"
```dart
// Make sure main() has:
await Supabase.initialize(
  url: 'YOUR_URL',
  anonKey: 'YOUR_KEY',
);
```

### Email confirmation not working
1. Check spam folder
2. Verify redirect URL in Supabase dashboard
3. Check email provider is enabled

### Can't connect to Supabase
1. Check internet connection
2. Verify URL and anon key are correct
3. Check Supabase project is not paused

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Sections not showing
1. Verify data exists in Supabase tables
2. Check RLS policies allow SELECT
3. Look at console for errors

### Deep linking not working (mobile)
1. iOS: Check Info.plist configuration
2. Android: Check AndroidManifest.xml
3. Verify URL scheme matches Supabase config

## Keyboard Shortcuts (VS Code)

- `Cmd/Ctrl + .` - Quick fixes
- `Cmd/Ctrl + Shift + P` - Command palette
- `F5` - Start debugging
- `Shift + F5` - Stop debugging
- `Cmd/Ctrl + /` - Toggle comment
- `Alt + Shift + F` - Format document

## Git Commands

```bash
# Initial setup
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/username/repo.git
git push -u origin main

# Regular workflow
git add .
git commit -m "Your message"
git push

# Create branch
git checkout -b feature-name

# Merge branch
git checkout main
git merge feature-name
```

## Useful URLs

- Supabase Dashboard: https://supabase.com/dashboard
- Flutter Docs: https://docs.flutter.dev
- Dart Packages: https://pub.dev
- Google Fonts: https://fonts.google.com

## Environment Variables

```bash
# Export (Linux/Mac)
export SUPABASE_URL="https://xxx.supabase.co"
export SUPABASE_ANON_KEY="xxx"

# Use in build
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

## Performance Tips

1. Use `const` constructors where possible
2. Avoid rebuilding entire widget tree
3. Use `ListView.builder` for long lists
4. Cache network responses
5. Optimize images (compress, use WebP)
6. Lazy load data
7. Profile before optimizing: `flutter run --profile`

## Security Checklist

- [ ] Row Level Security enabled on all tables
- [ ] Credentials not in source code
- [ ] HTTPS only
- [ ] Input validation
- [ ] Dependencies updated
- [ ] Error messages don't leak info
- [ ] Rate limiting configured
- [ ] Admin endpoints protected

## Before Deploying

- [ ] Test all features
- [ ] Test on different devices
- [ ] Test different screen sizes
- [ ] Update version number
- [ ] Update CHANGELOG
- [ ] Create git tag
- [ ] Backup database
- [ ] Update documentation
- [ ] Configure monitoring
- [ ] Set up error tracking

## Support

- GitHub Issues: [Your repo]/issues
- Email: your-email@example.com
- Supabase Discord: https://discord.supabase.com
- Flutter Discord: https://discord.gg/flutter

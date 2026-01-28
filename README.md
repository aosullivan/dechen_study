# Study App - Flutter + Supabase

A beautiful study app inspired by dechen.study aesthetics, built with Flutter and Supabase. Features include daily study sections, chapter quizzes, and full text reading.

## Features

- 📧 **Email Authentication** with confirmation
- 📅 **Daily Sections** - One section per day, mark as complete
- 🎯 **Chapter Quiz** - Test yourself by identifying which chapter a random section is from
- 📖 **Read Mode** - Browse the full text organized by chapters
- 🎨 **Beautiful UI** - Warm, serene design inspired by dechen.study

## Prerequisites

- Flutter SDK (3.0+)
- A Supabase account and project
- Git and GitHub (already set up)

## Setup Instructions

### 1. Supabase Configuration

1. Go to your [Supabase Dashboard](https://app.supabase.com)
2. Create a new project (or use existing)
3. **Set up the database:**
   - Go to SQL Editor in Supabase
   - Copy the contents of `supabase_schema.sql`
   - Paste and run it to create all tables

4. **Configure Email Authentication:**
   - Go to Authentication → Settings
   - Under "Auth Providers", enable Email provider
   - Configure email templates (optional but recommended):
     - Customize the confirmation email
     - Set the redirect URL to match your app

5. **Get your API credentials:**
   - Go to Settings → API
   - Copy your `Project URL` and `anon/public` key
   - You'll need these for the next step

### 2. Flutter App Configuration

1. **Update Supabase credentials:**
   ```dart
   // lib/utils/constants.dart
   const String supabaseUrl = 'YOUR_SUPABASE_URL'; // Paste your Project URL
   const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // Paste your anon key
   ```

2. **Install fonts:**
   
   Download these fonts and place them in a `fonts/` directory in your project root:
   - **Crimson Text** (Google Fonts): [Download](https://fonts.google.com/specimen/Crimson+Text)
     - CrimsonText-Regular.ttf
     - CrimsonText-SemiBold.ttf
   
   - **Lora** (Google Fonts): [Download](https://fonts.google.com/specimen/Lora)
     - Lora-Regular.ttf
     - Lora-Medium.ttf
     - Lora-SemiBold.ttf

   OR you can use system fonts by removing the font family from `main.dart` theme.

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

### 3. Upload Your Study Text

You need to populate the database with your study text. Here are two methods:

#### Method A: Using Supabase SQL Editor (Simple)

1. Go to Supabase → SQL Editor
2. Modify `sample_data_upload.sql` with your actual text content
3. Run the SQL to insert your data

#### Method B: Using a Script (Recommended for large texts)

Create a simple Python/Node.js script to:
1. Read your text file
2. Parse it into chapters and sections
3. Insert via Supabase API or SQL

Example structure:
```
Study Text
├── Chapter 1
│   ├── Section 1
│   ├── Section 2
│   └── Section 3
├── Chapter 2
│   ├── Section 1
│   └── Section 2
└── ...
```

### 4. Run the App

```bash
# For mobile (iOS/Android)
flutter run

# For web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── study_models.dart    # Data models
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   └── home/
│       ├── home_screen.dart
│       ├── daily_section_screen.dart
│       ├── quiz_screen.dart
│       └── read_screen.dart
├── services/
│   ├── auth_service.dart    # Authentication logic
│   └── study_service.dart   # Study data logic
├── utils/
│   └── constants.dart       # Supabase config
└── widgets/
    └── auth_text_field.dart # Reusable widgets
```

## Database Schema

- **study_texts**: Main text documents
- **chapters**: Chapters within a study text
- **sections**: Individual sections within chapters
- **daily_sections**: Tracks daily progress per user

## Usage

1. **Sign Up**: Create account with email (requires confirmation)
2. **Daily Tab**: View today's section and mark it complete
3. **Quiz Tab**: Get random sections and guess which chapter they're from
4. **Read Tab**: Browse the full text organized by chapters

## Design Notes

The app follows a warm, serene aesthetic inspired by dechen.study:
- **Colors**: Warm browns (#8B7355), cream backgrounds (#FAF8F5)
- **Typography**: Crimson Text for headings, Lora for body
- **Layout**: Clean, spacious, with subtle borders
- **Animations**: Minimal, elegant transitions

## Customization

### Change Color Scheme
Edit the colors in `lib/main.dart` under `ThemeData`:
```dart
seedColor: const Color(0xFF8B7355), // Main color
scaffoldBackgroundColor: const Color(0xFFFAF8F5), // Background
```

### Change Fonts
Update font families in `pubspec.yaml` and `main.dart`

### Modify Features
- Edit `daily_section_screen.dart` to change daily section behavior
- Edit `quiz_screen.dart` to modify quiz logic
- Edit `read_screen.dart` to customize reading experience

## Troubleshooting

**Email confirmation not working?**
- Check Supabase email settings
- Verify email templates are configured
- Check spam folder for confirmation emails

**Database errors?**
- Ensure `supabase_schema.sql` was run successfully
- Check RLS policies are enabled
- Verify your anon key has correct permissions

**Fonts not loading?**
- Verify font files are in `fonts/` directory
- Check `pubspec.yaml` font paths match actual files
- Run `flutter pub get` after adding fonts

**App not connecting to Supabase?**
- Double-check URL and anon key in `constants.dart`
- Ensure you're using the correct anon key (not service role)
- Check network connectivity

## Future Enhancements

Ideas for extending the app:
- Progress tracking and statistics
- Multiple study texts
- Bookmarks and notes
- Spaced repetition algorithm
- Share sections with friends
- Dark mode
- Offline mode

## License

MIT License - feel free to use and modify for your own study needs!

## Support

If you encounter issues:
1. Check the troubleshooting section
2. Review Supabase logs in the dashboard
3. Check Flutter console for error messages

Happy studying! 📚

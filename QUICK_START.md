# Quick Start Checklist ✅

Follow these steps to get your study app running:

## 1. Supabase Setup (15 minutes)

- [ ] Go to https://app.supabase.com
- [ ] Create a new project
- [ ] Go to SQL Editor
- [ ] Copy and run `supabase_schema.sql` 
- [ ] Go to Authentication → Settings → Enable Email provider
- [ ] Go to Settings → API
- [ ] Copy your Project URL
- [ ] Copy your anon/public key

## 2. Configure the App (5 minutes)

- [ ] Open `lib/utils/constants.dart`
- [ ] Paste your Supabase URL
- [ ] Paste your anon key
- [ ] Run `flutter pub get`

## 3. Add Fonts (10 minutes) - OPTIONAL

- [ ] Create `fonts/` directory in project root
- [ ] Download Crimson Text from Google Fonts
- [ ] Download Lora from Google Fonts
- [ ] Place font files in `fonts/` directory
- [ ] OR comment out font families in `main.dart` to use system fonts

## 4. Upload Your Study Text (30 minutes)

- [ ] Prepare your text file with chapters and sections
- [ ] Go to Supabase → SQL Editor
- [ ] Modify and run `sample_data_upload.sql` with your content
- [ ] OR create a script to parse and upload your text

## 5. Test the App (5 minutes)

- [ ] Run `flutter run` (or `flutter run -d chrome` for web)
- [ ] Create an account
- [ ] Check your email for confirmation
- [ ] Click the confirmation link
- [ ] Sign in
- [ ] Test all three tabs: Daily, Quiz, Read

## You're Done! 🎉

Your study app is now ready to use. Start with the Daily tab to begin your study journey.

## Need Help?

- Check `README.md` for detailed instructions
- Review Supabase logs if database issues occur
- Check Flutter console for app errors
- Verify email confirmation is working

## Pro Tips

1. **Test with sample data first** before uploading your full text
2. **Use descriptive section breaks** to make quizzes more meaningful
3. **Keep sections relatively short** (3-5 paragraphs) for better daily study
4. **Backup your Supabase database** regularly
5. **Customize colors** in `main.dart` to match your preferences

# Supabase Setup Instructions

## ✅ Completed Setup

1. **Supabase CLI Configuration**
   - Linked project: `dechen_study` (ref: `vzcfwipgpcscmlaqqfko`)
   - Region: East US (North Virginia)

2. **Storage Bucket Created**
   - Bucket name: `texts`
   - Privacy: Private (users can only access their own files)
   - Policies configured for CRUD operations per user

3. **Flutter Integration**
   - Added dependencies: `supabase_flutter`, `flutter_dotenv`
   - Environment variables configured in `.env` file
   - Supabase initialized in `main.dart`

## 🔧 Required Dashboard Configuration

### Enable Email Authentication

You need to configure email auth settings in the Supabase dashboard:

1. Go to: https://supabase.com/dashboard/project/vzcfwipgpcscmlaqqfko

2. Navigate to **Authentication** → **Providers**

3. Enable **Email** provider

4. Configure **Email Auth Settings**:
   - ✅ Enable email confirmations
   - Set **Confirm email** to `true`
   - Configure email templates (optional but recommended)
   - Set up SMTP for production (optional, uses Supabase SMTP by default)

5. Under **Authentication** → **URL Configuration**:
   - Add your app's redirect URLs for email confirmation
   - For local development: `http://localhost:3000/auth/callback`
   - For production: Your deployed app URL

### Optional: Email Templates

Customize email templates under **Authentication** → **Email Templates**:
- Confirmation email
- Magic link email
- Password reset email

## 📁 Project Structure

```
dechen_study/
├── .env                    # Supabase credentials (gitignored)
├── lib/
│   └── main.dart          # App entry point with Supabase initialization
└── supabase/
    └── migrations/
        └── 20260128_setup_auth_and_storage.sql
```

## 🔑 Environment Variables

Your `.env` file contains:
```
SUPABASE_URL=https://vzcfwipgpcscmlaqqfko.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

**Important:** The `.env` file is already added to `.gitignore` to protect your credentials.

### Test vs Prod

- **Prod** (Vercel): Uses `SUPABASE_URL` and `SUPABASE_ANON_KEY` from Vercel env vars.
- **Test** (local): Uses `SUPABASE_URL_TEST` and `SUPABASE_ANON_KEY_TEST` in `.env`. Run with `--dart-define=APP_ENV=test`.

See README "Environment Split (test vs prod)" for details.

## 🚀 Usage in Code

Access the Supabase client anywhere in your app:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Example: Sign up
await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password',
);

// Example: Upload to storage
await supabase.storage
  .from('texts')
  .upload('user_id/filename.txt', fileBytes);
```

## 📚 Next Steps

1. Complete the email auth configuration in the Supabase dashboard (see above)
2. Create authentication screens (login, signup, password reset)
3. Set up Riverpod providers for auth state management
4. Create models for your data
5. Build UI for uploading and viewing texts

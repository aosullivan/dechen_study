# Why the Vercel Deploy Was Failing

## Summary

The app at https://dechen-study.vercel.app/ returns **"Content not found"** because:

1. **Vercel does not include Flutter** in its build environment. If you connect the repo and use default or "Other" with Build Command `flutter build web`, the build **fails** with `flutter: command not found`, so nothing is deployed (or a previous empty/broken deploy is shown).

2. **No `vercel.json`** was in the project, so Vercel had no instructions for:
   - Installing the Flutter SDK during the build
   - Running the Flutter web build
   - Using `build/web` as the output directory

3. **Wrong content would be served if the build were skipped**: The repo root contains `web/index.html`, which references `flutter_bootstrap.js`. That file is only produced by `flutter build web`. So deploying the repo root without building would result in a broken or 404 page.

4. **`.env` is gitignored**. The app loads Supabase URL and anon key from `.env` at runtime. On Vercel that file doesn’t exist unless you create it during the build from Vercel’s environment variables (see below).

## Fix Applied

- **`vercel.json`** – Configures Install Command, Build Command, and Output Directory.
- **`scripts/install-flutter-vercel.sh`** – Installs Flutter (stable) and runs `flutter pub get`.
- **`scripts/build-flutter-vercel.sh`** – Writes `.env` from Vercel env vars, then runs `flutter build web`.

## What You Must Do in Vercel

1. **Environment variables**  
   In the Vercel project: **Settings → Environment Variables**, add:
   - `SUPABASE_URL` = your Supabase project URL  
   - `SUPABASE_ANON_KEY` = your Supabase anon key  

2. **Redeploy**  
   Trigger a new deploy (e.g. push a commit or use “Redeploy” in the Vercel dashboard) so the new build scripts and `vercel.json` are used.

## Optional: Build Without Installing Flutter on Vercel

If you prefer not to install Flutter on Vercel (faster deploys, no Flutter install step):

1. Build locally: `flutter build web --release`
2. Deploy only the output: `cd build/web && vercel --prod`

That uses the approach in `DEPLOYMENT.md` (Option 2: Vercel) and does not use Vercel’s Git-based build for this repo.

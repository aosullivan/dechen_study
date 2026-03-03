# Usage statistics setup

Usage statistics are already configured in the database (table `app_usage_events`, RPC `analytics_dashboard_json`). To have the app record events and the analytics dashboard show data, do the following.

## 1. Configure Supabase in the app

You need a `.env` in the project root and (for web) `web/supabase_config.js`.

**Option A – via Supabase MCP** (recommended): Use the Supabase MCP server to get the project URL and anon key (`get_project_url`, `get_publishable_keys`), then write `.env` and `web/supabase_config.js` with those values. Both files are gitignored.

**Option B – manually**: Create `.env` with:

```env
SUPABASE_URL=https://vzcfwipgpcscmlaqqfko.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

Get the anon key from the Supabase dashboard: **Project Settings → API → Project API keys → anon public**.

For web (local), either sync from `.env` once:

```bash
bash scripts/sync_supabase_config.sh
```

or ensure `web/supabase_config.js` sets `window.SUPABASE_URL` and `window.SUPABASE_ANON_KEY`. For production (e.g. Vercel), set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the build environment and inject them into `web/supabase_config.js` (e.g. via your build script).

## 2. Verify it works

- **App**: Use the app (open texts, read, quiz). Events are sent in the background. If Supabase isn’t configured, the service disables itself and you may see a debug message.
- **Analytics dashboard**: Open `/analytics.html` in the browser (e.g. `http://localhost:PORT/analytics.html` for local web, or `https://your-domain/analytics.html` in production). It calls `analytics_dashboard_json` and shows totals, unique users, and charts. If you see “Error: …” or a config error, check that `window.SUPABASE_URL` and `window.SUPABASE_ANON_KEY` are set (e.g. by loading `supabase_config.js` before the dashboard script).

## 3. (Optional) Stable anonymous IDs on web

For better unique-user counts on web (cookie-based ID that survives localStorage clear), deploy the `get-anon-id` Edge Function. You can deploy it via Supabase MCP (`deploy_edge_function` with `name: "get-anon-id"`, `verify_jwt: false`, and the function source from `supabase/functions/get-anon-id/index.ts`), or via CLI:

```bash
supabase login
supabase link --project-ref vzcfwipgpcscmlaqqfko
supabase functions deploy get-anon-id
```

The app will use it automatically on web when available; mobile keeps using device storage.

## Summary

| Step | Action |
|------|--------|
| 1 | Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to `.env` |
| 2 (web) | Run `bash scripts/sync_supabase_config.sh` for local web; ensure production build injects the same config |
| 3 | Use the app and open `/analytics.html` to confirm events and dashboard |
| 4 (optional) | Deploy `get-anon-id` Edge Function for stable web anon IDs |

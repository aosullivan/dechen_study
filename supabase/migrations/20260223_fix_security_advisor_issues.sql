-- Fix Supabase Security Advisor issues:
-- 1. security_definer_view: Set views to SECURITY INVOKER so they run with caller's permissions
-- 2. rls_disabled_in_public: Enable RLS on app_usage_event_retention_runs (audit log)

-- 0010: Security definer view - use invoker so RLS of underlying tables applies
ALTER VIEW public.analytics_text_dwell_daily_v1 SET (security_invoker = true);
ALTER VIEW public.analytics_mode_dwell_daily_v1 SET (security_invoker = true);
ALTER VIEW public.analytics_read_section_dwell_daily_v1 SET (security_invoker = true);
ALTER VIEW public.analytics_top_read_sections_30d_v1 SET (security_invoker = true);

-- 0013: RLS disabled in public - enable RLS on retention audit table
-- No policies: anon/authenticated get no access; service role and prune function (SECURITY DEFINER) bypass RLS
ALTER TABLE public.app_usage_event_retention_runs ENABLE ROW LEVEL SECURITY;

-- Add country_code to events for origin analytics; add unique anon/users and events_by_country to dashboard RPC.

ALTER TABLE public.app_usage_events
  ADD COLUMN IF NOT EXISTS country_code TEXT;

CREATE INDEX IF NOT EXISTS idx_app_usage_events_country_code
  ON public.app_usage_events (country_code)
  WHERE country_code IS NOT NULL;

CREATE OR REPLACE FUNCTION public.analytics_dashboard_json()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'events_by_mode', COALESCE((
      SELECT jsonb_agg(row_to_json(t)::jsonb)
      FROM (
        SELECT mode, COUNT(*)::int AS count
        FROM app_usage_events
        WHERE mode IS NOT NULL
        GROUP BY mode
        ORDER BY count DESC
      ) t
    ), '[]'::jsonb),
    'events_by_mode_and_text', COALESCE((
      SELECT jsonb_agg(row_to_json(t)::jsonb)
      FROM (
        SELECT mode, text_id, COUNT(*)::int AS count
        FROM app_usage_events
        WHERE mode IS NOT NULL AND text_id IS NOT NULL
        GROUP BY mode, text_id
        ORDER BY mode, count DESC
      ) t
    ), '[]'::jsonb),
    'events_by_type', COALESCE((
      SELECT jsonb_agg(row_to_json(t)::jsonb)
      FROM (
        SELECT event_name, mode, COUNT(*)::int AS count
        FROM app_usage_events
        GROUP BY event_name, mode
        ORDER BY count DESC
        LIMIT 20
      ) t
    ), '[]'::jsonb),
    'events_by_text', COALESCE((
      SELECT jsonb_agg(row_to_json(t)::jsonb)
      FROM (
        SELECT text_id, COUNT(*)::int AS count
        FROM app_usage_events
        WHERE text_id IS NOT NULL
        GROUP BY text_id
        ORDER BY count DESC
      ) t
    ), '[]'::jsonb),
    'events_over_time', COALESCE((
      SELECT jsonb_agg(row_to_json(t)::jsonb)
      FROM (
        SELECT to_char(date_trunc('day', occurred_at AT TIME ZONE 'utc'), 'YYYY-MM-DD') AS day,
               COUNT(*)::int AS count
        FROM app_usage_events
        WHERE occurred_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY date_trunc('day', occurred_at AT TIME ZONE 'utc')
        ORDER BY day
      ) t
    ), '[]'::jsonb),
    'events_over_time_by_text', COALESCE((
      SELECT jsonb_agg(row_to_json(t)::jsonb)
      FROM (
        SELECT to_char(date_trunc('day', occurred_at AT TIME ZONE 'utc'), 'YYYY-MM-DD') AS day,
               text_id,
               COUNT(*)::int AS count
        FROM app_usage_events
        WHERE occurred_at >= CURRENT_DATE - INTERVAL '30 days'
          AND text_id IS NOT NULL
        GROUP BY date_trunc('day', occurred_at AT TIME ZONE 'utc'), text_id
        ORDER BY day, text_id
      ) t
    ), '[]'::jsonb),
    'events_by_country', COALESCE((
      SELECT jsonb_agg(row_to_json(t)::jsonb)
      FROM (
        SELECT country_code, COUNT(*)::int AS count
        FROM app_usage_events
        WHERE country_code IS NOT NULL AND trim(country_code) <> ''
        GROUP BY country_code
        ORDER BY count DESC
        LIMIT 30
      ) t
    ), '[]'::jsonb),
    'quiz_summary', (
      SELECT jsonb_build_object(
        'quiz_attempts', COUNT(*) FILTER (WHERE event_name = 'quiz_attempt'),
        'quiz_sessions', COUNT(DISTINCT session_id) FILTER (WHERE mode = 'quiz' OR event_name IN ('quiz_attempt', 'quiz_next_question_tapped', 'quiz_answer_revealed'))
      )
      FROM app_usage_events
    ),
    'totals', (
      SELECT jsonb_build_object(
        'total_events', COUNT(*),
        'unique_sessions', COUNT(DISTINCT session_id),
        'unique_anon_users', (SELECT COUNT(DISTINCT anon_id)::int FROM app_usage_events WHERE user_id IS NULL AND anon_id IS NOT NULL),
        'unique_authenticated_users', (SELECT COUNT(DISTINCT user_id)::int FROM app_usage_events WHERE user_id IS NOT NULL)
      )
      FROM app_usage_events
    )
  ) INTO result;
  RETURN COALESCE(result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.analytics_dashboard_json() TO anon, authenticated;

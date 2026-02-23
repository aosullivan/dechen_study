-- RPC function for analytics dashboard. Returns JSON for HTML charts.
-- SECURITY DEFINER so anon can call it without SELECT on app_usage_events.

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
        'unique_sessions', COUNT(DISTINCT session_id)
      )
      FROM app_usage_events
    )
  ) INTO result;
  RETURN COALESCE(result, '{}'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.analytics_dashboard_json() TO anon, authenticated;

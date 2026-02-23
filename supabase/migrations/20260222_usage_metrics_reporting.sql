-- Usage metrics reporting views, retention pruning, and query-performance indexes.

-- Partial indexes to speed dwell-centric reporting queries.
CREATE INDEX IF NOT EXISTS idx_app_usage_events_surface_dwell_occurred_at
  ON public.app_usage_events (occurred_at DESC, text_id, mode)
  WHERE event_name = 'surface_dwell' AND duration_ms IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_app_usage_events_read_section_dwell_path_occurred_at
  ON public.app_usage_events (section_path, occurred_at DESC)
  WHERE event_name = 'read_section_dwell' AND duration_ms IS NOT NULL;

-- Daily text-level dwell aggregates from surface-level dwell events.
CREATE OR REPLACE VIEW public.analytics_text_dwell_daily_v1 AS
WITH base AS (
  SELECT
    date_trunc('day', occurred_at AT TIME ZONE 'utc')::date AS day_utc,
    text_id,
    session_id,
    COALESCE(user_id::text, anon_id) AS actor_id,
    LEAST(duration_ms, 7200000)::double precision / 1000.0 AS duration_sec
  FROM public.app_usage_events
  WHERE event_name = 'surface_dwell'
    AND duration_ms IS NOT NULL
    AND duration_ms >= 1000
    AND text_id IS NOT NULL
),
session_rollups AS (
  SELECT
    day_utc,
    text_id,
    session_id,
    SUM(duration_sec) AS session_dwell_sec
  FROM base
  GROUP BY day_utc, text_id, session_id
),
event_agg AS (
  SELECT
    day_utc,
    text_id,
    COUNT(*)::bigint AS dwell_event_count,
    COUNT(DISTINCT actor_id)::bigint AS unique_actor_count,
    COUNT(DISTINCT session_id)::bigint AS unique_session_count,
    ROUND(SUM(duration_sec)::numeric, 2) AS total_dwell_seconds,
    ROUND(AVG(duration_sec)::numeric, 2) AS avg_dwell_seconds,
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS median_event_dwell_seconds,
    ROUND(percentile_cont(0.9) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS p90_event_dwell_seconds
  FROM base
  GROUP BY day_utc, text_id
),
session_agg AS (
  SELECT
    day_utc,
    text_id,
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY session_dwell_sec)::numeric, 2)
      AS median_session_dwell_seconds
  FROM session_rollups
  GROUP BY day_utc, text_id
)
SELECT
  e.day_utc,
  e.text_id,
  e.total_dwell_seconds,
  e.dwell_event_count,
  e.unique_actor_count,
  e.unique_session_count,
  e.avg_dwell_seconds,
  e.median_event_dwell_seconds,
  e.p90_event_dwell_seconds,
  COALESCE(s.median_session_dwell_seconds, 0) AS median_session_dwell_seconds
FROM event_agg e
LEFT JOIN session_agg s
  ON s.day_utc = e.day_utc
 AND s.text_id = e.text_id;

-- Daily text+mode dwell aggregates from surface-level dwell events.
CREATE OR REPLACE VIEW public.analytics_mode_dwell_daily_v1 AS
WITH base AS (
  SELECT
    date_trunc('day', occurred_at AT TIME ZONE 'utc')::date AS day_utc,
    text_id,
    mode,
    session_id,
    COALESCE(user_id::text, anon_id) AS actor_id,
    LEAST(duration_ms, 7200000)::double precision / 1000.0 AS duration_sec
  FROM public.app_usage_events
  WHERE event_name = 'surface_dwell'
    AND duration_ms IS NOT NULL
    AND duration_ms >= 1000
    AND text_id IS NOT NULL
    AND mode IS NOT NULL
),
session_rollups AS (
  SELECT
    day_utc,
    text_id,
    mode,
    session_id,
    SUM(duration_sec) AS session_dwell_sec
  FROM base
  GROUP BY day_utc, text_id, mode, session_id
),
event_agg AS (
  SELECT
    day_utc,
    text_id,
    mode,
    COUNT(*)::bigint AS dwell_event_count,
    COUNT(DISTINCT actor_id)::bigint AS unique_actor_count,
    COUNT(DISTINCT session_id)::bigint AS unique_session_count,
    ROUND(SUM(duration_sec)::numeric, 2) AS total_dwell_seconds,
    ROUND(AVG(duration_sec)::numeric, 2) AS avg_dwell_seconds,
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS median_event_dwell_seconds,
    ROUND(percentile_cont(0.9) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS p90_event_dwell_seconds
  FROM base
  GROUP BY day_utc, text_id, mode
),
session_agg AS (
  SELECT
    day_utc,
    text_id,
    mode,
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY session_dwell_sec)::numeric, 2)
      AS median_session_dwell_seconds
  FROM session_rollups
  GROUP BY day_utc, text_id, mode
)
SELECT
  e.day_utc,
  e.text_id,
  e.mode,
  e.total_dwell_seconds,
  e.dwell_event_count,
  e.unique_actor_count,
  e.unique_session_count,
  e.avg_dwell_seconds,
  e.median_event_dwell_seconds,
  e.p90_event_dwell_seconds,
  COALESCE(s.median_session_dwell_seconds, 0) AS median_session_dwell_seconds
FROM event_agg e
LEFT JOIN session_agg s
  ON s.day_utc = e.day_utc
 AND s.text_id = e.text_id
 AND s.mode = e.mode;

-- Daily read-section dwell aggregates.
CREATE OR REPLACE VIEW public.analytics_read_section_dwell_daily_v1 AS
WITH base AS (
  SELECT
    date_trunc('day', occurred_at AT TIME ZONE 'utc')::date AS day_utc,
    occurred_at,
    text_id,
    mode,
    section_path,
    NULLIF(BTRIM(section_title), '') AS section_title,
    chapter_number,
    NULLIF(BTRIM(verse_ref), '') AS verse_ref,
    session_id,
    COALESCE(user_id::text, anon_id) AS actor_id,
    LEAST(duration_ms, 7200000)::double precision / 1000.0 AS duration_sec
  FROM public.app_usage_events
  WHERE event_name = 'read_section_dwell'
    AND duration_ms IS NOT NULL
    AND duration_ms >= 1000
    AND text_id IS NOT NULL
    AND section_path IS NOT NULL
),
event_agg AS (
  SELECT
    day_utc,
    text_id,
    mode,
    section_path,
    COUNT(*)::bigint AS dwell_event_count,
    COUNT(DISTINCT actor_id)::bigint AS unique_actor_count,
    COUNT(DISTINCT session_id)::bigint AS unique_session_count,
    ROUND(SUM(duration_sec)::numeric, 2) AS total_dwell_seconds,
    ROUND(AVG(duration_sec)::numeric, 2) AS avg_dwell_seconds,
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS median_event_dwell_seconds,
    ROUND(percentile_cont(0.9) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS p90_event_dwell_seconds
  FROM base
  GROUP BY day_utc, text_id, mode, section_path
),
labels AS (
  SELECT DISTINCT ON (day_utc, text_id, mode, section_path)
    day_utc,
    text_id,
    mode,
    section_path,
    section_title,
    chapter_number,
    verse_ref
  FROM base
  ORDER BY day_utc, text_id, mode, section_path, occurred_at DESC
)
SELECT
  e.day_utc,
  e.text_id,
  e.mode,
  e.section_path,
  l.section_title,
  l.chapter_number,
  l.verse_ref,
  e.total_dwell_seconds,
  e.dwell_event_count,
  e.unique_actor_count,
  e.unique_session_count,
  e.avg_dwell_seconds,
  e.median_event_dwell_seconds,
  e.p90_event_dwell_seconds
FROM event_agg e
LEFT JOIN labels l
  ON l.day_utc = e.day_utc
 AND l.text_id = e.text_id
 AND l.mode = e.mode
 AND l.section_path = e.section_path;

-- Top read sections over trailing 30 days.
CREATE OR REPLACE VIEW public.analytics_top_read_sections_30d_v1 AS
WITH base AS (
  SELECT
    occurred_at,
    text_id,
    mode,
    section_path,
    NULLIF(BTRIM(section_title), '') AS section_title,
    chapter_number,
    NULLIF(BTRIM(verse_ref), '') AS verse_ref,
    session_id,
    COALESCE(user_id::text, anon_id) AS actor_id,
    LEAST(duration_ms, 7200000)::double precision / 1000.0 AS duration_sec
  FROM public.app_usage_events
  WHERE event_name = 'read_section_dwell'
    AND duration_ms IS NOT NULL
    AND duration_ms >= 1000
    AND text_id IS NOT NULL
    AND section_path IS NOT NULL
    AND occurred_at >= TIMEZONE('utc', NOW()) - INTERVAL '30 days'
),
agg AS (
  SELECT
    text_id,
    mode,
    section_path,
    COUNT(*)::bigint AS dwell_event_count_30d,
    COUNT(DISTINCT actor_id)::bigint AS unique_actor_count_30d,
    COUNT(DISTINCT session_id)::bigint AS unique_session_count_30d,
    ROUND(SUM(duration_sec)::numeric, 2) AS total_dwell_seconds_30d,
    ROUND(AVG(duration_sec)::numeric, 2) AS avg_dwell_seconds_30d,
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS median_event_dwell_seconds_30d,
    ROUND(percentile_cont(0.9) WITHIN GROUP (ORDER BY duration_sec)::numeric, 2)
      AS p90_event_dwell_seconds_30d
  FROM base
  GROUP BY text_id, mode, section_path
),
labels AS (
  SELECT DISTINCT ON (text_id, mode, section_path)
    text_id,
    mode,
    section_path,
    section_title,
    chapter_number,
    verse_ref
  FROM base
  ORDER BY text_id, mode, section_path, occurred_at DESC
)
SELECT
  a.text_id,
  a.mode,
  a.section_path,
  l.section_title,
  l.chapter_number,
  l.verse_ref,
  a.total_dwell_seconds_30d,
  a.dwell_event_count_30d,
  a.unique_actor_count_30d,
  a.unique_session_count_30d,
  a.avg_dwell_seconds_30d,
  a.median_event_dwell_seconds_30d,
  a.p90_event_dwell_seconds_30d,
  DENSE_RANK() OVER (PARTITION BY a.text_id ORDER BY a.total_dwell_seconds_30d DESC)
    AS dwell_rank_within_text
FROM agg a
LEFT JOIN labels l
  ON l.text_id = a.text_id
 AND l.mode = a.mode
 AND l.section_path = a.section_path;

-- Retention audit log for pruning runs.
CREATE TABLE IF NOT EXISTS public.app_usage_event_retention_runs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ran_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  retain_interval INTERVAL NOT NULL,
  deleted_count BIGINT NOT NULL
);

-- Retention function with audit logging.
CREATE OR REPLACE FUNCTION public.prune_app_usage_events(
  retain_interval INTERVAL DEFAULT INTERVAL '12 months'
)
RETURNS TABLE(deleted_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_deleted BIGINT := 0;
BEGIN
  DELETE FROM public.app_usage_events
  WHERE occurred_at < TIMEZONE('utc', NOW()) - retain_interval;

  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  INSERT INTO public.app_usage_event_retention_runs (retain_interval, deleted_count)
  VALUES (retain_interval, v_deleted);

  RETURN QUERY SELECT v_deleted;
END;
$$;

ALTER FUNCTION public.prune_app_usage_events(INTERVAL)
  SET search_path = public, pg_temp;

-- Try to install a daily pruning schedule via pg_cron when available.
DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping pg_cron extension creation (insufficient privilege).';
  END;

  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM cron.job
        WHERE jobname = 'prune_app_usage_events_daily'
      ) THEN
        PERFORM cron.schedule(
          'prune_app_usage_events_daily',
          '15 3 * * *',
          $job$SELECT public.prune_app_usage_events(INTERVAL '12 months');$job$
        );
      END IF;
    EXCEPTION
      WHEN undefined_table THEN
        RAISE NOTICE 'pg_cron job table not available; configure schedule manually.';
    END;
  END IF;
END;
$$;

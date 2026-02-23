-- Smoke-check script for usage-metrics analytics views.
-- Run in SQL editor after migrations are applied.
-- This script is transaction-wrapped and rolls back test rows.

BEGIN;

INSERT INTO public.app_usage_events (
  event_name,
  session_id,
  user_id,
  anon_id,
  text_id,
  mode,
  section_path,
  section_title,
  chapter_number,
  verse_ref,
  duration_ms,
  occurred_at,
  properties
)
VALUES
  (
    'surface_dwell',
    'smoke_sess_1',
    NULL,
    'smoke_actor_1',
    'bodhicaryavatara',
    'read',
    '4.6.2.1.1.3',
    'Smoke Section A',
    9,
    '9.2bcd',
    120000,
    TIMEZONE('utc', NOW()) - INTERVAL '10 minutes',
    '{}'::jsonb
  ),
  (
    'surface_dwell',
    'smoke_sess_1',
    NULL,
    'smoke_actor_1',
    'bodhicaryavatara',
    'quiz',
    NULL,
    NULL,
    NULL,
    NULL,
    45000,
    TIMEZONE('utc', NOW()) - INTERVAL '8 minutes',
    '{}'::jsonb
  ),
  (
    'read_section_dwell',
    'smoke_sess_1',
    NULL,
    'smoke_actor_1',
    'bodhicaryavatara',
    'read',
    '4.6.2.1.1.3',
    'Smoke Section A',
    9,
    '9.2bcd',
    90000,
    TIMEZONE('utc', NOW()) - INTERVAL '7 minutes',
    '{}'::jsonb
  ),
  (
    'read_section_dwell',
    'smoke_sess_2',
    NULL,
    'smoke_actor_2',
    'bodhicaryavatara',
    'read',
    '4.6.2.1.1.4',
    'Smoke Section B',
    9,
    '9.3ab',
    60000,
    TIMEZONE('utc', NOW()) - INTERVAL '6 minutes',
    '{}'::jsonb
  );

-- Check #1: text-level dwell view contains rows.
SELECT
  COUNT(*) AS text_rows_today
FROM public.analytics_text_dwell_daily_v1
WHERE day_utc = (TIMEZONE('utc', NOW()))::date
  AND text_id = 'bodhicaryavatara';

-- Check #2: mode-level dwell view includes read + quiz.
SELECT
  mode,
  total_dwell_seconds,
  dwell_event_count
FROM public.analytics_mode_dwell_daily_v1
WHERE day_utc = (TIMEZONE('utc', NOW()))::date
  AND text_id = 'bodhicaryavatara'
ORDER BY mode;

-- Check #3: read-section daily view includes section paths.
SELECT
  section_path,
  total_dwell_seconds,
  dwell_event_count
FROM public.analytics_read_section_dwell_daily_v1
WHERE day_utc = (TIMEZONE('utc', NOW()))::date
  AND text_id = 'bodhicaryavatara'
ORDER BY section_path;

-- Check #4: top-30d view ranks sections.
SELECT
  section_path,
  total_dwell_seconds_30d,
  dwell_rank_within_text
FROM public.analytics_top_read_sections_30d_v1
WHERE text_id = 'bodhicaryavatara'
ORDER BY dwell_rank_within_text, section_path
LIMIT 10;

-- Check #5: retention function returns deleted count and logs run.
SELECT * FROM public.prune_app_usage_events(INTERVAL '100 years');

SELECT
  retain_interval,
  deleted_count
FROM public.app_usage_event_retention_runs
ORDER BY ran_at DESC
LIMIT 1;

ROLLBACK;

-- Usage metrics event stream for product analytics.
-- Stores append-only events for mode dwell, section dwell, and feature usage.

CREATE TABLE IF NOT EXISTS public.app_usage_events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  received_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  event_name TEXT NOT NULL CHECK (char_length(trim(event_name)) > 0),
  session_id TEXT NOT NULL CHECK (char_length(trim(session_id)) > 0),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  anon_id TEXT,
  text_id TEXT,
  mode TEXT,
  section_path TEXT,
  section_title TEXT,
  chapter_number INTEGER,
  verse_ref TEXT,
  duration_ms INTEGER CHECK (duration_ms IS NULL OR duration_ms >= 0),
  properties JSONB NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT app_usage_events_actor_check CHECK (
    user_id IS NOT NULL OR (anon_id IS NOT NULL AND char_length(trim(anon_id)) > 0)
  )
);

CREATE INDEX IF NOT EXISTS idx_app_usage_events_occurred_at
  ON public.app_usage_events (occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_usage_events_event_name_occurred_at
  ON public.app_usage_events (event_name, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_usage_events_text_mode_occurred_at
  ON public.app_usage_events (text_id, mode, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_usage_events_section_path_occurred_at
  ON public.app_usage_events (section_path, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_usage_events_user_occurred_at
  ON public.app_usage_events (user_id, occurred_at DESC);

ALTER TABLE public.app_usage_events ENABLE ROW LEVEL SECURITY;

-- Allow app clients to insert events:
-- - Authenticated users can only set user_id to their own auth.uid().
-- - Anonymous sessions can insert only when user_id is null.
DROP POLICY IF EXISTS "Insert usage metrics events" ON public.app_usage_events;
CREATE POLICY "Insert usage metrics events"
  ON public.app_usage_events
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    (auth.uid() IS NOT NULL AND user_id = auth.uid())
    OR
    (auth.uid() IS NULL AND user_id IS NULL)
  );

GRANT INSERT ON public.app_usage_events TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.app_usage_events_id_seq TO anon, authenticated;

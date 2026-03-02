-- Enforce one daily section per user per UTC calendar day.
-- Also deduplicate existing rows so the new unique index can be created safely.

WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, ((date AT TIME ZONE 'utc')::date)
      ORDER BY date DESC, created_at DESC, id DESC
    ) AS rn
  FROM public.daily_sections
)
DELETE FROM public.daily_sections d
USING ranked r
WHERE d.id = r.id
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_sections_user_day_utc_unique
  ON public.daily_sections (user_id, ((date AT TIME ZONE 'utc')::date));

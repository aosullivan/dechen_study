-- Change app_usage_events retention from 12 months to 4 weeks.
-- Unschedule existing daily job and reschedule with new interval; run prune once to apply immediately.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    BEGIN
      PERFORM cron.unschedule('prune_app_usage_events_daily');
    EXCEPTION
      WHEN undefined_object THEN
        NULL; -- job did not exist
    END;

    BEGIN
      PERFORM cron.schedule(
        'prune_app_usage_events_daily',
        '15 3 * * *',
        $job$SELECT public.prune_app_usage_events(INTERVAL '4 weeks');$job$
      );
    EXCEPTION
      WHEN undefined_table THEN
        RAISE NOTICE 'pg_cron job table not available; configure schedule manually.';
    END;
  END IF;
END;
$$;

-- Prune now so data older than 4 weeks is removed immediately.
SELECT public.prune_app_usage_events(INTERVAL '4 weeks');

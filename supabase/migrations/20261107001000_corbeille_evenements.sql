-- Corbeille des événements : un événement supprimé reste restaurable
-- pendant 30 jours, puis il est effacé définitivement.

alter table public.events
  add column if not exists deleted_at timestamptz;

create index if not exists events_deleted_at_idx
  on public.events (owner_id, deleted_at)
  where deleted_at is not null;

-- Purge des événements restés plus de 30 jours dans la corbeille. À
-- planifier (pg_cron) une fois par jour :
--   select cron.schedule('purge-corbeille', '15 3 * * *',
--     $$select public.purge_corbeille()$$);
create or replace function public.purge_corbeille()
returns integer
language sql
security definer
set search_path = public
as $$
  with gone as (
    delete from public.events
    where deleted_at is not null
      and deleted_at < now() - interval '30 days'
    returning 1
  )
  select count(*)::integer from gone;
$$;

revoke all on function public.purge_corbeille() from public, anon, authenticated;

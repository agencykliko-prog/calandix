-- Calandix · adresse e-mail dans la liste d'accès anticipé. Sans risque, peut
-- être relancé. SQL Editor → New query → coller tout le fichier → Run.
alter table public.early_access add column if not exists email text;
grant insert (email) on public.early_access to anon;

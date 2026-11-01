-- Calandix · signature des prestataires et durcissement. Sans risque, peut
-- être relancé. SQL Editor → New query → coller tout le fichier → Run.

-- Signature dans une table à part : creator_profiles est lisible par tous pour
-- les fiches publiées, une signature ne doit pas l'être.
create table if not exists public.creator_signatures (
  creator_id uuid primary key references public.creator_profiles (id) on delete cascade,
  image text not null check (char_length(image) <= 400000),
  updated_at timestamptz not null default now()
);
alter table public.creator_signatures enable row level security;

drop policy if exists "sa signature" on public.creator_signatures;
create policy "sa signature" on public.creator_signatures
  for all to authenticated
  using (creator_id = auth.uid()) with check (creator_id = auth.uid());
revoke all on public.creator_signatures from anon;

-- Accès anticipé : e-mail valide et de taille raisonnable.
alter table public.early_access add column if not exists email text;
alter table public.early_access drop constraint if exists early_access_email_check;
alter table public.early_access add constraint early_access_email_check
  check (email is null or (char_length(email) <= 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'));
grant insert (email) on public.early_access to anon;

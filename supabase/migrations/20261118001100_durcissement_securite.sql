-- ═══════════════════════════════════════════════════════════════════════
-- Calandix · durcissement de sécurité (audit OWASP du 18 nov. 2026)
-- Sans risque, peut être relancé. SQL Editor → New query → coller tout le
-- fichier → Run. Ne touche pas aux données existantes.
-- ═══════════════════════════════════════════════════════════════════════

-- ─── A01 · Fiche prestataire : pas d'auto-vérification à la création ────
-- La fiche est créée depuis les métadonnées du compte, que l'utilisateur
-- contrôle. Le déclencheur existant ne protégeait que la modification :
-- une fiche pouvait naître « vérifiée ». Désormais, à la création comme à
-- la modification, seul l'équipe (ou le serveur) fixe la vérification.
create or replace function public.protect_verification()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    if tg_op = 'INSERT' then
      new.verification = 'draft';
    else
      new.verification = old.verification;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists creator_profiles_protect on public.creator_profiles;
create trigger creator_profiles_protect before insert or update on public.creator_profiles
  for each row execute function public.protect_verification();

-- ─── A01 · Événement : le propriétaire ne change pas ────────────────────
-- Un co-organisateur « éditeur » pouvait remplacer owner_id et s'approprier
-- l'événement.
create or replace function public.protect_event_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.owner_id = old.owner_id;
    new.created_at = old.created_at;
  end if;
  return new;
end;
$$;

drop trigger if exists events_protect on public.events;
create trigger events_protect before update on public.events
  for each row execute function public.protect_event_owner();

-- ─── A01 · Avis : le prestataire répond, il ne réécrit pas l'avis ───────
-- La politique « répondre à un avis » autorisait le prestataire à modifier
-- toute la ligne, donc la note et le texte laissés par le client.
create or replace function public.protect_review()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.booking_id = old.booking_id;
    new.author_id = old.author_id;
    new.creator_id = old.creator_id;
    new.rating = old.rating;
    new.body = old.body;
    new.created_at = old.created_at;
  end if;
  return new;
end;
$$;

drop trigger if exists reviews_protect on public.reviews;
create trigger reviews_protect before update on public.reviews
  for each row execute function public.protect_review();

-- ─── A01 · Devis : rattaché à sa demande pour toujours ──────────────────
-- La politique de modification n'avait pas de WITH CHECK : un prestataire
-- pouvait déplacer un devis vers une autre demande.
drop policy if exists "modifier son devis" on public.quotes;
create policy "modifier son devis" on public.quotes
  for update to authenticated
  using (exists (select 1 from public.bookings b where b.id = booking_id and b.creator_id = auth.uid()))
  with check (exists (select 1 from public.bookings b where b.id = booking_id and b.creator_id = auth.uid()));

create or replace function public.protect_quote()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.is_admin() then
    new.booking_id = old.booking_id;
    new.created_at = old.created_at;
  end if;
  return new;
end;
$$;

drop trigger if exists quotes_protect on public.quotes;
create trigger quotes_protect before update on public.quotes
  for each row execute function public.protect_quote();

-- ─── A04 · Demande : « payée » ne se déclare pas depuis l'app ───────────
-- Comme paid_amount, l'étape « paid » n'est posée que par le serveur après
-- un paiement confirmé. Et une prestation ne se « clôture » qu'après avoir
-- été payée ou exécutée : sans cela, un client pouvait clôturer une demande
-- jamais honorée et publier un faux avis.
create or replace function public.protect_booking_step()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is null or public.is_admin() or new.step = old.step then
    return new;
  end if;
  if new.step = 'paid' then
    raise exception 'Étape réservée au paiement confirmé' using errcode = '42501';
  end if;
  if new.step = 'closed' and old.step not in ('paid', 'executing') then
    raise exception 'Une prestation se clôture après paiement' using errcode = '42501';
  end if;
  if old.step in ('paid', 'executing', 'closed') and new.step in ('requested', 'quoted', 'reserved') then
    raise exception 'Une demande payée ne revient pas en arrière' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists bookings_step_protect on public.bookings;
create trigger bookings_step_protect before update of step on public.bookings
  for each row execute function public.protect_booking_step();

-- ─── A05 · Mesure d'audience : entrées bornées ──────────────────────────
-- Table ouverte en insertion aux visiteurs : sans borne, un script pouvait
-- y écrire des textes de taille arbitraire. NOT VALID : les lignes déjà
-- présentes ne sont pas revérifiées.
alter table public.audience_hits drop constraint if exists audience_hits_metric_len;
alter table public.audience_hits add constraint audience_hits_metric_len
  check (char_length(metric) between 1 and 60) not valid;
alter table public.audience_hits drop constraint if exists audience_hits_screen_len;
alter table public.audience_hits add constraint audience_hits_screen_len
  check (screen is null or char_length(screen) <= 120) not valid;
revoke all on public.audience_hits from anon;
grant insert (metric, screen) on public.audience_hits to anon;

-- ─── A08 · Corbeille : chemin de recherche vide ─────────────────────────
-- Fonction SECURITY DEFINER : un search_path « public » permettrait de la
-- détourner par un objet homonyme. Les noms sont déjà qualifiés.
alter function public.purge_corbeille() set search_path = '';

-- Fonctions de déclencheur : jamais appelées directement.
revoke execute on function
  public.protect_verification(),
  public.protect_event_owner(),
  public.protect_review(),
  public.protect_quote(),
  public.protect_booking_step()
from public, anon, authenticated;

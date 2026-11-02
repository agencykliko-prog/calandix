-- Retrait de SasPay : les Edge Functions saspay-* sont supprimées, leur
-- fonction de règlement et l'index qui ne servait qu'à elles aussi.
-- Les tables payments, payouts et payout_accounts restent, sans lien avec un
-- prestataire de paiement : le prochain agrégateur s'y branchera.

drop function if exists public.saspay_settle_payment(uuid, text, numeric, numeric);
drop index if exists public.payments_pending_idx;

comment on column public.payout_accounts.method is 'Code du réseau mobile money de réception';

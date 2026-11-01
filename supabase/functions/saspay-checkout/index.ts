// Crée un paiement Eventa et sa page de paiement SasPay (Wave, Orange Money,
// MTN, Moov, carte). Le montant est toujours calculé ici, jamais par l'app.
//
// Corps : { purpose: 'deposit' | 'balance', booking_id }
//      ou { purpose: 'subscription', product: 'premium' | 'creator', plan }
// Réponse : { payment_id, checkout_url }
import { admin, asUser, cors, decimal, replyError, reply, saspay } from '../_shared/saspay.ts';

// Prix mensuels en FCFA (CGU : offres sans engagement).
const PLANS: Record<string, Record<string, { label: string; price: number }>> = {
  premium: {
    azur: { label: 'Azur', price: 2900 },
    signature: { label: 'Signature', price: 4900 },
    privilege: { label: 'Privilège', price: 9900 },
  },
  creator: { business: { label: 'Offre Creator', price: 29900 } },
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
  if (req.method !== 'POST') return reply({ error: 'Méthode non autorisée.' }, 405);

  try {
    const { data: { user } } = await asUser(req).auth.getUser();
    if (!user) return reply({ error: 'Connexion requise.' }, 401);
    if (!user.email) return reply({ error: 'Ajoutez une adresse e-mail à votre compte pour payer.', code: 'email_required' }, 422);

    const body = await req.json().catch(() => ({}));
    const db = admin();
    const { data: profile } = await db.from('profiles').select('full_name, phone').eq('id', user.id).single();

    let amount = 0, description = '';
    const row: Record<string, unknown> = { payer_id: user.id, purpose: body.purpose, method: 'saspay', provider: 'saspay', currency: 'XOF' };

    if (body.purpose === 'deposit' || body.purpose === 'balance') {
      const { data: b } = await db.from('bookings')
        .select('id, event_id, organizer_id, step, paid_amount, quotes(total, deposit_rate), creator_profiles(display_name)')
        .eq('id', body.booking_id).single();
      if (!b || b.organizer_id !== user.id) return reply({ error: 'Réservation introuvable.' }, 404);
      const q = Array.isArray(b.quotes) ? b.quotes[0] : b.quotes;
      if (!q) return reply({ error: 'Aucun devis accepté pour cette réservation.' }, 422);
      if (['declined', 'closed'].includes(b.step)) return reply({ error: 'Cette réservation est close.' }, 422);
      const vendor = (Array.isArray(b.creator_profiles) ? b.creator_profiles[0] : b.creator_profiles)?.display_name ?? 'prestataire';
      if (body.purpose === 'deposit') {
        if (b.paid_amount > 0) return reply({ error: 'L’acompte est déjà réglé.' }, 409);
        amount = Math.round((q.total * Number(q.deposit_rate)) / 500) * 500; // même arrondi que l'app
        description = `Acompte · ${vendor}`;
      } else {
        amount = q.total - b.paid_amount;
        description = `Solde · ${vendor}`;
      }
      Object.assign(row, { booking_id: b.id, event_id: b.event_id });
    } else if (body.purpose === 'subscription') {
      const plan = PLANS[body.product]?.[body.plan];
      if (!plan) return reply({ error: 'Formule inconnue.' }, 400);
      amount = plan.price;
      description = `Eventa ${plan.label} · 1 mois`;
      Object.assign(row, { product: body.product, plan: body.plan });
    } else {
      return reply({ error: 'Type de paiement inconnu.' }, 400);
    }
    if (amount <= 0) return reply({ error: 'Rien à payer.' }, 422);

    // Un paiement en attente identique est réutilisé (double clic, retour arrière).
    let pending = db.from('payments').select('id, checkout_url').eq('payer_id', user.id).eq('purpose', body.purpose)
      .eq('status', 'pending').eq('provider', 'saspay').eq('amount', amount).not('checkout_url', 'is', null)
      .gte('created_at', new Date(Date.now() - 50 * 60_000).toISOString());
    pending = row.booking_id ? pending.eq('booking_id', row.booking_id) : pending.eq('plan', row.plan);
    const { data: open } = await pending.limit(1).maybeSingle();
    if (open) return reply({ payment_id: open.id, checkout_url: open.checkout_url });

    const { data: payment, error } = await db.from('payments').insert({ ...row, amount }).select('id').single();
    if (error) throw error;

    const appUrl = (Deno.env.get('APP_URL') ?? '').replace(/\/$/, '');
    const session = await saspay<{ id: string; checkout_url: string }>('/checkout-sessions/', {
      method: 'POST',
      body: {
        amount: decimal(amount),
        currency: 'XOF',
        country: 'CI',
        description,
        customer_email: user.email,
        customer_name: profile?.full_name || user.email,
        ...(profile?.phone ? { customer_phone: profile.phone } : {}),
        ...(appUrl ? { return_url: `${appUrl}/app/#/paiement?payment=${payment.id}` } : {}),
        metadata: { eventa_payment_id: payment.id },
        expires_at: new Date(Date.now() + 60 * 60_000).toISOString(),
      },
    });

    await db.from('payments').update({ provider_ref: session.id, checkout_url: session.checkout_url }).eq('id', payment.id);
    return reply({ payment_id: payment.id, checkout_url: session.checkout_url });
  } catch (e) {
    return replyError(e);
  }
});

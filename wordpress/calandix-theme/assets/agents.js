/* Calandix · outils WebMCP pour les agents intégrés au navigateur.
   Lecture seule : tarifs, réponses de la FAQ, pages utiles. L'inscription à
   l'accès anticipé est le formulaire annoté (toolname) : la personne garde
   la main sur l'envoi. */
(() => {
  const mc = navigator.modelContext;
  if (!mc) return;
  const C = window.CX_AGENTS || {};
  const reply = (text) => ({ content: [{ type: 'text', text }] });

  // Offres lues dans les données structurées de la page.
  const offers = () => {
    for (const s of document.querySelectorAll('script[type="application/ld+json"]')) {
      try {
        const g = JSON.parse(s.textContent)['@graph'] || [];
        const app = g.find((n) => n['@type'] === 'SoftwareApplication');
        if (app && app.offers) return app.offers;
      } catch (e) { /* bloc d'une extension */ }
    }
    return [];
  };

  let faq = null;
  const loadFaq = () => (faq ||= fetch(C.faq).then((r) => r.json()).catch(() => []));
  const words = (t) => t.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter((w) => w.length > 2);

  const tools = [
    {
      name: 'calandix_tarifs',
      description: 'Tarifs Calandix en FCFA (XOF) : formules organisateurs (Découverte, Azur, Signature, Privilège), formules prestataires (Découverte, Starter, Creator, Business) et Pass Événement. Prix mensuels ; à l’année, 1 mois offert aux organisateurs et 2 aux prestataires.',
      inputSchema: { type: 'object', properties: {} },
      annotations: { readOnlyHint: true },
      execute: async () => reply(offers()
        .map((o) => `${o.name} : ${Number(o.price).toLocaleString('fr-FR')} FCFA${o.priceSpecification ? ' par mois' : ''}${o.description ? ` — ${o.description}` : ''}`)
        .join('\n') || 'Tarifs indisponibles.'),
    },
    {
      name: 'calandix_question',
      description: 'Cherche la réponse à une question sur Calandix (fonctionnement, formules, paiements, invités, prestataires) dans la base de questions fréquentes du site.',
      inputSchema: {
        type: 'object',
        properties: { question: { type: 'string', description: 'La question, en français de préférence.' } },
        required: ['question'],
      },
      annotations: { readOnlyHint: true },
      execute: async ({ question = '' } = {}) => {
        const q = new Set(words(question));
        const rows = await loadFaq();
        const scored = rows
          .map((r) => ({ r, s: words(`${r.q} ${(r.k || []).join(' ')}`).filter((w) => q.has(w)).length }))
          .filter((x) => x.s > 0 && x.r.a)
          .sort((a, b) => b.s - a.s)
          .slice(0, 3);
        if (!scored.length) return reply('Pas de réponse dans la FAQ. Contact : WhatsApp +225 07 04 25 22 25 ou contact@calandix.com.');
        return reply(scored.map(({ r }) => `Q : ${r.q}\nR : ${r.a}`).join('\n\n'));
      },
    },
    {
      name: 'calandix_pages',
      description: 'Adresses des pages utiles de Calandix : accueil, à propos, contact, conditions générales, confidentialité et application de démonstration.',
      inputSchema: { type: 'object', properties: {} },
      annotations: { readOnlyHint: true },
      execute: async () => reply((C.pages || []).join('\n')),
    },
  ];

  try {
    if (typeof mc.registerTool === 'function') tools.forEach((t) => mc.registerTool(t));
    else if (typeof mc.provideContext === 'function') mc.provideContext({ tools });
  } catch (e) { /* API encore expérimentale */ }
})();

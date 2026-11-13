/* Calandix · aperçu de l'éditeur Elementor : même rendu que le site.
   Retire les styles de base des éléments atomiques (qui écrasent la mise en
   page de la landing) et remet les attributs data-*, style… que le thème
   ajoute aussi sur le site. Les poignées d'édition d'Elementor restent. */
(() => {
  const A = window.CX_ATTRS || {};
  const strip = /^(e-con|e-atomic-element|e-[a-z-]+-base|e-default-[a-z0-9]+)$/;
  let queued = false;

  const fix = () => {
    queued = false;
    document.querySelectorAll('.e-atomic-element, [class*="-base"]').forEach((el) => {
      [...el.classList].forEach((c) => { if (strip.test(c)) el.classList.remove(c); });
    });
    for (const [id, list] of Object.entries(A)) {
      const el = document.querySelector(`[data-id="${id}"], [data-interaction-id="${id}"]`);
      if (!el || el.dataset.cxDone) continue;
      for (const [k, v] of Object.entries(list)) {
        // Masqué seulement pour l'assistance : le reste doit rester modifiable.
        if (k === 'hidden' && !el.closest('.candix')) continue;
        try { el.setAttribute(k, v); } catch (e) { /* nom d'attribut invalide */ }
      }
      el.dataset.cxDone = '1';
    }
    // Mots mis en avant et compléments de bouton (classes effacées par Elementor).
    document.querySelectorAll('h1 em, h2 em, h3 em, h4 em, p em, .btn em').forEach((e) => {
      if (!e.closest('.elementor-widget-html')) e.classList.add('script');
    });
    document.querySelectorAll('.btn > span:not([class])').forEach((e) => e.classList.add('wide-only'));
  };

  const schedule = () => { if (!queued) { queued = true; requestAnimationFrame(fix); } };
  addEventListener('DOMContentLoaded', () => {
    fix();
    new MutationObserver(schedule).observe(document.body, { childList: true, subtree: true });
  });
})();

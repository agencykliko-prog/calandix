/* Calandix · à exécuter avant le premier affichage. */
(() => {
  const d = document.documentElement;
  // Mode sombre : le choix enregistré, sinon le réglage de l'appareil.
  let t = null;
  try { t = localStorage.getItem('calandix-theme'); } catch (e) { /* navigation privée */ }
  if (!t) t = matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  d.dataset.theme = t;
  // Animations GSAP (app.js) : l'ouverture reste masquée le temps du chargement.
  // Sans GSAP au bout de 2,5 s (réseau lent, CDN bloqué), tout s'affiche.
  if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
    d.classList.add('anim');
    setTimeout(() => { if (!window.gsap) d.classList.remove('anim'); }, 2500);
  }
  // Téléphones 3D : après la page, et seulement si l'appareil suit.
  addEventListener('load', () => {
    const c = navigator.connection;
    const modest = c?.saveData || /2g|3g/.test(c?.effectiveType || '') || navigator.deviceMemory < 4 || navigator.hardwareConcurrency < 4;
    if (modest) return;
    const go = () => import(`${d.dataset.assets || './'}phone3d.js?v=3`);
    window.requestIdleCallback ? requestIdleCallback(go, { timeout: 2500 }) : setTimeout(go, 800);
  }, { once: true });
})();

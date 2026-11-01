/* Calandix · landing page : mascottes, confettis, révélations, simulateur, démo. */
(() => {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  // GSAP pilote l'ouverture et les révélations. Sans lui (ou en mouvement
  // réduit), les observateurs et les transitions CSS prennent le relais.
  const root = document.documentElement;
  const G = !reduce && root.classList.contains('anim') && window.gsap && window.ScrollTrigger;
  if (!G) root.classList.remove('anim');
  // Défilement lissé (grands écrans uniquement), créé par motion().
  let smoother = null;
  const fcfa = (n) => Math.round(n).toLocaleString('fr-FR').replace(/ | /g, ' ');

  /* ── Mascottes ─────────────────────────────────────────
     data-mascot="rire" : une pose de la fourmi. */
  const poses = ['rire', 'salut', 'sport', 'idee', 'bouee', 'course'];
  const src = (name) => `img/mascots/${name}.webp`;
  const mascots = [];
  document.querySelectorAll('[data-mascot]').forEach((host) => {
    const name = host.dataset.mascot;
    const img = new Image();
    img.className = 'm-img';
    // Dimensions déclarées et chargement différé (pas de saut de mise en page).
    img.width = 320;
    img.height = 320;
    img.loading = 'lazy';
    img.decoding = 'async';
    img.src = src(name);
    img.alt = '';
    img.draggable = false;
    img.style.animationDelay = `${-Math.random() * 3}s`;
    host.appendChild(img);
    const m = { host, img, name };
    mascots.push(m);
    if (!host.hasAttribute('data-interactive')) return;
    host.setAttribute('role', 'button');
    host.setAttribute('aria-label', 'Mascotte Calandix');
    host.tabIndex = 0;
    const jump = () => {
      // Saut, nouvelle pose, pluie de confettis.
      const list = poses;
      const next = list[(list.indexOf(m.img.src.split('/').pop().replace('.webp', '')) + 1) % list.length];
      m.img.classList.remove('jump');
      void m.img.offsetWidth;
      m.img.classList.add('jump');
      setTimeout(() => { m.img.src = src(next); }, 220);
      const r = host.getBoundingClientRect();
      burst(r.left + r.width / 2, r.top + r.height * .35, 60);
    };
    host.addEventListener('click', jump);
    host.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); jump(); } });
    img.addEventListener('animationend', () => img.classList.remove('jump', 'swap'));
  });
  // Toutes les poses en cache : les changements sont instantanés.
  addEventListener('load', () => setTimeout(() => {
    if (navigator.connection?.saveData) return;
    poses.forEach((n) => { const i = new Image(); i.src = src(n); });
  }, 2500), { once: true });

  // Les mascottes se penchent vers le pointeur.
  let px = innerWidth / 2, py = innerHeight / 3, leanQueued = false;
  const lean = () => {
    leanQueued = false;
    mascots.forEach(({ host }) => {
      const r = host.getBoundingClientRect();
      if (r.bottom < 0 || r.top > innerHeight) return;
      const dx = px - (r.left + r.width / 2);
      const k = Math.max(-1, Math.min(1, dx / 400));
      host.style.setProperty('--lean', `${(k * 8).toFixed(1)}deg`);
    });
  };
  if (!reduce) {
    addEventListener('pointermove', (e) => {
      px = e.clientX; py = e.clientY;
      if (!leanQueued) { leanQueued = true; requestAnimationFrame(lean); }
    }, { passive: true });
  }

  /* ── Confettis ───────────────────────────────────────── */
  const cv = document.querySelector('.confetti');
  const ctx = cv.getContext('2d');
  const colors = ['#E01928', '#4D39E2', '#E59D1F', '#2CE5B9', '#DB4F9E', '#FFC233'];
  let parts = [], running = false;
  const size = () => { const d = devicePixelRatio || 1; cv.width = innerWidth * d; cv.height = innerHeight * d; ctx.setTransform(d, 0, 0, d, 0, 0); };
  size(); addEventListener('resize', size);
  function burst(x, y, n = 90) {
    if (reduce) return;
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2, v = 4 + Math.random() * 8;
      parts.push({
        x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 6,
        w: 6 + Math.random() * 6, h: 4 + Math.random() * 8,
        r: Math.random() * 6, vr: (Math.random() - .5) * .4,
        c: colors[i % colors.length], life: 0, round: Math.random() < .3,
      });
    }
    if (!running) { running = true; requestAnimationFrame(tick); }
  }
  function tick() {
    ctx.clearRect(0, 0, innerWidth, innerHeight);
    parts = parts.filter((p) => p.life < 160 && p.y < innerHeight + 40);
    parts.forEach((p) => {
      p.life++; p.vy += .28; p.vx *= .985; p.vy *= .985;
      p.x += p.vx; p.y += p.vy; p.r += p.vr;
      ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.r);
      ctx.globalAlpha = Math.min(1, (160 - p.life) / 40);
      ctx.fillStyle = p.c;
      if (p.round) { ctx.beginPath(); ctx.arc(0, 0, p.w / 2, 0, 7); ctx.fill(); }
      else ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h * Math.abs(Math.cos(p.life / 8)));
      ctx.restore();
    });
    if (parts.length) requestAnimationFrame(tick); else { running = false; ctx.clearRect(0, 0, innerWidth, innerHeight); }
  }
  document.querySelectorAll('[data-confetti]').forEach((el) => el.addEventListener('click', (e) => {
    const r = el.getBoundingClientRect();
    burst(e.clientX || r.left + r.width / 2, e.clientY || r.top + r.height / 2);
  }));

  /* ── Ballons de l'ouverture ──────────────────────────── */
  const sky = document.querySelector('.balloons');
  if (sky && !reduce) {
    const hues = ['#E01928', '#2CE5B9', '#E59D1F', '#ffffff', '#EAE7F3'];
    for (let i = 0; i < 9; i++) {
      const b = document.createElement('span');
      b.className = 'balloon';
      const s = .6 + Math.random() * .7;
      b.style.cssText = `left:${(i / 9) * 100 + Math.random() * 6}%;background:${hues[i % hues.length]};` +
        `scale:${s};animation-duration:${14 + Math.random() * 12}s;animation-delay:${-Math.random() * 20}s;opacity:${.35 + s * .4}`;
      sky.appendChild(b);
    }
  }

  /* ── Bandeau défilant : contenu doublé pour une boucle sans couture ── */
  const track = document.querySelector('.marquee-track');
  if (track) track.innerHTML += track.innerHTML.replace(/<span>/g, '<span aria-hidden="true">');

  /* ── Titres découpés en mots ─────────────────────────── */
  // Les mots mis en avant (<em class="script">) gardent leur balise.
  document.querySelectorAll('.split').forEach((h) => {
    const words = [];
    h.childNodes.forEach((n) => {
      const open = n.nodeType === 1 ? `<${n.tagName.toLowerCase()}${n.className ? ` class="${n.className}"` : ''}>` : '';
      const close = n.nodeType === 1 ? `</${n.tagName.toLowerCase()}>` : '';
      n.textContent.split(/(\s+)/).forEach((w) => {
        if (!w.trim()) { if (words.length) words.push(null); return; }
        words.push(open + w + close);
      });
    });
    h.setAttribute('aria-label', h.textContent.trim());
    let i = 0, out = '';
    words.forEach((w) => {
      if (w === null) { out += ' '; return; }
      out += `<span class="w" aria-hidden="true"><span style="--i:${i++}">${w}</span></span>`;
    });
    h.innerHTML = out.replace(/\s+/g, ' ').trim();
  });

  /* ── Compteurs ───────────────────────────────────────── */
  const countTo = (el, to) => {
    const from = parseInt((el.textContent || '0').replace(/\D/g, ''), 10) || 0;
    if (reduce) { el.textContent = fcfa(to); return; }
    const t0 = performance.now(), dur = 1100;
    const step = (t) => {
      const k = Math.min(1, (t - t0) / dur), e = 1 - Math.pow(1 - k, 3);
      el.textContent = fcfa(from + (to - from) * e);
      if (k < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  };

  /* ── Révélations au défilement ───────────────────────── */
  // À l'arrivée d'un bloc : compteurs, conversation, duo de mascottes.
  const enter = (el) => {
    el.querySelectorAll('[data-count]').forEach((c) => countTo(c, +c.dataset.count));
    if (el.matches('[data-chat]')) playChat(el);
    if (el.matches('[data-duo]')) setTimeout(() => {
      // Le duo se retrouve au centre puis saute de joie.
      el.querySelectorAll('.m-img').forEach((img) => { img.style.animation = ''; img.classList.add('jump'); });
      const r = el.getBoundingClientRect();
      burst(r.left + r.width / 2, r.top + r.height * .35, 70);
    }, reduce ? 0 : 950);
  };
  const io = new IntersectionObserver((entries) => entries.forEach((en) => {
    if (!en.isIntersecting) return;
    en.target.classList.add('in');
    enter(en.target);
    io.unobserve(en.target);
  }), { threshold: .2, rootMargin: '0px 0px -8% 0px' });
  document.querySelectorAll(G ? '[data-duo]' : '.reveal, .split, [data-chat], [data-duo]').forEach((el, i) => {
    if (el.matches('.reveal')) el.style.transitionDelay = `${(i % 4) * 70}ms`;
    io.observe(el);
  });
  if (G) motion();

  /* ── GSAP : ouverture du hero et sections au défilement ─ */
  // Uniquement transform et opacité ; distances réduites sur mobile, parallaxe
  // réservée aux grands écrans, chaque déclencheur ne sert qu'une fois.
  function motion() {
    gsap.registerPlugin(ScrollTrigger);
    // La barre d'adresse mobile qui se replie ne recalcule pas tout.
    ScrollTrigger.config({ ignoreMobileResize: true });

    // Défilement lissé et parallaxe (data-speed) sur grand écran à la souris.
    // Créé AVANT les ScrollTrigger. Sur tactile, le défilement natif reste :
    // plus fluide, et les formulaires comme la démo intégrée se comportent
    // normalement.
    if (window.ScrollSmoother) {
      gsap.registerPlugin(ScrollSmoother);
      gsap.matchMedia().add('(min-width: 981px) and (pointer: fine)', () => {
        smoother = ScrollSmoother.create({ smooth: 1.1, effects: true });
        root.classList.add('smooth');
        return () => {
          smoother.kill();
          smoother = null;
          root.classList.remove('smooth');
        };
      });
    }
    const hero = document.querySelector('.hero');
    const inHero = (sel) => hero.querySelectorAll(sel);
    const phone = hero.querySelector('.phone-tilt');
    const title = hero.querySelector('h1');
    const dist = innerWidth > 980 ? 48 : 24;

    // Ouverture : navigation, titre mot à mot, texte, puis le téléphone qui
    // monte, le badge qui tourne et les bulles de discussion.
    gsap.timeline({ defaults: { duration: .8, ease: 'power3.out' } })
      // La barre se place par transformation (CSS) : seule son opacité est animée.
      .fromTo('.pill-nav', { autoAlpha: 0 }, { autoAlpha: 1, duration: .6 }, 0)
      .fromTo(inHero('.eyebrow'), { autoAlpha: 0, y: 16 }, { autoAlpha: 1, y: 0 }, .15)
      .fromTo(title.querySelectorAll('.w > span'), { y: 0, yPercent: 105 }, {
        yPercent: 0, duration: .9, ease: 'power4.out', stagger: .07,
        onComplete: () => title.classList.add('in'),
      }, .25)
      .fromTo(inHero('.lead, .hero-actions, .scroll-down'), { autoAlpha: 0, y: 20 }, { autoAlpha: 1, y: 0, stagger: .1 }, '-=.45')
      .addLabel('visual', .35)
      .fromTo(phone, { autoAlpha: 0, y: dist * 2.5 }, {
        autoAlpha: 1, y: 0, duration: 1.1, ease: 'expo.out', clearProps: 'transform',
        // Le tour sur lui-même (animation CSS) prend la suite.
        onComplete: () => phone.classList.add('spin'),
      }, 'visual')
      .fromTo(inHero('.ci-badge'), { autoAlpha: 0, scale: .4, rotation: -90 }, {
        autoAlpha: 1, scale: 1, rotation: 0, ease: 'back.out(1.7)', clearProps: 'transform',
      }, 'visual+=.5')
      // Les bulles flottent déjà en CSS : seule leur opacité est animée.
      .fromTo(inHero('.bubble'), { autoAlpha: 0 }, { autoAlpha: 1, duration: .5, stagger: .3 }, 'visual+=.7');

    // Titres des sections : les mots montent un à un. (y: 0, car GSAP lit le
    // translateY(105 %) du CSS comme un décalage en pixels.)
    gsap.utils.toArray('.split').filter((h) => h !== title).forEach((h) => {
      gsap.fromTo(h.querySelectorAll('.w > span'), { y: 0, yPercent: 105 }, {
        yPercent: 0, duration: .9, ease: 'power4.out', stagger: .05,
        scrollTrigger: { trigger: h, start: 'top 88%', once: true },
        onComplete: () => h.classList.add('in'),
      });
    });

    // Blocs des sections : groupés quand ils arrivent ensemble, en cascade.
    const extras = gsap.utils.toArray('.band:not(.hero) :is(.eyebrow, h2 + p), .chat');
    gsap.set(extras, { autoAlpha: 0, y: dist / 2 });
    gsap.set('.reveal', { y: dist });
    ScrollTrigger.batch([...document.querySelectorAll('.reveal'), ...extras], {
      start: 'top 88%',
      once: true,
      onEnter: (els) => {
        els.forEach(enter);
        gsap.to(els, {
          autoAlpha: 1, y: 0, rotation: 0, duration: .9, ease: 'power3.out', stagger: .09, overwrite: true,
          onComplete: () => {
            // Les styles CSS reprennent la main (survols, compteurs, anneau).
            els.forEach((el) => el.classList.add('in'));
            gsap.set(els, { clearProps: 'transform,opacity,visibility' });
          },
        });
      },
    });

    // Parallaxe douce : chaque bloc glisse à sa vitesse, la page paraît plus courte.
    gsap.utils.toArray('[data-parallax]').forEach((el) => {
      const d = +el.dataset.parallax;
      gsap.fromTo(el, { y: -d }, { y: d, ease: 'none', scrollTrigger: { trigger: el.closest('section'), start: 'top bottom', end: 'bottom top', scrub: .6 } });
    });
    // Prestataires : les cartes s'empilent. Le contenu lissé étant déplacé par
    // transformation, position: sticky n'y fonctionne pas : on épingle.
    const stack = gsap.utils.toArray('[data-stack] li');
    gsap.matchMedia().add('(min-width: 981px) and (pointer: fine)', () => {
      stack.forEach((li, i) => {
        if (i === stack.length - 1) return;
        ScrollTrigger.create({ trigger: li, start: `top ${96 + i * 12}px`, endTrigger: stack[stack.length - 1], end: `top ${96 + i * 12 + 170}px`, pin: true, pinSpacing: false });
      });
    });

    // Positions recalculées une fois les polices et les images en place.
    document.fonts?.ready.then(() => ScrollTrigger.refresh());
    addEventListener('load', () => ScrollTrigger.refresh(), { once: true });
  }

  // Mascottes des bordures : déclenchées par l'arrivée de leur section
  // (elles-mêmes démarrent hors champ).
  const peekIO = new IntersectionObserver((entries) => entries.forEach((en) => {
    if (!en.isIntersecting) return;
    en.target.querySelectorAll(':scope > [data-peek]').forEach((p) => p.classList.add('in'));
    peekIO.unobserve(en.target);
  }), { threshold: .15 });
  document.querySelectorAll('[data-peek]').forEach((p) => peekIO.observe(p.parentElement));

  /* ── Conversation WhatsApp ───────────────────────────── */
  function playChat(chat) {
    const items = [...chat.querySelectorAll('.chat-body > *')];
    items.forEach((it, i) => setTimeout(() => it.classList.add('shown'), reduce ? 0 : 300 + i * 900));
  }

  /* ── Simulateur de budget ────────────────────────────── */
  const $ = (id) => document.getElementById(id);
  const sb = $('simBudget'), sg = $('simGuests');
  const shares = { lineVenue: .28, lineFood: .24, lineDeco: .14, lineMusic: .12, linePhoto: .12, lineDress: .10 };
  const sim = () => {
    const b = parseInt(sb.value.replace(/\D/g, ''), 10) || 0, g = +sg.value;
    $('simGuestsOut').textContent = g;
    $('simPerGuest').textContent = `${fcfa(b / g)} FCFA`;
    Object.entries(shares).forEach(([id, part]) => { $(id).textContent = fcfa(b * part); });
  };
  if (sb && sg) {
    sb.addEventListener('input', () => {
      // Espaces des milliers pendant la saisie, curseur gardé depuis la fin.
      const fromEnd = sb.value.length - sb.selectionStart;
      const digits = sb.value.replace(/\D/g, '').slice(0, 11);
      sb.value = digits ? fcfa(+digits) : '';
      const at = Math.max(0, sb.value.length - fromEnd);
      sb.setSelectionRange(at, at);
      sim();
    });
    sg.addEventListener('input', sim);
    sim();
  }

  /* ── Téléphones : un tour complet sur eux-mêmes, une seule fois ── */
  const spinIO = new IntersectionObserver((entries) => entries.forEach((en) => {
    if (!en.isIntersecting) return;
    if (!reduce) en.target.classList.add('spin');
    spinIO.unobserve(en.target);
  }), { threshold: .35 });
  // Avec GSAP, le téléphone du hero tourne à la fin de l'ouverture.
  document.querySelectorAll(G ? '[data-spin]:not(.phone-tilt)' : '[data-spin]').forEach((ph) => spinIO.observe(ph));

  /* ── Retour en haut ──────────────────────────────────── */
  const toTop = document.querySelector('.to-top');
  if (toTop) {
    let tq = false;
    const check = () => { tq = false; toTop.classList.toggle('show', scrollY > innerHeight * 1.2); };
    addEventListener('scroll', () => { if (!tq) { tq = true; requestAnimationFrame(check); } }, { passive: true });
    toTop.addEventListener('click', () => {
      if (smoother) smoother.scrollTo(0, true);
      else scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
    });
    check();
  }

  /* ── Barre de navigation fixe ────────────────────────── */
  // Sous le bandeau en haut de page, collée en haut dès qu'on défile.
  const navBar = document.querySelector('.pill-nav');
  const banner = document.querySelector('.banner');
  const placeNav = () => navBar.style.setProperty('--nav-shift', `${banner.offsetHeight + 4}px`);
  const stickNav = () => navBar.classList.toggle('scrolled', scrollY > 8);
  let navQueued = false;
  addEventListener('scroll', () => {
    if (navQueued) return;
    navQueued = true;
    requestAnimationFrame(() => { navQueued = false; stickNav(); });
  }, { passive: true });
  addEventListener('resize', placeNav);
  placeNav();
  stickNav();

  /* ── Menu « Calandix » ───────────────────────────────── */
  const whyMenu = document.querySelector('.nav-why');
  const closeWhy = () => { whyMenu.open = false; };
  document.addEventListener('click', (e) => {
    // Un clic ailleurs, ou sur un lien du menu, le referme.
    if (!whyMenu.contains(e.target) || e.target.closest('.why-panel a')) closeWhy();
  });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeWhy(); });

  /* ── Logo du pied de page : s'empile à son arrivée ───── */
  const footLogo = document.querySelector('.foot-brand');
  new IntersectionObserver((entries, obs) => {
    if (!entries[0].isIntersecting) return;
    footLogo.classList.add('in');
    obs.disconnect();
  }, { threshold: .4 }).observe(footLogo);

  /* ── Candix : l'assistance ───────────────────────────── */
  // Base locale de questions fréquentes : hors de cette base, Candix oriente
  // vers un conseiller plutôt que d'inventer une réponse.
  (() => {
    const box = document.querySelector('[data-candix]');
    const panel = box.querySelector('.candix-panel');
    const open = box.querySelector('.candix-open');
    const log = box.querySelector('.candix-log');
    const tips = box.querySelector('.candix-tips');
    const form = box.querySelector('.candix-form');
    const field = form.querySelector('input');
    const base = [
      [['creer', 'nouvel', 'evenement', 'commencer'], 'Dans l’application, touchez « Créer un événement », choisissez le type et la catégorie, puis la date, le nombre d’invités et le budget. Calandix prépare la checklist et répartit le budget.'],
      [['budget', 'depense', 'poste', 'enveloppe'], 'Vous fixez un budget cible, le répartissez par poste et notez chaque paiement. Essayez le simulateur plus haut sur cette page.'],
      [['tarif', 'prix', 'formule', 'abonnement', 'premium', 'coute', 'cout', 'gratuit', 'azur', 'signature', 'privilege'], 'Découverte est gratuite, puis Azur 2 900 FCFA, Signature 4 900 FCFA et Privilège 9 900 FCFA par mois. L’offre Creator des prestataires part de 29 900 FCFA par mois.'],
      [['payer', 'paiement', 'acompte', 'wave', 'orange', 'mtn', 'moov', 'mobile money', 'carte'], 'Les paiements passent par Mobile Money ou carte. L’acompte est conservé jusqu’à la prestation, puis reversé au prestataire.'],
      [['prestataire', 'traiteur', 'dj', 'photographe', 'decor', 'salle', 'devis', 'reserver', 'agence', 'commission', 'creator'], 'Les organisateurs comparent les devis et réservent dans l’application. Côté prestataire : inscription gratuite, commission sur chaque prestation payée via l’application.'],
      [['invite', 'rsvp', 'presence', 'whatsapp'], 'Vous construisez votre liste d’invités, suivez les réponses et voyez le nombre de personnes attendues.'],
      [['disponible', 'sortie', 'lancement', 'telecharger', 'android', 'iphone', 'application'], 'Calandix est en version de démonstration. Essayez-la dès maintenant, ou inscrivez-vous à l’accès anticipé pour être prévenu à l’ouverture.'],
      [['bonjour', 'bonsoir', 'salut', 'merci', 'hello'], 'Avec plaisir ! Dites-moi ce que vous cherchez à savoir.'],
    ];
    const clean = (t) => t.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
    const answer = (q) => {
      const c = clean(q);
      let best = null, score = 0;
      base.forEach(([words, text]) => {
        const s = words.filter((w) => c.includes(w)).length;
        if (s > score) { score = s; best = text; }
      });
      return best || 'Je n’ai pas encore la réponse à cette question. Un conseiller peut vous aider : touchez « Parler à un conseiller » juste en dessous.';
    };
    const say = (text, me) => {
      const p = document.createElement('p');
      p.textContent = text;
      if (me) p.className = 'me';
      log.append(p);
      log.scrollTop = log.scrollHeight;
    };
    const ask = (q) => {
      if (!q.trim()) return;
      tips.hidden = true; tips.textContent = '';
      say(q.trim(), true);
      say(answer(q));
    };
    say('Bonjour, je suis Candix. Une question sur Calandix ?');
    ['Combien ça coûte ?', 'Comment payer ?', 'Quand sort l’application ?'].forEach((t) => {
      const b = document.createElement('button');
      b.type = 'button'; b.textContent = t;
      b.addEventListener('click', () => ask(t));
      tips.append(b);
    });
    const toggle = (on) => {
      panel.hidden = !on;
      open.setAttribute('aria-expanded', on);
      if (on) field.focus({ preventScroll: true });
    };
    open.addEventListener('click', () => toggle(panel.hidden));
    box.querySelector('[data-candix-close]').addEventListener('click', () => { toggle(false); open.focus(); });
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && !panel.hidden) toggle(false); });
    form.addEventListener('submit', (e) => { e.preventDefault(); ask(field.value); field.value = ''; });
  })();

  /* ── Mode sombre ─────────────────────────────────────── */
  document.querySelector('.theme-toggle').addEventListener('click', () => {
    const next = root.dataset.theme === 'dark' ? 'light' : 'dark';
    root.dataset.theme = next;
    try { localStorage.setItem('calandix-theme', next); } catch (e) { /* navigation privée */ }
    document.querySelector('meta[name=theme-color]').content = next === 'dark' ? '#110722' : '#4D39E2';
  });

  /* ── En trois temps : la boîte survolée s'ouvre ──────── */
  const stepBoxes = [...document.querySelectorAll('[data-steps] .step')];
  stepBoxes.forEach((st) => {
    const show = () => stepBoxes.forEach((o) => o.classList.toggle('on', o === st));
    ['pointerenter', 'focus', 'click'].forEach((ev) => st.addEventListener(ev, show));
  });

  /* ── Marketplace : éventail ──────────────────────────── */
  (() => {
    const fan = document.querySelector('[data-fan]');
    if (!fan) return;
    const cards = [...fan.children];
    const n = cards.length;
    let at = 0, timer = 0, seen = false, over = false;
    fan.classList.add('fan-on');
    const place = () => {
      const step = fan.clientWidth < 620 ? 34 : 88;
      cards.forEach((c, i) => {
        let d = (i - at + n) % n;
        if (d > n / 2) d -= n;
        const a = Math.abs(d);
        c.classList.toggle('front', d === 0);
        c.style.zIndex = 20 - a;
        c.style.opacity = a > 3 ? 0 : 1;
        c.style.transform = `translateX(${d * step}px) translateY(${a * a * 3}px) rotate(${d * 7}deg) scale(${1 - a * .06})`;
        c.setAttribute('aria-hidden', d !== 0);
      });
    };
    const go = (by) => { at = (at + by + n) % n; place(); };
    const stop = () => { clearInterval(timer); timer = 0; };
    const play = () => { stop(); if (!reduce && seen && !over) timer = setInterval(() => go(1), 3600); };
    cards.forEach((c, i) => c.addEventListener('click', () => { at = i; place(); }));
    document.querySelector('[data-fan-prev]').addEventListener('click', () => { go(-1); play(); });
    document.querySelector('[data-fan-next]').addEventListener('click', () => { go(1); play(); });
    fan.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') go(-1);
      if (e.key === 'ArrowRight') go(1);
    });
    fan.addEventListener('pointerenter', () => { over = true; stop(); });
    fan.addEventListener('pointerleave', () => { over = false; play(); });
    let x0 = null;
    fan.addEventListener('touchstart', (e) => { x0 = e.touches[0].clientX; over = true; stop(); }, { passive: true });
    fan.addEventListener('touchend', (e) => {
      const dx = e.changedTouches[0].clientX - x0;
      if (Math.abs(dx) > 30) go(dx < 0 ? 1 : -1);
      over = false; play();
    }, { passive: true });
    new IntersectionObserver(([en]) => { seen = en.isIntersecting; seen ? play() : stop(); }, { threshold: .25 }).observe(fan);
    addEventListener('resize', place);
    place();
  })();

  /* ── Barre : survol roulant, ordre d'apparition du menu ─ */
  document.querySelectorAll('.nav-links > a').forEach((a) => {
    const t = a.textContent;
    a.innerHTML = '';
    const roll = document.createElement('span');
    roll.className = 'roll';
    const one = document.createElement('span'); one.textContent = t;
    const two = document.createElement('span'); two.textContent = t; two.setAttribute('aria-hidden', 'true');
    roll.append(one, two);
    a.append(roll);
  });
  [...document.querySelectorAll('.nav-links > *')].forEach((el, i) => el.style.setProperty('--n', i));
  document.querySelector('[data-socials]').innerHTML = document.querySelector('.footer .socials').innerHTML;

  /* ── Réseaux : comptes à venir ───────────────────────── */
  document.addEventListener('click', (e) => {
    if (!e.target.closest('[data-soon]')) return;
    e.preventDefault();
    toast('Ce compte arrive bientôt.');
  });

  /* ── Ancres internes ─────────────────────────────────── */
  // Avec ScrollSmoother, le contenu est déplacé par transformation : le saut
  // natif vers une ancre tombe à côté, on passe par smoother.scrollTo().
  document.addEventListener('click', (e) => {
    const a = e.target.closest('a[href^="#"]');
    if (!smoother || !a || a.getAttribute('href').length < 2) return;
    const target = document.getElementById(a.getAttribute('href').slice(1));
    if (!target) return;
    e.preventDefault();
    smoother.scrollTo(target, true, 'top 86px');
    history.replaceState(null, '', a.getAttribute('href'));
    // Le focus suit (lien d'évitement, navigation au clavier).
    if (!target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
    target.focus({ preventScroll: true });
  });

  /* ── Liens vers l'application de démo ────────────────── */
  // En ligne, l'application est servie sous /app/ ; en local, par le serveur de démo (port 8080).
  const local = !location.hostname || location.port === '8090';
  const base = local ? `http://${location.hostname || 'localhost'}:8080/#` : `${location.origin}/app/#`;
  const app = (path) => base + path;
  document.querySelectorAll('[data-demo]').forEach((a) => { a.href = app('/connexion'); a.target = '_blank'; a.rel = 'noopener'; });
  document.querySelectorAll('[data-demo-pro]').forEach((a) => { a.href = app('/connexion?profil=creator'); a.target = '_blank'; a.rel = 'noopener'; });
  document.querySelectorAll('[data-app-link]').forEach((a) => { a.href = app(a.dataset.appLink); a.target = '_blank'; a.rel = 'noopener'; });

  /* ── Petit message en bas d'écran ──────────────────────── */
  const toast = (msg) => {
    let t = document.querySelector('.toast');
    if (!t) { t = document.createElement('div'); t.className = 'toast'; t.setAttribute('role', 'status'); document.body.append(t); }
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(t._h);
    t._h = setTimeout(() => t.classList.remove('show'), 2600);
  };

  /* ── Accès anticipé : enregistré dans Supabase ───────── */
  // Clé publishable : publique par conception, la table n'accepte que l'insertion.
  const SUPABASE_URL = 'https://wszjcjmwenpzqvyixqds.supabase.co';
  const SUPABASE_KEY = 'sb_publishable_fRfVPiiBvhsYHc4e-d1rTw_lAWP1D5F';
  const early = document.querySelector('[data-early]');
  if (early) {
    const msg = early.querySelector('.form-msg');
    const btn = early.querySelector('button[type=submit]');
    const done = early.querySelector('.early-done');
    // Le chargement reste visible au moins ce temps : un éclair passerait pour un bug.
    const minWait = (t0) => new Promise((ok) => setTimeout(ok, Math.max(0, 700 - (performance.now() - t0))));
    early.addEventListener('submit', async (e) => {
      e.preventDefault();
      if (!early.reportValidity()) return;
      const t0 = performance.now();
      btn.disabled = true;
      btn.classList.add('loading');
      btn.setAttribute('aria-busy', 'true');
      msg.className = 'form-msg';
      msg.textContent = '';
      try {
        if (early.elements['bot-field'].value) throw new Error('bot');
        // Numéro normalisé : chiffres seulement, + conservé en tête.
        const whatsapp = early.elements.whatsapp.value.trim().replace(/(?!^\+)[^0-9]/g, '');
        const nom = early.elements.nom.value.trim();
        const profil = early.elements.profil.value;
        const email = early.elements.email.value.trim().toLowerCase();
        const send = (row) => fetch(`${SUPABASE_URL}/rest/v1/early_access`, {
          method: 'POST',
          headers: { apikey: SUPABASE_KEY, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
          body: JSON.stringify({ nom, whatsapp, profil, consent: true, source: 'landing', ...row }),
        });
        let r = await send({ email });
        // Colonne absente tant que la migration 000700 n'est pas exécutée.
        if ([400, 401, 403].includes(r.status)) r = await send({});
        // 409 : numéro déjà inscrit, on le traite comme un succès.
        if (!r.ok && r.status !== 409) throw new Error(r.status);
        await minWait(t0);
        thank(nom.split(/\s+/)[0], profil);
      } catch (err) {
        await minWait(t0);
        msg.className = 'form-msg err';
        msg.textContent = 'L’envoi n’a pas abouti. Réessayez dans un instant.';
      } finally {
        btn.disabled = false;
        btn.classList.remove('loading');
        btn.removeAttribute('aria-busy');
      }
    });

    // Remerciement : coche dessinée, message personnalisé, confettis depuis la coche.
    function thank(prenom, profil) {
      done.querySelector('.early-title').textContent = `Bienvenue sur la liste, ${prenom} !`;
      done.querySelector('.early-text').textContent = profil === 'prestataire'
        ? 'On vous écrit dès l’ouverture de l’espace pro, avec les avantages de lancement réservés aux premiers prestataires.'
        : 'On vous écrit dès l’ouverture, avec les avantages de lancement pour votre prochain événement.';
      early.reset();
      early.classList.add('sent');
      done.hidden = false;
      done.querySelector('.early-title').focus({ preventScroll: true });
      const r = done.querySelector('.early-check').getBoundingClientRect();
      setTimeout(() => burst(r.left + r.width / 2, r.top + r.height / 2, 120), 380);
    }
    done.querySelector('.early-again').addEventListener('click', () => {
      done.hidden = true;
      early.classList.remove('sent');
      early.elements.nom.focus();
    });
  }

  /* ── Menu mobile ─────────────────────────────────────── */
  const burger = document.querySelector('.burger'), nav = document.querySelector('.pill-nav');
  burger.addEventListener('click', () => {
    const open = burger.getAttribute('aria-expanded') !== 'true';
    burger.setAttribute('aria-expanded', open);
    nav.classList.toggle('open', open);
  });
  nav.querySelectorAll('.nav-links a').forEach((a) => a.addEventListener('click', () => {
    burger.setAttribute('aria-expanded', 'false'); nav.classList.remove('open'); closeWhy();
  }));
})();

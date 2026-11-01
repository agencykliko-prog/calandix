/* Calandix · téléphones 3D (three.js).
   La maquette réaliste (img/phone/frame.webp) devient un objet 3D : corps en
   titane, dos en verre, bloc photo, ombre portée et reflet sur l'écran.
   L'écran reste du vrai HTML (accueil reproduit, démo en direct) : il reçoit
   la même perspective que la caméra, donc il colle à la maquette. */
import * as THREE from 'three';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';

const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
const finePointer = matchMedia('(pointer: fine)').matches;

// Mesures de la maquette, en pixels de l'image (1043 × 2156).
const IMG_W = 1043, IMG_H = 2156;
const BODY_W = 1029 / IMG_W, BODY_R = 185 / IMG_W;   // corps sans les boutons
const SCREEN = { x: 30, y: 22, w: 983, h: 2110, r: 156 };
const A = IMG_H / IMG_W;                             // hauteur pour une largeur de 1
const DEPTH = BODY_W * 0.105;                        // ≈ 7,8 mm pour 71,5 mm

const webgl = (() => {
  try { return !!document.createElement('canvas').getContext('webgl2'); } catch { return false; }
})();

if (!reduce && webgl) document.querySelectorAll('[data-phone3d]').forEach(setup);

function roundedRect(w, h, r) {
  const s = new THREE.Shape(), x = -w / 2, y = -h / 2;
  s.moveTo(x + r, y);
  s.lineTo(x + w - r, y); s.quadraticCurveTo(x + w, y, x + w, y + r);
  s.lineTo(x + w, y + h - r); s.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  s.lineTo(x + r, y + h); s.quadraticCurveTo(x, y + h, x, y + h - r);
  s.lineTo(x, y + r); s.quadraticCurveTo(x, y, x + r, y);
  return s;
}

// Texture dessinée sur un canevas (ombre floue, reflet).
function canvasTexture(w, h, draw) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  draw(c.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

function buildPhone(frameTex) {
  const g = new THREE.Group();

  // Masque de l'écran : n'écrit que la profondeur, le HTML dessous reste visible.
  const sw = SCREEN.w / IMG_W, sh = SCREEN.h / IMG_W, sr = SCREEN.r / IMG_W;
  const sx = (SCREEN.x + SCREEN.w / 2) / IMG_W - .5, sy = A / 2 - (SCREEN.y + SCREEN.h / 2) / IMG_W;
  const mask = new THREE.Mesh(new THREE.ShapeGeometry(roundedRect(sw, sh, sr), 24), new THREE.MeshBasicMaterial({ colorWrite: false }));
  mask.position.set(sx, sy, DEPTH / 2);
  mask.renderOrder = -1;
  g.add(mask);

  // Face avant : la maquette détourée.
  const front = new THREE.Mesh(
    new THREE.PlaneGeometry(1, A),
    new THREE.MeshBasicMaterial({ map: frameTex, transparent: true, toneMapped: false, depthWrite: false }),
  );
  front.position.z = DEPTH / 2 + .002;
  front.renderOrder = 2;
  g.add(front);

  // Tranche en titane (les faces avant et arrière de l'extrusion sont masquées).
  const bev = .018;
  const side = new THREE.ExtrudeGeometry(roundedRect(BODY_W - 2 * bev, A - 2 * bev, BODY_R - bev), {
    depth: DEPTH - 2 * bev, bevelEnabled: true, bevelThickness: bev, bevelSize: bev, bevelSegments: 5, curveSegments: 28,
  });
  side.translate(0, 0, -(DEPTH - 2 * bev) / 2);
  const titanium = new THREE.MeshPhysicalMaterial({ color: 0x2b2b30, metalness: 1, roughness: .3 });
  const hidden = new THREE.MeshBasicMaterial({ visible: false });
  g.add(new THREE.Mesh(side, [hidden, titanium]));

  // Dos en verre dépoli.
  const back = new THREE.Mesh(
    new THREE.ShapeGeometry(roundedRect(BODY_W - .004, A - .004, BODY_R), 28),
    new THREE.MeshPhysicalMaterial({ color: 0x1d1a24, metalness: .2, roughness: .55, clearcoat: 1, clearcoatRoughness: .2 }),
  );
  back.rotation.y = Math.PI;
  back.position.z = -DEPTH / 2 - .001;
  g.add(back);

  // Bloc photo : en haut à gauche vu de dos.
  const cam = new THREE.Group();
  const bump = new THREE.Mesh(
    new THREE.ExtrudeGeometry(roundedRect(.42, .42, .1), { depth: .012, bevelEnabled: true, bevelThickness: .006, bevelSize: .006, bevelSegments: 3, curveSegments: 16 }),
    new THREE.MeshPhysicalMaterial({ color: 0x24212c, metalness: .3, roughness: .25, clearcoat: 1 }),
  );
  cam.add(bump);
  const ring = new THREE.MeshPhysicalMaterial({ color: 0x3a3a40, metalness: 1, roughness: .25 });
  const glass = new THREE.MeshPhysicalMaterial({ color: 0x05070f, metalness: .1, roughness: .05, clearcoat: 1, clearcoatRoughness: .02 });
  [[-.1, .1], [-.1, -.1], [.1, 0]].forEach(([x, y]) => {
    const barrel = new THREE.Mesh(new THREE.CylinderGeometry(.078, .078, .03, 40), ring);
    barrel.rotation.x = Math.PI / 2;
    barrel.position.set(x, y, .03);
    const lens = new THREE.Mesh(new THREE.CircleGeometry(.056, 40), glass);
    lens.position.set(x, y, .046);
    cam.add(barrel, lens);
  });
  const flash = new THREE.Mesh(new THREE.CircleGeometry(.024, 24), new THREE.MeshBasicMaterial({ color: 0xf3e6c8 }));
  flash.position.set(.12, .14, .02);
  cam.add(flash);
  cam.rotation.y = Math.PI;
  cam.position.set(BODY_W / 2 - .06 - .21, A / 2 - .06 - .21, -DEPTH / 2);
  g.add(cam);

  // Reflet sur la vitre : une bande claire qui glisse quand le téléphone tourne.
  const glareTex = canvasTexture(256, 256, (c, w, h) => {
    const gr = c.createLinearGradient(0, 0, w, h);
    gr.addColorStop(0, 'rgba(255,255,255,0)');
    gr.addColorStop(.42, 'rgba(255,255,255,0)');
    gr.addColorStop(.5, 'rgba(255,255,255,1)');
    gr.addColorStop(.58, 'rgba(255,255,255,0)');
    gr.addColorStop(1, 'rgba(255,255,255,0)');
    c.fillStyle = gr; c.fillRect(0, 0, w, h);
  });
  const glare = new THREE.Mesh(
    new THREE.ShapeGeometry(roundedRect(sw, sh, sr), 24),
    new THREE.MeshBasicMaterial({ map: glareTex, transparent: true, opacity: .07, blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false }),
  );
  // UV de ShapeGeometry = coordonnées locales : on les ramène à 0..1.
  const uv = glare.geometry.attributes.uv;
  for (let i = 0; i < uv.count; i++) uv.setXY(i, uv.getX(i) / sw + .5, uv.getY(i) / sh + .5);
  glare.position.set(sx, sy, DEPTH / 2 + .001);
  glare.renderOrder = 1;
  g.add(glare);

  return { group: g, glare, glareTex };
}

function setup(el) {
  const screen = el.querySelector('.screen');
  const img = el.querySelector('.phone-frame');
  if (!screen || !img) return;
  const calm = el.dataset.phone3d === 'calm';

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'low-power' });
  renderer.setClearColor(0x000000, 0);
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.domElement.className = 'p3d-canvas';
  renderer.domElement.setAttribute('aria-hidden', 'true');

  const scene = new THREE.Scene();
  const pmrem = new THREE.PMREMGenerator(renderer);
  scene.environment = pmrem.fromScene(new RoomEnvironment(), .04).texture;
  pmrem.dispose();
  const key = new THREE.DirectionalLight(0xffffff, 1.6);
  key.position.set(-2, 3, 4);
  scene.add(key);

  const camera = new THREE.PerspectiveCamera(30, 1, 1, 10000);

  const frameTex = new THREE.TextureLoader().load(img.currentSrc || img.src, () => {
    el.classList.add('p3d');
    el.append(renderer.domElement); // au-dessus de l'écran HTML
    resize();
    draw(performance.now());
  });
  frameTex.colorSpace = THREE.SRGBColorSpace;
  frameTex.anisotropy = renderer.capabilities.getMaxAnisotropy();
  const { group: phone, glare, glareTex } = buildPhone(frameTex);
  scene.add(phone);

  // Ombre portée floue, derrière le téléphone (elle ne tourne pas avec lui).
  const shadow = new THREE.Mesh(
    new THREE.PlaneGeometry(1, 1),
    new THREE.MeshBasicMaterial({
      map: canvasTexture(256, 512, (c, w, h) => {
        // Flou par shadowBlur (ctx.filter manque sur Safari) : la forme est
        // dessinée hors du canevas, seule son ombre y tombe.
        c.shadowColor = 'rgba(26,6,55,1)';
        c.shadowBlur = 30;
        c.shadowOffsetX = w * 2;
        c.beginPath(); c.roundRect(72 - w * 2, 76, w - 144, h - 152, 40); c.fill();
      }),
      transparent: true, opacity: .32, depthWrite: false, toneMapped: false,
    }),
  );
  shadow.renderOrder = -2;
  scene.add(shadow);

  // Unités du monde = pixels CSS : le HTML de l'écran et la 3D partagent l'échelle.
  let W = 0, H = 0, D = 0;
  function resize() {
    W = el.clientWidth; H = el.clientHeight;
    if (!W) return;
    const sw = W * 1.7, sh = H * 1.3;
    D = H * 2.4;
    renderer.setPixelRatio(Math.min(devicePixelRatio || 1, 2));
    renderer.setSize(sw, sh, false);
    Object.assign(renderer.domElement.style, { width: `${sw}px`, height: `${sh}px` });
    camera.fov = 2 * Math.atan(sh / 2 / D) * 180 / Math.PI;
    camera.aspect = sw / sh;
    camera.near = D / 10; camera.far = D * 3;
    camera.position.set(0, 0, D);
    camera.updateProjectionMatrix();
    phone.scale.setScalar(W);
    shadow.scale.set(W * 1.15, H * 1.08, 1);
    // Origine des transformations de l'écran : le centre du téléphone.
    screen.style.transformOrigin = `${W / 2 - screen.offsetLeft}px ${H / 2 - screen.offsetTop}px`;
  }
  new ResizeObserver(() => { resize(); draw(performance.now()); }).observe(el);

  // ── Mouvement ──────────────────────────────────────────
  const cur = { rx: 0, ry: 0, y: 0 }, aim = { rx: 0, ry: 0 };
  let ptr = { x: 0, y: 0 }, hold = false, holdUntil = 0, spinAt = -1, spun = false;
  if (finePointer) addEventListener('pointermove', (e) => {
    ptr = { x: e.clientX / innerWidth - .5, y: e.clientY / innerHeight - .5 };
  }, { passive: true });
  // Démo : on s'immobilise dès qu'on la touche, pour pouvoir s'en servir.
  if (calm) {
    el.addEventListener('pointerenter', () => { hold = true; });
    el.addEventListener('pointerleave', () => { hold = false; });
    el.addEventListener('touchstart', () => { holdUntil = performance.now() + 9000; }, { passive: true });
  }

  // Le tour complet est déclenché par app.js (classe « spin »).
  const trySpin = () => { if (!spun && el.classList.contains('spin')) { spun = true; spinAt = performance.now(); } };
  new MutationObserver(trySpin).observe(el, { attributes: true, attributeFilter: ['class'] });

  const ease = (t) => (t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
  let last = performance.now();

  function draw(now) {
    if (!W) return;
    const dt = Math.min(.05, (now - last) / 1000); last = now;
    const t = now / 1000;
    const still = calm && (hold || now < holdUntil);
    const amp = still ? 0 : calm ? .45 : 1;

    // Flottement, regard vers le curseur, inclinaison selon le défilement.
    const r = el.getBoundingClientRect();
    const scroll = Math.max(-1, Math.min(1, (r.top + r.height / 2 - innerHeight / 2) / innerHeight));
    aim.ry = amp * (Math.sin(t * .6) * .12 + ptr.x * .5);
    aim.rx = amp * (Math.sin(t * .8 + 1) * .05 + ptr.y * .3 + scroll * .18);
    const k = 1 - Math.exp(-dt * 4);
    cur.rx += (aim.rx - cur.rx) * k;
    cur.ry += (aim.ry - cur.ry) * k;
    cur.y = amp * Math.sin(t * 1.1) * H * .012;

    let spin = 0;
    if (spinAt >= 0) {
      const p = Math.min(1, (now - spinAt) / 2200);
      spin = ease(p) * Math.PI * 2;
      if (p === 1) spinAt = -1;
    }
    // Toutes les 5 secondes, une légère rotation fait vivre l'écran d'accueil.
    const phase = reduce || calm ? 1 : (now % 5000) / 1400;
    const sway = phase < 1 ? Math.sin(phase * Math.PI * 2) * .3 : 0;
    const ry = cur.ry + spin + sway;

    phone.position.y = cur.y;
    phone.rotation.set(cur.rx, ry, 0);
    shadow.position.set(-Math.sin(ry) * W * .12 + W * .03, cur.y * .4 - H * .03, -W * .55);
    shadow.material.opacity = .32 * (.75 + .25 * Math.abs(Math.cos(ry)));
    glareTex.offset.set(-Math.sin(ry) * .9 + cur.rx * .6, 0);

    // L'écran HTML suit exactement la face avant (repère CSS : y vers le bas).
    screen.style.transform =
      `perspective(${D}px) translate3d(0, ${-cur.y}px, 0) rotateX(${-cur.rx}rad) rotateY(${ry}rad) translateZ(${(DEPTH / 2) * W}px)`;

    renderer.render(scene, camera);
  }

  // Rendu seulement quand le téléphone est à l'écran.
  let raf = 0, visible = false;
  const loop = (now) => { draw(now); raf = visible ? requestAnimationFrame(loop) : 0; };
  new IntersectionObserver(([en]) => {
    visible = en.isIntersecting;
    if (visible && !raf) { last = performance.now(); raf = requestAnimationFrame(loop); }
  }, { rootMargin: '120px' }).observe(el);
  trySpin();
}

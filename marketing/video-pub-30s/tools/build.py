"""Génère index.html et compositions/*.html de la pub Calandix « La fête d'Awa ».

    python tools/build.py

Les valeurs (couleurs, polices, tailles, temps) viennent de SPEC.md.
"""
import html
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1080, 1350

FONTS = """
@font-face{font-family:'Red Hat Display';src:url('assets/fonts/RedHatDisplay-500.woff2') format('woff2');font-weight:500}
@font-face{font-family:'Red Hat Display';src:url('assets/fonts/RedHatDisplay-700.woff2') format('woff2');font-weight:700}
@font-face{font-family:'Red Hat Display';src:url('assets/fonts/RedHatDisplay-800.woff2') format('woff2');font-weight:800}
@font-face{font-family:'Satisfy';src:url('assets/fonts/Satisfy-400.woff2') format('woff2');font-weight:400}
"""

BASE_CSS = """
#root{position:absolute;inset:0;overflow:hidden;font-family:'Red Hat Display',sans-serif;color:#1A0637}
.bg{position:absolute;inset:0}
.cream{background:#F7F5F2}
.cream .halo{position:absolute;left:14%;top:30%;width:72%;height:64%;border-radius:50%;
  background:radial-gradient(closest-side,#E3DDF7 0%,rgba(234,231,243,.75) 45%,rgba(247,245,242,0) 100%)}
.violet{background:#4D39E2}
.violet .halo{position:absolute;left:-10%;top:40%;width:120%;height:80%;border-radius:50%;
  background:radial-gradient(closest-side,rgba(120,100,255,.55),rgba(77,57,226,0))}
.cam{position:absolute;inset:0;transform-origin:50% 60%}
.title{position:absolute;left:72px;right:72px;top:96px;font-weight:800;font-size:72px;line-height:1.04;
  letter-spacing:-.025em;text-wrap:balance}
.title .w{display:inline-block;overflow:hidden;vertical-align:top;padding:.04em .02em .12em;margin:-.04em -.02em -.12em}
.title .w>span{display:inline-block}
.title em{font-family:'Satisfy',cursive;font-style:normal;font-weight:400;font-size:1.16em;letter-spacing:0;line-height:.9}
.on-cream em{color:#4D39E2}
.on-violet{color:#fff}.on-violet em{color:#FFC233}
.phone{position:absolute;width:540px;height:1116px}
.phone .scr{position:absolute;left:15.5px;top:11.4px;width:509px;height:1092px;border-radius:78px;overflow:hidden;background:#fff}
.phone .scr{background:#F5F3F0}
.phone .scr img{position:absolute;left:0;top:44px;width:100%;height:calc(100% - 44px);object-fit:cover;object-position:top}
.phone .fr{position:absolute;inset:0;width:100%;height:100%}
.shadow{filter:drop-shadow(0 40px 46px rgba(26,6,55,.34))}
.plate{position:absolute;border-radius:34px;padding:18px;background:rgba(255,255,255,.62);
  backdrop-filter:blur(22px);-webkit-backdrop-filter:blur(22px);border:1.5px solid rgba(255,255,255,.85);
  box-shadow:0 40px 80px -28px rgba(26,6,55,.38),0 8px 16px -8px rgba(26,6,55,.25);overflow:hidden}
.plate img{display:block;width:100%;border-radius:22px}
.plate .shine{position:absolute;top:-40%;left:-60%;width:40%;height:180%;transform:rotate(18deg);
  background:linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,.55),rgba(255,255,255,0))}
.finger{position:absolute;width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.92);
  border:3px solid #1A0637;box-shadow:0 10px 20px -6px rgba(26,6,55,.45)}
"""


def title_html(text, cls):
    """Chaque mot dans un masque ; *mot* = écriture manuscrite."""
    out = []
    for i, word in enumerate(text.split(' ')):
        acc = word.startswith('*')
        word = word.strip('*')
        inner = f'<em>{html.escape(word)}</em>' if acc else html.escape(word)
        out.append(f'<span class="w"><span>{inner}</span></span>')
    return f'<div class="title {cls}">{" ".join(out)}</div>'


def scene(sid, dur, body, script, extra_css=''):
    return f"""<template>
  <style>{FONTS}{BASE_CSS}{extra_css}</style>
  <div id="root" data-composition-id="{sid}" data-width="{W}" data-height="{H}">
{body}
  </div>
  <script>
    const tl = gsap.timeline({{ paused: true }});
    const D = {dur};
{script}
    window.__timelines["{sid}"] = tl;
  </script>
</template>
"""


TITLE_IN = """    tl.fromTo('#{sid}-t .w>span', {{ yPercent: 105 }}, {{ yPercent: 0, duration: .5, ease: 'expo.out', stagger: .06 }}, {t0});
"""
CAM = """    tl.fromTo('#{sid}-cam', {{ scale: 1 }}, {{ scale: 1.05, duration: D, ease: 'sine.inOut' }}, 0);
"""


def product(sid, dur, screen, crop, text, phone_x, plate, ground='cream', extra_body='', extra_script='', phone_in='right'):
    """Plan produit : vrai téléphone + plaque de verre (découpe réelle) + titre."""
    px, py, pw = plate
    on = 'on-cream' if ground == 'cream' else 'on-violet'
    body = f"""    <div class="bg {ground}"><div class="halo"></div></div>
    <div id="{sid}-cam" class="cam">
      <div id="{sid}-ph" class="phone shadow" style="left:{phone_x}px;top:318px" data-layout-allow-overflow>
        <div class="scr"><img src="assets/app/{screen}.png" alt=""></div>
        <img class="fr" src="assets/img/frame.webp" alt="">
      </div>
      <div id="{sid}-pl" class="plate" style="left:{px}px;top:{py}px;width:{pw}px">
        <img src="assets/app/crop-{crop}.png" alt=""><div id="{sid}-sh" class="shine"></div>
      </div>
{extra_body}    </div>
    <div id="{sid}-t-wrap">{title_html(text, on).replace('class="title', f'id="{sid}-t" class="title', 1)}</div>
"""
    dx = 260 if phone_in == 'right' else -260
    script = CAM.format(sid=sid) + f"""    tl.fromTo('#{sid}-ph', {{ x: {dx}, opacity: 0 }}, {{ x: 0, opacity: 1, duration: .55, ease: 'expo.out' }}, 0);
    tl.fromTo('#{sid}-pl', {{ y: 70, scale: .9, opacity: 0 }}, {{ y: 0, scale: 1, opacity: 1, duration: .5, ease: 'back.out(1.4)' }}, .12);
    tl.fromTo('#{sid}-sh', {{ xPercent: 0 }}, {{ xPercent: 520, duration: .9, ease: 'power2.inOut' }}, .45);
""" + TITLE_IN.format(sid=sid, t0='.05') + extra_script + f"""    tl.to('#{sid}-ph', {{ x: {-dx // 2}, opacity: 0, duration: .28, ease: 'power2.in' }}, D - .3);
    tl.to('#{sid}-pl', {{ y: -40, opacity: 0, duration: .26, ease: 'power2.in' }}, D - .3);
    tl.to('#{sid}-t .w>span', {{ yPercent: -105, duration: .26, ease: 'power2.in', stagger: .02 }}, D - .3);
"""
    return scene(sid, dur, body, script)


SHOTS = []


def add(sid, start, dur, content):
    SHOTS.append((sid, start, dur))
    os.makedirs(os.path.join(ROOT, 'compositions'), exist_ok=True)
    open(os.path.join(ROOT, 'compositions', sid + '.html'), 'w', encoding='utf-8').write(content)


# 01 · Accroche : le chaos du groupe
bubbles = [
    ('Tantie Awa', 'Qui s’occupe du traiteur ?', 0), ('Kouassi', 'On en parle ce soir', 1),
    ('Mariam', 'Le DJ ne répond pas 😩', 0), ('Serge', 'Quelqu’un a le devis ?', 1),
    ('Fatou', 'Combien on est déjà ?', 0), ('Kouassi', 'Vocal · 3:47', 1),
    ('Tantie Awa', 'Et la salle ??', 0), ('Mariam', 'Je ne retrouve rien', 1), ('Serge', '???', 0)]
bub = ''
for i, (who, msg, side) in enumerate(bubbles):
    y = 470 + i * 88
    x = 150 if side == 0 else 430
    bub += (f'      <div id="s01-b{i}" class="bub {"r" if side else ""}" style="left:{x}px;top:{y}px">'
            f'<small>{html.escape(who)}</small>{html.escape(msg)}</div>\n')
s01_body = f"""    <div class="bg violet"><div class="halo"></div></div>
    <div id="s01-cam" class="cam">
      <div id="s01-ph" class="phone" style="left:270px;top:330px;opacity:.35;filter:blur(3px)" data-layout-allow-overflow>
        <div class="scr" style="background:#221043"></div><img class="fr" src="assets/img/frame.webp" alt="">
      </div>
{bub}      <div id="s01-card" class="card"><b>Mariage Awa &amp; Kouassi</b><span>J-42</span></div>
    </div>
    {title_html('247 messages. Zéro *décision*', 'on-violet').replace('class="title', 'id="s01-t" class="title', 1)}
"""
s01_css = """.bub{position:absolute;width:500px;padding:16px 22px;border-radius:24px 24px 24px 6px;background:#fff;
 font-size:28px;font-weight:700;color:#1A0637;box-shadow:0 18px 30px -16px rgba(10,4,40,.6)}
.bub.r{border-radius:24px 24px 6px 24px;background:#D9FDD3}
.bub small{display:block;font-size:20px;font-weight:800;color:#E01928;margin-bottom:2px}
.bub.r small{color:#1f8a70}
.card{position:absolute;left:240px;top:760px;width:600px;height:180px;border-radius:34px;background:#fff;
 display:flex;flex-direction:column;justify-content:center;padding:0 40px;box-shadow:0 40px 80px -28px rgba(10,4,40,.6)}
.card b{font-size:40px;font-weight:800}.card span{font-size:64px;font-weight:800;color:#E01928;line-height:1}
"""
s01_script = CAM.format(sid='s01') + "".join(
    f"    tl.fromTo('#s01-b{i}', {{ y: 40, scale: .8, opacity: 0 }}, {{ y: 0, scale: 1, opacity: 1, duration: .28, ease: 'back.out(1.8)' }}, {(i - 3) * 0.13:.2f});\n"
    for i in range(3, len(bubbles))) + "".join(
    f"    tl.to('#s01-b{i}', {{ x: {390 - (150 if bubbles[i][2] == 0 else 430) - 0}, y: {850 - (470 + i * 88)}, scale: .2, opacity: 0, duration: .32, ease: 'power3.in' }}, {1.30 + i * 0.015:.3f});\n"
    for i in range(len(bubbles))) + """    tl.fromTo('#s01-card', { scale: .3, opacity: 0 }, { scale: 1, opacity: 1, duration: .4, ease: 'back.out(1.6)' }, 1.55);
"""
add('s01', 0, 2.40, scene('s01', 2.40, s01_body, s01_script, s01_css))

# 02 → 12 · Parcours dans l'app
P = [
    # sid, start, dur, écran, découpe, titre, x téléphone, (x, y, largeur plaque), fond, sens
    ('s02', 2.40, 1.92, '60-new', 'tile', 'Tout *commence* ici', 470, (70, 560, 430), 'cream', 'right'),
    ('s03', 4.32, 1.92, '61-event', 'j42', 'Votre fête, à un *seul* endroit', 70, (430, 640, 590), 'cream', 'left'),
    ('s04', 6.24, 2.40, '62-budget', 'budget', 'Chaque franc a *sa place*', 470, (60, 560, 600), 'cream', 'right'),
    ('s05', 8.64, 1.92, '63-invites', 'rsvp', 'Les invités répondent *en ligne*', 70, (420, 620, 600), 'cream', 'left'),
    ('s06', 10.56, 1.92, '64-taches', 'taches', 'Chaque étape *planifiée*', 470, (60, 620, 600), 'cream', 'right'),
    ('s07', 12.48, 1.92, '66-explorer', 'vendor', 'Les bons *prestataires*', 70, (520, 470, 500), 'cream', 'left'),
    ('s08', 14.40, 2.40, '32-compare', 'analyse', 'Comparez les *devis*', 470, (50, 470, 560), 'cream', 'right'),
    ('s09', 16.80, 1.92, '41b-signed', 'sign', 'Signez, la date est *bloquée*', 70, (540, 430, 470), 'cream', 'left'),
    ('s10', 18.72, 2.40, '46-paid', 'paid', 'Payez en *Mobile Money*', 470, (60, 430, 520), 'violet', 'right'),
    ('s11', 21.12, 1.92, '69-thread-sent', 'chat', 'Vos prestataires, en *direct*', 70, (430, 560, 600), 'cream', 'left'),
    ('s12', 23.04, 1.92, '47-booking-paid', 'confirmed', 'Prêt pour le *jour J*', 470, (40, 640, 620), 'cream', 'right'),
]
for sid, start, dur, screen, crop, text, phx, plate, ground, side in P:
    extra_body, extra_script = '', ''
    if sid == 's02':  # le doigt touche « Mariages & unions »
        extra_body = '      <div id="s02-f" class="finger" style="left:160px;top:640px"></div>\n'
        extra_script = """    tl.fromTo('#s02-f', { scale: 1.8, opacity: 0 }, { scale: 1, opacity: 1, duration: .3, ease: 'power3.out' }, .9);
    tl.to('#s02-f', { scale: .82, duration: .12, yoyo: true, repeat: 1, ease: 'power1.inOut' }, 1.25);
    tl.to('#s02-pl', { scale: .97, duration: .12, yoyo: true, repeat: 1, ease: 'power1.inOut' }, 1.25);
"""
    if sid == 's10':  # logos Mobile Money sous la plaque
        logos = ''.join(f'<span class="mm"><img src="assets/img/{n}.webp" alt=""></span>' for n in ['wave', 'orange-money', 'momo', 'moov'])
        extra_body = f'      <div id="s10-mm" class="mmrow">{logos}</div>\n'
        extra_script = """    tl.fromTo('#s10-mm .mm', { y: 30, opacity: 0 }, { y: 0, opacity: 1, duration: .4, ease: 'back.out(1.6)', stagger: .07 }, .7);
"""
    content = product(sid, dur, screen, crop, text, phx, plate, ground, extra_body, extra_script, side)
    if sid == 's10':
        content = content.replace('</style>', """.mmrow{position:absolute;left:60px;top:1110px;width:440px;display:grid;grid-template-columns:repeat(4,1fr);gap:14px}
.mm{height:100px;border-radius:24px;background:#fff;display:grid;place-items:center;box-shadow:0 18px 30px -18px rgba(10,4,40,.6)}
.mm img{max-width:80px;max-height:64px;object-fit:contain}
.violet .plate{background:rgba(255,255,255,.18);border-color:rgba(255,255,255,.5)}
</style>""", 1)
    add(sid, start, dur, content)

# 13 · Multi-écrans
s13_body = """    <div class="bg cream"><div class="halo"></div></div>
    <div id="s13-cam" class="cam">
      <div id="s13-lap" class="laptop">
        <div class="lid"><div class="lscr"><img src="assets/app/70-desk-home.png" alt=""></div></div>
        <div class="base"></div>
      </div>
      <div id="s13-ph" class="phone shadow" style="left:690px;top:560px;width:300px;height:620px">
        <div class="scr" style="left:8.6px;top:6.3px;width:282.8px;height:606.6px;border-radius:44px"><img src="assets/app/01-home.png" alt=""></div>
        <img class="fr" src="assets/img/frame.webp" alt="">
      </div>
    </div>
    """ + title_html('Sur mobile et *ordinateur*', 'on-cream').replace('class="title', 'id="s13-t" class="title', 1) + """
    <div id="s13-sub" class="sub">Bientôt sur iOS et Android · déjà sur le web</div>
"""
s13_css = """.laptop{position:absolute;left:60px;top:390px;width:860px}
.lid{background:#2b2b30;border-radius:26px 26px 8px 8px;padding:18px;box-shadow:0 40px 80px -28px rgba(26,6,55,.38)}
.lscr{border-radius:10px;overflow:hidden;aspect-ratio:16/10;background:#fff}
.lscr img{width:100%;height:100%;object-fit:cover;object-position:top}
.base{height:26px;margin:0 -40px;border-radius:0 0 30px 30px;background:linear-gradient(#d9d8de,#a9a8b0)}
.sub{position:absolute;left:72px;right:72px;top:1210px;font-weight:700;font-size:34px;color:#4a3f63;text-align:left}
"""
s13_script = CAM.format(sid='s13') + """    tl.fromTo('#s13-lap', { y: 120, opacity: 0 }, { y: 0, opacity: 1, duration: .6, ease: 'expo.out' }, 0);
    tl.fromTo('#s13-ph', { x: 200, opacity: 0 }, { x: 0, opacity: 1, duration: .55, ease: 'expo.out' }, .18);
""" + TITLE_IN.format(sid='s13', t0='.08') + """    tl.fromTo('#s13-sub', { y: 24, opacity: 0 }, { y: 0, opacity: 1, duration: .45, ease: 'expo.out' }, .25);
    tl.to(['#s13-lap', '#s13-ph', '#s13-sub'], { opacity: 0, duration: .25, ease: 'power2.in' }, D - .28);
    tl.to('#s13-t .w>span', { yPercent: -105, duration: .25, ease: 'power2.in', stagger: .02 }, D - .28);
"""
add('s13', 24.96, 2.40, scene('s13', 2.40, s13_body, s13_script, s13_css))

# 14 · Fin
s14_body = """    <div class="bg violet"><div class="halo"></div></div>
    <div class="end">
      <img id="s14-mark" class="mark" src="assets/img/calandix-mark.svg" alt="">
      <div class="wm-mask"><img id="s14-wm" class="wm" src="assets/img/calandix-wordmark-light.svg" alt=""></div>
      <p id="s14-line" class="line">Toute votre fête, dans <em>une seule app</em></p>
      <div id="s14-btn" class="btn">Rejoindre l’accès anticipé</div>
      <p id="s14-url" class="url">calandix.com</p>
    </div>
"""
s14_css = """.end{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:34px;color:#fff;text-align:center;padding:0 80px}
.mark{width:190px;height:auto}
.wm-mask{overflow:hidden}.wm{height:96px;display:block}
.line{font-weight:800;font-size:52px;line-height:1.1;letter-spacing:-.02em;max-width:880px;text-wrap:balance}
.line em{font-family:'Satisfy',cursive;font-style:normal;font-weight:400;font-size:1.16em;color:#FFC233}
.btn{margin-top:10px;padding:30px 54px;border-radius:999px;background:#E01928;font-weight:800;font-size:38px;box-shadow:0 24px 40px -20px rgba(10,4,40,.7)}
.url{font-weight:800;font-size:34px;letter-spacing:.06em}
"""
s14_script = """    tl.fromTo('#s14-mark', { scale: 0, rotation: -25 }, { scale: 1, rotation: 0, duration: .5, ease: 'back.out(1.7)' }, 0);
    tl.fromTo('#s14-wm', { yPercent: 110 }, { yPercent: 0, duration: .5, ease: 'expo.out' }, .22);
    tl.fromTo('#s14-line', { y: 30, opacity: 0 }, { y: 0, opacity: 1, duration: .45, ease: 'expo.out' }, .38);
    tl.fromTo('#s14-btn', { scale: .6, opacity: 0 }, { scale: 1, opacity: 1, duration: .5, ease: 'back.out(1.8)' }, .5);
    tl.fromTo('#s14-url', { opacity: 0 }, { opacity: 1, duration: .35, ease: 'power2.out' }, .6);
"""
add('s14', 27.36, 2.64, scene('s14', 2.64, s14_body, s14_script, s14_css))

# index.html
hosts = '\n'.join(
    f'      <div id="{sid}" data-composition-id="{sid}" data-composition-src="compositions/{sid}.html" '
    f'data-start="{start:.2f}" data-duration="{dur:.2f}" data-track-index="1" data-track-kind="graphics" '
    f'data-width="{W}" data-height="{H}"></div>'
    for sid, start, dur in SHOTS)
index = f"""<!doctype html>
<html lang="fr">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width={W}, height={H}" />
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * {{ margin: 0; padding: 0; box-sizing: border-box; }}
      html, body {{ margin: 0; width: {W}px; height: {H}px; overflow: hidden; background: #F7F5F2; }}
      #root {{ position: relative; width: 100%; height: 100%; }}
    </style>
  </head>
  <body>
    <div id="root" data-composition-id="main" data-start="0" data-duration="30" data-fps="60" data-width="{W}" data-height="{H}">
{hosts}
    </div>
    <script>
      window.__timelines = window.__timelines || {{}};
      const tl = gsap.timeline({{ paused: true }});
      window.__timelines["main"] = tl;
    </script>
  </body>
</html>
"""
open(os.path.join(ROOT, 'index.html'), 'w', encoding='utf-8').write(index)
print('ok', len(SHOTS), 'plans')

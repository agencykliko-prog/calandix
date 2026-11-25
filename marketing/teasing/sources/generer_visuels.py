"""Calandix · 10 affiches de teasing 1080 × 1350 (HTML -> PNG via Chrome)."""
import os

A = 'file:///F:/PRODUCT/APP%20SAAS/Calandix/landing/'
IMG = A + 'img/'
OUT = os.path.dirname(os.path.abspath(__file__))

BASE = f"""
@font-face{{font-family:RHD;src:url({A}fonts/RedHatDisplay-500.woff2);font-weight:500}}
@font-face{{font-family:RHD;src:url({A}fonts/RedHatDisplay-700.woff2);font-weight:700}}
@font-face{{font-family:RHD;src:url({A}fonts/RedHatDisplay-800.woff2);font-weight:800}}
@font-face{{font-family:Satisfy;src:url({A}fonts/Satisfy-400.woff2)}}
:root{{--violet:#4D39E2;--coral:#E01928;--mango:#E59D1F;--mango-hi:#FFC233;--lagoon:#2CE5B9;--candy:#DB4F9E;
--ink:#1A0637;--night:#221043;--cream:#F7F5F2;--lavender:#EAE7F3;--white:#fff}}
*{{box-sizing:border-box;margin:0;padding:0}}
html,body{{width:1080px;height:1350px;overflow:hidden}}
.p{{position:relative;width:1080px;height:1350px;overflow:hidden;font-family:RHD;background:var(--bg);color:var(--fg)}}
.logo{{position:absolute;top:64px;left:72px;height:52px;z-index:5}}
.h{{font-weight:800;font-size:88px;line-height:1.02;letter-spacing:-.03em;text-wrap:balance}}
.s{{font-family:Satisfy;font-weight:400;font-size:1.16em;letter-spacing:0;line-height:.9}}
.sub{{font-weight:700;font-size:36px;line-height:1.3;opacity:.92;text-wrap:pretty}}
.foot{{position:absolute;left:72px;right:72px;bottom:60px;display:flex;justify-content:space-between;align-items:center;z-index:5}}
.soon{{font-weight:800;font-size:28px;letter-spacing:.14em;text-transform:uppercase}}
.cta{{font-weight:800;font-size:30px;padding:20px 34px;border-radius:99px;background:var(--coral);color:#fff}}
.m{{position:absolute;z-index:3}}
.conf i{{position:absolute;display:block;border-radius:4px}}
"""


def conf(seed, n=26, area=(0, 0, 1080, 1350), colors=('#E01928', '#FFC233', '#2CE5B9', '#DB4F9E', '#ffffff', '#4D39E2')):
    import random
    r = random.Random(seed)
    out = []
    x0, y0, x1, y1 = area
    for i in range(n):
        w = r.randint(12, 26)
        h = r.choice([w, int(w * .45)])
        rad = '50%' if r.random() < .3 else '4px'
        out.append(f'<i style="left:{r.randint(x0, x1)}px;top:{r.randint(y0, y1)}px;width:{w}px;height:{h}px;'
                   f'background:{colors[i % len(colors)]};transform:rotate({r.randint(0, 180)}deg);border-radius:{rad};opacity:.95"></i>')
    return '<div class="conf">' + ''.join(out) + '</div>'


def page(name, bg, fg, body, css='', logo='light', cta='Accès anticipé', soon='Bientôt · calandix.com'):
    body = body.replace(' ?', ' ?').replace(' !', ' !').replace(' :', ' :')
    lg = IMG + ('calandix-logo-light.svg' if logo == 'light' else 'calandix-logo.svg')
    html = f"""<!doctype html><html lang="fr"><meta charset="utf-8"><style>{BASE}{css}</style>
<div class="p" style="--bg:{bg};--fg:{fg}"><img class="logo" src="{lg}" alt="">{body}
<div class="foot"><span class="soon">{soon}</span><span class="cta">{cta}</span></div></div></html>"""
    open(os.path.join(OUT, name + '.html'), 'w', encoding='utf-8').write(html)


# 1 · Le cahier
page('01-cahier', '#F7F5F2', '#1A0637', f"""
<div style="position:absolute;left:72px;right:72px;top:170px"><p class="h">Ton budget de mariage tient encore dans un <span class="s" style="color:var(--violet)">cahier</span> ?</p>
<p class="sub" style="margin-top:26px;color:#4a3f63">Bientôt, il tiendra dans ta poche.</p></div>
<div class="note"><b>Mariage · budget</b>
<p><s>Salle ....... 800 000</s></p><p><s>Traiteur ... 1 200 000</s> ???</p><p>Déco ....... <s>350 000</s> 420 000</p><p><s>DJ ......... 150 000</s></p><p>Gâteau ..... ?</p><p class="tot">Total : <s>3 000 000</s> ... ?</p></div>
<div class="ph"><div class="scr"></div><img src="{IMG}phone/frame.webp" alt=""></div>
<img class="m" src="{IMG}mascots/triste.webp" style="left:34px;bottom:150px;width:300px">
""", css="""
.note{position:absolute;left:250px;top:560px;width:560px;height:620px;background:#fff;border-radius:10px;transform:rotate(-6deg);
 box-shadow:0 30px 60px -20px rgba(26,6,55,.35);padding:44px 40px 40px 90px;
 background-image:linear-gradient(#fff 0 0),repeating-linear-gradient(#fff 0 55px,#c9d6f2 55px 57px);background-size:4px 100%,100% 100%;background-repeat:no-repeat;background-position:62px 0,0 0;
 font-family:Satisfy;font-size:38px;color:#2c2a6b;line-height:57px}
.note::before{content:"";position:absolute;left:62px;top:0;bottom:0;width:3px;background:#f2a0a6}
.note b{font-weight:400;color:#E01928;font-size:44px}
.note .tot{color:#E01928}
.ph{position:absolute;right:70px;top:500px;width:280px;transform:rotate(9deg);z-index:2;filter:drop-shadow(0 30px 40px rgba(26,6,55,.35))}
.ph img{width:100%;display:block;position:relative}
.ph .scr{position:absolute;inset:2% 4%;border-radius:40px;background:linear-gradient(160deg,#4D39E2,#DB4F9E 60%,#FFC233);filter:blur(6px)}
""", logo='dark')

# 2 · Le groupe WhatsApp
msgs = [('Tantie Awa', 'Qui s’occupe du traiteur finalement ?', 0), ('Ibrahim', 'On en parle ce soir', 1), ('Mariam', 'Quelqu’un a le devis du DJ ??', 0),
        ('Koffi', 'J’ai envoyé ça hier 👆', 1), ('Tantie Awa', 'Je ne retrouve rien dans ce groupe', 0), ('Ibrahim', 'Vocal (3:47)', 1), ('Mariam', '???', 0)]
bub = ''.join(f'<div class="b {"r" if side else ""}"><small>{who}</small>{t}</div>' for who, t, side in msgs)
page('02-whatsapp', '#221043', '#fff', f"""
<div style="position:absolute;left:72px;right:72px;top:170px"><p class="h"><span style="color:var(--mango-hi)">247</span> messages non lus. Aucune décision <span class="s" style="color:var(--lagoon)">prise</span>.</p></div>
<div class="chat"><div class="top"><b>Mariage Awa & Koffi 💍</b><span>38 participants</span><i>247</i></div>{bub}</div>
<img class="m" src="{IMG}mascots/triste.webp" style="right:40px;bottom:140px;width:290px">
<p class="sub" style="position:absolute;left:72px;bottom:150px;width:560px">L’organisation à plusieurs va enfin respirer.</p>
""", css="""
.chat{position:absolute;left:72px;right:250px;top:470px;height:520px;background:#efe9df;border-radius:34px;padding:0 26px 26px;overflow:hidden;display:flex;flex-direction:column;gap:14px;
 box-shadow:0 30px 60px -20px rgba(0,0,0,.5);-webkit-mask-image:linear-gradient(#000 80%,transparent)}
.chat .top{margin:0 -26px 6px;padding:22px 26px;background:#1f8a70;color:#fff;display:flex;align-items:center;gap:14px;font-size:26px}
.chat .top span{opacity:.8;font-size:20px;font-weight:500;flex:1}
.chat .top i{font-style:normal;background:#2CE5B9;color:#1A0637;font-weight:800;border-radius:99px;padding:6px 14px;font-size:22px}
.b{max-width:76%;background:#fff;color:#1A0637;border-radius:20px;padding:12px 18px;font-size:24px;font-weight:500;line-height:1.3}
.b small{display:block;color:#E01928;font-weight:800;font-size:18px}
.b.r{align-self:flex-end;background:#d9fdd3}.b.r small{color:#1f8a70}
""")

# 3 · J-14
page('03-j14', '#4D39E2', '#fff', f"""
{conf(3, 34, (40, 140, 1040, 1150))}
<div class="big">J-14</div>
<div style="position:absolute;left:72px;right:72px;top:820px"><p class="h" style="font-size:76px">Et toi, tu sais où en est ton <span class="s" style="color:var(--mango-hi)">budget</span> ?</p>
<p class="sub" style="margin-top:24px">Calandix arrive. Tu sauras toujours.</p></div>
<img class="m" src="{IMG}mascots/course.webp" style="right:50px;top:860px;width:250px">
""", css=""".big{position:absolute;left:56px;top:150px;font-weight:800;font-size:520px;line-height:1;letter-spacing:-.06em;color:#E01928;
text-shadow:14px 14px 0 #1A0637}""")

# 4 · Le franc
parts = [('Lieu', 26, '#4D39E2'), ('Traiteur', 30, '#E01928'), ('Déco', 16, '#2CE5B9'), ('DJ', 12, '#DB4F9E'), ('Photo', 16, '#1A0637')]
acc, stops = 0, []
for _, v, c in parts:
    stops.append(f'{c} {acc}% {acc + v}%'); acc += v
legend = ''.join(f'<li><i style="background:{c}"></i>{n}</li>' for n, v, c in parts)
page('04-franc', '#FFC233', '#1A0637', f"""
<div style="position:absolute;left:72px;right:72px;top:170px"><p class="h">Chaque franc aura <span class="s" style="color:var(--coral)">sa place</span>.</p></div>
<div class="coin"><div class="pie" style="background:conic-gradient({','.join(stops)})"></div><div class="face"><b>FCFA</b></div></div>
<ul class="lg">{legend}</ul>
<img class="m" src="{IMG}mascots/idee.webp" style="right:50px;top:470px;width:250px">
<p class="sub" style="position:absolute;left:72px;right:72px;bottom:150px">Lieu, traiteur, déco, DJ : tout est réparti, tout est suivi.</p>
""", css=""".coin{position:absolute;left:110px;top:430px;width:560px;height:560px;border-radius:50%;background:#1A0637;padding:22px;box-shadow:0 34px 60px -24px rgba(26,6,55,.55)}
.pie{width:100%;height:100%;border-radius:50%}
.face{position:absolute;inset:170px;border-radius:50%;background:#FFC233;display:grid;place-items:center;border:8px solid #1A0637}
.face b{font-size:52px;font-weight:800;letter-spacing:.04em}
.lg{position:absolute;left:720px;top:820px;list-style:none;display:grid;gap:12px;font-weight:800;font-size:30px}
.lg li{display:flex;align-items:center;gap:14px}.lg i{width:28px;height:28px;border-radius:8px}""", logo='dark')

# 5 · Le DJ fantôme
page('05-dj', '#120826', '#fff', f"""
<div class="photo"></div><div class="spot"></div>
<div style="position:absolute;left:72px;right:72px;top:170px;z-index:4"><p class="h">Le DJ ne répond <span class="s" style="color:var(--mango-hi)">plus</span> ?</p></div>
<div class="msg"><p>Bonsoir, vous êtes toujours dispo pour samedi ? 🙏</p><small>23:12 ✓✓ Vu</small></div>
<p class="sub" style="position:absolute;left:72px;right:72px;bottom:150px;z-index:4">Bientôt, des prestataires vérifiés. Et ton acompte protégé.</p>
""", css=""".photo{position:absolute;inset:0;background:url(""" + IMG + """vendor_dj.webp) center 60%/cover;filter:grayscale(.85) brightness(.45)}
.spot{position:absolute;inset:0;background:radial-gradient(ellipse 520px 420px at 50% 62%,transparent,rgba(18,8,38,.88) 70%),linear-gradient(rgba(18,8,38,.9),transparent 35%,transparent 70%,rgba(18,8,38,.95))}
.msg{position:absolute;right:72px;top:470px;width:600px;background:#d9fdd3;color:#1A0637;border-radius:28px 28px 6px 28px;padding:26px 30px;font-size:32px;font-weight:700;line-height:1.3;z-index:4;box-shadow:0 30px 50px -20px rgba(0,0,0,.6)}
.msg small{display:block;text-align:right;font-size:22px;color:#4a7d8c;margin-top:8px}""")

# 6 · Mobile Money
logos = ''.join(f'<span class="pl"><img src="{IMG}pay/{p}.webp" alt=""></span>' for p in ['wave', 'orange-money', 'momo', 'moov'])
page('06-mobile-money', '#2CE5B9', '#1A0637', f"""
{conf(6, 22, (420, 380, 1050, 900))}
<div style="position:absolute;left:72px;right:72px;top:170px"><p class="h" style="font-size:74px">Tu paies déjà tout avec ton téléphone. Pourquoi pas ta <span class="s" style="color:var(--violet)">fête</span> ?</p></div>
<div class="ph"><img class="fr" src="{IMG}phone/frame.webp" alt=""><div class="in"><div class="ok">✓</div><b>Acompte payé</b><span>Traiteur · samedi 14</span></div></div>
<div class="row">{logos}</div>
""", css=""".ph{position:absolute;left:110px;top:520px;width:290px;transform:rotate(-7deg);filter:drop-shadow(0 30px 40px rgba(26,6,55,.35));z-index:2}
.ph .fr{width:100%;display:block;position:relative;z-index:2}
.ph .in{position:absolute;inset:3% 5%;border-radius:40px;background:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;z-index:1;text-align:center}
.ok{width:110px;height:110px;border-radius:50%;background:#2CE5B9;color:#1A0637;font-size:64px;font-weight:800;display:grid;place-items:center;margin-bottom:10px}
.ph b{font-size:34px;font-weight:800}.ph span{font-size:20px;color:#645A7C;font-weight:700}
.row{position:absolute;left:500px;right:72px;top:720px;display:grid;grid-template-columns:1fr 1fr;gap:22px}
.pl{background:#fff;border-radius:26px;height:130px;display:grid;place-items:center;box-shadow:0 18px 30px -18px rgba(26,6,55,.45)}
.pl{overflow:hidden}.pl img{max-width:200px;max-height:86px;width:auto;height:auto;object-fit:contain}""", logo='dark')

# 7 · La dot
page('07-dot', '#DB4F9E', '#fff', f"""
<div class="pagne"></div>
<div style="position:absolute;left:72px;right:72px;top:170px"><p class="h">Deux familles. Une liste. Zéro <span class="s" style="color:var(--mango-hi)">malentendu</span>.</p></div>
<div class="list"><div class="who"><span><img src="{IMG}avatar_2.webp" alt="">Famille Koné</span><span><img src="{IMG}avatar_4.webp" alt="">Famille Yao</span></div>
<ul><li class="d">Salle réservée</li><li class="d">Boissons commandées</li><li class="d">Pagnes choisis</li><li>Cadeaux à confirmer</li></ul></div>
<p class="sub" style="position:absolute;left:72px;right:190px;bottom:150px">Mariage, dot, baptême : on s’organise ensemble, enfin.</p>
""", css=""".foot{right:170px}.pagne{position:absolute;right:0;top:0;bottom:0;width:100px;background:
repeating-linear-gradient(45deg,#FFC233 0 18px,#1A0637 18px 26px,#E01928 26px 44px,#1A0637 44px 52px),#FFC233;opacity:.95}
.list{position:absolute;left:72px;right:200px;top:560px;background:#fff;color:#1A0637;border-radius:34px;padding:36px 40px;box-shadow:0 30px 60px -24px rgba(26,6,55,.5)}
.who{display:flex;gap:16px;flex-wrap:wrap;margin-bottom:22px}
.who span{display:flex;align-items:center;gap:12px;background:#EAE7F3;border-radius:99px;padding:8px 22px 8px 8px;font-weight:800;font-size:24px}
.who img{width:52px;height:52px;border-radius:50%;object-fit:cover}
ul{list-style:none;display:grid;gap:16px}
li{display:flex;align-items:center;gap:18px;font-size:32px;font-weight:700}
li::before{content:"";width:40px;height:40px;border-radius:12px;border:4px solid #c8c0dc;flex:none}
li.d::before{content:"✓";border:0;background:#2CE5B9;color:#1A0637;font-weight:800;display:grid;place-items:center;font-size:26px}
li.d{color:#645A7C;text-decoration:line-through;text-decoration-thickness:2px}""")

# 8 · Les invités
cards = ''
for i, (x, y, r, ok) in enumerate([(90, 600, -10, 0), (300, 640, 6, 1), (520, 590, -4, 1), (160, 820, 8, 1), (400, 860, -7, 0), (620, 820, 5, 1)]):
    cards += (f'<div class="card {"ok" if ok else ""}" style="left:{x}px;top:{y}px;transform:rotate({r}deg)">'
              + ('<b>✓</b><span>Je viens</span>' if ok else '<em>Vous êtes invité·e</em><span>Répondre</span>') + '</div>')
page('08-invites', '#EAE7F3', '#1A0637', f"""
<div style="position:absolute;left:72px;right:72px;top:170px"><p class="h" style="font-size:74px">Qui vient ? Combien ? Tu le sauras sans <span class="s" style="color:var(--coral)">appeler</span> tout le monde.</p></div>
{cards}
<img class="m" src="{IMG}mascots/panneau.webp" style="right:30px;top:600px;width:270px"><span class="sign">Je viens !</span>
<p class="sub" style="position:absolute;left:72px;right:72px;bottom:150px">Un lien, et chaque invité répond en ligne.</p>
""", css=""".card{position:absolute;width:230px;height:170px;border-radius:22px;background:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;
box-shadow:0 20px 34px -18px rgba(26,6,55,.4);font-weight:800}
.card em{font-family:Satisfy;font-style:normal;font-weight:400;font-size:34px;color:#4D39E2}
.card span{font-size:20px;background:#4D39E2;color:#fff;border-radius:99px;padding:6px 16px}
.card.ok{background:#1A0637;color:#fff}.card.ok b{width:70px;height:70px;border-radius:50%;background:#2CE5B9;color:#1A0637;display:grid;place-items:center;font-size:40px}
.card.ok span{background:transparent;font-size:24px}
.sign{position:absolute;left:848px;top:752px;width:108px;text-align:center;font-family:Satisfy;font-size:27px;color:#E01928;z-index:4;transform:rotate(-2deg)}""", logo='dark')

# 9 · Le mystère
page('09-mystere', '#120826', '#fff', f"""
<div class="light"></div><div class="cur l"></div><div class="cur r"></div>
<img class="m" src="{IMG}mascots/salut.webp" style="left:640px;top:610px;width:300px;z-index:4">
<div style="position:absolute;left:72px;right:72px;top:170px;z-index:5"><p class="h">Quelque chose se prépare pour vos <span class="s" style="color:var(--mango-hi)">fêtes</span>.</p></div>
<div class="badge"><svg viewBox="0 0 200 200"><defs><path id="a" d="M100,100 m-74,0 a74,74 0 1,1 148,0 a74,74 0 1,1 -148,0"/></defs>
<text><textPath href="#a">100% CÔTE D’IVOIRE ✦ 100% CÔTE D’IVOIRE ✦ </textPath></text></svg><span><i></i><i></i><i></i></span></div>
<p class="sub" style="position:absolute;left:72px;right:72px;bottom:150px;z-index:5">100 % Côte d’Ivoire. Bientôt.</p>
""", css=""".light{position:absolute;left:560px;top:380px;width:420px;height:900px;background:radial-gradient(ellipse at center,#FFE29A 0%,#FFC233 25%,rgba(255,194,51,0) 70%);filter:blur(10px)}
.cur{position:absolute;top:360px;bottom:0;background:repeating-linear-gradient(90deg,#3a28b8 0 34px,#4D39E2 34px 60px,#2f1fa0 60px 80px);box-shadow:inset 0 30px 40px -10px rgba(0,0,0,.5)}
.cur.l{left:0;width:660px;border-radius:0 0 80px 0;z-index:3}.cur.r{right:0;width:170px;z-index:5}
.badge{position:absolute;left:90px;top:520px;width:240px;height:240px;border-radius:50%;background:rgba(255,255,255,.12);backdrop-filter:blur(8px);border:2px solid rgba(255,255,255,.35);z-index:6;display:grid;place-items:center}
.badge svg{position:absolute;inset:0;width:100%;height:100%;fill:#fff;font:800 15px RHD;letter-spacing:.12em}
.badge span{width:96px;height:96px;border-radius:50%;overflow:hidden;display:flex;border:4px solid #fff}
.badge i{flex:1}.badge i:nth-child(1){background:#F77F00}.badge i:nth-child(2){background:#fff}.badge i:nth-child(3){background:#009E60}""")

# 10 · La révélation
balloons = ''.join(f'<span class="bl" style="left:{x}px;top:{y}px;background:{c};transform:scale({s})"></span>'
                   for x, y, c, s in [(60, 760, '#E01928', 1), (180, 650, '#FFC233', .8), (860, 700, '#2CE5B9', .9), (950, 560, '#DB4F9E', .7), (90, 470, '#ffffff', .6)])
page('10-revelation', '#4D39E2', '#fff', f"""
{balloons}{conf(10, 26, (40, 120, 1040, 560))}
<div style="position:absolute;left:72px;right:72px;top:170px;text-align:center"><p class="h" style="font-size:80px">Organiser un événement <span class="s" style="color:var(--mango-hi)">inoubliable</span>.</p>
<p class="sub" style="margin-top:18px">Sans y laisser ta tête.</p></div>
<div class="ph"><img class="sc" src="{IMG}phone/bienvenue.webp" alt=""><img class="fr" src="{IMG}phone/frame.webp" alt=""></div>
<img class="m" src="{IMG}mascots/rire.webp" style="left:650px;top:690px;width:270px;z-index:4">
<img src="{IMG}calandix-logo-light.svg" style="position:absolute;left:50%;transform:translateX(-50%);bottom:190px;height:70px;z-index:5" alt="">
""", soon='Inscris-toi sur calandix.com', cta='Accès anticipé', css=""".ph{position:absolute;left:390px;top:450px;width:280px;transform:rotate(-5deg);filter:drop-shadow(0 34px 44px rgba(10,4,40,.5));z-index:3}
.ph .fr{width:100%;display:block;position:relative;z-index:2}
.ph .sc{position:absolute;left:3%;top:1.2%;width:94%;height:97.6%;object-fit:cover;border-radius:44px;z-index:1}
.bl{position:absolute;width:150px;height:180px;border-radius:50% 50% 48% 48%;opacity:.85;z-index:1}
.bl::after{content:"";position:absolute;left:50%;top:100%;width:2px;height:180px;background:rgba(255,255,255,.5)}
.logo{display:none}""")
print('ok')

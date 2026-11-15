"""Pages publiques du site (À propos, Conditions, Confidentialité, Contact).

Le texte vient des écrans de l'application (lib/features/about/presentation),
seule source : la version française de chaque bi('fr', 'en').

    python wordpress/app_pages.py  ->  build/pages/<slug>.html
"""

import html
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'lib', 'features', 'about', 'presentation')
OUT = os.path.join(ROOT, 'build', 'pages')

# Coordonnées publiées sur la landing (pied de page, Candix).
WHATSAPP = '+225 07 04 25 22 25'
EMAIL = 'contact@calandix.com'
WHATSAPP_URL = 'https://wa.me/2250704252225'

LIT = r"'((?:[^'\\]|\\.)*)'"


def dart_str(s):
    return (s.replace("\\'", "'").replace('\\n', '\n').replace('\\$', '$')
            .replace('\\\\', '\\'))


def french_strings(path):
    """Premier argument de chaque bi('fr', 'en') ou _p / _ul, dans l'ordre."""
    src = open(path, encoding='utf-8').read()
    # Littéraux adjacents concaténés sur plusieurs lignes.
    src = re.sub(r"'\s*\n\s*'", '', src)
    out = []
    for m in re.finditer(r"\b(bi|_p|_ul)\(\s*" + LIT + r"\s*,\s*" + LIT, src):
        out.append((m.group(1), dart_str(m.group(2))))
    return out


def render(blocks):
    parts = []
    in_list = False  # avantages listés sous « Pour les … »
    for kind, text in blocks:
        t = text.strip()
        if not t:
            continue
        lines = [x for x in t.split('\n') if x.strip()]
        is_title = (len(t) < 70 and '\n' not in t and not t.endswith('.')
                    and kind == 'bi')
        if is_title and t.startswith('Pour les '):
            if in_list:
                parts.append('</ul>')
            parts.append(f'<h2>{html.escape(t)}</h2>\n<ul>')
            in_list = True
            continue
        if in_list and is_title and t[0].isupper() and len(t.split()) > 3:
            parts.append(f'<li>{html.escape(t)}</li>')
            continue
        if in_list:
            parts.append('</ul>')
            in_list = False
        if is_title:
            parts.append(f'<h2>{html.escape(t)}</h2>')
        elif kind == '_ul' or all(x.lstrip().startswith('•') for x in lines):
            items = ''.join(f'<li>{html.escape(x.lstrip("• ").strip())}</li>' for x in lines)
            parts.append(f'<ul>{items}</ul>')
        else:
            parts.extend(f'<p>{html.escape(x.strip())}</p>' for x in lines)
    if in_list:
        parts.append('</ul>')
    return '\n'.join(parts)


def page(slug, title, intro, body):
    os.makedirs(OUT, exist_ok=True)
    doc = f'<p class="lead">{html.escape(intro)}</p>\n{body}' if intro else body
    open(os.path.join(OUT, f'{slug}.html'), 'w', encoding='utf-8').write(doc)
    return slug, title


def main():
    made = []
    for slug, title, file in [
        ('a-propos', 'À propos de Calandix', 'about_screen.dart'),
        ('conditions', 'Conditions générales d’utilisation', 'terms_screen.dart'),
        ('confidentialite', 'Politique de confidentialité', 'privacy_screen.dart'),
    ]:
        blocks = french_strings(os.path.join(SRC, file))
        # « À propos » : la fin de l'écran n'est faite que de libellés
        # d'interface (titres de sections repliées, liens, contacts).
        cut = next((i for i, (_, t) in enumerate(blocks) if t == 'Nos valeurs'), None)
        if slug == 'a-propos' and cut is not None:
            blocks = blocks[:cut]
        # Conditions et confidentialité : après le dernier article viennent
        # l'en-tête de l'écran (avec la date de mise à jour) et ses boutons.
        intro = ''
        head = {'conditions': 'Conditions générales',
                'confidentialite': 'Politique de confidentialité'}.get(slug)
        idx = next((i for i, (_, t) in enumerate(blocks) if t == head), None) if head else None
        if idx is not None:
            date = next((t for _, t in blocks[idx:idx + 3] if 'mise à jour' in t.lower()), '')
            intro = date.replace('Utilisation et vente · ', '').strip()
            if intro:
                intro = intro[0].upper() + intro[1:] + '.'
            blocks = blocks[:idx]
        made.append(page(slug, title, intro, render(blocks)))

    contact = '\n'.join([
        '<p>Une question sur Calandix, une formule ou une réservation ? Notre équipe vous répond sur WhatsApp, par téléphone et par e-mail.</p>',
        f'<p><strong>WhatsApp :</strong> <a href="{WHATSAPP_URL}">{WHATSAPP}</a></p>',
        f'<p><strong>Téléphone :</strong> <a href="tel:{WHATSAPP.replace(" ", "")}">{WHATSAPP}</a></p>',
        f'<p><strong>E-mail :</strong> <a href="mailto:{EMAIL}">{EMAIL}</a></p>',
        '<p>Vous pouvez aussi poser votre question à Candix, l’assistance de la page d’accueil, '
        'ou rejoindre la liste d’accès anticipé pour être prévenu de l’ouverture.</p>',
        '<p><a href="/#acces-anticipe">Rejoindre l’accès anticipé</a> · <a href="/">Retour à l’accueil</a></p>',
    ])
    made.append(page('contact', 'Contact', '', contact))
    for slug, title in made:
        print(slug, title, os.path.getsize(os.path.join(OUT, f'{slug}.html')), 'octets')


if __name__ == '__main__':
    main()

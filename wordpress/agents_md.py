"""Version Markdown de l'accueil, servie aux agents (Accept: text/markdown).

Tirée de landing/index.html pour rester alignée sur la page :

    python wordpress/agents_md.py  ->  wordpress/calandix-theme/agents/index.md (+ jsonld.json)
"""

import os
import re

from bs4 import BeautifulSoup

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'landing', 'index.html')
OUT = os.path.join(ROOT, 'wordpress', 'calandix-theme', 'agents', 'index.md')

# Décor et parties interactives sans texte utile pour un agent.
SKIP = ('.phone', '.bubble', '.chat', '.balloons', '.edge-peek', '.ci-badge', '.marquee', '.b-stack',
        '.socials', '.foot-word', '.foot-brand', '.store-pill', 'svg', 'script', 'form', '.hp',
        '.scroll-down', '.why-icon', '[aria-hidden="true"]')

PAGES = ('\n---\n\nPages : [À propos](https://calandix.com/a-propos/) · '
         '[Contact](https://calandix.com/contact/) · '
         '[Conditions générales](https://calandix.com/conditions/) · '
         '[Confidentialité](https://calandix.com/confidentialite/) · '
         '[Résumé pour les agents](https://calandix.com/llms.txt)\n\n'
         'Contact : WhatsApp et téléphone +225 07 04 25 22 25 · contact@calandix.com\n')


def text(el):
    t = el.get_text(' ', strip=True)
    return re.sub(r'\s+', ' ', t).replace(' .', '.').replace(' ,', ',')


def main():
    soup = BeautifulSoup(open(SRC, encoding='utf-8').read(), 'html.parser')
    for sel in SKIP:
        for el in soup.select(sel):
            el.decompose()
    out = ['# Calandix · Le budget parfait pour célébrer', '',
           '> Version Markdown de https://calandix.com/ pour les agents et les outils d’IA.', '']

    for sec in soup.select('header.band, section.band, footer.footer'):
        last = None
        panels = set()
        for el in sec.find_all(['h1', 'h2', 'h3', 'h4', 'p', 'li', 'summary', 'figcaption']):
            if el.find_parent(['li']) and el.name != 'li':
                continue
            if el.name == 'summary' and el.find_parent(class_='pass-more'):
                continue  # « Voir / Masquer le contenu du Pass »
            t = text(el)
            if not t or t == last:
                continue
            last = t
            cls = el.get('class') or []
            # Tarifs : un intertitre par public.
            panel = el.find_parent(attrs={'data-aud-panel': True})
            if panel is not None and panel['data-aud-panel'] not in panels:
                panels.add(panel['data-aud-panel'])
                label = ('Formules organisateurs' if panel['data-aud-panel'] == 'org'
                         else 'Formules prestataires')
                out += ['', f'### {label}', '']
            if el.name == 'h1':
                continue  # titre déjà en tête du document
            if el.name == 'h2':
                out += ['', f'## {t}', '']
            elif el.name in ('h3', 'h4') or 'pass-kicker' in cls:
                out += ['', f'#### {t}' if panel is not None else f'### {t}', '']
            elif el.name == 'summary':
                out += ['', f'**{t}**', '']
            elif el.name == 'li':
                if out and out[-1] and not out[-1].startswith('- '):
                    out.append('')
                out.append(f'- {t}')
            else:
                if 'eyebrow' in cls:
                    continue
                if out and out[-1].startswith('- '):
                    out.append('')
                out += [t.replace(' Demander un devis', ''), '']

    md = re.sub(r'\n{3,}', '\n\n', '\n'.join(out)).strip() + '\n' + PAGES
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, 'w', encoding='utf-8').write(md)
    print(OUT, len(md), 'caractères')
    jsonld(BeautifulSoup(open(SRC, encoding='utf-8').read(), 'html.parser'))


def jsonld(soup):
    """Données structurées de l'accueil : organisation, site, application
    (avec ses offres) et questions fréquentes, d'après la page."""
    import json

    base = 'https://calandix.com/'
    logo = base + 'wp-content/themes/calandix/landing/img/calandix-logo-email.png'
    offers = []
    for panel in soup.select('[data-aud-panel]'):
        audience = 'organisateurs' if panel['data-aud-panel'] == 'org' else 'prestataires'
        for art in panel.select('article.plan'):
            name = text(art.select_one('h3'))
            price = art.select_one('.price')
            amount = int(price.get('data-price', 0)) if price else 0
            offers.append({
                '@type': 'Offer',
                'name': f'{name} ({audience})',
                'price': str(amount),
                'priceCurrency': 'XOF',
                'description': text(art.select_one('.plan-tag')) if art.select_one('.plan-tag') else None,
                **({'priceSpecification': {
                    '@type': 'UnitPriceSpecification', 'price': str(amount), 'priceCurrency': 'XOF',
                    'billingDuration': 1, 'unitCode': 'MON'}} if amount else {}),
            })
    pass_price = soup.select_one('.pass-price b')
    if pass_price:
        offers.append({'@type': 'Offer', 'name': 'Pass Événement (90 jours, un événement)',
                       'price': re.sub(r'\D', '', text(pass_price)), 'priceCurrency': 'XOF'})
    faq = []
    for d in soup.select('#faq details.faq-item'):
        q = d.select_one('summary')
        a = d.select_one('.faq-a')
        if q and a:
            faq.append({'@type': 'Question', 'name': text(q),
                        'acceptedAnswer': {'@type': 'Answer', 'text': text(a)}})
    desc = soup.select_one('meta[name=description]')['content']
    graph = {
        '@context': 'https://schema.org',
        '@graph': [
            {
                '@type': 'Organization', '@id': base + '#organisation', 'name': 'Calandix', 'url': base,
                'logo': logo, 'slogan': 'Le budget parfait pour célébrer', 'description': desc,
                'areaServed': {'@type': 'Country', 'name': 'Côte d’Ivoire'},
                'telephone': '+2250704252225', 'email': 'contact@calandix.com',
                'contactPoint': {'@type': 'ContactPoint', 'telephone': '+2250704252225',
                                 'contactType': 'customer support', 'email': 'contact@calandix.com', 'availableLanguage': ['fr'],
                                 'areaServed': 'CI', 'url': 'https://wa.me/2250704252225'},
            },
            {
                '@type': 'WebSite', '@id': base + '#site', 'url': base, 'name': 'Calandix',
                'inLanguage': 'fr', 'publisher': {'@id': base + '#organisation'},
            },
            {
                '@type': 'SoftwareApplication', '@id': base + '#application', 'name': 'Calandix',
                'url': base + 'app/', 'applicationCategory': 'BusinessApplication',
                'operatingSystem': 'Web', 'description': desc, 'inLanguage': 'fr',
                'publisher': {'@id': base + '#organisation'},
                'offers': [{k: v for k, v in o.items() if v is not None} for o in offers],
            },
            {'@type': 'FAQPage', '@id': base + '#faq', 'mainEntity': faq},
        ],
    }
    path = os.path.join(ROOT, 'wordpress', 'calandix-theme', 'agents', 'jsonld.json')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(graph, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(path, len(offers), 'offres,', len(faq), 'questions')


if __name__ == '__main__':
    main()

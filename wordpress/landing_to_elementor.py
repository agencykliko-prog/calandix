"""Convertit landing/index.html en page Elementor (éléments atomiques, V4).

    python wordpress/landing_to_elementor.py  ->  build/elementor-accueil.json

Chaque balise de la landing devient l'élément Elementor qui la rend à
l'identique, pour que la page se modifie dans l'éditeur visuel :

- titres h1 à h6               -> « Titre » (e-heading)
- paragraphes et span de texte -> « Paragraphe » (e-paragraph)
- liens                        -> « Bouton » (e-button, balise a)
- images                       -> « Image » (e-image)
- div, section, header, nav…   -> « Bloc div » (e-div-block)
- le reste (formulaires, listes, svg, détails…) -> widget « HTML », intact.

Les classes de la landing deviennent des classes globales Elementor (même nom),
donc styles.css s'applique tel quel. Elementor gratuit ne gère pas les
attributs data-* ni style= : ils sont rangés à part (attrs) et remis au rendu
par le thème, repérés par l'identifiant de l'élément.
"""

import hashlib
import json
import os
import re

from bs4 import BeautifulSoup, Comment, NavigableString, Tag

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'landing', 'index.html')
OUT = os.path.join(ROOT, 'build', 'elementor-accueil.json')

# Adresse publique des fichiers de la landing (thème Calandix).
ASSETS = 'https://calandix.com/wp-content/themes/calandix/landing/'

DIV_TAGS = {'div', 'header', 'section', 'article', 'aside', 'footer', 'main', 'nav'}
HEADINGS = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}
# Balises gardées par chaque élément texte d'Elementor (sans attributs).
ALLOWED = {
    'e-heading': {'b', 'strong', 'sup', 'sub', 's', 'em', 'i', 'u', 'del', 'span', 'br'},
    'e-paragraph': {'b', 'strong', 'sup', 'sub', 's', 'em', 'u', 'del', 'span', 'br'},
    'e-button': {'b', 'strong', 'sup', 'sub', 's', 'em', 'i', 'u', 'del', 'span', 'br'},
}
# Classes d'éléments en ligne qu'Elementor efface et que le thème remet.
INLINE_FIX = {('em', 'script'): '<em>', ('span', 'script'): '<em>', ('span', 'wide-only'): '<span>'}

_ids = set()


def eid(seed):
    n = 0
    while True:
        h = hashlib.md5(f'{seed}:{n}'.encode()).hexdigest()[:7]
        if h not in _ids:
            _ids.add(h)
            return h
        n += 1


def fix_urls(html):
    html = re.sub(r'(src|href|srcset)="(img|fonts)/', rf'\1="{ASSETS}\2/', html)
    return html.replace('https://eventa.ci/', 'https://calandix.com/')


def s(v):
    return {'$$type': 'string', 'value': v}


class Builder:
    def __init__(self):
        self.labels = []      # classes globales, dans l'ordre d'apparition
        self.attrs = {}       # id -> {attribut: valeur}
        self.fixes = {}       # id -> [[avant, après]]
        self.counter = 0

    def classes(self, node):
        out = []
        for c in node.get('class', []) or []:
            if c not in self.labels:
                self.labels.append(c)
            out.append(c)
        return {'$$type': 'classes', 'value': out}  # libellés ; ids posés au déploiement

    def extra_attrs(self, node, el_id, skip=()):
        keep = {k: (' '.join(v) if isinstance(v, list) else v)
                for k, v in node.attrs.items()
                if k not in ('class', 'id') and k not in skip}
        if keep:
            self.attrs[el_id] = keep

    def inline_html(self, node, kind):
        """Contenu en ligne compatible, ou None s'il faut le widget HTML."""
        allowed = ALLOWED[kind]
        fixes = []
        for child in node.descendants:
            if isinstance(child, Comment):
                return None
            if not isinstance(child, Tag):
                continue
            if child.name not in allowed:
                return None
            cls = child.get('class') or []
            other = {k for k in child.attrs if k != 'class'}
            if other:
                return None
            if cls:
                key = (child.name, ' '.join(cls))
                if key not in INLINE_FIX:
                    return None
                fixes.append(key)
            elif child.name == 'span':
                return None  # un span nu serait pris pour wide-only
        html = ''.join(str(c) for c in node.contents)
        for (tag, cls), repl in INLINE_FIX.items():
            closing = '</em>' if repl == '<em>' else f'</{tag}>'
            html = re.sub(rf'<{tag} class="{cls}">(.*?)</{tag}>', rf'{repl}\1{closing}', html, flags=re.S)
        return html.strip(), fixes

    def node_id(self, node):
        self.counter += 1
        return eid(f'{node.name}:{self.counter}:{node.get("class")}:{node.get("id")}')

    def record_fixes(self, el_id, fixes):
        pairs = []
        for tag, cls in fixes:
            if cls == 'script':
                pairs.append(['<em>', '<em class="script">'])
            elif cls == 'wide-only':
                pairs.append(['<span>', '<span class="wide-only">'])
        if pairs:
            uniq = []
            for p in pairs:
                if p not in uniq:
                    uniq.append(p)
            self.fixes[el_id] = uniq

    def html_widget(self, node):
        el_id = self.node_id(node)
        raw = fix_urls(str(node))
        return {
            'id': el_id, 'elType': 'widget', 'widgetType': 'html',
            'settings': {'html': f'<!--cx:raw-->{raw}<!--/cx:raw-->'},
            'elements': [],
        }

    def common(self, node, el_id, settings, skip=()):
        settings['classes'] = self.classes(node)
        if node.get('id'):
            settings['_cssid'] = s(node['id'])
        self.extra_attrs(node, el_id, skip)
        return settings

    def convert(self, node):
        if not isinstance(node, Tag) or node.name in ('script', 'style'):
            return None
        name = node.name

        if name in HEADINGS:
            got = self.inline_html(node, 'e-heading')
            if got:
                el_id = self.node_id(node)
                html, fixes = got
                self.record_fixes(el_id, fixes)
                return {'id': el_id, 'elType': 'widget', 'widgetType': 'e-heading', 'elements': [],
                        'settings': self.common(node, el_id, {'tag': s(name), 'title': {'$$type': 'escaped-html', 'value': html}})}

        if name in ('p', 'span') and not node.find(True, recursive=False) or name in ('p', 'span'):
            got = self.inline_html(node, 'e-paragraph')
            if got:
                el_id = self.node_id(node)
                html, fixes = got
                self.record_fixes(el_id, fixes)
                return {'id': el_id, 'elType': 'widget', 'widgetType': 'e-paragraph', 'elements': [],
                        'settings': self.common(node, el_id, {'tag': s(name), 'paragraph': {'$$type': 'escaped-html', 'value': html}})}

        if name == 'a' and node.get('href') is not None:
            got = self.inline_html(node, 'e-button')
            if got:
                el_id = self.node_id(node)
                html, fixes = got
                self.record_fixes(el_id, fixes)
                href = fix_urls(f'href="{node["href"]}"')[6:-1]
                return {'id': el_id, 'elType': 'widget', 'widgetType': 'e-button', 'elements': [],
                        'settings': self.common(node, el_id, {
                            'tag': s('a'),
                            'text': {'$$type': 'escaped-html', 'value': html},
                            'link': {'$$type': 'link', 'value': {
                                'destination': {'$$type': 'url', 'value': href},
                                'isTargetBlank': {'$$type': 'boolean', 'value': node.get('target') == '_blank'},
                            }},
                        }, skip=('href', 'target'))}

        if name == 'img' and node.get('src'):
            el_id = self.node_id(node)
            url = fix_urls(f'src="{node["src"]}"')[5:-1]
            return {'id': el_id, 'elType': 'widget', 'widgetType': 'e-image', 'elements': [],
                    'settings': self.common(node, el_id, {
                        'image': {'$$type': 'image', 'value': {
                            'src': {'$$type': 'image-src', 'value': {'id': None, 'url': {'$$type': 'url', 'value': url}}},
                            'size': s('full'),
                        }},
                    }, skip=('src',))}

        if name in DIV_TAGS:
            kids = [c for c in node.contents
                    if not (isinstance(c, NavigableString) and (isinstance(c, Comment) or not c.strip()))]
            if kids and all(isinstance(c, Tag) for c in kids):
                el_id = self.node_id(node)
                children = [x for x in (self.convert(c) for c in kids) if x]
                return {'id': el_id, 'elType': 'e-div-block', 'elements': children,
                        'settings': self.common(node, el_id, {'tag': s(name)})}

        return self.html_widget(node)


def main():
    soup = BeautifulSoup(open(SRC, encoding='utf-8').read(), 'html.parser')
    b = Builder()
    elements = []
    for child in soup.body.children:
        if isinstance(child, Tag) and child.name not in ('script',):
            el = b.convert(child)
            if el:
                elements.append(el)

    counts = {}

    def walk(els):
        for e in els:
            k = e.get('widgetType') or e['elType']
            counts[k] = counts.get(k, 0) + 1
            walk(e['elements'])
    walk(elements)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump({'elements': elements, 'labels': b.labels, 'attrs': b.attrs, 'fixes': b.fixes},
              open(OUT, 'w', encoding='utf-8'), ensure_ascii=False)
    print(OUT)
    print(json.dumps(counts, ensure_ascii=False), 'classes:', len(b.labels), 'attrs:', len(b.attrs))


if __name__ == '__main__':
    main()

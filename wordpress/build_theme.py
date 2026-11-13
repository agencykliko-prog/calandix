"""Assemble le thème WordPress « calandix » en zip prêt à téléverser.

Le thème (wordpress/calandix-theme/) n'est qu'une enveloppe : la page vient
de landing/, copiée dans le dossier landing/ du thème.

    python wordpress/build_theme.py   ->  build/calandix-theme.zip

Sur le serveur : extraire dans wp-content/themes/ puis activer « Calandix ».
L'application Flutter se publie à part, sous /app/ :

    flutter build web --release --base-href /app/ --output build/web-app
"""

import os
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEME = os.path.join(ROOT, 'wordpress', 'calandix-theme')
LANDING = os.path.join(ROOT, 'landing')
OUT = os.path.join(ROOT, 'build', 'calandix-theme.zip')
# robots.txt et sitemap.xml : WordPress fournit les siens.
SKIP = {'robots.txt', 'sitemap.xml'}


def main() -> None:
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with zipfile.ZipFile(OUT, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(THEME):
            for f in sorted(files):
                full = os.path.join(root, f)
                rel = os.path.relpath(full, THEME).replace(os.sep, '/')
                z.write(full, f'calandix/{rel}')
        for root, _, files in os.walk(LANDING):
            for f in files:
                full = os.path.join(root, f)
                rel = os.path.relpath(full, LANDING).replace(os.sep, '/')
                if rel in SKIP:
                    continue
                z.write(full, f'calandix/landing/{rel}')
        cover = os.path.join(LANDING, 'img', 'og-calandix.jpg')
        if os.path.exists(cover):
            z.write(cover, 'calandix/screenshot.jpg')
    print(OUT)


if __name__ == '__main__':
    main()

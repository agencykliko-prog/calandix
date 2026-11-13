# calandix.com (WordPress)

La page d'accueil de calandix.com est une page **Elementor** (« Accueil »),
modifiable dans l'éditeur visuel. Elle reprend la landing (`landing/`) balise
pour balise avec les éléments atomiques d'Elementor 4 (Titre, Paragraphe,
Bouton, Image, Bloc div) ; les parties interactives (simulateur, formulaire,
tarifs, Candix, téléphone) sont des widgets HTML.

- Les classes de la landing sont des **classes globales** Elementor du même
  nom : `landing/styles.css` s'applique tel quel, sur le site comme dans
  l'éditeur.
- Elementor gratuit ne gère pas les attributs `data-*`, `style`, `hidden` : ils
  sont rangés en méta de la page (`_cx_attrs`) et remis au rendu par le thème
  (`calandix_restore_markup`), et dans l'aperçu de l'éditeur par
  `assets/editor-preview.js`.
- Le SEO (titre, description, aperçus de partage) se règle dans **Yoast**.
- L'application Flutter est servie sous `/app/`.

## Republier depuis la landing

À faire seulement pour repartir de `landing/index.html` : cela **remplace**
les modifications faites dans Elementor.

```bash
python wordpress/build_theme.py          # build/calandix-theme.zip
python wordpress/landing_to_elementor.py # build/elementor-accueil.json
```

Puis sur le site : extraire le zip dans `wp-content/themes/`, déposer le JSON
dans `wp-content/cx-tmp/elementor-accueil.json` et exécuter
`wordpress/deploy_elementor.php` (Novamira, « execute-php »).

Application :

```bash
flutter build web --release --base-href /app/ --output build/web-app
```

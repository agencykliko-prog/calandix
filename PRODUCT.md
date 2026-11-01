# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter (Dart 3), Riverpod, go_router. v1 de validation : données fictives locales, aucun backend. Supabase prévu ensuite (cahier des charges). Prévisualisation locale via Flutter web.

## Users

Organisateurs particuliers et professionnels en Côte d'Ivoire (puis Afrique francophone) qui préparent un mariage, un anniversaire, un baby shower, un EVJF, une sortie ou un événement pro, souvent à plusieurs (co-organisateurs, familles). Usage mobile prioritaire, connexions variables.

## Product Purpose

Calandix — « Le budget parfait pour célébrer ». Centraliser l'organisation d'un événement : budget (cible, prévu, engagé, payé, reste), tâches et rétroplanning, prestataires (devis, réservation, paiement), invités/RSVP et coordination de l'équipe en temps réel. La v1 valide le parcours accueil → dashboard.

## Positioning

Le budget est au centre : chaque réservation met à jour l'engagé, chaque paiement le payé, avec le FCFA comme devise par défaut et le mobile money comme moyen de paiement local. Un socle commun de dashboard qui s'adapte à la catégorie d'événement (couleur, vocabulaire, modules spécifiques) plutôt qu'un dashboard par type.

## Operating Context

Chaque événement a son propre espace (budget, tâches, prestataires, invités, documents). Widgets d'accueil communs : prochaine tâche urgente, dernier paiement dû, RSVP du jour, météo du jour J à J-7, activité récente de l'équipe. Contact prestataire en un clic via WhatsApp.

## Capabilities and Constraints

- Sources : `Cahier_des_charges_plateforme_evenementielle.docx`, `Fonctionnalités des dashboards par type d'événement.docx`.
- v1 : onboarding, connexion simulée, accueil multi-événements, dashboard d'événement, budget, tâches, prestataires, équipe — données de démo pour plusieurs types d'événements (mariage, anniversaire, baby shower).
- Hors v1 : paiements réels, marketplace complète, back-office, dashboard prestataire.
- Le nom « Calandix » (anciennement Eventa) : validation juridique à confirmer.

## Brand Commitments

- Nom : Calandix (anciennement Eventa). Slogan : « Le budget parfait pour célébrer ».
- Logo : fichier fourni, déclinaisons dans `landing/img/calandix-*.svg` et `assets/brand/` ; ne pas le redessiner.
- Mascotte : la fourmi rouge (`assets/images/mascots/`), huit poses.
- Couleurs officielles : rouge #E01928, mangue #E59D1F, violet #4D39E2 (principal), turquoise #2CE5B9 ; encre #1A0637, fond #F7F5F2. Thèmes personnalisables dans Compte.
- Ton : tech, moderne, accessible, rassurant, convivial.
- Références d'inspiration citées par l'utilisateur : Luma (iOS), Structured (iOS).

## Evidence on Hand

Photos Unsplash dans `eventa/assets/images/`. Aucun témoignage, client ou chiffre réel : ne pas en inventer en dehors des données de démo clairement fictives.

## Product Principles

1. Le budget doit toujours être lisible en un coup d'œil, avec la formule explicitée.
2. Un événement = un espace ; jamais de mélange entre projets.
3. Mobile d'abord, rapide sur réseau faible.
4. L'émotion de la fête, la fiabilité d'un outil financier.

## Accessibility & Inclusion

Contrastes suffisants (notamment textes sur jaune/turquoise), couleurs d'état distinctes des couleurs de marque, tailles de texte lisibles en petits formats.

# Calandix

**Le budget parfait pour célébrer.**

Application d'organisation d'événements (Côte d'Ivoire, FCFA) : budget, planification des tâches, marketplace de prestataires, réservations, paiements et coordination d'équipe. Trois espaces : **Organisateur**, **Creator** (prestataires, agences) et **centre de contrôle** de l'équipe Calandix.

> Version de démonstration : données fictives locales, connexion simulée, paiements et agent IA simulés. Aucun backend n'est encore branché (Supabase prévu).

## Fonctionnalités

- **Organisateur** : accueil avec la mascotte, dashboard par événement, budget éditable avec répartition et export CSV, agenda Jour / Semaine / Mois, marketplace avec filtres et demande de devis, réservation en 7 étapes, collaborateurs avec droits, suggestions Premium contextuelles. Avec abonnement ou Pass Événement : invitations numériques avec lien de réponse personnel (présence, accompagnants, régime) et QR code d'entrée, contrôle des entrées le jour J, rappels WhatsApp et SMS automatiques (quota mensuel), assistant IA et comparaison assistée des devis (analyse des écarts), Concierge Calandix (demandes de devis pré-remplies, suivi des réservations), album privé photos et vidéos avec vue invité, coffre-fort avec dossier Inspirations, suivi de l'avancement de chaque collaborateur, assistance prioritaire (Privilège, Pass). Le Pass applique ses plafonds (2 000 invités, 30 collaborateurs). Page de l'événement pour les invités (programme, lieu et itinéraire, hébergements, FAQ), contrat de prestation signé électroniquement dans la réservation, statistiques du budget (prévu face au réel, comparaison avec des événements similaires), contrôle des entrées en mode hors ligne, notifications push réglables par type (devis reçu, acompte payé, rappel J-1).
- **Creator – espace pro** (`/pro/...`) : profil et catalogue (logo, forfaits avec conditions propres, options, conditions de vente, autres activités en Business), disponibilités (dates bloquées, capacité, anti-double réservation, synchronisation Google Agenda et export .ics), modèles de devis par type d'événement et relance automatique des devis sans réponse, notifications push (nouvelle demande, acompte payé, rappel J-1), devis détaillés avec questions au client, suivi des commandes en 7 statuts (de la demande à la clôture), revenus et reversements (relevés CSV), réputation et performance, badges (abonnement, vérification, qualité) visibles sur la fiche publique, statistiques commerciales et historique des clients (dès Starter), Studio avec atelier de création (dès Creator), équipe multi-utilisateurs avec droits appliqués par rôle : commercial, responsable, comptable, administrateur (Business).
- **Centre de contrôle** (`/admin`) : vue d'ensemble temps réel et 10 modules (comptes, vérification des prestataires, catalogue, réservations et litiges, paiements, modèle économique, marketing, service client, analytics, rôles et sécurité avec journal d'audit).
- Mascotte animée (connexion, accueil, compte, agenda, chargements), mode sombre, français / anglais, effets sonores.
- Pages À propos et Politique de confidentialité (brouillon à valider par un juriste).
- Inscription et connexion pour les deux profils, photo de profil avec recadrage.
- Interface responsive : barre d'onglets sur mobile, rail latéral sur tablette et ordinateur.

## Tester sur mobile

Après `flutter build web --release`, servir `build/web` sur le réseau local (port 8080), puis scanner les QR codes générés à la racine du dossier projet (`eventa_qr_demo.html`).

## Stack

Flutter (Dart 3) · Riverpod · go_router · Inter · icônes Phosphor (polices embarquées).

## Lancer le projet

```bash
flutter pub get
flutter run -d chrome
```

Tests et analyse :

```bash
flutter analyze
flutter test
```

Version web :

```bash
flutter build web --release
```

## Structure

Un seul code Flutter sert le web et le mobile ; seul ce qui dépend vraiment
de la plateforme est isolé dans `platform/`.

```
lib/
  main.dart      démarrage (Supabase, formats de date)
  app/           application et routeur (routes, garde d'accès)
  core/          socle sans interface
    auth/        session, profil, passerelle d'authentification
    backend/     client Supabase
    config/      configuration (URL, clé publishable)
    models/      modèles de domaine partagés (événement, budget,
                 prestataires, invités, équipe et droits)
    prefs/, i18n/, analytics/, sound/, utils/
  ui/            design system
    theme/       couleurs, typographie, icônes, mouvement
    widgets/     composants (boutons, panneaux, formulaires, mascotte…)
    dataviz/     kit commun des tableaux de bord : KpiCard, KpiGrid,
                 BarChart, Sparkline, Donut, LiveDot
  features/      un dossier par domaine (events, budget, planning, booking,
                 marketplace, pro, premium, notifications, …), en
                 data / domain / presentation
  admin/         console d'administration (web)
  platform/
    web/         implémentations navigateur (téléchargement, liens, préférences)
    mobile/      implémentations hors navigateur
supabase/        migrations et Edge Functions (Deno)
test/            tests unitaires et de widgets
```

Règles de dépendance :
- `core/` n'importe jamais `features/` ni `admin/`. Seule exception admise :
  `ui/theme/` (les modèles portent leur icône et leur couleur).
- `ui/theme/` n'importe rien du projet hormis `core/i18n/`.
- Un indicateur ou un graphique de tableau de bord vient toujours de
  `ui/dataviz/` (organisateur, espace pro et administration).

Le contexte produit est décrit dans [PRODUCT.md](PRODUCT.md).

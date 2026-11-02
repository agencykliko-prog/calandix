# Calandix — tâches à effectuer

État au 2 novembre 2026, commit `393e9a9` (`main` et `refacto/architecture`).
Cochez au fur et à mesure.

## 1. Informations à fournir (bloquant avant la campagne)

Les textes légaux sont en ligne mais contiennent encore des champs entre crochets.

- [ ] **Raison sociale** de l'éditeur
- [ ] **Siège social**
- [ ] **Numéro RCCM**
- [ ] **Contact du délégué à la protection des données** : adresse e-mail et adresse postale

Emplacements à compléter :
- `lib/features/about/presentation/terms_screen.dart` (l. 29-30, FR et EN)
- `lib/features/about/presentation/privacy_screen.dart` (l. 39-40 et 201, FR et EN)

- [ ] **URL des réseaux sociaux** : Facebook, Instagram, TikTok
  (aujourd'hui `href="#"` dans `landing/index.html`, l. 455-457 ; seul WhatsApp est actif)

## 2. Backend Supabase (à faire depuis votre tableau de bord)

- [ ] Exécuter la migration `supabase/migrations/20261101000700_acces_anticipe_email.sql`
- [ ] Exécuter la migration `supabase/migrations/20261102000800_signature_securite.sql`
  (table `creator_signatures`, lisible par son seul propriétaire)
- [ ] Redéployer la fonction `saspay-checkout` (nouvelle offre Signature à 4 900 F)
- [ ] Ajouter votre compte dans `admin_members` pour accéder à l'espace admin
- [ ] Vérifier que les modèles d'e-mails (`supabase/templates/*.html`) sont bien chargés dans Auth

## 3. Vérifications avant le lancement de la campagne

Non testé jusqu'ici :
- [ ] Site en ligne (calandix.netlify.app) après le dernier déploiement Netlify
- [ ] Formulaire d'accès anticipé : envoi réel et réception de la ligne en base
- [ ] Bandeau « Inscrivez-vous via le formulaire » qui mène bien au formulaire
- [ ] Safari et Firefox
- [ ] Vrais téléphones (Android et iPhone)
- [ ] Connexion admin réelle
- [ ] Connexion Supabase sous la politique de sécurité (CSP) en production
- [ ] Nom de domaine : eventa.ci ne pointe pas encore vers le site (conservé pour l'instant)

## 4. Améliorations proposées (non demandées, à décider)

- [ ] Rediriger tous les boutons d'appel à l'action vers le formulaire d'accès anticipé
- [ ] Suivi des sources de la campagne (paramètres UTM)
- [ ] Protection anti-spam du formulaire
- [ ] Retirer les prestataires fictifs de la marketplace avant le lancement
- [ ] Rôles admin réels (distinguer les niveaux d'accès)

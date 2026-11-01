import '../../commerce/domain/commerce_models.dart';

/// Réponses de Candix : une base locale de questions fréquentes. Quand la
/// question sort de cette base, Candix oriente vers un conseiller plutôt que
/// d'inventer une réponse.
class _Entry {
  const _Entry(this.keywords, this.answer);
  final List<String> keywords;
  final String Function() answer;
}

const candixSuggestions = [
  'Comment créer un événement ?',
  'Comment fonctionne le budget ?',
  'Combien coûtent les formules ?',
  'Comment payer un prestataire ?',
];

final _entries = <_Entry>[
  _Entry(
    ['creer', 'nouvel', 'evenement', 'commencer'],
    () => 'Touchez « Créer un événement » sur l’accueil, choisissez le type et la catégorie, puis la date, le nombre d’invités et le budget. Calandix prépare la checklist et répartit le budget.',
  ),
  _Entry(
    ['budget', 'depense', 'poste', 'reste', 'enveloppe'],
    () => 'Dans votre événement, ouvrez Budget : fixez un budget cible, répartissez-le par poste et notez chaque paiement. Chaque devis accepté met à jour l’engagé, chaque paiement le payé.',
  ),
  _Entry(
    [
      'tarif',
      'prix',
      'formule',
      'abonnement',
      'premium',
      'coute',
      'cout',
      'azur',
      'signature',
      'privilege',
    ],
    () =>
        'Formules organisateur : Découverte gratuite, Azur ${Plan.azur.price} FCFA, Signature ${Plan.signature.price} FCFA et Privilège ${Plan.privilege.price} FCFA par mois. L’offre Creator des prestataires part de 29 900 FCFA par mois.',
  ),
  _Entry(
    [
      'payer',
      'paiement',
      'acompte',
      'wave',
      'orange',
      'mtn',
      'moov',
      'mobile money',
      'carte',
      'rembours',
    ],
    () => 'Les paiements passent par Mobile Money ou carte. L’acompte est conservé jusqu’à la validation de la prestation, puis reversé au prestataire.',
  ),
  _Entry(
    [
      'prestataire',
      'traiteur',
      'dj',
      'photographe',
      'decor',
      'salle',
      'devis',
      'reserver',
      'reservation',
      'agence',
    ],
    () => 'Dans Explorer, cherchez dès trois lettres ou filtrez par catégorie et par zone. Demandez des devis, comparez-les dans votre événement, puis choisissez et réservez.',
  ),
  _Entry(
    ['invite', 'rsvp', 'presence', 'confirme', 'relance', 'whatsapp'],
    () => 'Dans votre événement, section Invités & RSVP : ajoutez vos invités, leur réponse et leurs accompagnants. Vous voyez d’un coup d’œil le nombre de personnes attendues.',
  ),
  _Entry(
    ['tache', 'planning', 'retroplanning', 'rappel', 'agenda', 'etape'],
    () => 'Chaque événement a son rétroplanning : les tâches sont classées par échéance et l’Agenda les regroupe, tous événements confondus.',
  ),
  _Entry(
    [
      'equipe',
      'collaborateur',
      'co-organisateur',
      'droit',
      'partager',
      'acces',
    ],
    () => 'Dans votre événement, « Gérer les accès » permet d’inviter des collaborateurs et de régler leurs droits : budget, tâches, prestataires, invités, paiements.',
  ),
  _Entry(
    ['theme', 'couleur', 'sombre', 'langue', 'anglais', 'son'],
    () => 'Tout se règle dans Compte : couleur du thème, mode sombre, langue et sons.',
  ),
  _Entry(
    [
      'mot de passe',
      'connexion',
      'compte',
      'inscription',
      'connecter',
      'photo',
    ],
    () => 'Mot de passe oublié : utilisez le lien sur l’écran de connexion. Votre profil se modifie dans Compte.',
  ),
  _Entry(
    [
      'creator',
      'commission',
      'reversement',
      'revenu',
      'verification',
      'verifie',
    ],
    () => 'Côté prestataire : commission de 8 % sur chaque prestation payée via l’application, reversement sur votre mobile money, et vérification du dossier pour obtenir le badge.',
  ),
  _Entry([
    'bonjour',
    'bonsoir',
    'salut',
    'merci',
    'hello',
  ], () => 'Avec plaisir ! Dites-moi ce que vous cherchez à faire.'),
];

String _clean(String s) {
  const from = 'àâäéèêëîïôöùûüç’';
  const to = 'aaaeeeeiioouuuc\'';
  var out = s.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out;
}

/// La réponse la plus proche de la question, ou l'orientation vers un conseiller.
String candixAnswer(String question) {
  final q = _clean(question);
  _Entry? best;
  var score = 0;
  for (final e in _entries) {
    final s = e.keywords.where(q.contains).length;
    if (s > score) {
      score = s;
      best = e;
    }
  }
  return best?.answer() ??
      'Je n’ai pas encore la réponse à cette question. Un conseiller peut vous aider : touchez « Parler à un conseiller » juste en dessous.';
}

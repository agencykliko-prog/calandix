import 'package:flutter/widgets.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/models/models.dart';

// ─── Paiements ──────────────────────────────────────────────────────────

enum PayMethod {
  orange('Orange Money', AppIcons.mobile, Color(0xFFFF7900), true),
  mtn('MTN Money', AppIcons.mobile, Color(0xFFFFCB05), true),
  wave('Wave', AppIcons.mobile, Color(0xFF1DC4FF), true),
  moov('Moov Money', AppIcons.mobile, Color(0xFF0066B3), true),
  card('Carte bancaire', AppIcons.card, Color(0xFF6B5E8A), false),
  applePay('Apple Pay', AppIcons.apple, Color(0xFF6B5E8A), false),
  googlePay('Google Pay', AppIcons.google, Color(0xFF6B5E8A), false);

  const PayMethod(this._label, this.icon, this.dot, this.mobileMoney);
  final String _label;
  String get label => _label.tr;
  final IconData icon;

  /// Couleur d'appoint de l'opérateur.
  final Color dot;
  final bool mobileMoney;

  /// Logo officiel du moyen de paiement, quand on l'a.
  String? get logo => switch (this) {
    PayMethod.orange => 'assets/images/pay/orange-money.webp',
    PayMethod.mtn => 'assets/images/pay/momo.webp',
    PayMethod.wave => 'assets/images/pay/wave.webp',
    PayMethod.moov => 'assets/images/pay/moov.webp',
    PayMethod.card => 'assets/images/pay/visa.webp',
    _ => null,
  };
}

@immutable
class Receipt {
  const Receipt({
    required this.ref,
    required this.label,
    required this.amount,
    required this.method,
    required this.date,
    required this.payee,
    this.fees = 0,
  });

  final String ref;
  final String label;
  final int amount;
  final int fees;
  final PayMethod method;
  final DateTime date;
  final String payee;

  int get total => amount + fees;
}

// ─── Réservation : 7 étapes ─────────────────────────────────────────────

enum BookingStep {
  selected('Choix', 'Prestataire choisi'),
  requested('Demande', 'Devis demandé'),
  quoted('Devis', 'Devis reçu'),
  reserved('Résa.', 'Date bloquée'),
  paid('Paiement', 'Acompte réglé'),
  executing('Exécution', 'Préparation en cours'),
  closed('Clôture', 'Dossier clôturé');

  const BookingStep(this._label, this._status);
  final String _label;
  String get label => _label.tr;
  final String _status;
  String get status => _status.tr;
}

@immutable
class QuoteRequest {
  const QuoteRequest({
    required this.date,
    required this.guests,
    required this.message,
    this.options = const [],
    this.budget,
  });

  final DateTime date;
  final int guests;
  final String message;
  final List<String> options;
  final int? budget;
}

@immutable
class QuoteLine {
  const QuoteLine(this.label, this.amount, {this.optional = false});
  final String label;
  final int amount;
  final bool optional;
}

@immutable
class Quote {
  const Quote({
    required this.lines,
    required this.conditions,
    required this.fees,
    required this.validUntil,
    this.depositRate = 0.3,
    this.lastOffer = false,
  });

  final List<QuoteLine> lines;
  final List<String> conditions;

  /// Frais de service plateforme.
  final int fees;
  final DateTime validUntil;
  final double depositRate;

  /// Le prestataire a déjà fait sa dernière offre sur ce devis.
  final bool lastOffer;

  int get subtotal => lines.fold(0, (s, l) => s + l.amount);
  int get total => subtotal + fees;
  int get deposit => (total * depositRate / 500).round() * 500;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.fromMe,
    required this.text,
    required this.at,
  });
  final bool fromMe;
  final String text;
  final DateTime at;
}

@immutable
class Booking {
  const Booking({
    required this.id,
    required this.vendor,
    required this.eventId,
    required this.step,
    required this.request,
    required this.createdAt,
    this.quote,
    this.paidAmount = 0,
    this.receipts = const [],
    this.messages = const [],
    this.payoutDone = false,
    this.rating,
    this.archived = false,
  });

  final String id;
  final Vendor vendor;
  final String eventId;
  final BookingStep step;
  final QuoteRequest request;
  final DateTime createdAt;
  final Quote? quote;
  final int paidAmount;
  final List<Receipt> receipts;
  final List<ChatMessage> messages;
  final bool payoutDone;
  final int? rating;
  final bool archived;

  int get balance => (quote?.total ?? 0) - paidAmount;
  bool get fullyPaid => quote != null && balance <= 0;

  Booking copyWith({
    BookingStep? step,
    Quote? quote,
    int? paidAmount,
    List<Receipt>? receipts,
    List<ChatMessage>? messages,
    bool? payoutDone,
    int? rating,
    bool? archived,
  }) => Booking(
    id: id,
    vendor: vendor,
    eventId: eventId,
    step: step ?? this.step,
    request: request,
    createdAt: createdAt,
    quote: quote ?? this.quote,
    paidAmount: paidAmount ?? this.paidAmount,
    receipts: receipts ?? this.receipts,
    messages: messages ?? this.messages,
    payoutDone: payoutDone ?? this.payoutDone,
    rating: rating ?? this.rating,
    archived: archived ?? this.archived,
  );
}

// ─── Abonnements ────────────────────────────────────────────────────────

enum Plan {
  free('Découverte', 0, Hues.ink),
  azur('Azur', 1500, Hues.lagoon),
  signature('Signature', 2900, Hues.violet),
  privilege('Privilège', 5900, Hues.gold);

  const Plan(this._label, this.price, this._hue);
  final String _label;
  String get label => _label.tr;
  final int price;
  final Hues _hue;
  Hue get hue => _hue.hue;

  /// Formule annuelle : deux mois offerts, soit dix mois payés.
  int get yearlyPrice => price * 10;

  bool includes(Plan other) => index >= other.index;

  /// Espace du coffre-fort : 1 Go offert, davantage avec un abonnement.
  int get vaultMb => switch (this) {
    Plan.free => 1024,
    Plan.azur => 5 * 1024,
    Plan.signature => 10 * 1024,
    Plan.privilege => 20 * 1024,
  };

  /// Événements à venir en même temps ; sans limite avec un abonnement.
  int? get activeEvents => this == Plan.free ? 4 : null;

  String get vaultLabel => vaultMb >= 1024
      ? '{0} Go'.trf([vaultMb ~/ 1024])
      : '{0} Mo'.trf([vaultMb]);
}

// ─── Formules prestataires (pack prestataire) ───────────────────────────

/// Formules de l'espace pro. Plus la formule monte, plus la commission
/// prélevée sur les sommes encaissées via Calandix baisse.
enum ProPlan {
  decouverte(
    'Découverte',
    0,
    0.08,
    5,
    Hues.ink,
    'Pour rejoindre la marketplace et présenter votre activité.',
  ),
  starter(
    'Starter',
    4900,
    0.07,
    15,
    Hues.lagoon,
    'Pour professionnaliser votre présence.',
  ),
  creator(
    'Creator',
    14900,
    0.05,
    null,
    Hues.violet,
    'Pour développer votre clientèle.',
  ),
  business(
    'Business',
    29900,
    0.03,
    null,
    Hues.gold,
    'Pour les agences et entreprises événementielles.',
  );

  const ProPlan(
    this._label,
    this.price,
    this.commission,
    this.catalogLimit,
    this._hue,
    this._pitch,
  );

  final String _label;
  String get label => _label.tr;
  final int price;

  /// Part prélevée sur chaque encaissement effectif (0,08 = 8 %).
  final double commission;

  /// Prestations au catalogue ; null = sans limite.
  final int? catalogLimit;
  final Hues _hue;
  Hue get hue => _hue.hue;
  final String _pitch;
  String get pitch => _pitch.tr;

  int get commissionPercent => (commission * 100).round();

  /// Formule annuelle : dix mensualités pour douze mois d'accès.
  int get yearlyPrice => price * 10;
  int get yearlySaving => price * 2;

  bool get free => price == 0;
  bool includes(ProPlan other) => index >= other.index;

  /// Le Studio professionnel est ouvert à partir de Creator.
  bool get studio => includes(ProPlan.creator);

  /// Montant encaissé par mois à partir duquel la baisse de commission
  /// rembourse l'abonnement (comparé à Découverte).
  int? get breakEven => free
      ? null
      : (price / (ProPlan.decouverte.commission - commission)).round();

  /// Ce que la formule apporte de plus que la précédente.
  List<String> get features => switch (this) {
    ProPlan.decouverte => [
      'Profil professionnel, photos et réalisations'.tr,
      'Jusqu’à 5 prestations au catalogue'.tr,
      'Demandes et envoi de devis'.tr,
      'Disponibilités, commandes et réservations'.tr,
      'Avis clients vérifiés'.tr,
    ],
    ProPlan.starter => [
      'Jusqu’à 15 prestations au catalogue'.tr,
      'Galerie enrichie et profil personnalisé'.tr,
      'Devis avancés et suivi des demandes'.tr,
      'Statistiques de consultation et historique clients'.tr,
      'Badge Starter'.tr,
    ],
    ProPlan.creator => [
      'Catalogue étendu, sans limite'.tr,
      'Studio professionnel Calandix'.tr,
      'Visibilité renforcée dans les résultats pertinents'.tr,
      'Statistiques commerciales, acomptes et reversements'.tr,
      'Outils de gestion de la réputation'.tr,
    ],
    ProPlan.business => [
      'Plusieurs collaborateurs avec droits d’accès'.tr,
      'Plusieurs activités ou catégories'.tr,
      'Analyse des ventes et suivi commercial'.tr,
      'Mise en avant commerciale renforcée'.tr,
      'Assistance prioritaire'.tr,
    ],
  };
}

/// Options de visibilité ponctuelles, ouvertes à toutes les formules, y
/// compris Découverte. Toujours signalées « Sponsorisé ».
enum ProBoost {
  profile(
    'Boost de profil',
    1500,
    7,
    AppIcons.rocket,
    'Votre profil mis en avant pendant 7 jours.',
  ),
  search(
    'Boost de recherche',
    2500,
    7,
    AppIcons.search,
    'En tête de votre catégorie, signalé « Sponsorisé ».',
  ),
  featured(
    'Prestataire à la une',
    3500,
    7,
    AppIcons.star,
    'Un emplacement éditorial sur l’accueil des organisateurs.',
  ),
  campaign(
    'Campagne promotionnelle',
    5000,
    null,
    AppIcons.megaphone,
    'Une prestation, une offre spéciale ou une promotion mise en avant.',
  );

  const ProBoost(this._label, this.price, this.days, this.icon, this._desc);
  final String _label;
  String get label => _label.tr;

  /// Prix indicatif ; « dès » ce montant pour une campagne.
  final int price;

  /// Durée en jours ; null = selon la campagne.
  final int? days;
  final IconData icon;
  final String _desc;
  String get description => _desc.tr;
}

/// Services réalisés par l'équipe Calandix, facturés à part. Prix null :
/// sur devis.
const proServices = <(String, int?, IconData)>[
  ('Création de profil professionnel', 5000, AppIcons.user),
  ('Création de catalogue numérique', 10000, AppIcons.images),
  ('Shooting photo professionnel', null, AppIcons.camera),
  ('Création de contenus promotionnels', null, AppIcons.palette),
  ('Accompagnement marketing', null, AppIcons.target),
];

/// Fonctionnalités soumises à un abonnement, et le niveau minimal requis.
enum PremiumFeature {
  events('Plus de 4 événements actifs', Plan.azur, AppIcons.calendarPlus),
  collaborators('Plus de 2 collaborateurs', Plan.azur, AppIcons.userPlus),
  agent('Agent IA de votre événement', Plan.signature, AppIcons.sparkle),
  vault('Coffre-fort au-delà de 1 Go', Plan.azur, AppIcons.lock);

  const PremiumFeature(this._label, this.minPlan, this.icon);
  final String _label;
  String get label => _label.tr;
  final Plan minPlan;
  final IconData icon;
}

// ─── Coffre-fort ────────────────────────────────────────────────────────

enum VaultFolder {
  contracts('Contrats', AppIcons.contract),
  quotes('Devis', AppIcons.file),
  invoices('Factures & reçus', AppIcons.invoice),
  photos('Photos', AppIcons.images),
  certificates('Certificats', AppIcons.certificate),
  documents('Documents', AppIcons.folder);

  const VaultFolder(this._label, this.icon);
  final String _label;
  String get label => _label.tr;
  final IconData icon;
}

@immutable
class VaultDoc {
  const VaultDoc({
    required this.name,
    required this.folder,
    required this.sizeKb,
    required this.date,
    this.eventId,
  });

  final String name;
  final VaultFolder folder;
  final int sizeKb;
  final DateTime date;
  final String? eventId;
}

extension BookingEventX on Booking {
  bool belongsTo(Event e) => eventId == e.id;
}

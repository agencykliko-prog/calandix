import 'package:flutter/foundation.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';

// Modèles de l'espace professionnel du Creator (démo locale).

// ─── Profil & catalogue ─────────────────────────────────────────────────

/// Forfait vendu par le prestataire.
@immutable
class ProPackage {
  const ProPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.includes,
    this.unit = 'forfait',
    this.active = true,
    this.conditions = '',
    this.activity,
  });

  final String id;
  final String name;
  final int price;
  final List<String> includes;

  /// Conditions propres à cette offre (acompte, délai, nombre d'invités…),
  /// en plus des conditions de vente générales.
  final String conditions;

  /// Activité à laquelle l'offre est rattachée (formule Business) ;
  /// `null` : l'activité principale.
  final VendorCategory? activity;

  /// « forfait », « par invité », « par heure »…
  final String unit;
  final bool active;

  ProPackage copyWith({
    String? name,
    int? price,
    List<String>? includes,
    String? unit,
    bool? active,
    String? conditions,
    VendorCategory? activity,
    bool clearActivity = false,
  }) => ProPackage(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    includes: includes ?? this.includes,
    unit: unit ?? this.unit,
    active: active ?? this.active,
    conditions: conditions ?? this.conditions,
    activity: clearActivity ? null : activity ?? this.activity,
  );
}

/// Option proposée en supplément d'un forfait.
@immutable
class ProOption {
  const ProOption({
    required this.id,
    required this.name,
    required this.price,
    this.active = true,
  });

  final String id;
  final String name;
  final int price;
  final bool active;

  ProOption copyWith({String? name, int? price, bool? active}) => ProOption(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    active: active ?? this.active,
  );
}

/// Conditions de vente appliquées par défaut aux devis.
@immutable
class SaleTerms {
  const SaleTerms({
    this.depositPercent = 30,
    this.balanceDaysBefore = 7,
    this.freeCancelDays = 30,
    this.quoteValidityDays = 7,
    this.travelFee = 15000,
    this.lastOfferPercent = 7,
    this.notes = 'Matériel fourni et repris par nos soins. Accès au lieu 3 h avant le début.',
  });

  final int depositPercent;

  /// Solde dû N jours avant la prestation.
  final int balanceDaysBefore;

  /// Annulation gratuite jusqu'à N jours avant.
  final int freeCancelDays;
  final int quoteValidityDays;

  /// Frais de déplacement hors zone, en FCFA.
  final int travelFee;

  /// Dernière offre : remise maximale consentie sur un devis, en %.
  final int lastOfferPercent;
  final String notes;

  SaleTerms copyWith({
    int? depositPercent,
    int? balanceDaysBefore,
    int? freeCancelDays,
    int? quoteValidityDays,
    int? travelFee,
    int? lastOfferPercent,
    String? notes,
  }) => SaleTerms(
    depositPercent: depositPercent ?? this.depositPercent,
    balanceDaysBefore: balanceDaysBefore ?? this.balanceDaysBefore,
    freeCancelDays: freeCancelDays ?? this.freeCancelDays,
    quoteValidityDays: quoteValidityDays ?? this.quoteValidityDays,
    travelFee: travelFee ?? this.travelFee,
    lastOfferPercent: lastOfferPercent ?? this.lastOfferPercent,
    notes: notes ?? this.notes,
  );
}

@immutable
class ProCatalog {
  const ProCatalog({
    required this.portfolio,
    required this.zones,
    required this.categories,
    required this.packages,
    required this.options,
    this.terms = const SaleTerms(),
    this.logo,
    this.activities = const [],
  });

  /// Logo importé par le prestataire (affiché sur la fiche publique).
  final Uint8List? logo;

  /// Activités supplémentaires (formule Business) : le prestataire apparaît
  /// aussi dans ces catégories.
  final List<VendorCategory> activities;

  /// Photos (assets) mises en avant sur la fiche publique.
  final List<String> portfolio;
  final List<String> zones;

  /// Catégories secondaires (la principale est sur le profil).
  final List<String> categories;
  final List<ProPackage> packages;
  final List<ProOption> options;
  final SaleTerms terms;

  ProCatalog copyWith({
    List<String>? portfolio,
    List<String>? zones,
    List<String>? categories,
    List<ProPackage>? packages,
    List<ProOption>? options,
    SaleTerms? terms,
    Uint8List? logo,
    bool clearLogo = false,
    List<VendorCategory>? activities,
  }) => ProCatalog(
    portfolio: portfolio ?? this.portfolio,
    zones: zones ?? this.zones,
    categories: categories ?? this.categories,
    packages: packages ?? this.packages,
    options: options ?? this.options,
    terms: terms ?? this.terms,
    logo: clearLogo ? null : logo ?? this.logo,
    activities: activities ?? this.activities,
  );
}

// ─── Disponibilités ─────────────────────────────────────────────────────

@immutable
class Availability {
  const Availability({
    this.blocked = const {},
    this.capacityPerDay = 2,
    this.preventDouble = true,
  });

  /// Jours fermés à la réservation (congés, maintenance…).
  final Set<DateTime> blocked;

  /// Prestations maximum qu'on peut assurer le même jour.
  final int capacityPerDay;

  /// Refuser automatiquement les demandes sur les jours complets.
  final bool preventDouble;

  Availability copyWith({
    Set<DateTime>? blocked,
    int? capacityPerDay,
    bool? preventDouble,
  }) => Availability(
    blocked: blocked ?? this.blocked,
    capacityPerDay: capacityPerDay ?? this.capacityPerDay,
    preventDouble: preventDouble ?? this.preventDouble,
  );
}

// ─── Commandes & prestations ────────────────────────────────────────────

/// Étapes d'une commande après l'acceptation du devis. Avec « Nouvelle
/// demande » et « Devis envoyé » (côté demandes), elles forment les
/// 7 statuts du suivi : le jour J est un repère dans « Prestation confirmée ».
enum OrderStage {
  accepted('Devis accepté'),
  confirmed('Acompte payé'),
  preparing('Prestation confirmée'),
  delivering('Jour J'),
  done('Prestation réalisée'),
  closed('Commande clôturée');

  const OrderStage(this._label);
  final String _label;
  String get label => _label.tr;
}

/// Suivi d'une commande confirmée (clé : identifiant de la demande).
@immutable
class OrderProgress {
  const OrderProgress({
    this.stage = OrderStage.accepted,
    this.checked = const {},
    this.note,
  });

  final OrderStage stage;

  /// Exigences du client déjà traitées (index de la liste).
  final Set<int> checked;
  final String? note;

  OrderProgress copyWith({
    OrderStage? stage,
    Set<int>? checked,
    String? note,
  }) => OrderProgress(
    stage: stage ?? this.stage,
    checked: checked ?? this.checked,
    note: note ?? this.note,
  );
}

// ─── Revenus & reversements ─────────────────────────────────────────────

enum PayoutStatus {
  scheduled('Programmé'),
  sent('Effectué');

  const PayoutStatus(this._label);
  final String _label;
  String get label => _label.tr;
}

@immutable
class Payout {
  const Payout({
    required this.ref,
    required this.label,
    required this.gross,
    required this.commission,
    required this.date,
    required this.status,
    this.method = 'Wave',
  });

  final String ref;
  final String label;

  /// Montant payé par le client pour la prestation.
  final int gross;

  /// Commission Calandix prélevée.
  final int commission;
  final DateTime date;
  final PayoutStatus status;
  final String method;

  int get net => gross - commission;

  Payout copyWith({PayoutStatus? status, DateTime? date}) => Payout(
    ref: ref,
    label: label,
    gross: gross,
    commission: commission,
    date: date ?? this.date,
    status: status ?? this.status,
    method: method,
  );
}

// ─── Réputation ─────────────────────────────────────────────────────────

@immutable
class ProReview {
  const ProReview({
    required this.id,
    required this.author,
    required this.event,
    required this.rating,
    required this.text,
    required this.date,
    this.reply,
    this.avatar,
  });

  final String id;
  final String author;
  final String event;
  final int rating;
  final String text;
  final DateTime date;
  final String? reply;
  final String? avatar;

  ProReview withReply(String r) => ProReview(
    id: id,
    author: author,
    event: event,
    rating: rating,
    text: text,
    date: date,
    reply: r,
    avatar: avatar,
  );
}

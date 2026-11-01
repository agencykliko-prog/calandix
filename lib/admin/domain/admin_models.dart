import 'package:flutter/foundation.dart';

// Modèles du centre de contrôle Calandix (exploitant de la plateforme).
// Démo : données fictives, aucune donnée réelle.

// ─── Rôles et permissions ───────────────────────────────────────────────

enum AdminPermission {
  overview('Voir la vue d’ensemble (chiffres clés)'),
  accounts('Gérer les comptes'),
  verification('Vérifier les prestataires'),
  catalog('Administrer le catalogue'),
  bookings('Gérer réservations et litiges'),
  payments('Contrôler paiements et remboursements'),
  pricing('Paramétrer le modèle économique'),
  marketing('Gérer marketing et fidélisation'),
  support('Traiter le service client'),
  analytics('Consulter les analytics'),
  security('Gérer rôles, sécurité et paramètres');

  const AdminPermission(this.label);
  final String label;
}

enum AdminRole {
  superAdmin('Super administrateur', 'Tous les droits'),
  finance('Finance', 'Paiements, revenus, modèle économique'),
  moderation('Modération', 'Comptes, prestataires, catalogue'),
  support('Service client', 'Tickets, réservations, litiges'),
  marketing('Marketing', 'Campagnes, codes promo, analytics');

  const AdminRole(this.label, this.scope);
  final String label;
  final String scope;
}

/// Permissions par défaut de chaque rôle (modifiables dans Sécurité).
Map<AdminRole, Set<AdminPermission>> defaultPermissions() => {
  AdminRole.superAdmin: AdminPermission.values.toSet(),
  AdminRole.finance: {
    AdminPermission.overview,
    AdminPermission.payments,
    AdminPermission.pricing,
    AdminPermission.bookings,
    AdminPermission.analytics,
  },
  AdminRole.moderation: {
    AdminPermission.accounts,
    AdminPermission.verification,
    AdminPermission.catalog,
  },
  AdminRole.support: {
    AdminPermission.support,
    AdminPermission.bookings,
    AdminPermission.accounts,
  },
  AdminRole.marketing: {AdminPermission.marketing, AdminPermission.analytics},
};

@immutable
class AdminMember {
  const AdminMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.twoFactor = true,
    this.active = true,
  });

  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final bool twoFactor;
  final bool active;

  AdminMember copyWith({AdminRole? role, bool? active}) => AdminMember(
    id: id,
    name: name,
    email: email,
    role: role ?? this.role,
    twoFactor: twoFactor,
    active: active ?? this.active,
  );
}

// ─── Comptes ────────────────────────────────────────────────────────────

enum AccountKind {
  organizer('Organisateur'),
  creator('Creator');

  const AccountKind(this.label);
  final String label;
}

enum AccountStatus {
  active('Actif'),
  pending('En attente'),
  suspended('Suspendu');

  const AccountStatus(this.label);
  final String label;
}

@immutable
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.kind,
    required this.status,
    required this.joined,
    required this.lastSeen,
    this.events = 0,
    this.volume = 0,
    this.note,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final AccountKind kind;
  final AccountStatus status;
  final DateTime joined;
  final DateTime lastSeen;

  /// Événements (organisateur) ou prestations (creator).
  final int events;

  /// Montant total payé (organisateur) ou encaissé (creator), en FCFA.
  final int volume;

  /// Motif de suspension ou remarque interne.
  final String? note;

  Account copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    AccountStatus? status,
    String? note,
  }) => Account(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    kind: kind,
    status: status ?? this.status,
    joined: joined,
    lastSeen: lastSeen,
    events: events,
    volume: volume,
    note: note ?? this.note,
  );
}

// ─── Vérification des prestataires ──────────────────────────────────────

enum DocStatus {
  missing('Manquant'),
  submitted('À contrôler'),
  valid('Conforme'),
  invalid('Non conforme');

  const DocStatus(this.label);
  final String label;
}

@immutable
class VendorDoc {
  const VendorDoc(this.name, this.status);
  final String name;
  final DocStatus status;

  VendorDoc withStatus(DocStatus s) => VendorDoc(name, s);
}

enum VerifyStatus {
  pending('À vérifier'),
  info('Infos demandées'),
  approved('Vérifié'),
  rejected('Refusé');

  const VerifyStatus(this.label);
  final String label;
}

@immutable
class VendorCheck {
  const VendorCheck({
    required this.id,
    required this.business,
    required this.owner,
    required this.category,
    required this.zone,
    required this.rccm,
    required this.submitted,
    required this.docs,
    this.status = VerifyStatus.pending,
    this.comment,
  });

  final String id;
  final String business;
  final String owner;
  final String category;
  final String zone;
  final String? rccm;
  final DateTime submitted;
  final List<VendorDoc> docs;
  final VerifyStatus status;
  final String? comment;

  int get validDocs => docs.where((d) => d.status == DocStatus.valid).length;

  VendorCheck copyWith({
    List<VendorDoc>? docs,
    VerifyStatus? status,
    String? comment,
  }) => VendorCheck(
    id: id,
    business: business,
    owner: owner,
    category: category,
    zone: zone,
    rccm: rccm,
    submitted: submitted,
    docs: docs ?? this.docs,
    status: status ?? this.status,
    comment: comment ?? this.comment,
  );
}

// ─── Catalogue ──────────────────────────────────────────────────────────

@immutable
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.subcategories,
    required this.listings,
    this.visible = true,
  });

  final String id;
  final String name;
  final List<String> subcategories;
  final int listings;
  final bool visible;

  CatalogCategory copyWith({
    String? name,
    List<String>? subcategories,
    bool? visible,
  }) => CatalogCategory(
    id: id,
    name: name ?? this.name,
    subcategories: subcategories ?? this.subcategories,
    listings: listings,
    visible: visible ?? this.visible,
  );
}

enum ListingStatus {
  published('Publiée'),
  review('En revue'),
  hidden('Masquée');

  const ListingStatus(this.label);
  final String label;
}

@immutable
class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.vendor,
    required this.category,
    required this.price,
    required this.status,
    this.reports = 0,
    this.sponsored = false,
  });

  final String id;
  final String title;
  final String vendor;
  final String category;
  final int price;
  final ListingStatus status;

  /// Signalements d'utilisateurs.
  final int reports;
  final bool sponsored;

  Listing copyWith({ListingStatus? status, bool? sponsored}) => Listing(
    id: id,
    title: title,
    vendor: vendor,
    category: category,
    price: price,
    status: status ?? this.status,
    reports: status == ListingStatus.published ? 0 : reports,
    sponsored: sponsored ?? this.sponsored,
  );
}

// ─── Réservations ───────────────────────────────────────────────────────

enum OrderStatus {
  confirmed('Confirmée'),
  changed('Modifiée'),
  cancelled('Annulée'),
  dispute('En litige'),
  completed('Terminée');

  const OrderStatus(this.label);
  final String label;
}

@immutable
class Order {
  const Order({
    required this.ref,
    required this.client,
    required this.vendor,
    required this.event,
    required this.date,
    required this.amount,
    required this.status,
    this.dispute,
    this.history = const [],
  });

  final String ref;
  final String client;
  final String vendor;
  final String event;
  final DateTime date;
  final int amount;
  final OrderStatus status;

  /// Motif du litige, s'il y en a un.
  final String? dispute;

  /// Historique lisible (changements, annulations, décisions).
  final List<String> history;

  Order copyWith({OrderStatus? status, String? note}) => Order(
    ref: ref,
    client: client,
    vendor: vendor,
    event: event,
    date: date,
    amount: amount,
    status: status ?? this.status,
    dispute: dispute,
    history: note == null ? history : [...history, note],
  );
}

// ─── Paiements ──────────────────────────────────────────────────────────

enum TxKind {
  payment('Paiement'),
  refund('Remboursement'),
  payout('Reversement'),
  subscription('Abonnement');

  const TxKind(this.label);
  final String label;
}

enum TxStatus {
  success('Réussi'),
  pending('En attente'),
  failed('Échoué');

  const TxStatus(this.label);
  final String label;
}

@immutable
class Transaction {
  const Transaction({
    required this.ref,
    required this.at,
    required this.kind,
    required this.method,
    required this.amount,
    required this.commission,
    required this.status,
    required this.party,
    this.reconciled = false,
  });

  final String ref;
  final DateTime at;
  final TxKind kind;
  final String method;
  final int amount;

  /// Part revenant à la plateforme (commission ou abonnement).
  final int commission;
  final TxStatus status;

  /// Client ou prestataire concerné.
  final String party;

  /// Rapproché avec le relevé de l'opérateur de paiement.
  final bool reconciled;

  Transaction copyWith({TxStatus? status, bool? reconciled}) => Transaction(
    ref: ref,
    at: at,
    kind: kind,
    method: method,
    amount: amount,
    commission: commission,
    status: status ?? this.status,
    party: party,
    reconciled: reconciled ?? this.reconciled,
  );
}

// ─── Modèle économique ──────────────────────────────────────────────────

@immutable
class PricingModel {
  const PricingModel({
    this.commission = 8,
    this.serviceFee = 2,
    this.mobileMoneyFee = 1,
    this.payoutDelayDays = 2,
    this.subscriptions = const {
      'Azur': 2900,
      'Signature': 4900,
      'Privilège': 9900,
      'Offre Creator': 29900,
    },
    this.categoryCommission = const {
      'Lieux': 6,
      'Traiteur': 8,
      'Décoration': 10,
      'Photo & vidéo': 10,
      'Musique & DJ': 10,
    },
  });

  /// Commission prélevée sur le prestataire, en %.
  final double commission;

  /// Frais de service payés par le client, en %.
  final double serviceFee;

  /// Frais Mobile Money répercutés, en %.
  final double mobileMoneyFee;

  /// Délai de reversement au prestataire après validation.
  final int payoutDelayDays;

  /// Prix mensuels des abonnements, en FCFA.
  final Map<String, int> subscriptions;

  /// Commissions particulières par catégorie, en %.
  final Map<String, double> categoryCommission;

  PricingModel copyWith({
    double? commission,
    double? serviceFee,
    double? mobileMoneyFee,
    int? payoutDelayDays,
    Map<String, int>? subscriptions,
    Map<String, double>? categoryCommission,
  }) => PricingModel(
    commission: commission ?? this.commission,
    serviceFee: serviceFee ?? this.serviceFee,
    mobileMoneyFee: mobileMoneyFee ?? this.mobileMoneyFee,
    payoutDelayDays: payoutDelayDays ?? this.payoutDelayDays,
    subscriptions: subscriptions ?? this.subscriptions,
    categoryCommission: categoryCommission ?? this.categoryCommission,
  );
}

// ─── Marketing ──────────────────────────────────────────────────────────

@immutable
class PromoCode {
  const PromoCode({
    required this.code,
    required this.label,
    required this.percent,
    required this.uses,
    required this.limit,
    required this.expires,
    this.active = true,
  });

  final String code;
  final String label;
  final int percent;
  final int uses;
  final int limit;
  final DateTime expires;
  final bool active;

  PromoCode copyWith({bool? active}) => PromoCode(
    code: code,
    label: label,
    percent: percent,
    uses: uses,
    limit: limit,
    expires: expires,
    active: active ?? this.active,
  );
}

enum CampaignStatus {
  draft('Brouillon'),
  scheduled('Programmée'),
  running('En cours'),
  done('Terminée');

  const CampaignStatus(this.label);
  final String label;
}

@immutable
class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    required this.channel,
    required this.audience,
    required this.status,
    this.sent = 0,
    this.openRate = 0,
    this.conversions = 0,
  });

  final String id;
  final String name;

  /// Push, e-mail, WhatsApp ou SMS.
  final String channel;
  final String audience;
  final CampaignStatus status;
  final int sent;
  final double openRate;
  final int conversions;

  Campaign copyWith({CampaignStatus? status, int? sent}) => Campaign(
    id: id,
    name: name,
    channel: channel,
    audience: audience,
    status: status ?? this.status,
    sent: sent ?? this.sent,
    openRate: openRate,
    conversions: conversions,
  );
}

// ─── Service client ─────────────────────────────────────────────────────

enum TicketPriority {
  low('Basse'),
  normal('Normale'),
  high('Haute'),
  urgent('Urgente');

  const TicketPriority(this.label);
  final String label;
}

enum TicketStatus {
  open('Nouveau'),
  progress('En cours'),
  waiting('En attente client'),
  resolved('Résolu');

  const TicketStatus(this.label);
  final String label;
}

@immutable
class Ticket {
  const Ticket({
    required this.id,
    required this.subject,
    required this.from,
    required this.channel,
    required this.priority,
    required this.status,
    required this.created,
    this.assignee,
    this.messages = const [],
  });

  final String id;
  final String subject;
  final String from;

  /// WhatsApp, e-mail, in-app ou téléphone.
  final String channel;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime created;
  final String? assignee;
  final List<String> messages;

  Ticket copyWith({TicketStatus? status, String? assignee, String? message}) =>
      Ticket(
        id: id,
        subject: subject,
        from: from,
        channel: channel,
        priority: priority,
        status: status ?? this.status,
        created: created,
        assignee: assignee ?? this.assignee,
        messages: message == null ? messages : [...messages, message],
      );
}

// ─── Journal d'audit ────────────────────────────────────────────────────

@immutable
class AuditEntry {
  const AuditEntry({
    required this.at,
    required this.actor,
    required this.action,
    required this.target,
  });

  final DateTime at;
  final String actor;
  final String action;
  final String target;
}

// ─── Alertes ────────────────────────────────────────────────────────────

enum AlertKind { dispute, anomaly, incident, verification, support }

@immutable
class AdminAlert {
  const AdminAlert({
    required this.kind,
    required this.title,
    required this.detail,
    required this.route,
    this.critical = false,
  });

  final AlertKind kind;
  final String title;
  final String detail;

  /// Module à ouvrir pour traiter l'alerte.
  final String route;
  final bool critical;
}

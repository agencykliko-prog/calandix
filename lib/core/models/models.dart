import 'package:flutter/widgets.dart';

import '../i18n/tr.dart';
import '../../ui/theme/app_icons.dart';
import '../../ui/theme/eventa_colors.dart';

/// Les 10 familles d'événements. Chaque famille a ses sous-catégories,
/// sa couleur, et son agent IA (Premium).
enum EventCategory {
  wedding('Mariages & unions', 'Mariage', AppIcons.wedding, Hues.coral, [
    'Mariage civil',
    'Mariage religieux',
    'Mariage traditionnel',
    'Dot',
    'Fiançailles',
    'Renouvellement de vœux',
  ]),
  birthday(
    'Anniversaires & fêtes',
    'Anniversaire',
    AppIcons.birthday,
    Hues.violet,
    [
      'Anniversaire adulte',
      'Anniversaire enfant',
      'Fête surprise',
      'Soirée à thème',
      'Anniversaire de mariage',
    ],
  ),
  baby('Bébé & famille', 'Bébé', AppIcons.baby, Hues.lagoon, [
    'Baby shower',
    'Gender reveal',
    'Baptême',
    'Sounna',
    'Première communion',
    'Fête de naissance',
  ]),
  friends('EVJF, EVG & amis', 'Entre amis', AppIcons.friends, Hues.candy, [
    'EVJF',
    'EVG',
    'Brunch',
    'Pool party',
    'Beach party',
    'Soirée privée',
  ]),
  outing('Sorties & loisirs', 'Sortie', AppIcons.outing, Hues.sky, [
    'Pique-nique',
    'Camping',
    'Excursion',
    'Randonnée',
    'Barbecue',
    'Sortie en bateau',
  ]),
  pro('Événements professionnels', 'Pro', AppIcons.pro, Hues.violet, [
    'Team building',
    'Séminaire',
    'Conférence',
    'Lancement de produit',
    'Inauguration',
    'Afterwork',
  ]),
  milestone(
    'Célébrations personnelles',
    'Célébration',
    AppIcons.milestone,
    Hues.violet,
    ['Remise de diplôme', 'Réussite à un examen', 'Promotion', 'Pot de départ'],
  ),
  family(
    'Familiaux & communautaires',
    'Famille',
    AppIcons.family,
    Hues.lagoon,
    [
      'Réunion familiale',
      'Fête communautaire',
      'Retrouvailles',
      'Célébration religieuse',
      'Hommage & funérailles',
    ],
  ),
  charity(
    'Associatifs & solidaires',
    'Associatif',
    AppIcons.charity,
    Hues.candy,
    [
      'Gala',
      'Collecte de fonds',
      'Rencontre communautaire',
      'Campagne de sensibilisation',
    ],
  ),
  seasonal('Fêtes saisonnières', 'Saison', AppIcons.seasonal, Hues.peach, [
    'Noël',
    'Nouvel An',
    'Saint-Valentin',
    'Fête des mères',
    'Fête des pères',
    'Tabaski',
    'Pâques',
  ]);

  const EventCategory(
    this._label,
    this._short,
    this.icon,
    this._hue,
    this._subcategories,
  );

  final String _label;
  String get label => _label.tr;
  final String _short;
  String get short => _short.tr;
  final IconData icon;
  final Hues _hue;
  Hue get hue => _hue.hue;
  final List<String> _subcategories;
  List<String> get subcategories => [for (final s in _subcategories) s.tr];
}

enum BudgetCategory {
  venue('Lieu', AppIcons.venue),
  catering('Restauration', AppIcons.food),
  drinks('Boissons', AppIcons.drinks),
  decor('Décoration', AppIcons.decor),
  photo('Photo & vidéo', AppIcons.camera),
  music('Animation', AppIcons.music),
  outfits('Tenues & beauté', AppIcons.dress),
  invitations('Invitations', AppIcons.mail),
  transport('Transport', AppIcons.car),
  cake('Gâteau', AppIcons.birthday),
  gifts('Cadeaux', AppIcons.gift),
  rental('Location', AppIcons.chair),
  staff('Personnel', AppIcons.staff),
  activities('Activités', AppIcons.boat),
  contingency('Imprévus', AppIcons.shield);

  const BudgetCategory(this._label, this.icon);
  final String _label;
  String get label => _label.tr;
  final IconData icon;
}

@immutable
class BudgetLine {
  const BudgetLine({
    required this.category,
    required this.estimated,
    this.committed = 0,
    this.paid = 0,
    this.note,
  });

  final BudgetCategory category;

  /// Prévu (estimation).
  final int estimated;

  /// Engagé : devis acceptés, réservations confirmées.
  final int committed;

  /// Payé : paiements confirmés.
  final int paid;
  final String? note;

  int get remainingToPay => committed - paid;
  int get remainingToSpend => estimated - committed;
  bool get isOver => committed > estimated;

  BudgetLine copyWith({
    int? estimated,
    int? committed,
    int? paid,
    String? note,
  }) => BudgetLine(
    category: category,
    estimated: estimated ?? this.estimated,
    committed: committed ?? this.committed,
    paid: paid ?? this.paid,
    note: note ?? this.note,
  );
}

/// Une dépense réellement réglée, rattachée à un poste.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.label,
    required this.amount,
    required this.date,
    this.method = 'Mobile money',
  });

  final String id;
  final BudgetCategory category;
  final String label;
  final int amount;
  final DateTime date;
  final String method;
}

enum Module { budget, tasks, vendors, team, guests }

@immutable
class EventTask {
  const EventTask({
    required this.id,
    required this.title,
    required this.due,
    required this.module,
    this.assigneeId,
    this.done = false,
    this.urgent = false,
    this.durationMin = 30,
    this.icon = AppIcons.check,
  });

  final String id;
  final String title;
  final DateTime due;
  final Module module;
  final String? assigneeId;
  final bool done;
  final bool urgent;
  final int durationMin;
  final IconData icon;

  EventTask copyWith({
    bool? done,
    String? title,
    DateTime? due,
    int? durationMin,
    Module? module,
  }) => EventTask(
    id: id,
    title: title ?? this.title,
    due: due ?? this.due,
    module: module ?? this.module,
    assigneeId: assigneeId,
    done: done ?? this.done,
    urgent: urgent,
    durationMin: durationMin ?? this.durationMin,
    icon: icon,
  );
}

/// Les 12 familles de prestataires du cahier des charges.
enum VendorCategory {
  venue('Lieux', AppIcons.venue, BudgetCategory.venue),
  decor('Décoration', AppIcons.decor, BudgetCategory.decor),
  catering('Restauration', AppIcons.food, BudgetCategory.catering),
  photo('Photo & vidéo', AppIcons.camera, BudgetCategory.photo),
  music('Animation', AppIcons.music, BudgetCategory.music),
  rental('Location', AppIcons.chair, BudgetCategory.rental),
  beauty('Mode & beauté', AppIcons.dress, BudgetCategory.outfits),
  paper('Papeterie', AppIcons.mail, BudgetCategory.invitations),
  transport('Transport', AppIcons.car, BudgetCategory.transport),
  staff('Personnel', AppIcons.staff, BudgetCategory.staff),
  planner('Organisation', AppIcons.planner, BudgetCategory.contingency),
  activity('Activités', AppIcons.boat, BudgetCategory.activities);

  const VendorCategory(this._label, this.icon, this.budget);
  final String _label;
  String get label => _label.tr;
  final IconData icon;
  final BudgetCategory budget;
}

/// Espaces sponsorisés achetés par les professionnels.
enum Sponsor {
  ofTheMonth('Sponsor du mois'),
  recommended('Recommandé'),
  featured('Mise en avant'),
  result('Sponsorisé');

  const Sponsor(this._label);
  final String _label;
  String get label => _label.tr;
}

@immutable
class VendorPackage {
  const VendorPackage(this.name, this.price, this.description);
  final String name;
  final int price;
  final String description;
}

@immutable
class Review {
  const Review(this.author, this.rating, this.text, this.when);
  final String author;
  final int rating;
  final String text;
  final String when;
}

@immutable
class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.category,
    required this.tagline,
    required this.description,
    required this.priceFrom,
    required this.image,
    required this.zone,
    this.unit = 'forfait',
    this.rating = 4.8,
    this.reviews = 64,
    this.available = true,
    this.nextAvailable,
    this.verified = true,
    this.sponsor,
    this.responseTime = '1 h',
    this.phone = '+225 07 00 00 00 00',
    this.packages = const [],
  });

  final String id;
  final String name;
  final VendorCategory category;
  final String tagline;
  final String description;
  final int priceFrom;
  final String unit;
  final String image;
  final String zone;
  final double rating;
  final int reviews;
  final bool available;
  final String? nextAvailable;
  final bool verified;
  final Sponsor? sponsor;
  final String responseTime;
  final String phone;
  final List<VendorPackage> packages;

  /// Coordonnées de démonstration, dérivées de l'identifiant.
  String get email => 'contact@${id.replaceAll('-', '')}.ci';
  String get website => '${id.replaceAll('-', '')}.ci';
  String get phoneNumber {
    final n = id.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) % 100000000);
    final d = n.toString().padLeft(8, '0');
    return '+225 07 ${d.substring(0, 2)} ${d.substring(2, 4)} ${d.substring(4, 6)} ${d.substring(6, 8)}';
  }
}

enum VendorStatus {
  contacted('Contacté'),
  quoted('Devis reçu'),
  booked('Réservé'),
  paid('Payé');

  const VendorStatus(this._label);
  final String _label;
  String get label => _label.tr;
}

/// Un prestataire rattaché à un événement.
@immutable
class EventVendor {
  const EventVendor({
    required this.vendor,
    required this.status,
    required this.amount,
  });

  final Vendor vendor;
  final VendorStatus status;
  final int amount;
}

/// Droits fins d'un collaborateur.
@immutable
class Permissions {
  const Permissions({
    this.budget = true,
    this.tasks = true,
    this.vendors = true,
    this.guests = true,
    this.payments = false,
  });

  final bool budget;
  final bool tasks;
  final bool vendors;
  final bool guests;
  final bool payments;

  static const all = Permissions(payments: true);
  static const readOnly = Permissions(
    budget: false,
    tasks: false,
    vendors: false,
    guests: false,
  );

  Permissions copyWith({
    bool? budget,
    bool? tasks,
    bool? vendors,
    bool? guests,
    bool? payments,
  }) => Permissions(
    budget: budget ?? this.budget,
    tasks: tasks ?? this.tasks,
    vendors: vendors ?? this.vendors,
    guests: guests ?? this.guests,
    payments: payments ?? this.payments,
  );
}

enum TeamRole {
  owner('Propriétaire'),
  admin('Admin'),
  editor('Éditeur'),
  viewer('Lecteur');

  const TeamRole(this._label);
  final String _label;
  String get label => _label.tr;
}

@immutable
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.avatar,
    this.online = false,
    this.side,
    this.permissions = const Permissions(),
    this.pending = false,
  });

  final String id;
  final String name;
  final TeamRole role;
  final String? avatar;
  final bool online;
  final String? side;
  final Permissions permissions;

  /// Invitation envoyée, pas encore acceptée.
  final bool pending;

  String get firstName => name.split(' ').first;
  String get initials => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
}

@immutable
class Activity {
  const Activity({
    required this.memberId,
    required this.text,
    required this.at,
    required this.module,
  });

  final String memberId;
  final String text;
  final DateTime at;
  final Module module;
}

@immutable
class Payment {
  const Payment({
    required this.label,
    required this.amount,
    required this.due,
    this.method = 'Mobile money',
  });

  final String label;
  final int amount;
  final DateTime due;
  final String method;
}

enum Rsvp { pending, yes, no }

/// Un invité de la liste, avec sa réponse.
@immutable
class Guest {
  const Guest({
    required this.id,
    required this.name,
    this.phone,
    this.group,
    this.rsvp = Rsvp.pending,
    this.companions = 0,
    this.diet,
    this.addedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? group;
  final Rsvp rsvp;

  /// Personnes qui l'accompagnent (conjoint, enfants…).
  final int companions;
  final String? diet;
  final DateTime? addedAt;

  Guest copyWith({
    String? id,
    String? name,
    String? phone,
    String? group,
    Rsvp? rsvp,
    int? companions,
    String? diet,
  }) => Guest(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    group: group ?? this.group,
    rsvp: rsvp ?? this.rsvp,
    companions: companions ?? this.companions,
    diet: diet ?? this.diet,
    addedAt: addedAt,
  );
}

@immutable
class Guests {
  const Guests({
    required this.invited,
    required this.confirmed,
    required this.declined,
    this.todayNew = 0,
    this.list = const [],
    this.expected = 0,
  });

  /// Compteurs tirés de la liste. Tant qu'elle est vide, le nombre d'invités
  /// prévu à la création de l'événement sert de repère.
  factory Guests.fromList(List<Guest> list, {int expected = 0}) {
    final now = DateTime.now();
    bool today(DateTime? d) =>
        d != null &&
        d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;
    return Guests(
      invited: list.isEmpty ? expected : list.length,
      confirmed: list.where((g) => g.rsvp == Rsvp.yes).length,
      declined: list.where((g) => g.rsvp == Rsvp.no).length,
      todayNew: list.where((g) => today(g.addedAt)).length,
      list: list,
      expected: expected,
    );
  }

  final int invited;
  final int confirmed;
  final int declined;
  final int todayNew;
  final List<Guest> list;

  /// Nombre d'invités prévu à la création de l'événement.
  final int expected;

  int get pending => invited - confirmed - declined;

  /// Personnes attendues : invités présents et leurs accompagnants.
  int get headcount => list.isEmpty
      ? confirmed
      : list
            .where((g) => g.rsvp == Rsvp.yes)
            .fold(0, (s, g) => s + 1 + g.companions);
}

@immutable
class Event {
  const Event({
    required this.id,
    required this.name,
    required this.category,
    required this.date,
    required this.venue,
    required this.city,
    required this.cover,
    required this.targetBudget,
    required this.budget,
    required this.tasks,
    required this.vendors,
    required this.team,
    required this.activity,
    required this.guests,
    this.subcategories = const [],
    this.expenses = const [],
    this.nextPayment,
    this.subtitle,
  });

  final String id;
  final String name;
  final String? subtitle;
  final EventCategory category;
  final List<String> subcategories;
  final DateTime date;
  final String venue;
  final String city;
  final String cover;

  /// Budget cible : montant maximal souhaité.
  final int targetBudget;
  final List<BudgetLine> budget;
  final List<Expense> expenses;
  final List<EventTask> tasks;
  final List<EventVendor> vendors;
  final List<TeamMember> team;
  final List<Activity> activity;
  final Guests guests;
  final Payment? nextPayment;

  int get estimated => budget.fold(0, (s, l) => s + l.estimated);
  int get committed => budget.fold(0, (s, l) => s + l.committed);
  int get paid => budget.fold(0, (s, l) => s + l.paid);
  int get remainingToPay => committed - paid;

  /// Disponible estimé = budget cible − engagé (formule affichée à l'écran).
  int get available => targetBudget - committed;

  /// Reste à dépenser = budget cible − payé.
  int get remainingToSpend => targetBudget - paid;
  double get committedRatio =>
      targetBudget == 0 ? 0 : (committed / targetBudget).clamp(0, 1.5);

  int get tasksDone => tasks.where((t) => t.done).length;
  double get taskProgress => tasks.isEmpty ? 0 : tasksDone / tasks.length;
  int get vendorsConfirmed => vendors
      .where(
        (v) => v.status == VendorStatus.booked || v.status == VendorStatus.paid,
      )
      .length;
  int get onlineCount => team.where((m) => m.online).length;

  /// Collaborateurs invités (hors propriétaire).
  int get collaborators => team.where((m) => m.role != TeamRole.owner).length;

  /// Avancement global : tâches 50 %, prestataires 30 %, RSVP 20 %.
  double get overallProgress {
    final v = vendors.isEmpty ? 0.0 : vendorsConfirmed / vendors.length;
    final g = guests.invited == 0
        ? 0.0
        : (guests.confirmed + guests.declined) / guests.invited;
    return (taskProgress * 0.5 + v * 0.3 + g * 0.2).clamp(0, 1);
  }

  TeamMember? member(String? id) {
    for (final m in team) {
      if (m.id == id) return m;
    }
    return null;
  }

  BudgetLine? line(BudgetCategory c) {
    for (final l in budget) {
      if (l.category == c) return l;
    }
    return null;
  }

  Event copyWith({
    List<EventTask>? tasks,
    List<BudgetLine>? budget,
    List<Expense>? expenses,
    List<TeamMember>? team,
    List<EventVendor>? vendors,
    List<Activity>? activity,
    Guests? guests,
    int? targetBudget,
  }) => Event(
    id: id,
    name: name,
    subtitle: subtitle,
    category: category,
    subcategories: subcategories,
    date: date,
    venue: venue,
    city: city,
    cover: cover,
    targetBudget: targetBudget ?? this.targetBudget,
    budget: budget ?? this.budget,
    expenses: expenses ?? this.expenses,
    tasks: tasks ?? this.tasks,
    vendors: vendors ?? this.vendors,
    team: team ?? this.team,
    activity: activity ?? this.activity,
    guests: guests ?? this.guests,
    nextPayment: nextPayment,
  );
}

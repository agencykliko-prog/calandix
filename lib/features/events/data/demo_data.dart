import '../../../ui/theme/app_icons.dart';
import '../../commerce/data/catalog.dart';
import '../../../core/models/models.dart';

/// Données de démonstration (fictives). Les dates sont relatives à
/// aujourd'hui pour que les comptes à rebours restent cohérents.
abstract final class DemoData {
  static const _img = 'assets/images';

  static DateTime _d(int days, [int hour = 10, int minute = 0]) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + days, hour, minute);
  }

  static const currentUser = TeamMember(
    id: 'awa',
    name: 'Awa Traoré',
    role: TeamRole.owner,
    avatar: '$_img/avatar_1.jpg',
    online: true,
    permissions: Permissions.all,
  );

  static const _awa = TeamMember(
    id: 'awa',
    name: 'Awa Traoré',
    role: TeamRole.owner,
    avatar: '$_img/avatar_1.jpg',
    online: true,
    side: 'Côté mariée',
    permissions: Permissions.all,
  );
  static const _kouassi = TeamMember(
    id: 'kouassi',
    name: "Kouassi N'Guessan",
    role: TeamRole.admin,
    avatar: '$_img/avatar_2.jpg',
    online: true,
    side: 'Côté marié',
    permissions: Permissions.all,
  );
  static const _fatou = TeamMember(
    id: 'fatou',
    name: 'Fatou Diabaté',
    role: TeamRole.editor,
    avatar: '$_img/avatar_3.jpg',
    online: true,
    side: 'Côté mariée',
  );
  static const _serge = TeamMember(
    id: 'serge',
    name: 'Serge Yao',
    role: TeamRole.editor,
    avatar: '$_img/avatar_4.jpg',
    side: 'Côté marié',
  );
  static const _mariam = TeamMember(
    id: 'mariam',
    name: 'Mariam Traoré',
    role: TeamRole.viewer,
    avatar: '$_img/avatar_5.jpg',
    online: true,
    side: 'Côté mariée',
    permissions: Permissions.readOnly,
  );

  static List<EventTask> _done(String prefix, List<String> titles, Module m) =>
      [
        for (var i = 0; i < titles.length; i++)
          EventTask(
            id: '$prefix-done-$i',
            title: titles[i],
            due: _d(-(titles.length - i) * 3, 9 + i % 8),
            module: m,
            done: true,
            assigneeId: const ['awa', 'kouassi', 'fatou', 'serge'][i % 4],
          ),
      ];

  static const _firstNames = [
    'Aya',
    'Kouamé',
    'Adjoua',
    'Yao',
    'Aminata',
    'Koffi',
    'Mariam',
    'Serge',
    'Affoué',
    'Ibrahim',
    'Akissi',
    'Moussa',
    'Ama',
    'Didier',
    'Fanta',
    'Hervé',
    'Nadège',
    'Souleymane',
    'Grâce',
    'Arnaud',
    'Bintou',
    'Junior',
    'Estelle',
    'Lassina',
    'Christelle',
    'Brice',
    'Salimata',
    'Wilfried',
  ];
  static const _lastNames = [
    'Kouassi',
    'Konan',
    'Traoré',
    'Coulibaly',
    'N’Guessan',
    'Bamba',
    'Yapi',
    'Diallo',
    'Kouadio',
    'Ouattara',
    'Aka',
    'Koné',
    'Tanoh',
    'Gbagbo',
    'Assi',
    'Doumbia',
    'Ehui',
    'Cissé',
    'Amani',
    'Touré',
  ];

  /// Liste d'invités fictive qui retombe sur les compteurs voulus.
  static Guests _guests(
    String prefix, {
    required int invited,
    required int confirmed,
    required int declined,
    required int todayNew,
    required List<String> groups,
  }) {
    final now = DateTime.now();
    final list = [
      for (var i = 0; i < invited; i++)
        Guest(
          id: '$prefix-g$i',
          name:
              '${_firstNames[i % _firstNames.length]} '
              '${_lastNames[(i + i ~/ _firstNames.length) % _lastNames.length]}',
          phone: i % 3 == 0
              ? null
              : '07 ${(10 + i % 89)} ${(20 + i * 13 % 79)} ${(30 + i * 7 % 69)} ${(40 + i * 3 % 59)}',
          group: groups[i % groups.length],
          rsvp: i < confirmed
              ? Rsvp.yes
              : i < confirmed + declined
              ? Rsvp.no
              : Rsvp.pending,
          companions: i < confirmed && i % 4 == 0 ? 1 : 0,
          addedAt: i >= invited - todayNew
              ? now
              : now.subtract(Duration(days: 2 + i % 20)),
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return Guests.fromList(list, expected: invited);
  }

  static List<Event> events() => [wedding(), birthday(), babyShower()];

  static Event wedding() => Event(
    id: 'mariage-awa-kouassi',
    name: 'Mariage Awa & Kouassi',
    subtitle: 'Dot, civil et réception',
    category: EventCategory.wedding,
    subcategories: const ['Dot', 'Mariage civil', 'Mariage religieux'],
    date: _d(42, 16),
    venue: 'Espace Latrille Events',
    city: 'Cocody, Abidjan',
    cover: '$_img/cover_wedding.jpg',
    targetBudget: 12500000,
    budget: const [
      BudgetLine(
        category: BudgetCategory.venue,
        estimated: 3000000,
        committed: 3000000,
        paid: 1500000,
      ),
      BudgetLine(
        category: BudgetCategory.catering,
        estimated: 3600000,
        committed: 3400000,
        paid: 1700000,
      ),
      BudgetLine(
        category: BudgetCategory.decor,
        estimated: 1300000,
        committed: 1200000,
        paid: 600000,
      ),
      BudgetLine(
        category: BudgetCategory.photo,
        estimated: 900000,
        committed: 450000,
        paid: 225000,
      ),
      BudgetLine(
        category: BudgetCategory.music,
        estimated: 450000,
        committed: 450000,
        paid: 225000,
      ),
      BudgetLine(category: BudgetCategory.drinks, estimated: 900000),
      BudgetLine(
        category: BudgetCategory.outfits,
        estimated: 850000,
        note: 'Pagne du cortège inclus',
      ),
      BudgetLine(category: BudgetCategory.transport, estimated: 300000),
      BudgetLine(category: BudgetCategory.invitations, estimated: 250000),
      BudgetLine(category: BudgetCategory.contingency, estimated: 950000),
    ],
    expenses: [
      Expense(
        id: 'e1',
        category: BudgetCategory.venue,
        label: 'Acompte salle',
        amount: 1500000,
        date: _d(-40),
        method: 'Wave',
      ),
      Expense(
        id: 'e2',
        category: BudgetCategory.catering,
        label: 'Acompte traiteur',
        amount: 1700000,
        date: _d(-21),
        method: 'Orange Money',
      ),
      Expense(
        id: 'e3',
        category: BudgetCategory.decor,
        label: 'Acompte décoration',
        amount: 600000,
        date: _d(-14),
        method: 'Carte bancaire',
      ),
      Expense(
        id: 'e4',
        category: BudgetCategory.photo,
        label: 'Acompte photographe',
        amount: 225000,
        date: _d(-9),
        method: 'MTN Money',
      ),
      Expense(
        id: 'e5',
        category: BudgetCategory.music,
        label: 'Acompte DJ',
        amount: 225000,
        date: _d(-3),
        method: 'Wave',
      ),
    ],
    tasks: [
      EventTask(
        id: 'w1',
        title: 'Valider le menu de dégustation',
        due: _d(0, 11),
        module: Module.vendors,
        assigneeId: 'kouassi',
        urgent: true,
        durationMin: 90,
        icon: AppIcons.food,
      ),
      EventTask(
        id: 'w2',
        title: 'Relancer les RSVP côté marié',
        due: _d(0, 18),
        module: Module.guests,
        assigneeId: 'serge',
        durationMin: 30,
        icon: AppIcons.mail,
      ),
      EventTask(
        id: 'w3',
        title: 'Payer le solde du DJ',
        due: _d(1, 9, 30),
        module: Module.budget,
        assigneeId: 'awa',
        urgent: true,
        durationMin: 15,
        icon: AppIcons.coins,
      ),
      EventTask(
        id: 'w4',
        title: 'Essayage de la robe',
        due: _d(2, 15),
        module: Module.tasks,
        assigneeId: 'awa',
        durationMin: 120,
        icon: AppIcons.dress,
      ),
      EventTask(
        id: 'w5',
        title: 'Commander le pagne du cortège (40 pièces)',
        due: _d(3, 10),
        module: Module.tasks,
        assigneeId: 'fatou',
        durationMin: 45,
        icon: AppIcons.bag,
      ),
      EventTask(
        id: 'w6',
        title: 'Mairie de Cocody : publication des bans',
        due: _d(5, 8, 30),
        module: Module.tasks,
        assigneeId: 'kouassi',
        durationMin: 60,
        icon: AppIcons.buildings,
      ),
      EventTask(
        id: 'w7',
        title: 'Choisir le photographe (2 devis)',
        due: _d(7, 14),
        module: Module.vendors,
        assigneeId: 'awa',
        durationMin: 45,
        icon: AppIcons.camera,
      ),
      EventTask(
        id: 'w8',
        title: 'Finaliser le plan de table',
        due: _d(9, 19),
        module: Module.guests,
        assigneeId: 'fatou',
        durationMin: 120,
        icon: AppIcons.table,
      ),
      EventTask(
        id: 'w9',
        title: 'Vérifier les éléments de la dot',
        due: _d(12, 10),
        module: Module.tasks,
        assigneeId: 'mariam',
        durationMin: 60,
        icon: AppIcons.gift,
      ),
      EventTask(
        id: 'w10',
        title: 'Confirmer les navettes invités',
        due: _d(16, 11),
        module: Module.vendors,
        assigneeId: 'serge',
        durationMin: 30,
        icon: AppIcons.car,
      ),
      EventTask(
        id: 'w11',
        title: 'Imprimer menus et marque-places',
        due: _d(21, 10),
        module: Module.tasks,
        assigneeId: 'fatou',
        durationMin: 60,
        icon: AppIcons.printer,
      ),
      EventTask(
        id: 'w12',
        title: 'Répétition du cortège',
        due: _d(35, 17),
        module: Module.team,
        assigneeId: 'kouassi',
        durationMin: 120,
        icon: AppIcons.team,
      ),
      EventTask(
        id: 'w13',
        title: 'Préparer les enveloppes prestataires',
        due: _d(41, 18),
        module: Module.budget,
        assigneeId: 'awa',
        durationMin: 45,
        icon: AppIcons.mail,
      ),
      ..._done('w', const [
        'Fixer la date avec les deux familles',
        'Définir le budget cible',
        'Choisir les témoins',
        'Visiter trois salles',
        'Réserver Espace Latrille Events',
        'Verser l’acompte de la salle',
        'Liste des invités côté mariée',
        'Liste des invités côté marié',
        'Rencontrer le traiteur',
        'Accepter le devis traiteur',
        'Choisir la palette de déco',
        'Réserver la décoratrice',
        'Réserver le DJ',
        'Envoyer les save-the-date',
        'Créer le groupe WhatsApp familles',
        'Choisir le tissu du pagne',
        'Prendre RDV coiffure & maquillage',
        'Préparer le dossier de mairie',
        'Définir le déroulé de la dot',
        'Choisir les alliances',
        'Réserver l’hébergement famille',
        'Moodboard validé',
        'Envoyer les invitations digitales',
        'Ouvrir la cagnotte mobile money',
      ], Module.tasks),
    ],
    vendors: [
      EventVendor(
        vendor: Catalog.vendor('latrille'),
        status: VendorStatus.paid,
        amount: 3000000,
      ),
      EventVendor(
        vendor: Catalog.vendor('saveurs'),
        status: VendorStatus.booked,
        amount: 3400000,
      ),
      EventVendor(
        vendor: Catalog.vendor('ines-deco'),
        status: VendorStatus.booked,
        amount: 1200000,
      ),
      EventVendor(
        vendor: Catalog.vendor('lagune-sound'),
        status: VendorStatus.booked,
        amount: 450000,
      ),
      EventVendor(
        vendor: Catalog.vendor('studio-lumiere'),
        status: VendorStatus.quoted,
        amount: 450000,
      ),
    ],
    team: const [_awa, _kouassi, _fatou, _serge, _mariam],
    activity: [
      Activity(
        memberId: 'fatou',
        text: 'a coché « Moodboard validé »',
        at: DateTime.now().subtract(const Duration(minutes: 12)),
        module: Module.tasks,
      ),
      Activity(
        memberId: 'kouassi',
        text: 'a accepté le devis de Lagune Sound',
        at: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
        module: Module.vendors,
      ),
      Activity(
        memberId: 'serge',
        text: 'a ajouté 12 invités côté marié',
        at: DateTime.now().subtract(const Duration(hours: 3)),
        module: Module.guests,
      ),
      Activity(
        memberId: 'mariam',
        text: 'a versé 50 000 FCFA à la cagnotte',
        at: DateTime.now().subtract(const Duration(hours: 20)),
        module: Module.budget,
      ),
    ],
    guests: _guests(
      'w',
      invited: 250,
      confirmed: 162,
      declined: 18,
      todayNew: 8,
      groups: const [
        'Famille de la mariée',
        'Famille du marié',
        'Amis',
        'Collègues',
      ],
    ),
    nextPayment: Payment(
      label: 'Solde Lagune Sound',
      amount: 225000,
      due: _d(1, 9, 30),
    ),
  );

  static Event birthday() => Event(
    id: 'anniv-yasmine-30',
    name: 'Les 30 ans de Yasmine',
    subtitle: 'Fête surprise · Gold & Rose',
    category: EventCategory.birthday,
    subcategories: const ['Fête surprise', 'Anniversaire adulte'],
    date: _d(27, 20),
    venue: 'Rooftop Le Toit',
    city: 'Plateau, Abidjan',
    cover: '$_img/cover_birthday.jpg',
    targetBudget: 1800000,
    budget: const [
      BudgetLine(
        category: BudgetCategory.venue,
        estimated: 600000,
        committed: 600000,
        paid: 300000,
      ),
      BudgetLine(
        category: BudgetCategory.catering,
        estimated: 450000,
        committed: 400000,
      ),
      BudgetLine(
        category: BudgetCategory.music,
        estimated: 150000,
        committed: 150000,
        paid: 150000,
      ),
      BudgetLine(
        category: BudgetCategory.cake,
        estimated: 90000,
        committed: 90000,
        paid: 45000,
      ),
      BudgetLine(category: BudgetCategory.drinks, estimated: 250000),
      BudgetLine(category: BudgetCategory.decor, estimated: 180000),
      BudgetLine(category: BudgetCategory.gifts, estimated: 50000),
      BudgetLine(category: BudgetCategory.contingency, estimated: 30000),
    ],
    tasks: [
      EventTask(
        id: 'b1',
        title: 'Plan de diversion avec sa sœur',
        due: _d(1, 19),
        module: Module.team,
        assigneeId: 'fatou',
        urgent: true,
        durationMin: 30,
        icon: AppIcons.eyeOff,
      ),
      EventTask(
        id: 'b2',
        title: 'Commander le gâteau (3 étages, or)',
        due: _d(4, 12),
        module: Module.vendors,
        assigneeId: 'awa',
        durationMin: 30,
        icon: AppIcons.birthday,
      ),
      EventTask(
        id: 'b3',
        title: 'Collecter les vidéos des proches',
        due: _d(10, 20),
        module: Module.guests,
        assigneeId: 'mariam',
        durationMin: 60,
        icon: AppIcons.camera,
      ),
      EventTask(
        id: 'b4',
        title: 'Playlist collaborative',
        due: _d(18, 21),
        module: Module.team,
        assigneeId: 'fatou',
        durationMin: 30,
        icon: AppIcons.music,
      ),
      ..._done('b', const [
        'Choisir le thème',
        'Réserver le rooftop',
        'Réserver le DJ',
        'Créer le groupe secret',
        'Lister les invités',
        'Envoyer les invitations',
        'Ouvrir la cagnotte cadeau',
      ], Module.tasks),
    ],
    vendors: [
      EventVendor(
        vendor: Catalog.vendor('lagune-sound'),
        status: VendorStatus.paid,
        amount: 150000,
      ),
      EventVendor(
        vendor: Catalog.vendor('douce-heure'),
        status: VendorStatus.quoted,
        amount: 90000,
      ),
    ],
    team: const [_awa, _fatou, _mariam],
    activity: [
      Activity(
        memberId: 'mariam',
        text: 'a reçu 6 vidéos de proches',
        at: DateTime.now().subtract(const Duration(hours: 2)),
        module: Module.guests,
      ),
    ],
    guests: _guests(
      'b',
      invited: 60,
      confirmed: 31,
      declined: 4,
      todayNew: 3,
      groups: const ['Famille', 'Amis', 'Collègues'],
    ),
    nextPayment: Payment(
      label: 'Solde Rooftop Le Toit',
      amount: 300000,
      due: _d(6),
    ),
  );

  static Event babyShower() => Event(
    id: 'baby-shower-mariam',
    name: 'Baby shower de Mariam',
    subtitle: 'Organisé pour Mariam',
    category: EventCategory.baby,
    subcategories: const ['Baby shower'],
    date: _d(14, 15),
    venue: 'Villa Les Palmiers',
    city: 'Riviera 3, Abidjan',
    cover: '$_img/cover_babyshower.jpg',
    targetBudget: 650000,
    budget: const [
      BudgetLine(
        category: BudgetCategory.catering,
        estimated: 220000,
        committed: 200000,
        paid: 100000,
      ),
      BudgetLine(
        category: BudgetCategory.decor,
        estimated: 150000,
        committed: 150000,
        paid: 150000,
      ),
      BudgetLine(
        category: BudgetCategory.cake,
        estimated: 60000,
        committed: 60000,
      ),
      BudgetLine(category: BudgetCategory.gifts, estimated: 120000),
      BudgetLine(category: BudgetCategory.photo, estimated: 70000),
      BudgetLine(category: BudgetCategory.contingency, estimated: 30000),
    ],
    tasks: [
      EventTask(
        id: 's1',
        title: 'Partager la liste de naissance',
        due: _d(0, 17),
        module: Module.guests,
        assigneeId: 'awa',
        urgent: true,
        durationMin: 15,
        icon: AppIcons.gift,
      ),
      EventTask(
        id: 's2',
        title: 'Valider la déco ballons pastel',
        due: _d(3, 11),
        module: Module.vendors,
        assigneeId: 'fatou',
        durationMin: 30,
        icon: AppIcons.decor,
      ),
      EventTask(
        id: 's3',
        title: 'Préparer le quiz bébé',
        due: _d(9, 18),
        module: Module.team,
        assigneeId: 'awa',
        durationMin: 45,
        icon: AppIcons.help,
      ),
      EventTask(
        id: 's4',
        title: 'Coin calme pour Mariam',
        due: _d(13, 10),
        module: Module.tasks,
        assigneeId: 'fatou',
        durationMin: 30,
        icon: AppIcons.chair,
      ),
      ..._done('s', const [
        'Choisir la date',
        'Réserver la villa',
        'Lister les invitées',
        'Commander les cupcakes',
        'Choisir le thème pastel',
        'Créer le groupe',
        'Envoyer les invitations',
        'Payer la déco',
      ], Module.tasks),
    ],
    vendors: [
      EventVendor(
        vendor: Catalog.vendor('ballon-studio'),
        status: VendorStatus.paid,
        amount: 150000,
      ),
      EventVendor(
        vendor: Catalog.vendor('saveurs'),
        status: VendorStatus.booked,
        amount: 200000,
      ),
    ],
    team: const [_awa, _fatou],
    activity: [
      Activity(
        memberId: 'fatou',
        text: 'a payé la décoration',
        at: DateTime.now().subtract(const Duration(hours: 5)),
        module: Module.budget,
      ),
    ],
    guests: _guests(
      's',
      invited: 35,
      confirmed: 22,
      declined: 2,
      todayNew: 2,
      groups: const ['Famille', 'Amies'],
    ),
    nextPayment: Payment(
      label: 'Gâteau Douce Heure',
      amount: 60000,
      due: _d(10),
    ),
  );
}

import 'dart:math' as math;

import '../domain/admin_models.dart';

/// Données fictives du centre de contrôle. Aucune donnée réelle.
abstract final class AdminDemo {
  static DateTime _ago({int d = 0, int h = 0, int m = 0}) =>
      DateTime.now().subtract(Duration(days: d, hours: h, minutes: m));

  static DateTime _in(int d, [int h = 16]) {
    final n = DateTime.now().add(Duration(days: d));
    return DateTime(n.year, n.month, n.day, h);
  }

  static final team = [
    const AdminMember(
      id: 'adm1',
      name: 'Jean-Jacques Djipro',
      email: 'jean-jacques@calandix.demo',
      role: AdminRole.superAdmin,
    ),
    const AdminMember(
      id: 'adm2',
      name: 'Karen Akablan',
      email: 'karen@calandix.demo',
      role: AdminRole.finance,
    ),
    const AdminMember(
      id: 'adm3',
      name: 'Serge Yao',
      email: 'serge@calandix.demo',
      role: AdminRole.moderation,
    ),
    const AdminMember(
      id: 'adm4',
      name: 'Aïcha Diallo',
      email: 'aicha@calandix.demo',
      role: AdminRole.support,
    ),
    const AdminMember(
      id: 'adm5',
      name: 'Marc Gnahoré',
      email: 'marc@calandix.demo',
      role: AdminRole.marketing,
      twoFactor: false,
    ),
  ];

  static final accounts = <Account>[
    Account(
      id: 'U-1042',
      name: 'Awa Traoré',
      email: 'awa.traore@demo.ci',
      phone: '+225 07 08 12 34 56',
      city: 'Abidjan',
      kind: AccountKind.organizer,
      status: AccountStatus.active,
      joined: _ago(d: 64),
      lastSeen: _ago(m: 12),
      events: 3,
      volume: 4850000,
    ),
    Account(
      id: 'U-1043',
      name: 'Maison Inès Déco',
      email: 'contact@inesdeco.demo',
      phone: '+225 05 44 21 09 87',
      city: 'Abidjan',
      kind: AccountKind.creator,
      status: AccountStatus.active,
      joined: _ago(d: 120),
      lastSeen: _ago(h: 2),
      events: 41,
      volume: 12600000,
    ),
    Account(
      id: 'U-1051',
      name: 'Koffi N’Guessan',
      email: 'koffi.ng@demo.ci',
      phone: '+225 01 22 33 44 55',
      city: 'Bouaké',
      kind: AccountKind.organizer,
      status: AccountStatus.active,
      joined: _ago(d: 21),
      lastSeen: _ago(d: 1),
      events: 1,
      volume: 650000,
    ),
    Account(
      id: 'U-1058',
      name: 'Lagune Sound',
      email: 'booking@lagunesound.demo',
      phone: '+225 07 77 88 99 00',
      city: 'Abidjan',
      kind: AccountKind.creator,
      status: AccountStatus.active,
      joined: _ago(d: 200),
      lastSeen: _ago(h: 5),
      events: 88,
      volume: 21400000,
    ),
    Account(
      id: 'U-1063',
      name: 'Fatou Konaté',
      email: 'fatou.k@demo.ci',
      phone: '+225 05 01 02 03 04',
      city: 'Yamoussoukro',
      kind: AccountKind.organizer,
      status: AccountStatus.suspended,
      joined: _ago(d: 40),
      lastSeen: _ago(d: 9),
      events: 2,
      volume: 300000,
      note: 'Trois rétrofacturations Mobile Money en 10 jours',
    ),
    Account(
      id: 'U-1070',
      name: 'Studio Lumière',
      email: 'hello@studiolumiere.demo',
      phone: '+225 07 12 12 12 12',
      city: 'Abidjan',
      kind: AccountKind.creator,
      status: AccountStatus.active,
      joined: _ago(d: 150),
      lastSeen: _ago(h: 1),
      events: 57,
      volume: 15800000,
    ),
    Account(
      id: 'U-1077',
      name: 'Délices d’Assinie',
      email: 'traiteur@assinie.demo',
      phone: '+225 01 98 76 54 32',
      city: 'Assinie',
      kind: AccountKind.creator,
      status: AccountStatus.pending,
      joined: _ago(d: 2),
      lastSeen: _ago(h: 3),
    ),
    Account(
      id: 'U-1080',
      name: 'Yasmine Ouattara',
      email: 'yasmine.o@demo.ci',
      phone: '+225 07 45 45 45 45',
      city: 'Abidjan',
      kind: AccountKind.organizer,
      status: AccountStatus.active,
      joined: _ago(d: 8),
      lastSeen: _ago(m: 40),
      events: 1,
      volume: 980000,
    ),
    Account(
      id: 'U-1084',
      name: 'Bassam Events',
      email: 'contact@bassamevents.demo',
      phone: '+225 05 66 55 44 33',
      city: 'Grand-Bassam',
      kind: AccountKind.creator,
      status: AccountStatus.pending,
      joined: _ago(d: 1),
      lastSeen: _ago(h: 20),
    ),
    Account(
      id: 'U-1089',
      name: 'Ibrahim Sangaré',
      email: 'ibra.s@demo.ci',
      phone: '+225 01 11 22 33 44',
      city: 'San-Pédro',
      kind: AccountKind.organizer,
      status: AccountStatus.active,
      joined: _ago(d: 33),
      lastSeen: _ago(d: 3),
      events: 2,
      volume: 1750000,
    ),
    Account(
      id: 'U-1093',
      name: 'DJ Kenzo',
      email: 'kenzo@demo.ci',
      phone: '+225 07 31 31 31 31',
      city: 'Abidjan',
      kind: AccountKind.creator,
      status: AccountStatus.suspended,
      joined: _ago(d: 90),
      lastSeen: _ago(d: 14),
      events: 12,
      volume: 2100000,
      note: 'Annulations répétées le jour J (4 signalements)',
    ),
    Account(
      id: 'U-1101',
      name: 'Mariam Touré',
      email: 'mariam.t@demo.ci',
      phone: '+225 05 80 80 80 80',
      city: 'Abidjan',
      kind: AccountKind.organizer,
      status: AccountStatus.active,
      joined: _ago(d: 5),
      lastSeen: _ago(h: 6),
      events: 1,
      volume: 0,
    ),
  ];

  static List<VendorDoc> _docs(List<DocStatus> s) => [
    VendorDoc('RCCM / registre de commerce', s[0]),
    VendorDoc('Pièce d’identité du gérant', s[1]),
    VendorDoc('Justificatif d’adresse', s[2]),
    VendorDoc('Portfolio (10 photos minimum)', s[3]),
  ];

  static final checks = <VendorCheck>[
    VendorCheck(
      id: 'V-301',
      business: 'Délices d’Assinie',
      owner: 'Rokia Fofana',
      category: 'Traiteur',
      zone: 'Assinie · Grand-Bassam',
      rccm: 'CI-GBS-2025-B-0412',
      submitted: _ago(d: 2),
      docs: _docs([
        DocStatus.submitted,
        DocStatus.submitted,
        DocStatus.submitted,
        DocStatus.submitted,
      ]),
    ),
    VendorCheck(
      id: 'V-302',
      business: 'Bassam Events',
      owner: 'Hervé Kouamé',
      category: 'Organisation',
      zone: 'Grand-Bassam',
      rccm: null,
      submitted: _ago(d: 1),
      docs: _docs([
        DocStatus.missing,
        DocStatus.submitted,
        DocStatus.submitted,
        DocStatus.submitted,
      ]),
    ),
    VendorCheck(
      id: 'V-298',
      business: 'Atelier Pagne Chic',
      owner: 'Salimata Cissé',
      category: 'Mode & beauté',
      zone: 'Abidjan · Treichville',
      rccm: 'CI-ABJ-2024-A-7781',
      submitted: _ago(d: 4),
      docs: _docs([
        DocStatus.valid,
        DocStatus.valid,
        DocStatus.invalid,
        DocStatus.submitted,
      ]),
      status: VerifyStatus.info,
      comment: 'Justificatif d’adresse de plus de 3 mois',
    ),
    VendorCheck(
      id: 'V-295',
      business: 'Bateaux d’Ébrié',
      owner: 'Paul Aké',
      category: 'Transport',
      zone: 'Abidjan · Lagune',
      rccm: 'CI-ABJ-2023-B-1120',
      submitted: _ago(d: 6),
      docs: _docs([
        DocStatus.valid,
        DocStatus.valid,
        DocStatus.valid,
        DocStatus.valid,
      ]),
      status: VerifyStatus.approved,
    ),
    VendorCheck(
      id: 'V-290',
      business: 'Sweet Cakes CI',
      owner: 'Grâce Ahoua',
      category: 'Gâteau',
      zone: 'Abidjan · Cocody',
      rccm: 'CI-ABJ-2025-A-0099',
      submitted: _ago(d: 3),
      docs: _docs([
        DocStatus.submitted,
        DocStatus.valid,
        DocStatus.submitted,
        DocStatus.submitted,
      ]),
    ),
  ];

  static final categories = <CatalogCategory>[
    const CatalogCategory(
      id: 'c1',
      name: 'Lieux',
      subcategories: ['Salles de réception', 'Jardins', 'Plages', 'Rooftops'],
      listings: 64,
    ),
    const CatalogCategory(
      id: 'c2',
      name: 'Traiteur',
      subcategories: [
        'Cuisine ivoirienne',
        'Buffets',
        'Cocktails',
        'Pâtisserie',
      ],
      listings: 92,
    ),
    const CatalogCategory(
      id: 'c3',
      name: 'Décoration',
      subcategories: ['Fleurs', 'Arches', 'Ballons', 'Scénographie'],
      listings: 71,
    ),
    const CatalogCategory(
      id: 'c4',
      name: 'Photo & vidéo',
      subcategories: ['Photographe', 'Vidéaste', 'Drone', 'Photobooth'],
      listings: 48,
    ),
    const CatalogCategory(
      id: 'c5',
      name: 'Musique & DJ',
      subcategories: ['DJ', 'Orchestre', 'Sonorisation', 'Griots'],
      listings: 55,
    ),
    const CatalogCategory(
      id: 'c6',
      name: 'Mode & beauté',
      subcategories: ['Tenues', 'Maquillage', 'Coiffure'],
      listings: 39,
    ),
    const CatalogCategory(
      id: 'c7',
      name: 'Transport',
      subcategories: ['Voitures de cérémonie', 'Navettes', 'Bateaux'],
      listings: 17,
      visible: false,
    ),
  ];

  static final listings = <Listing>[
    const Listing(
      id: 'L-881',
      title: 'Salle Prestige 300 places',
      vendor: 'Espace Latrille Events',
      category: 'Lieux',
      price: 1800000,
      status: ListingStatus.published,
      sponsored: true,
    ),
    const Listing(
      id: 'L-874',
      title: 'Buffet ivoirien 150 couverts',
      vendor: 'Saveurs d’Ivoire',
      category: 'Traiteur',
      price: 2250000,
      status: ListingStatus.published,
    ),
    const Listing(
      id: 'L-902',
      title: 'Arche florale blanc & or',
      vendor: 'Maison Inès Déco',
      category: 'Décoration',
      price: 450000,
      status: ListingStatus.review,
    ),
    const Listing(
      id: 'L-905',
      title: 'Pack DJ + sono 6 h',
      vendor: 'DJ Kenzo',
      category: 'Musique & DJ',
      price: 350000,
      status: ListingStatus.hidden,
      reports: 4,
    ),
    const Listing(
      id: 'L-910',
      title: 'Reportage photo journée',
      vendor: 'Studio Lumière',
      category: 'Photo & vidéo',
      price: 600000,
      status: ListingStatus.published,
    ),
    const Listing(
      id: 'L-913',
      title: 'Croisière lagune 40 invités',
      vendor: 'Bateaux d’Ébrié',
      category: 'Transport',
      price: 900000,
      status: ListingStatus.review,
    ),
    const Listing(
      id: 'L-917',
      title: 'Gâteau 5 étages personnalisé',
      vendor: 'Sweet Cakes CI',
      category: 'Traiteur',
      price: 220000,
      status: ListingStatus.published,
      reports: 2,
    ),
  ];

  static final orders = <Order>[
    Order(
      ref: 'EVT-0412',
      client: 'Awa Traoré',
      vendor: 'Espace Latrille Events',
      event: 'Mariage Awa & Koffi',
      date: _in(42),
      amount: 1800000,
      status: OrderStatus.confirmed,
      history: ['Acompte de 540 000 FCFA réglé (Wave)'],
    ),
    Order(
      ref: 'EVT-0498',
      client: 'Awa Traoré',
      vendor: 'Saveurs d’Ivoire',
      event: 'Mariage Awa & Koffi',
      date: _in(42),
      amount: 2250000,
      status: OrderStatus.changed,
      history: [
        'Acompte réglé',
        'Couverts passés de 120 à 150 (+450 000 FCFA)',
      ],
    ),
    Order(
      ref: 'EVT-0533',
      client: 'Yasmine Ouattara',
      vendor: 'DJ Kenzo',
      event: 'Les 30 ans de Yasmine',
      date: _ago(d: 3),
      amount: 350000,
      status: OrderStatus.dispute,
      dispute: 'Prestataire absent le jour J, la cliente demande le remboursement intégral',
      history: ['Acompte réglé (Orange Money)', 'Litige ouvert par la cliente'],
    ),
    Order(
      ref: 'EVT-0541',
      client: 'Ibrahim Sangaré',
      vendor: 'Studio Lumière',
      event: 'Séminaire San-Pédro',
      date: _in(12),
      amount: 600000,
      status: OrderStatus.confirmed,
    ),
    Order(
      ref: 'EVT-0550',
      client: 'Koffi N’Guessan',
      vendor: 'Lagune Sound',
      event: 'Anniversaire Koffi',
      date: _in(5),
      amount: 420000,
      status: OrderStatus.cancelled,
      history: ['Annulée par le client à J-20, acompte remboursé'],
    ),
    Order(
      ref: 'EVT-0556',
      client: 'Mariam Touré',
      vendor: 'Maison Inès Déco',
      event: 'Baby shower de Mariam',
      date: _ago(d: 6),
      amount: 380000,
      status: OrderStatus.completed,
      history: ['Prestation validée', 'Reversement effectué'],
    ),
    Order(
      ref: 'EVT-0561',
      client: 'Fatou Konaté',
      vendor: 'Sweet Cakes CI',
      event: 'Remise de diplôme',
      date: _ago(d: 1),
      amount: 220000,
      status: OrderStatus.dispute,
      dispute: 'Gâteau livré différent du modèle validé, remboursement partiel demandé (50 %)',
      history: ['Solde réglé (MTN MoMo)', 'Litige ouvert par la cliente'],
    ),
  ];

  static const _methods = [
    'Wave',
    'Orange Money',
    'MTN MoMo',
    'Moov Money',
    'Carte bancaire',
  ];
  static const _parties = [
    'Awa Traoré',
    'Yasmine Ouattara',
    'Ibrahim Sangaré',
    'Koffi N’Guessan',
    'Mariam Touré',
    'Lagune Sound',
    'Studio Lumière',
    'Maison Inès Déco',
  ];

  static int _seq = 7000;

  /// Transaction aléatoire plausible (flux temps réel de la démo).
  static Transaction randomTx(math.Random r, {DateTime? at}) {
    final roll = r.nextInt(100);
    final kind = roll < 70
        ? TxKind.payment
        : roll < 82
        ? TxKind.payout
        : roll < 93
        ? TxKind.subscription
        : TxKind.refund;
    final amount = switch (kind) {
      TxKind.subscription => const [1500, 2900, 5900, 15000][r.nextInt(4)],
      _ => (r.nextInt(60) + 3) * 25000,
    };
    final commission = switch (kind) {
      TxKind.payment => (amount * 0.10).round(),
      TxKind.subscription => amount,
      TxKind.refund => -(amount * 0.02).round(),
      TxKind.payout => 0,
    };
    final st = r.nextInt(100);
    return Transaction(
      ref: 'TX-${_seq++}',
      at: at ?? DateTime.now(),
      kind: kind,
      method: _methods[r.nextInt(_methods.length)],
      amount: kind == TxKind.refund || kind == TxKind.payout ? -amount : amount,
      commission: commission,
      status: st < 88
          ? TxStatus.success
          : st < 95
          ? TxStatus.pending
          : TxStatus.failed,
      party: _parties[r.nextInt(_parties.length)],
      reconciled: r.nextInt(100) < 75,
    );
  }

  static List<Transaction> transactions() {
    final r = math.Random(42);
    return [for (var i = 0; i < 40; i++) randomTx(r, at: _ago(m: i * 37 + 3))];
  }

  static final promos = <PromoCode>[
    PromoCode(
      code: 'MARIAGE26',
      label: 'Mariages · saison sèche',
      percent: 10,
      uses: 184,
      limit: 500,
      expires: _in(60),
    ),
    PromoCode(
      code: 'BIENVENUE',
      label: 'Premier événement',
      percent: 15,
      uses: 912,
      limit: 2000,
      expires: _in(120),
    ),
    PromoCode(
      code: 'TABASKI',
      label: 'Fête de Tabaski',
      percent: 8,
      uses: 300,
      limit: 300,
      expires: _ago(d: 20),
      active: false,
    ),
  ];

  static final campaigns = <Campaign>[
    const Campaign(
      id: 'K1',
      name: 'Relance des devis non acceptés',
      channel: 'WhatsApp',
      audience: 'Organisateurs avec devis en attente',
      status: CampaignStatus.running,
      sent: 1240,
      openRate: 0.71,
      conversions: 96,
    ),
    const Campaign(
      id: 'K2',
      name: 'Lancement Signature',
      channel: 'E-mail',
      audience: 'Organisateurs Découverte actifs',
      status: CampaignStatus.done,
      sent: 8650,
      openRate: 0.38,
      conversions: 214,
    ),
    const Campaign(
      id: 'K3',
      name: 'Fêtes de fin d’année',
      channel: 'Push',
      audience: 'Tous les organisateurs',
      status: CampaignStatus.scheduled,
    ),
    const Campaign(
      id: 'K4',
      name: 'Boostez votre fiche',
      channel: 'SMS',
      audience: 'Creators sans Publicité Premium',
      status: CampaignStatus.draft,
    ),
  ];

  static final tickets = <Ticket>[
    Ticket(
      id: 'T-2207',
      subject: 'Prestataire absent le jour J',
      from: 'Yasmine Ouattara',
      channel: 'WhatsApp',
      priority: TicketPriority.urgent,
      status: TicketStatus.open,
      created: _ago(h: 2),
      messages: [
        'Le DJ ne s’est jamais présenté, j’ai payé l’acompte. Je veux être remboursée.',
      ],
    ),
    Ticket(
      id: 'T-2205',
      subject: 'Paiement Wave débité deux fois',
      from: 'Ibrahim Sangaré',
      channel: 'In-app',
      priority: TicketPriority.high,
      status: TicketStatus.progress,
      created: _ago(h: 7),
      assignee: 'Karen Akablan',
      messages: [
        'J’ai été débité deux fois de 180 000 FCFA.',
        'Nous vérifions avec Wave, réponse sous 24 h.',
      ],
    ),
    Ticket(
      id: 'T-2201',
      subject: 'Comment ajouter un co-organisateur ?',
      from: 'Mariam Touré',
      channel: 'E-mail',
      priority: TicketPriority.low,
      status: TicketStatus.waiting,
      created: _ago(d: 1),
      assignee: 'Aïcha Diallo',
    ),
    Ticket(
      id: 'T-2198',
      subject: 'Mon profil n’apparaît pas dans Explorer',
      from: 'Bassam Events',
      channel: 'E-mail',
      priority: TicketPriority.normal,
      status: TicketStatus.open,
      created: _ago(d: 1, h: 4),
    ),
    Ticket(
      id: 'T-2190',
      subject: 'Facture pour mon entreprise',
      from: 'Koffi N’Guessan',
      channel: 'Téléphone',
      priority: TicketPriority.normal,
      status: TicketStatus.resolved,
      created: _ago(d: 3),
      assignee: 'Aïcha Diallo',
    ),
  ];

  static final audit = <AuditEntry>[
    AuditEntry(
      at: _ago(m: 25),
      actor: 'Serge Yao',
      action: 'Annonce masquée',
      target: 'L-905 · Pack DJ + sono 6 h',
    ),
    AuditEntry(
      at: _ago(h: 3),
      actor: 'Karen Akablan',
      action: 'Rapprochement validé',
      target: 'Relevé Wave du jour',
    ),
    AuditEntry(
      at: _ago(d: 1),
      actor: 'Jean-Jacques Djipro',
      action: 'Rôle modifié',
      target: 'Marc Gnahoré → Marketing',
    ),
    AuditEntry(
      at: _ago(d: 2),
      actor: 'Serge Yao',
      action: 'Prestataire vérifié',
      target: 'V-295 · Bateaux d’Ébrié',
    ),
    AuditEntry(
      at: _ago(d: 9),
      actor: 'Jean-Jacques Djipro',
      action: 'Compte suspendu',
      target: 'U-1063 · Fatou Konaté',
    ),
  ];

  // ─── Séries pour les analytics (12 derniers mois) ───────────────────

  static const signups = [
    420,
    510,
    640,
    590,
    720,
    880,
    1040,
    990,
    1210,
    1380,
    1520,
    1690,
  ];
  static const gmv = [
    38,
    44,
    52,
    49,
    61,
    74,
    88,
    81,
    97,
    112,
    126,
    141,
  ]; // millions FCFA
  static const revenue = [
    3.1,
    3.6,
    4.3,
    4.0,
    5.1,
    6.2,
    7.4,
    6.9,
    8.3,
    9.6,
    10.9,
    12.2,
  ]; // millions FCFA
  static const channels = {
    'Bouche-à-oreille': 0.34,
    'Instagram & TikTok': 0.27,
    'WhatsApp (parrainage)': 0.19,
    'Prestataires partenaires': 0.12,
    'Recherche Google': 0.08,
  };

  /// Rétention des cohortes : % d'actifs aux mois 1, 2, 3 après l'inscription.
  static const cohorts = {
    'Juin': [62, 48, 41],
    'Juillet': [65, 51, 44],
    'Août': [68, 53, 45],
    'Septembre': [71, 56, null],
    'Octobre': [73, null, null],
  };
}

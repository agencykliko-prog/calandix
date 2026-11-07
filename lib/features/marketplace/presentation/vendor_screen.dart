import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../inbox/presentation/inbox_providers.dart';
import 'widgets/vendor_card.dart';
import '../data/vendor_media.dart';

class VendorScreen extends ConsumerWidget {
  const VendorScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = Catalog.vendor(id);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 320,
            backgroundColor: Confetti.cream,
            automaticallyImplyLeading: false,
            titleSpacing: 12,
            title: Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                RoundIconButton(
                  icon: AppIcons.share,
                  tooltip: 'Partager',
                  onTap: () => toast(context, 'Lien de la fiche copié'.tr),
                ),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'vendor-${v.id}',
                child: VendorPhoto(v.image, cacheWidth: 1200),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Tag(
                        label: v.category.label,
                        hue: Hue.mango,
                        icon: v.category.icon,
                      ),
                      if (v.verified)
                        Tag(
                          label: 'Vérifié'.tr,
                          hue: Hue.violet,
                          icon: AppIcons.verified,
                        ),
                      if (Catalog.qualityOf(v))
                        Tag(
                          label: 'Qualité Calandix'.tr,
                          hue: Hue.candy,
                          icon: AppIcons.star,
                        ),
                      if (!Catalog.planOf(v).free)
                        Tag(
                          label: 'Formule {0}'.trf([Catalog.planOf(v).label]),
                          hue: Hue.gold,
                          icon: AppIcons.crown,
                        ),
                      if (v.sponsor != null) SponsorTag(sponsor: v.sponsor!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Pressable(
                    onTap: () => showBadgesInfo(context, v),
                    child: Text(
                      'Que signifient ces badges ?'.tr,
                      style: context.text.labelMedium?.copyWith(
                        color: Confetti.coralDeep,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(v.name, style: context.text.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    v.tagline,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.eventa.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Note, zone et délai passent à la ligne sur écran étroit.
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Stars(rating: v.rating, reviews: v.reviews, size: 14),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.place,
                            size: 15,
                            color: Confetti.inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            v.zone,
                            style: context.text.labelMedium?.copyWith(
                              color: context.eventa.muted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.clock,
                            size: 15,
                            color: Confetti.inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Répond en {0}'.trf([v.responseTime]),
                            style: context.text.labelMedium?.copyWith(
                              color: context.eventa.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tarif'.tr,
                                style: context.text.labelSmall?.copyWith(
                                  color: context.eventa.muted,
                                ),
                              ),
                              Text(
                                priceLabel(v),
                                style: context.text.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 34, color: Confetti.line),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Disponibilité'.tr,
                                style: context.text.labelSmall?.copyWith(
                                  color: context.eventa.muted,
                                ),
                              ),
                              Text(
                                v.available
                                    ? 'Disponible'.tr
                                    : (v.nextAvailable ?? 'Complet'.tr),
                                style: context.text.titleSmall?.copyWith(
                                  color: v.available
                                      ? Confetti.success
                                      : Confetti.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('À propos'.tr, style: context.text.titleLarge),
                  const SizedBox(height: 8),
                  Text(v.description, style: context.text.bodyLarge),
                  const SizedBox(height: 26),
                  Text('Portfolio'.tr, style: context.text.titleLarge),
                  const SizedBox(height: 10),
                  _Portfolio(photos: VendorMedia.portfolioOf(v)),
                  const SizedBox(height: 26),
                  Text('Coordonnées'.tr, style: context.text.titleLarge),
                  const SizedBox(height: 10),
                  _InfoList(
                    rows: [
                      (AppIcons.phone, v.phoneNumber),
                      (AppIcons.mail, v.email),
                      (AppIcons.globe, v.website),
                      (AppIcons.place, '{0}, Abidjan'.trf([v.zone])),
                    ],
                  ),
                  if (v.packages.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text('Formules'.tr, style: context.text.titleLarge),
                    const SizedBox(height: 10),
                    _InfoList(
                      rows: [for (final p in v.packages) (null, p.name)],
                      captions: [
                        for (final p in v.packages)
                          p.conditions == null
                              ? p.description
                              : '{0}\nConditions : {1}'.trf([
                                  p.description,
                                  p.conditions!,
                                ]),
                      ],
                      trailing: [for (final p in v.packages) fcfa(p.price)],
                    ),
                  ],
                  const SizedBox(height: 26),
                  ReviewsSection(vendor: v),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(vendor: v),
    );
  }
}

/// Portfolio : cinq réalisations, la première en grand ; un toucher ouvre
/// la photo en plein écran.
class _Portfolio extends StatelessWidget {
  const _Portfolio({required this.photos});

  final List<String> photos;

  void _open(BuildContext context, int i) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: PageView(
          controller: PageController(initialPage: i),
          children: [
            for (final p in photos)
              InteractiveViewer(
                child: Center(child: VendorPhoto(p, fit: BoxFit.contain)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(int i) => Pressable(
      onTap: () => _open(context, i),
      semanticLabel: 'Photo {0} du portfolio'.trf([i + 1]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: VendorPhoto(photos[i], cacheWidth: i == 0 ? 900 : 400),
      ),
    );
    return SizedBox(
      height: 260,
      child: Row(
        children: [
          Expanded(flex: 3, child: tile(0)),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: tile(1)),
                      const SizedBox(width: 8),
                      Expanded(child: tile(2)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: tile(3)),
                      const SizedBox(width: 8),
                      Expanded(child: tile(4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vendor;
    Widget contact(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
    ) => SizedBox(
      width: 58,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: context.text.labelSmall),
          ],
        ),
      ),
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Confetti.surface,
        border: Border(top: BorderSide(color: Confetti.line)),
      ),
      child: Row(
        children: [
          contact(
            AppIcons.phone,
            'Appeler'.tr,
            Confetti.ink,
            () => toast(
              context,
              'Appel vers {0}'.trf([v.phone]),
              icon: AppIcons.phone,
            ),
          ),
          contact(
            AppIcons.message,
            'Message'.tr,
            Confetti.violet,
            () => _messageSheet(context, ref, v),
          ),
          contact(
            AppIcons.whatsapp,
            'WhatsApp'.tr,
            Confetti.success,
            () => toast(
              context,
              'Ouverture de WhatsApp avec {0}'.trf([v.name]),
              icon: AppIcons.whatsapp,
            ),
          ),
          const SizedBox(width: 8),
          // Le libellé complet doit rester lisible : version courte sur
          // les téléphones étroits plutôt qu'un texte tronqué.
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => PillButton(
                key: const ValueKey('request-quote'),
                label: box.maxWidth >= 190
                    ? 'Demander un devis'.tr
                    : 'Devis'.tr,
                icon: box.maxWidth >= 190 ? null : AppIcons.file,
                height: 50,
                onPressed: () => showQuoteRequestSheet(context, ref, v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Premier message au prestataire : la conversation s'ouvre ensuite dans
  /// la messagerie, où arrive sa réponse.
  void _messageSheet(BuildContext context, WidgetRef ref, Vendor v) {
    final c = TextEditingController(
      text: 'Bonjour, êtes-vous disponible à ma date ?'.tr,
    );
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message à {0}'.trf([v.name]), style: ctx.text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Répond généralement en {0}.'.trf([v.responseTime]),
              style: ctx.text.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(controller: c, maxLines: 4, minLines: 3, autofocus: true),
            const SizedBox(height: 14),
            PillButton(
              label: 'Envoyer'.tr,
              icon: AppIcons.send,
              tone: ButtonTone.dark,
              onPressed: () {
                final text = c.text.trim();
                if (text.isEmpty) return;
                ref.read(directThreadsProvider.notifier).send(v, text);
                Navigator.of(ctx).pop();
                context.push(Routes.conversation(directConversationId(v)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Demande pré-remplie (par le concierge) : événement, invités, budget du
/// poste et premier message.
@immutable
class QuotePrefill {
  const QuotePrefill({this.eventId, this.guests, this.budget, this.message});
  final String? eventId;
  final int? guests;
  final int? budget;
  final String? message;
}

/// Étape 2 : demande de devis personnalisée.
Future<void> showQuoteRequestSheet(
  BuildContext context,
  WidgetRef ref,
  Vendor v, {
  QuotePrefill? prefill,
}) async {
  final events = ref.read(eventsProvider).value ?? const <Event>[];
  if (events.isEmpty) {
    toast(context, 'Créez d’abord un événement'.tr, icon: AppIcons.info);
    return;
  }
  final bookingId = await showEventaSheet<String>(
    context,
    builder: (_) => _QuoteRequest(vendor: v, events: events, prefill: prefill),
  );
  if (bookingId != null && context.mounted) {
    context.push(Routes.booking(bookingId));
  }
}

/// Une question propre au métier du prestataire (choix simple ou multiple).
class _Need {
  const _Need(this.label, this.options, {this.multi = false});
  final String label;
  final List<String> options;
  final bool multi;
}

/// Ce que chaque métier a besoin de savoir pour chiffrer juste.
const _needs = <VendorCategory, List<_Need>>{
  VendorCategory.venue: [
    _Need('Durée', ['Soirée', 'Journée', 'Week-end']),
    _Need('Espace', ['Intérieur', 'Extérieur', 'Les deux']),
    _Need('Sur place', [
      'Parking',
      'Hébergement',
      'Cuisine équipée',
    ], multi: true),
  ],
  VendorCategory.decor: [
    _Need('Éléments', [
      'Arche',
      'Centres de table',
      'Scène',
      'Ballons',
      'Éclairage',
    ], multi: true),
    _Need('Style', ['Traditionnel', 'Moderne', 'Bohème', 'Glamour']),
  ],
  VendorCategory.catering: [
    _Need('Service', ['Buffet', 'Service à table', 'Cocktail dînatoire']),
    _Need('Régimes', [
      'Sans porc',
      'Halal',
      'Végétarien',
      'Sans piment',
    ], multi: true),
    _Need('En plus', ['Boissons', 'Gâteau', 'Vaisselle'], multi: true),
  ],
  VendorCategory.photo: [
    _Need('Couverture', ['Cérémonie', 'Soirée', 'Journée complète']),
    _Need('Livrables', [
      'Photos retouchées',
      'Film',
      'Drone',
      'Album imprimé',
    ], multi: true),
  ],
  VendorCategory.music: [
    _Need('Prestation', ['DJ', 'Live', 'Maître de cérémonie']),
    _Need('Ambiance', [
      'Coupé-décalé',
      'Afro',
      'Zouk',
      'Gospel',
      'Classiques',
    ], multi: true),
  ],
  VendorCategory.rental: [
    _Need('Articles', [
      'Chaises',
      'Tables',
      'Nappes',
      'Vaisselle',
      'Tentes',
      'Sono',
    ], multi: true),
  ],
  VendorCategory.beauty: [
    _Need('Prestation', [
      'Maquillage',
      'Coiffure',
      'Tenue sur mesure',
    ], multi: true),
    _Need('Pour', ['La mariée', 'Le marié', 'Le cortège']),
  ],
  VendorCategory.paper: [
    _Need('Supports', [
      'Faire-part',
      'Menus',
      'Plan de table',
      'Invitations numériques',
    ], multi: true),
  ],
  VendorCategory.transport: [
    _Need('Véhicule', [
      'Berline',
      'Limousine',
      'Voiture de collection',
      'Minibus',
    ]),
    _Need('En plus', ['Décoration du véhicule', 'Aller-retour'], multi: true),
  ],
  VendorCategory.staff: [
    _Need('Rôles', ['Serveurs', 'Hôtesses', 'Sécurité', 'Barmen'], multi: true),
  ],
  VendorCategory.planner: [
    _Need('Mission', [
      'Coordination du jour J',
      'Organisation complète',
      'Conseil',
    ]),
    _Need('Étapes', [
      'Dot',
      'Mariage civil',
      'Cérémonie religieuse',
      'Réception',
    ], multi: true),
  ],
  VendorCategory.activity: [
    _Need('Format', ['Privatisation', 'Places individuelles']),
  ],
};

class _QuoteRequest extends ConsumerStatefulWidget {
  const _QuoteRequest({
    required this.vendor,
    required this.events,
    this.prefill,
  });

  final Vendor vendor;
  final List<Event> events;
  final QuotePrefill? prefill;

  @override
  ConsumerState<_QuoteRequest> createState() => _QuoteRequestState();
}

class _QuoteRequestState extends ConsumerState<_QuoteRequest> {
  late Event _event =
      widget.events.where((e) => e.id == widget.prefill?.eventId).firstOrNull ??
      widget.events.first;
  late double _guests = (widget.prefill?.guests ?? _event.guests.invited)
      .clamp(1, 5000)
      .toDouble();
  late final _guestsCtrl = TextEditingController(
    text: _guests.round().toString(),
  );
  final _answers = <String, Set<String>>{};
  late VendorPackage? _package = widget.vendor.packages.isEmpty
      ? null
      : widget.vendor.packages.first;
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  String? _budget;
  bool _delivery = false;
  final _address = TextEditingController();
  bool _staff = false;
  int _staffCount = 2;
  bool _tasting = false;
  String _tastingWhen = 'En semaine'.tr;
  bool _overtime = false;
  int _hours = 2;
  late final _message = TextEditingController();
  bool _sending = false;

  static const _budgets = [
    'Moins de 250 000 FCFA',
    '250 000 – 500 000 FCFA',
    '500 000 – 1 000 000 FCFA',
    '1 000 000 – 3 000 000 FCFA',
    'Plus de 3 000 000 FCFA',
  ];

  @override
  void initState() {
    super.initState();
    _address.text = _event.venue;
    final p = widget.prefill;
    if (p?.message != null) _message.text = p!.message!;
    if (p?.budget case final b?) {
      _budget = b < 250000
          ? _budgets[0]
          : b < 500000
          ? _budgets[1]
          : b < 1000000
          ? _budgets[2]
          : b <= 3000000
          ? _budgets[3]
          : _budgets[4];
    }
  }

  @override
  void dispose() {
    _guestsCtrl.dispose();
    _message.dispose();
    _address.dispose();
    super.dispose();
  }

  VendorCategory get _cat => widget.vendor.category;
  bool get _canDeliver => const {
    VendorCategory.decor,
    VendorCategory.rental,
    VendorCategory.catering,
    VendorCategory.paper,
  }.contains(_cat);
  bool get _canStaff => const {
    VendorCategory.catering,
    VendorCategory.venue,
    VendorCategory.planner,
    VendorCategory.staff,
  }.contains(_cat);
  bool get _canTaste =>
      const {VendorCategory.catering, VendorCategory.beauty}.contains(_cat);
  bool get _canOvertime => const {
    VendorCategory.music,
    VendorCategory.photo,
    VendorCategory.staff,
    VendorCategory.venue,
    VendorCategory.transport,
  }.contains(_cat);

  /// Estimation indicative : formule × invités quand le prix est par
  /// personne ou par pièce, sinon le prix de la formule.
  int? get _estimate {
    final price = _package?.price ?? widget.vendor.priceFrom;
    final perHead =
        widget.vendor.unit == 'pers.' || widget.vendor.unit == 'pièce';
    return perHead ? price * _guests.round() : price;
  }

  void _setGuests(int n) {
    final v = n.clamp(1, 5000);
    setState(() => _guests = v.toDouble());
    final t = v.toString();
    if (_guestsCtrl.text != t) _guestsCtrl.text = t;
  }

  List<String> get _options => [
    if (_package != null) 'Formule : {0}'.trf([_package!.name]),
    for (final e in _answers.entries)
      if (e.value.isNotEmpty)
        '${e.key.tr} : ${e.value.map((x) => x.tr).join(', ')}',
    'Début : {0}:{1}'.trf([
      _start.hour.toString().padLeft(2, '0'),
      _start.minute.toString().padLeft(2, '0'),
    ]),
    if (_budget != null) 'Budget : {0}'.trf([_budget]),
    if (_delivery)
      'Livraison & installation ({0})'.trf([
        _address.text.trim().isEmpty
            ? 'adresse à préciser'.tr
            : _address.text.trim(),
      ]),
    if (_staff) 'Personnel supplémentaire × {0}'.trf([_staffCount]),
    if (_tasting) 'Dégustation ou essai ({0})'.trf([_tastingWhen]),
    if (_overtime) 'Heures supplémentaires × {0} h'.trf([_hours]),
  ];

  Future<void> _send() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final extras = _options
        .where(
          (o) =>
              !o.startsWith('Formule') &&
              !o.startsWith('Début') &&
              !o.startsWith('Budget'),
        )
        .toList();
    _guests = (int.tryParse(_guestsCtrl.text) ?? _guests.round())
        .clamp(1, 5000)
        .toDouble();
    final id = ref
        .read(bookingsProvider.notifier)
        .request(
          widget.vendor,
          _event.id,
          QuoteRequest(
            date: DateTime(
              _event.date.year,
              _event.date.month,
              _event.date.day,
              _start.hour,
              _start.minute,
            ),
            guests: _guests.round(),
            message: [
              if (_message.text.trim().isNotEmpty) _message.text.trim(),
              ..._options,
            ].join('\n'),
            options: extras,
          ),
        );
    if (mounted) Navigator.of(context).pop(id);
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) => Pressable(
    onTap: onTap,
    scale: 0.9,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Confetti.cream,
        shape: BoxShape.circle,
        border: Border.all(color: Confetti.line),
      ),
      child: Icon(icon, size: 14, color: Confetti.ink),
    ),
  );

  Widget _choice(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) => Pressable(
    onTap: onTap,
    scale: 0.96,
    child: AnimatedContainer(
      duration: Motion.fast,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? Confetti.ink : Confetti.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? Confetti.ink : Confetti.line),
      ),
      child: Text(
        label,
        style: context.text.labelMedium?.copyWith(
          color: selected ? Confetti.onInk : Confetti.ink,
        ),
      ),
    ),
  );

  Widget _stepper(
    int value,
    ValueChanged<int> onChanged, {
    int min = 1,
    int max = 20,
    String unit = '',
  }) {
    Widget b(IconData i, VoidCallback? f) => Pressable(
      onTap: f,
      scale: 0.9,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Confetti.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Confetti.line),
        ),
        child: Icon(
          i,
          size: 14,
          color: f == null ? Confetti.inkFaint : Confetti.ink,
        ),
      ),
    );
    return Row(
      children: [
        b(AppIcons.minus, value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 56,
          child: Text(
            '$value$unit',
            textAlign: TextAlign.center,
            style: context.text.titleSmall,
          ),
        ),
        b(AppIcons.add, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demande de devis'.tr, style: context.text.headlineSmall),
          Text(
            '{0} · gratuit et sans engagement'.trf([v.name]),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 18),
          AppSelect<Event>(
            label: 'Événement'.tr,
            value: _event,
            options: widget.events,
            labelOf: (e) => '${e.name} · ${shortDate(e.date)}',
            iconOf: (e) => e.category.icon,
            onChanged: (e) {
              setState(() {
                _event = e;
                _address.text = e.venue;
              });
              _setGuests(e.guests.invited);
            },
          ),
          if (v.packages.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppSelect<VendorPackage>(
              label: 'Formule souhaitée'.tr,
              value: _package,
              options: v.packages,
              labelOf: (p) => '${p.name} · ${fcfa(p.price)}',
              onChanged: (p) => setState(() => _package = p),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel('Heure de début'.tr),
                    Pressable(
                      scale: 0.98,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (t != null) setState(() => _start = t);
                      },
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Confetti.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Confetti.line),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.clock,
                              size: 18,
                              color: Confetti.inkMuted,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _start.format(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FieldLabel('Nombre d’invités'.tr),
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Confetti.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Confetti.line),
                      ),
                      child: Row(
                        children: [
                          _roundBtn(
                            AppIcons.minus,
                            () => _setGuests(_guests.round() - 10),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _guestsCtrl,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: context.text.titleSmall,
                              decoration: const InputDecoration(
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (t) {
                                final n = int.tryParse(t);
                                if (n != null && n > 0) {
                                  setState(() => _guests = n.toDouble());
                                }
                              },
                            ),
                          ),
                          _roundBtn(
                            AppIcons.add,
                            () => _setGuests(_guests.round() + 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppSelect<String>(
            label: 'Budget indicatif'.tr,
            value: _budget,
            options: _budgets,
            labelOf: (b) => b.tr,
            optional: true,
            onChanged: (b) => setState(() => _budget = b),
          ),
          for (final need in _needs[_cat] ?? const <_Need>[]) ...[
            const SizedBox(height: 16),
            FieldLabel(
              need.multi
                  ? '{0} (plusieurs choix)'.trf([need.label.tr])
                  : need.label.tr,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in need.options)
                  _choice(
                    o.tr,
                    selected: _answers[need.label]?.contains(o) ?? false,
                    onTap: () => setState(() {
                      final set = _answers.putIfAbsent(need.label, () => {});
                      if (need.multi) {
                        set.contains(o) ? set.remove(o) : set.add(o);
                      } else {
                        set
                          ..clear()
                          ..add(o);
                      }
                    }),
                  ),
              ],
            ),
          ],
          if (_estimate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Confetti.lavender,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.coins, size: 18, color: Confetti.violet),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.vendor.unit == 'pers.' ||
                              widget.vendor.unit == 'pièce'
                          ? 'Estimation pour {0} invités'.trf([_guests.round()])
                          : 'Estimation de la formule'.tr,
                      style: context.text.bodySmall,
                    ),
                  ),
                  Text(
                    fcfa(_estimate!),
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_canDeliver || _canStaff || _canTaste || _canOvertime) ...[
            const SizedBox(height: 18),
            FieldLabel('Options'.tr),
          ],
          if (_canDeliver)
            CheckRow(
              label: 'Livraison & installation'.tr,
              caption: 'Le prestataire s’installe sur place'.tr,
              value: _delivery,
              onChanged: (x) => setState(() => _delivery = x),
              revealed: TextField(
                controller: _address,
                decoration: InputDecoration(
                  hintText: 'Adresse du lieu'.tr,
                  prefixIcon: Icon(AppIcons.place, size: 18),
                ),
              ),
            ),
          if (_canStaff) ...[
            const SizedBox(height: 8),
            CheckRow(
              label: 'Personnel supplémentaire'.tr,
              value: _staff,
              onChanged: (x) => setState(() => _staff = x),
              revealed: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nombre de personnes'.tr,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  _stepper(_staffCount, (n) => setState(() => _staffCount = n)),
                ],
              ),
            ),
          ],
          if (_canTaste) ...[
            const SizedBox(height: 8),
            CheckRow(
              label: _cat == VendorCategory.beauty
                  ? 'Essai avant le jour J'.tr
                  : 'Dégustation'.tr,
              value: _tasting,
              onChanged: (x) => setState(() => _tasting = x),
              revealed: Wrap(
                spacing: 8,
                children: [
                  for (final w in [
                    'En semaine'.tr,
                    'Le week-end'.tr,
                    'Peu importe'.tr,
                  ])
                    ChoiceChip(
                      label: Text(w),
                      selected: _tastingWhen == w,
                      showCheckmark: false,
                      selectedColor: Confetti.ink,
                      labelStyle: context.text.labelMedium?.copyWith(
                        color: _tastingWhen == w
                            ? Confetti.onInk
                            : Confetti.ink,
                      ),
                      backgroundColor: Confetti.surface,
                      side: BorderSide(
                        color: _tastingWhen == w ? Confetti.ink : Confetti.line,
                      ),
                      onSelected: (_) => setState(() => _tastingWhen = w),
                    ),
                ],
              ),
            ),
          ],
          if (_canOvertime) ...[
            const SizedBox(height: 8),
            CheckRow(
              label: 'Heures supplémentaires'.tr,
              value: _overtime,
              onChanged: (x) => setState(() => _overtime = x),
              revealed: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Durée en plus'.tr,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  _stepper(
                    _hours,
                    (n) => setState(() => _hours = n),
                    max: 8,
                    unit: ' h',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppField(
            label: 'Message au prestataire'.tr,
            controller: _message,
            optional: true,
            maxLines: 3,
            hint: 'Votre thème, vos contraintes, vos questions…'.tr,
          ),
          const SizedBox(height: 20),
          PillButton(
            label: 'Envoyer la demande'.tr,
            icon: AppIcons.send,
            loading: _sending,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

/// Liste sobre : une ligne par information, séparateurs fins.
class _InfoList extends StatelessWidget {
  const _InfoList({required this.rows, this.captions, this.trailing});

  final List<(IconData?, String)> rows;
  final List<String>? captions;
  final List<String>? trailing;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  if (rows[i].$1 != null) ...[
                    Icon(rows[i].$1, size: 18, color: Confetti.inkMuted),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$2, style: context.text.titleSmall),
                        if (captions != null)
                          Text(captions![i], style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    Text(trailing![i], style: context.text.titleSmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Avis vérifiés : la note d'abord, puis chaque avis sur une ligne nette
/// (étoiles, date, commentaire, auteur et statut de vérification).
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key, required this.vendor});

  final Vendor vendor;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final reviews = _all ? Catalog.reviews : Catalog.reviews.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avis vérifiés'.tr, style: context.text.titleLarge),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              v.rating.toStringAsFixed(1).replaceAll('.', ','),
              style: context.text.displaySmall?.copyWith(
                fontSize: 40,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StarRow(rating: v.rating.round(), size: 15),
                    const SizedBox(height: 3),
                    Text(
                      '{0} avis de clients ayant réservé'.trf([v.reviews]),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (final (i, r) in reviews.indexed) ...[
                const Divider(height: 1),
                Entrance(
                  key: ValueKey(r.author),
                  index: i < 3 ? 0 : i - 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StarRow(rating: r.rating, size: 13),
                            const Spacer(),
                            Text(
                              r.when,
                              style: context.text.labelSmall?.copyWith(
                                color: Confetti.inkFaint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.text, style: context.text.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(r.author, style: context.text.labelMedium),
                            const SizedBox(width: 8),
                            Icon(
                              AppIcons.verified,
                              size: 13,
                              color: Confetti.lagoonText,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'Réservation vérifiée'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.labelSmall?.copyWith(
                                  color: Confetti.lagoonText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (Catalog.reviews.length > 3)
          TextButton(
            onPressed: () => setState(() => _all = !_all),
            child: Text(
              _all
                  ? 'Voir moins'.tr
                  : 'Voir les {0} avis'.trf([Catalog.reviews.length]),
              style: context.text.labelMedium?.copyWith(
                color: Confetti.coralDeep,
              ),
            ),
          ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.size});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 5; i++)
        Icon(
          i < rating ? AppIcons.star : AppIcons.starLine,
          size: size,
          color: i < rating ? Confetti.mango : Confetti.inkFaint,
        ),
    ],
  );
}

/// Les trois badges d'une fiche, expliqués à l'organisateur.
void showBadgesInfo(BuildContext context, Vendor v) {
  final plan = Catalog.planOf(v);
  final quality = Catalog.qualityOf(v);
  Widget row(IconData icon, Hue hue, String title, String body, bool on) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: icon, hue: hue, size: 36, solid: on),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(body, style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
  showEventaSheet<void>(
    context,
    builder: (ctx) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Les badges de {0}'.trf([v.name]), style: ctx.text.headlineSmall),
        const SizedBox(height: 16),
        row(
          AppIcons.verified,
          Hue.violet,
          v.verified ? 'Profil vérifié'.tr : 'Profil non vérifié'.tr,
          'L’équipe Calandix a contrôlé la pièce d’identité, le RCCM, l’adresse et des réalisations.'
              .tr,
          v.verified,
        ),
        row(
          AppIcons.star,
          Hue.candy,
          quality ? 'Qualité Calandix'.tr : 'Badge de qualité non obtenu'.tr,
          'Attribué sur des critères objectifs : note moyenne d’au moins 4,5, au moins 10 avis vérifiés, prestations réalisées et réponses rapides.'
              .tr,
          quality,
        ),
        row(
          AppIcons.crown,
          Hue.gold,
          plan.free ? 'Sans abonnement'.tr : 'Formule {0}'.trf([plan.label]),
          'Indique la formule souscrite. Il ne dit rien de la qualité des prestations.'
              .tr,
          !plan.free,
        ),
      ],
    ),
  );
}

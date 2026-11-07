import 'package:flutter/material.dart';

import '../../events/presentation/event_trash.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../marketplace/presentation/vendor_screen.dart';
import '../../events/presentation/events_providers.dart';

/// Besoins compris dans la demande faite au concierge.
class ConciergeBrief {
  const ConciergeBrief({
    required this.guests,
    required this.budget,
    required this.needs,
    required this.city,
  });

  final int guests;
  final int budget;
  final List<VendorCategory> needs;
  final String city;
}

/// Répartition type du budget (la même que le simulateur de la landing).
const _shares = <VendorCategory, int>{
  VendorCategory.venue: 28,
  VendorCategory.catering: 24,
  VendorCategory.decor: 14,
  VendorCategory.music: 12,
  VendorCategory.photo: 12,
  VendorCategory.beauty: 10,
};

const _keywords = <VendorCategory, List<String>>{
  VendorCategory.venue: ['salle', 'lieu', 'domaine', 'espace'],
  VendorCategory.catering: [
    'traiteur',
    'repas',
    'restauration',
    'cuisine',
    'buffet',
  ],
  VendorCategory.decor: ['décor', 'deco', 'déco', 'fleur'],
  VendorCategory.photo: ['photo', 'vidéo', 'video', 'caméra'],
  VendorCategory.music: ['dj', 'musique', 'animation', 'orchestre', 'son'],
  VendorCategory.beauty: ['tenue', 'maquill', 'coiff', 'beauté', 'robe'],
  VendorCategory.rental: ['location', 'chaise', 'tente', 'bâche'],
  VendorCategory.transport: ['transport', 'voiture', 'car ', 'navette'],
  VendorCategory.paper: ['invitation', 'faire-part', 'papeterie'],
};

/// Lit la demande en langage courant : nombre d'invités, budget, besoins.
ConciergeBrief readBrief(String text, Event e) {
  final t = text.toLowerCase();
  int? guests;
  final g = RegExp(r'(\d[\d  ]*)\s*(personnes|invités|invites|pers)')
      .firstMatch(t);
  if (g != null) {
    guests = int.tryParse(g.group(1)!.replaceAll(RegExp(r'\D'), ''));
  }
  int? budget;
  final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*(millions?|m\b)').firstMatch(t);
  if (m != null) {
    budget = (double.parse(m.group(1)!.replaceAll(',', '.')) * 1000000).round();
  } else {
    final f = RegExp(r'(\d[\d  .]{3,})\s*(fcfa|f\b|cfa)').firstMatch(t);
    if (f != null) {
      budget = int.tryParse(f.group(1)!.replaceAll(RegExp(r'\D'), ''));
    }
  }
  final needs = [
    for (final MapEntry(:key, :value) in _keywords.entries)
      if (value.any(t.contains)) key,
  ];
  return ConciergeBrief(
    guests: guests ?? (e.guests.invited > 0 ? e.guests.invited : 100),
    budget: budget ?? e.targetBudget,
    needs: needs.isEmpty
        ? const [
            VendorCategory.venue,
            VendorCategory.catering,
            VendorCategory.decor,
          ]
        : needs,
    city: e.city.trim().isEmpty ? 'Abidjan' : e.city.trim(),
  );
}

/// Échéances proposées, en jours avant l'événement.
List<(int, String)> _steps(List<VendorCategory> needs) => [
  if (needs.contains(VendorCategory.venue)) (90, 'Réserver le lieu'),
  if (needs.contains(VendorCategory.catering))
    (60, 'Choisir et réserver le traiteur'),
  if (needs.contains(VendorCategory.decor)) (60, 'Valider la décoration'),
  if (needs.contains(VendorCategory.photo)) (45, 'Réserver le photographe'),
  if (needs.contains(VendorCategory.music)) (45, 'Réserver l’animation'),
  (30, 'Envoyer les invitations'),
  (14, 'Confirmer chaque prestataire et l’acompte'),
  (7, 'Relancer les invités sans réponse'),
  (1, 'Faire le point final avec l’équipe'),
];

class _Exchange {
  const _Exchange(this.question, this.brief);
  final String question;
  final ConciergeBrief brief;
}

/// Concierge Calandix : il analyse la demande, propose un plan
/// d'organisation, une répartition du budget, des prestataires adaptés et
/// les échéances à suivre. Il prépare, l'organisateur décide.
class ConciergeScreen extends ConsumerStatefulWidget {
  const ConciergeScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends ConsumerState<ConciergeScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _exchanges = <_Exchange>[];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ask(Event e, String text) {
    if (text.trim().isEmpty) return;
    setState(() => _exchanges.add(_Exchange(text.trim(), readBrief(text, e))));
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventProvider(widget.eventId));
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: RoundIconButton(
              icon: AppIcons.back,
              tooltip: 'Retour',
              onTap: () => context.pop(),
            ),
          ),
        ),
        leadingWidth: 64,
        title: Text('Concierge Calandix'.tr),
      ),
      body: async.when(
        loading: () => const Center(child: MascotLoader.party()),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
        data: (e) => e == null ? MissingEvent(id: widget.eventId) : _body(e),
      ),
    );
  }

  Widget _body(Event e) {
    final example = 'J’organise « {0} » pour {1} personnes à {2}. J’ai besoin d’un traiteur, d’un décorateur et d’un photographe. Mon budget est de {3}. Aide-moi à avancer.'
        .trf([
          e.name,
          e.guests.invited > 0 ? e.guests.invited : 200,
          e.city.trim().isEmpty ? 'Abidjan' : e.city.trim(),
          fcfa(e.targetBudget),
        ]);
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            physics: const BouncingScrollPhysics(),
            children: [
              NightPanel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Mascot(size: 56, mood: MascotMood.happy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dites-moi ce dont vous avez besoin.'.tr,
                            style: context.text.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'J’analyse votre demande, je propose un plan, je trouve des prestataires sur Calandix et je prépare vos échéances. Vous gardez la décision.'
                                .tr,
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_exchanges.isEmpty) ...[
                const SizedBox(height: 14),
                Text('Exemple de demande'.tr, style: context.text.titleSmall),
                const SizedBox(height: 8),
                Panel(
                  onTap: () => _ask(e, example),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(example, style: context.text.bodyMedium),
                      ),
                      const SizedBox(width: 8),
                      Icon(AppIcons.send, size: 18, color: Confetti.violet),
                    ],
                  ),
                ),
              ],
              for (final x in _exchanges) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Confetti.violet,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        x.question,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _Answer(event: e, brief: x.brief),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'Votre demande'.tr,
                  controller: _ctrl,
                  hint: 'Besoins, nombre d’invités, budget…'.tr,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (v) => _ask(e, v),
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: AppIcons.send,
                tooltip: 'Envoyer'.tr,
                background: Confetti.violet,
                foreground: Colors.white,
                size: 48,
                onTap: () => _ask(e, _ctrl.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Answer extends ConsumerWidget {
  const _Answer({required this.event, required this.brief});

  final Event event;
  final ConciergeBrief brief;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final b = brief;
    final weights = {for (final c in b.needs) c: _shares[c] ?? 6};
    final total = weights.values.fold<int>(0, (s, w) => s + w);
    final now = DateTime.now();
    final steps = [
      for (final (days, title) in _steps(b.needs))
        (() {
          final due = e.date.subtract(Duration(days: days));
          return (due.isBefore(now) ? now : due, title.tr, days);
        })(),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. Vos besoins'.tr, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Tag(
                label: '{0} invités'.trf([b.guests]),
                hue: Hue.violet,
                icon: AppIcons.guests,
              ),
              Tag(
                label: fcfa(b.budget),
                hue: Hue.lagoon,
                icon: AppIcons.wallet,
              ),
              Tag(label: b.city, hue: Hue.mango, icon: AppIcons.place),
              for (final c in b.needs)
                Tag(label: c.label, hue: Hue.ink, icon: c.icon),
            ],
          ),
          if (b.guests > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Soit environ {0} par invité, tous postes compris.'.trf([
                fcfa((b.budget / b.guests).round()),
              ]),
              style: context.text.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text('2. Répartition proposée'.tr, style: context.text.titleSmall),
          const SizedBox(height: 8),
          for (final MapEntry(:key, :value) in weights.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(key.icon, size: 16, color: context.eventa.muted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(key.label)),
                  Text(
                    fcfa((b.budget * value / total / 1000).round() * 1000),
                    style: context.text.titleSmall,
                  ),
                ],
              ),
            ),
          Text(
            'Répartition type, à ajuster selon vos priorités.'.tr,
            style: context.text.bodySmall?.copyWith(
              color: context.eventa.muted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '3. Prestataires pertinents sur Calandix'.tr,
            style: context.text.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final c in b.needs) ...[
            for (final v in ([
              for (final v in Catalog.vendors)
                if (v.category == c) v,
            ]..sort((a, z) => z.rating.compareTo(a.rating))).take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  onTap: () => showQuoteRequestSheet(
                    context,
                    ref,
                    v,
                    prefill: QuotePrefill(
                      eventId: e.id,
                      guests: b.guests,
                      budget: weights[c] == null
                          ? null
                          : (b.budget * weights[c]! / total / 1000).round() *
                                1000,
                      message: 'Bonjour, je prépare « {0} » le {1} à {2}, pour {3} invités. Pouvez-vous me faire une proposition ?'
                          .trf([e.name, mediumDate(e.date), b.city, b.guests]),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconTile(icon: c.icon, hue: Hue.violet, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: context.text.titleSmall),
                            Text(
                              '{0} · dès {1}'.trf([v.zone, fcfa(v.priceFrom)]),
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Demande pré-remplie'.tr,
                        style: context.text.labelMedium?.copyWith(
                          color: Confetti.violet,
                        ),
                      ),
                      Icon(AppIcons.chevron, size: 16, color: Confetti.violet),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            '4. Suivi de vos réservations'.tr,
            style: context.text.titleSmall,
          ),
          const SizedBox(height: 8),
          _Tracking(event: e, needs: b.needs),
          const SizedBox(height: 16),
          Text('5. Plan d’organisation'.tr, style: context.text.titleSmall),
          const SizedBox(height: 8),
          for (final (due, title, days) in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      'J-{0}'.trf([days]),
                      style: context.text.labelMedium?.copyWith(
                        color: Confetti.violet,
                      ),
                    ),
                  ),
                  Expanded(child: Text(title)),
                  Text(shortDate(due), style: context.text.bodySmall),
                ],
              ),
            ),
          const SizedBox(height: 12),
          PillButton(
            label: 'Ajouter ces échéances à mes tâches'.tr,
            icon: AppIcons.calendarCheck,
            height: 48,
            onPressed: () {
              final n = ref.read(eventsProvider.notifier);
              final have = {for (final t in e.tasks) t.title};
              var added = 0;
              for (final (due, title, _) in steps) {
                if (have.contains(title)) continue;
                n.addTask(
                  e.id,
                  EventTask(
                    id: 'cc${DateTime.now().microsecondsSinceEpoch}$added',
                    title: title,
                    due: due,
                    module: Module.tasks,
                  ),
                );
                added++;
              }
              toast(
                context,
                added == 0
                    ? 'Ces échéances sont déjà dans vos tâches.'.tr
                    : '{0} échéances ajoutées, avec rappels la veille.'.trf([
                        added,
                      ]),
                icon: AppIcons.checkCircle,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Le concierge prépare et vous conseille ; il ne réserve ni ne paie rien sans votre accord.'
                .tr,
            style: context.text.bodySmall?.copyWith(
              color: context.eventa.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Où en est chaque besoin : devis demandé, reçu, date bloquée, acompte…
class _Tracking extends ConsumerWidget {
  const _Tracking({required this.event, required this.needs});

  final Event event;
  final List<VendorCategory> needs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = [
      for (final b in ref.watch(bookingsProvider))
        if (b.eventId == event.id && !b.archived) b,
    ];
    return Column(
      children: [
        for (final c in needs)
          (() {
            final mine = bookings.where((b) => b.vendor.category == c).toList()
              ..sort((a, z) => z.step.index.compareTo(a.step.index));
            final top = mine.firstOrNull;
            final done =
                top != null && top.step.index >= BookingStep.reserved.index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    done
                        ? AppIcons.checkCircle
                        : top == null
                        ? AppIcons.minus
                        : AppIcons.timer,
                    size: 16,
                    color: done
                        ? Confetti.success
                        : top == null
                        ? context.eventa.muted
                        : Confetti.mango,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c.label)),
                  Flexible(
                    child: Text(
                      top == null
                          ? 'À demander'.tr
                          : mine.length > 1
                          ? '{0} · {1} devis'.trf([
                              top.step.status,
                              mine.length,
                            ])
                          : '{0} · {1}'.trf([top.step.status, top.vendor.name]),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          })(),
        if (bookings.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push(Routes.compareQuotes(event.id)),
              child: Text('Comparer les devis reçus'.tr),
            ),
          ),
      ],
    );
  }
}

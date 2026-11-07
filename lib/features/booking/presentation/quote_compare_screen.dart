import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../../core/models/models.dart';
import '../../marketplace/data/vendor_media.dart';

// ─── Comparateur de devis ───────────────────────────────────────────────
// Les devis reçus pour un même événement et une même catégorie de
// prestataire, côte à côte : total, acompte, validité, note et détail des
// lignes. Le choix renvoie vers la réservation, où l'on accepte les
// conditions.

/// Devis d'une même catégorie, du moins cher au plus cher.
@immutable
class QuoteGroup {
  const QuoteGroup(this.category, this.offers);
  final VendorCategory category;
  final List<Booking> offers;

  Booking get cheapest => offers.first;

  /// Écart entre le devis le plus cher et le moins cher.
  int get spread => offers.last.quote!.total - offers.first.quote!.total;

  /// Une offre de la catégorie est déjà réservée.
  Booking? get chosen => offers
      .where((b) => b.step.index >= BookingStep.reserved.index)
      .firstOrNull;
}

/// Lecture assistée d'un groupe de devis : ce qui les distingue vraiment
/// (contenu, acompte, avis, validité) et l'offre la plus équilibrée.
@immutable
class QuoteAnalysis {
  const QuoteAnalysis({
    required this.best,
    required this.points,
    required this.exclusive,
  });

  /// Meilleur équilibre prix, contenu et avis.
  final Booking best;

  /// Constats, du plus utile au moins utile.
  final List<String> points;

  /// Prestations incluses chez un seul prestataire.
  final Map<String, List<String>> exclusive;
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

QuoteAnalysis? analyzeQuotes(QuoteGroup g) {
  final offers = [
    for (final b in g.offers)
      if (b.quote != null) b,
  ];
  if (offers.length < 2) return null;
  int included(Booking b) => b.quote!.lines.where((l) => !l.optional).length;
  final minTotal = offers.first.quote!.total;
  final maxTotal = offers.last.quote!.total;
  final maxLines = offers.map(included).reduce((a, b) => a > b ? a : b);
  double score(Booking b) {
    final q = b.quote!;
    final price = maxTotal == minTotal
        ? 1.0
        : 1 - (q.total - minTotal) / (maxTotal - minTotal);
    final rating = (b.vendor.rating - 4).clamp(0, 1).toDouble();
    final content = maxLines == 0 ? 1.0 : included(b) / maxLines;
    final deposit = 1 - q.depositRate;
    return price * .4 + rating * .3 + content * .2 + deposit * .1;
  }

  final best = offers.reduce((a, b) => score(b) > score(a) ? b : a);
  final points = <String>[];
  final cheapest = offers.first;
  final complete = offers.reduce((a, b) => included(b) > included(a) ? b : a);
  final rated = offers.reduce(
    (a, b) => b.vendor.rating > a.vendor.rating ? b : a,
  );
  final lowDeposit = offers.reduce(
    (a, b) => b.quote!.depositRate < a.quote!.depositRate ? b : a,
  );
  points.add(
    '{0} est le moins cher, {1} de moins que le plus cher.'.trf([
      cheapest.vendor.name,
      fcfa(maxTotal - minTotal),
    ]),
  );
  if (included(complete) > included(cheapest)) {
    points.add(
      '{0} inclut le plus de prestations ({1} lignes, contre {2}).'.trf([
        complete.vendor.name,
        included(complete),
        included(cheapest),
      ]),
    );
  }
  if (rated.id != cheapest.id) {
    points.add(
      '{0} est le mieux noté : {1} sur {2} avis.'.trf([
        rated.vendor.name,
        rated.vendor.rating.toStringAsFixed(1).replaceAll('.', ','),
        rated.vendor.reviews,
      ]),
    );
  }
  final rates = {for (final b in offers) b.quote!.depositRate};
  if (rates.length > 1) {
    points.add(
      'L’acompte le plus léger : {0} ({1} %).'.trf([
        lowDeposit.vendor.name,
        (lowDeposit.quote!.depositRate * 100).round(),
      ]),
    );
  }
  final soon = offers
      .where(
        (b) =>
            b.quote!.validUntil.difference(DateTime.now()).inDays <= 3 &&
            b.quote!.validUntil.isAfter(DateTime.now()),
      )
      .toList();
  for (final b in soon) {
    points.add(
      'Le devis de {0} expire le {1} : décidez avant.'.trf([
        b.vendor.name,
        shortDate(b.quote!.validUntil),
      ]),
    );
  }

  // Prestations qu'un seul devis contient.
  final owners = <String, Set<String>>{};
  final labels = <String, String>{};
  for (final b in offers) {
    for (final l in b.quote!.lines) {
      final k = _norm(l.label);
      labels[k] = l.label;
      owners.putIfAbsent(k, () => {}).add(b.vendor.name);
    }
  }
  final exclusive = <String, List<String>>{};
  owners.forEach((k, who) {
    if (who.length == 1) {
      exclusive.putIfAbsent(who.first, () => []).add(labels[k]!);
    }
  });
  return QuoteAnalysis(best: best, points: points, exclusive: exclusive);
}

/// Catégories d'un événement ayant reçu au moins un devis.
final quoteGroupsProvider = Provider.family<List<QuoteGroup>, String>((
  ref,
  eventId,
) {
  final byCategory = <VendorCategory, List<Booking>>{};
  for (final b in ref.watch(bookingsProvider)) {
    if (b.eventId != eventId || b.archived || b.quote == null) continue;
    byCategory.putIfAbsent(b.vendor.category, () => []).add(b);
  }
  return [
    for (final e in byCategory.entries)
      QuoteGroup(
        e.key,
        e.value..sort((a, b) => a.quote!.total.compareTo(b.quote!.total)),
      ),
  ]..sort((a, b) {
    // Les catégories les plus disputées d'abord, puis l'ordre du catalogue.
    final n = b.offers.length.compareTo(a.offers.length);
    return n != 0 ? n : a.category.index.compareTo(b.category.index);
  });
});

/// Autres devis de la même catégorie pour le même événement.
final rivalQuotesProvider = Provider.family<int, String>((ref, bookingId) {
  final b = ref.watch(bookingProvider(bookingId));
  if (b == null) return 0;
  final group = ref
      .watch(quoteGroupsProvider(b.eventId))
      .where((g) => g.category == b.vendor.category)
      .firstOrNull;
  return group == null
      ? 0
      : group.offers.where((x) => x.id != bookingId).length;
});

class QuoteCompareScreen extends ConsumerWidget {
  const QuoteCompareScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(quoteGroupsProvider(eventId));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.event(eventId)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparer les devis'.tr,
                    style: context.text.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les devis reçus côte à côte, par type de prestataire.'.tr,
                    style: context.text.bodyMedium?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Panel(
                  child: Text(
                    'Aucun devis reçu pour cet événement. Demandez un devis à au moins deux prestataires d’une même catégorie pour les comparer.'
                        .tr,
                    style: context.text.bodyMedium,
                  ),
                ),
              ),
            for (final g in groups) _Group(group: g),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group});
  final QuoteGroup group;

  @override
  Widget build(BuildContext context) {
    final g = group;
    final chosen = g.chosen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          g.category.label,
          action: '{0} devis'.trf([g.offers.length]),
        ),
        if (g.offers.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              chosen != null
                  ? '{0} est réservé.'.trf([chosen.vendor.name])
                  : '{0} écart entre le moins cher et le plus cher.'.trf([
                      fcfa(g.spread),
                    ]),
              style: context.text.bodySmall?.copyWith(color: Confetti.inkMuted),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Demandez un autre devis dans cette catégorie pour comparer.'.tr,
              style: context.text.bodySmall?.copyWith(color: Confetti.inkMuted),
            ),
          ),
        if (analyzeQuotes(g) case final a? when chosen == null)
          _Analysis(analysis: a),
        LayoutBuilder(
          builder: (context, box) {
            // Sur grand écran, les devis se partagent la largeur ; sur
            // mobile, ils défilent à l'horizontale.
            const minW = 260.0;
            final fits = g.offers.length * minW + (g.offers.length - 1) * 12;
            final cards = [
              for (final b in g.offers)
                _Offer(
                  booking: b,
                  cheapest: g.offers.length > 1 && b.id == g.cheapest.id,
                  locked: chosen != null && chosen.id != b.id,
                ),
            ];
            if (fits <= box.maxWidth) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, c) in cards.indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: c),
                    ],
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, c) in cards.indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      SizedBox(width: minW, child: c),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({
    required this.booking,
    required this.cheapest,
    required this.locked,
  });

  final Booking booking;
  final bool cheapest;

  /// Une autre offre de la catégorie est déjà réservée.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final q = b.quote!;
    final v = b.vendor;
    final reserved = b.step.index >= BookingStep.reserved.index;
    final expired = !reserved && q.validUntil.isBefore(DateTime.now());
    final muted = context.text.bodySmall?.copyWith(color: Confetti.inkMuted);

    Widget line(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: muted)),
          Text(value, style: context.text.labelMedium?.copyWith(color: color)),
        ],
      ),
    );

    return Panel(
      key: ValueKey('offer-${b.id}'),
      padding: const EdgeInsets.all(14),
      color: cheapest && !locked ? Confetti.lagoonTint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VendorPhoto(
                  v.image,
                  width: 40,
                  height: 40,
                  cacheWidth: 120,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    Row(
                      children: [
                        Icon(AppIcons.star, size: 12, color: Confetti.gold),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '{0} · {1} avis'.trf([
                              v.rating.toStringAsFixed(1).replaceAll('.', ','),
                              v.reviews,
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (reserved)
                Tag(
                  label: 'Réservé'.tr,
                  hue: Hue.violet,
                  icon: AppIcons.calendarCheck,
                ),
              if (cheapest)
                Tag(label: 'Le moins cher'.tr, hue: Hue.lagoon, solid: true),
              if (v.verified)
                Tag(
                  label: 'Vérifié'.tr,
                  hue: Hue.violet,
                  icon: AppIcons.verified,
                ),
              if (expired) Tag(label: 'Expiré'.tr, hue: Hue.coral),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fcfa(q.total),
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          line(
            'Acompte ({0} %)'.trf([(q.depositRate * 100).round()]),
            fcfa(q.deposit),
          ),
          line('Frais de service'.tr, fcfa(q.fees)),
          line(
            'Valable jusqu’au'.tr,
            shortDate(q.validUntil),
            color: expired ? Confetti.coralDeep : null,
          ),
          line('Répond en'.tr, v.responseTime),
          const Divider(height: 18),
          for (final l in q.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l.optional ? '{0} (option)'.trf([l.label]) : l.label,
                      style: context.text.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(fcfaCompact(l.amount), style: context.text.labelSmall),
                ],
              ),
            ),
          const Spacer(),
          const SizedBox(height: 12),
          PillButton(
            key: ValueKey('choose-${b.id}'),
            label: reserved ? 'Voir la réservation'.tr : 'Choisir ce devis'.tr,
            tone: reserved || cheapest ? ButtonTone.primary : ButtonTone.ghost,
            height: 42,
            onPressed: locked || expired
                ? null
                : () => context.push(Routes.booking(b.id)),
          ),
        ],
      ),
    );
  }
}

/// Lecture assistée : ce qui différencie les devis, et notre avis.
class _Analysis extends StatelessWidget {
  const _Analysis({required this.analysis});
  final QuoteAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(AppIcons.check, size: 14, color: Confetti.violet),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: context.text.bodySmall)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        color: Confetti.violetTint,
        border: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.sparkle, size: 18, color: Confetti.violetText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analyse Calandix'.tr,
                    style: context.text.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Meilleur équilibre prix, contenu et avis : {0}.'.trf([
                a.best.vendor.name,
              ]),
              style: context.text.titleSmall?.copyWith(
                color: Confetti.violetText,
              ),
            ),
            for (final p in a.points) bullet(p),
            for (final e in a.exclusive.entries)
              bullet(
                'Seulement chez {0} : {1}.'.trf([e.key, e.value.join(', ')]),
              ),
            const SizedBox(height: 8),
            Text(
              'Calcul indicatif : prix 40 %, note 30 %, contenu 20 %, acompte 10 %. Lisez les conditions avant de choisir.'
                  .tr,
              style: context.text.labelSmall?.copyWith(
                color: context.eventa.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

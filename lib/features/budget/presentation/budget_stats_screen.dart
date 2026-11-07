import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/dataviz/dataviz.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/presentation/events_providers.dart';

/// Répartition type d'un budget de fête, en % (la même que le simulateur
/// de la landing et le Concierge) : repère quand aucun événement
/// comparable n'est disponible.
const typicalShares = <BudgetCategory, int>{
  BudgetCategory.venue: 28,
  BudgetCategory.catering: 24,
  BudgetCategory.decor: 14,
  BudgetCategory.music: 12,
  BudgetCategory.photo: 12,
  BudgetCategory.outfits: 10,
};

/// Montant réel d'un poste : ce qui est engagé, ou payé s'il est plus élevé.
int realOf(BudgetLine l) => l.committed > l.paid ? l.committed : l.paid;

/// Part de chaque poste dans un budget prévu, en %.
Map<BudgetCategory, double> sharesOf(Event e) {
  final total = e.budget.fold<int>(0, (s, l) => s + l.estimated);
  if (total == 0) return const {};
  return {for (final l in e.budget) l.category: l.estimated * 100 / total};
}

/// Statistiques du budget : prévu face au réel, poste par poste, et
/// comparaison avec des événements similaires.
class BudgetStatsScreen extends ConsumerWidget {
  const BudgetStatsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Statistiques du budget'.tr)),
      body: async.when(
        loading: () => const Center(child: MascotLoader.party()),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
        data: (events) {
          final e = events.where((x) => x.id == id).firstOrNull;
          if (e == null) return const SizedBox();
          final similar = [
            for (final x in events)
              if (x.id != e.id &&
                  x.category == e.category &&
                  x.budget.isNotEmpty)
                x,
          ];
          return _Body(event: e, similar: similar);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.event, required this.similar});
  final Event event;
  final List<Event> similar;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final planned = e.budget.fold<int>(0, (s, l) => s + l.estimated);
    final real = e.budget.fold<int>(0, (s, l) => s + realOf(l));
    final paid = e.budget.fold<int>(0, (s, l) => s + l.paid);
    final gap = real - planned;
    final lines = [...e.budget]
      ..sort((a, b) => b.estimated.compareTo(a.estimated));
    final over = lines.where((l) => realOf(l) > l.estimated).toList();

    // Repère : moyenne des événements similaires, sinon répartition type.
    final Map<BudgetCategory, double> reference;
    final String referenceLabel;
    if (similar.isNotEmpty) {
      final sum = <BudgetCategory, double>{};
      for (final x in similar) {
        sharesOf(x).forEach((k, v) => sum[k] = (sum[k] ?? 0) + v);
      }
      reference = {for (final k in sum.keys) k: sum[k]! / similar.length};
      referenceLabel = 'Moyenne de vos {0} autres événements « {1} »'.trf([
        similar.length,
        e.category.short,
      ]);
    } else {
      reference = {
        for (final MapEntry(:key, :value) in typicalShares.entries)
          key: value.toDouble(),
      };
      referenceLabel = 'Répartition type d’une fête (repère Calandix)'.tr;
    }
    final mine = sharesOf(e);
    final compared = {...mine.keys, ...reference.keys}.toList()
      ..sort((a, b) => (reference[b] ?? 0).compareTo(reference[a] ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        Text(e.name, style: context.text.bodySmall),
        const SizedBox(height: 12),
        KpiGrid.compact(
          children: [
            KpiCard.compact(
              label: 'Prévu'.tr,
              value: fcfaCompact(planned),
              hue: Hue.violet,
              icon: AppIcons.wallet,
            ),
            KpiCard.compact(
              label: 'Réel (engagé)'.tr,
              value: fcfaCompact(real),
              hue: Hue.mango,
              icon: AppIcons.coins,
            ),
            KpiCard.compact(
              label: 'Payé'.tr,
              value: fcfaCompact(paid),
              hue: Hue.lagoon,
              icon: AppIcons.checkCircle,
            ),
            KpiCard.compact(
              label: gap > 0 ? 'Dépassement'.tr : 'Marge restante'.tr,
              value: fcfaCompact(gap.abs()),
              hue: gap > 0 ? Hue.coral : Hue.lagoon,
              icon: gap > 0 ? AppIcons.warning : AppIcons.shield,
            ),
          ],
        ),
        if (over.isNotEmpty) ...[
          const SizedBox(height: 12),
          Panel(
            color: Confetti.coralTint,
            border: false,
            child: Text(
              'Postes au-dessus du prévu : {0}.'.trf([
                [
                  for (final l in over)
                    '{0} (+{1})'.trf([
                      l.category.label,
                      fcfaCompact(realOf(l) - l.estimated),
                    ]),
                ].join(', '),
              ]),
              style: context.text.bodySmall,
            ),
          ),
        ],
        SectionTitle('Prévu face au réel'.tr),
        Panel(
          child: Column(
            children: [
              for (final l in lines)
                _PlanVsReal(line: l, max: lines.first.estimated),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (final (c, t) in [
                    (Confetti.lavender, 'Prévu'.tr),
                    (Confetti.violet, 'Réel'.tr),
                    (Confetti.coral, 'Dépassement'.tr),
                  ])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(color: c),
                        const SizedBox(width: 6),
                        Text(t, style: context.text.labelSmall),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        SectionTitle('Comparaison'.tr),
        Text(referenceLabel, style: context.text.bodySmall),
        const SizedBox(height: 8),
        Panel(
          child: Column(
            children: [
              for (final k in compared)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(k.icon, size: 16, color: context.eventa.muted),
                      const SizedBox(width: 8),
                      Expanded(child: Text(k.label)),
                      Text(
                        '{0} %'.trf([(mine[k] ?? 0).round()]),
                        style: context.text.titleSmall,
                      ),
                      SizedBox(
                        width: 92,
                        child: Text(
                          'repère {0} %'.trf([(reference[k] ?? 0).round()]),
                          textAlign: TextAlign.end,
                          style: context.text.bodySmall?.copyWith(
                            color:
                                ((mine[k] ?? 0) - (reference[k] ?? 0)).abs() >=
                                    8
                                ? Confetti.coralDeep
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'En rouge : un écart de 8 points ou plus avec le repère, à vérifier.'
                    .tr,
                style: context.text.labelSmall?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.pop(),
          child: Text('Retour au budget'.tr),
        ),
      ],
    );
  }
}

class _PlanVsReal extends StatelessWidget {
  const _PlanVsReal({required this.line, required this.max});
  final BudgetLine line;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l = line;
    final real = realOf(l);
    final over = real > l.estimated;
    final top = [max, real].reduce((a, b) => a > b ? a : b);
    double w(int v) => top == 0 ? 0 : v / top;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.category.label, style: context.text.titleSmall),
              ),
              Text(
                '{0} / {1}'.trf([fcfaCompact(real), fcfaCompact(l.estimated)]),
                style: context.text.labelSmall?.copyWith(
                  color: over ? Confetti.coralDeep : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Container(
                  height: 8,
                  width: box.maxWidth * w(l.estimated),
                  decoration: BoxDecoration(
                    color: Confetti.lavender,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: box.maxWidth * w(real),
                  decoration: BoxDecoration(
                    color: over ? Confetti.coral : Confetti.violet,
                    borderRadius: BorderRadius.circular(4),
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

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

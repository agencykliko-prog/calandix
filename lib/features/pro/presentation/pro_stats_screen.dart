import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/dataviz/dataviz.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'creator_providers.dart';
import 'pro_widgets.dart';
import 'studio_providers.dart';

/// Statistiques commerciales et historique des clients du prestataire,
/// à partir de la formule Starter.
class ProStatsScreen extends ConsumerWidget {
  const ProStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(proPlanProvider).includes(ProPlan.starter);
    return ProPage(
      title: 'Statistiques & clients'.tr,
      subtitle: unlocked
          ? 'Comprenez votre activité et retrouvez vos clients.'.tr
          : 'Inclus dès la formule Starter.'.tr,
      children: unlocked
          ? const [_Stats(), _TopOffers(), _Clients()]
          : [
              Panel(
                onTap: () => context.push(Routes.business),
                child: Row(
                  children: [
                    IconTile(icon: AppIcons.chart, hue: Hue.lagoon, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Visites du profil, demandes, devis, taux de transformation et historique de chaque client : passez à Starter ({0} / mois).'
                            .trf([fcfa(ProPlan.starter.price)]),
                        style: context.text.bodyMedium,
                      ),
                    ),
                    Icon(AppIcons.lock, size: 18, color: Hue.lagoon.text),
                  ],
                ),
              ),
            ],
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(requestsProvider);
    final live = ref.watch(liveSessionProvider);
    final quoted = requests
        .where((r) => r.status != RequestStatus.received)
        .length;
    final won = requests
        .where((r) => r.status == RequestStatus.confirmed)
        .toList();
    final amount = won.fold<int>(0, (s, r) => s + (r.quote ?? 0));
    final rate = requests.isEmpty ? 0 : won.length / requests.length;
    // Visites : mesure réelle à brancher ; la démo montre un ordre de
    // grandeur fictif.
    final visits = live ? null : 40 + requests.length * 27;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Statistiques commerciales'.tr),
        KpiGrid.compact(
          children: [
            KpiCard.compact(
              label: 'Visites du profil'.tr,
              value: visits == null ? '—' : '$visits',
              hue: Hue.violet,
              icon: AppIcons.eye,
              caption: visits == null
                  ? 'Mesure bientôt disponible'.tr
                  : '30 derniers jours'.tr,
            ),
            KpiCard.compact(
              label: 'Demandes reçues'.tr,
              value: '${requests.length}',
              hue: Hue.coral,
              icon: AppIcons.inbox,
            ),
            KpiCard.compact(
              label: 'Devis envoyés'.tr,
              value: '$quoted',
              hue: Hue.mango,
              icon: AppIcons.file,
            ),
            KpiCard.compact(
              label: 'Taux de transformation'.tr,
              value: '${(rate * 100).round()} %',
              hue: Hue.lagoon,
              icon: AppIcons.trendUp,
              caption: 'Demandes devenues réservations'.tr,
            ),
            KpiCard.compact(
              label: 'Réservations réalisées'.tr,
              value: fcfaCompact(amount),
              hue: Hue.gold,
              icon: AppIcons.coins,
              caption: '{0} réservations'.trf([won.length]),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopOffers extends ConsumerWidget {
  const _TopOffers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = <String, int>{};
    for (final r in ref.watch(requestsProvider)) {
      final names = r.items.isNotEmpty
          ? [
              for (final i in r.items)
                if (!i.option) i.label,
            ]
          : r.options;
      for (final n in names) {
        counts[n] = (counts[n] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (top.isEmpty) return const SizedBox.shrink();
    final max = top.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Prestations les plus demandées'.tr),
        Panel(
          child: Column(
            children: [
              for (final e in top.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodyMedium,
                            ),
                          ),
                          Text(
                            '{0} demandes'.trf([e.value]),
                            style: context.text.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Meter(value: e.value / max, color: Confetti.violet),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Clients extends ConsumerWidget {
  const _Clients();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(studioClientsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Historique des clients'.tr),
        if (clients.isEmpty)
          Text(
            'Vos clients apparaîtront ici dès la première demande.'.tr,
            style: context.text.bodyMedium,
          ),
        for (final c in clients)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              onTap: () => showEventaSheet<void>(
                context,
                builder: (_) => _ClientSheet(name: c.name),
              ),
              child: Row(
                children: [
                  IconTile(icon: AppIcons.user, hue: Hue.violet, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: context.text.titleSmall),
                        Text(
                          '{0} demandes · {1} commandes · dernière le {2}'.trf([
                            c.requests,
                            c.confirmed,
                            shortDate(c.last),
                          ]),
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(fcfaCompact(c.revenue), style: context.text.titleSmall),
                  Icon(AppIcons.chevron, size: 16, color: context.eventa.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Événements, demandes et commandes d'un client.
class _ClientSheet extends ConsumerWidget {
  const _ClientSheet({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = [
      for (final r in ref.watch(requestsProvider))
        if (r.client == name) r,
    ]..sort((a, b) => b.date.compareTo(a.date));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: context.text.headlineSmall),
          const SizedBox(height: 12),
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/pro/devis/${r.id}');
                },
                child: Row(
                  children: [
                    Icon(r.category.icon, size: 20, color: r.category.hue.text),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.eventName, style: context.text.titleSmall),
                          Text(
                            '{0} · {1}'.trf([
                              mediumDate(r.date),
                              r.status.label,
                            ]),
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (r.quote != null)
                      Text(fcfa(r.quote!), style: context.text.labelMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

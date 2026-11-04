import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../platform/mobile/download_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/download_web.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';
import '../domain/pro_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'pro_providers.dart';
import 'pro_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// E. Revenus & reversements : commandes payées, commissions, reversements
/// attendus et effectués, relevés de paiements.
class RevenueScreen extends ConsumerWidget {
  const RevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    final plan = ref.watch(proPlanProvider);
    final rate = plan.commission;
    final orders = ref
        .watch(requestsProvider)
        .where((r) => r.status == RequestStatus.confirmed)
        .toList();
    // Commandes encore ouvertes : seul l'acompte est encaissé.
    final open = orders
        .where((r) => pro.progressOf(r.id).stage != OrderStage.closed)
        .toList();
    int deposit(ClientRequest r) =>
        ((r.quote ?? 0) * r.depositPercent / 100).round();
    final sent = pro.payouts.where((p) => p.status == PayoutStatus.sent);
    final scheduled = pro.payouts.where(
      (p) => p.status == PayoutStatus.scheduled,
    );

    final paid =
        open.fold<int>(0, (s, r) => s + deposit(r)) +
        pro.payouts.fold<int>(0, (s, p) => s + p.gross);
    final commissions =
        pro.payouts.fold<int>(0, (s, p) => s + p.commission) +
        open.fold<int>(0, (s, r) => s + ((r.quote ?? 0) * rate).round());
    final expected =
        scheduled.fold<int>(0, (s, p) => s + p.net) +
        open.fold<int>(0, (s, r) => s + ((r.quote ?? 0) * (1 - rate)).round());
    final done = sent.fold<int>(0, (s, p) => s + p.net);

    // Reversements nets des 6 derniers mois (démo : historique + réel).
    final now = DateTime.now();
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
    ];
    const history = [640000, 910000, 1180000, 760000];
    final bars = [
      for (final (i, m) in months.indexed)
        i < history.length
            ? history[i].toDouble()
            : sent
                  .where(
                    (p) => p.date.year == m.year && p.date.month == m.month,
                  )
                  .fold<int>(0, (s, p) => s + p.net)
                  .toDouble(),
    ];
    final hi = bars.fold<double>(1, (a, b) => b > a ? b : a);

    return ProPage(
      title: 'Revenus & reversements'.tr,
      subtitle: 'Calandix encaisse les paiements de vos clients et vous reverse le net après chaque prestation.'
          .tr,
      children: [
        const SizedBox(height: 12),
        _UpgradeHint(
          plan: plan,
          monthly: (bars.fold<double>(0, (a, b) => a + b) / bars.length)
              .round(),
        ),
        KpiGrid.compact(
          children: [
            KpiCard.compact(
              label: 'Commandes payées'.tr,
              value: fcfaCompact(paid),
              hue: Hue.lagoon,
              icon: AppIcons.coins,
            ),
            KpiCard.compact(
              label: 'Commissions prélevées'.tr,
              value: fcfaCompact(commissions),
              hue: Hue.coral,
              icon: AppIcons.receipt,
              caption: 'Formule {0} · {1} %'.trf([
                plan.label,
                plan.commissionPercent,
              ]),
            ),
            KpiCard.compact(
              label: 'Reversements attendus'.tr,
              value: fcfaCompact(expected),
              hue: Hue.mango,
              icon: AppIcons.timer,
            ),
            KpiCard.compact(
              label: 'Reversements effectués'.tr,
              value: fcfaCompact(done),
              hue: Hue.violet,
              icon: AppIcons.checkCircle,
            ),
          ],
        ),
        SectionTitle('Reversements des 6 derniers mois'.tr),
        Panel(
          child: SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, v) in bars.indexed)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          v == 0 ? '' : fcfaCompact(v.round()),
                          style: context.text.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: v / hi),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, t, _) => Container(
                            height: 110 * t + 2,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: i == bars.length - 1
                                  ? Confetti.violet
                                  : Confetti.violet.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('MMM', L10n.intl).format(months[i]),
                          style: context.text.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        SectionTitle('Commandes payées'.tr),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, r) in open.indexed) ...[
                if (i > 0) const Divider(height: 1),
                _MoneyRow(
                  title: r.eventName,
                  caption: 'Acompte reçu · prestation {0}'.trf([
                    shortDate(r.date),
                  ]),
                  gross: r.quote ?? 0,
                  status: 'Acompte reçu'.tr,
                  hue: Hue.mango,
                ),
              ],
              for (final p in pro.payouts) ...[
                if (open.isNotEmpty || p != pro.payouts.first)
                  const Divider(height: 1),
                _MoneyRow(
                  title: p.label,
                  caption: '{0} · commission {1}'.trf([
                    p.ref,
                    fcfa(p.commission),
                  ]),
                  gross: p.gross,
                  status: p.status == PayoutStatus.sent
                      ? 'Reversée'.tr
                      : 'Soldée'.tr,
                  hue: p.status == PayoutStatus.sent ? Hue.lagoon : Hue.violet,
                ),
              ],
            ],
          ),
        ),
        SectionTitle('Reversements'.tr),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, p) in pro.payouts.indexed) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      IconTile(
                        icon: p.status == PayoutStatus.sent
                            ? AppIcons.checkCircle
                            : AppIcons.timer,
                        hue: p.status == PayoutStatus.sent
                            ? Hue.lagoon
                            : Hue.mango,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '{0} · {1}'.trf([fcfa(p.net), p.method]),
                              style: context.text.titleSmall,
                            ),
                            Text(
                              '{0} · {1}'.trf([p.ref, p.label]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Tag(
                            label: p.status.label,
                            hue: p.status == PayoutStatus.sent
                                ? Hue.lagoon
                                : Hue.mango,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shortDate(p.date),
                            style: context.text.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          child: Row(
            children: [
              IconTile(icon: AppIcons.mobile, hue: Hue.violet, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compte de reversement'.tr,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      'Wave · +225 05 •• •• 87',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => toast(
                  context,
                  'Modification sécurisée par code SMS (démo)'.tr,
                  icon: AppIcons.lock,
                ),
                child: Text(
                  'Modifier'.tr,
                  style: context.text.labelMedium?.copyWith(
                    color: Confetti.coralDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionTitle('Relevés de paiements'.tr),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, m) in months.reversed.take(3).indexed) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(AppIcons.csv, size: 19, color: Confetti.inkMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Relevé {0}'.trf([
                            DateFormat('MMMM y', L10n.intl).format(m),
                          ]),
                          style: context.text.titleSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _download(context, m, pro.payouts),
                        child: Text(
                          'Télécharger'.tr,
                          style: context.text.labelMedium?.copyWith(
                            color: Confetti.coralDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _download(
    BuildContext context,
    DateTime month,
    List<Payout> payouts,
  ) async {
    final rows = payouts.where(
      (p) => p.date.year == month.year && p.date.month == month.month,
    );
    final csv = StringBuffer(
      '${['Référence'.tr, 'Prestation'.tr, 'Brut'.tr, 'Commission'.tr, 'Net'.tr, 'Statut'.tr, 'Date'.tr].join(';')}\n',
    );
    for (final p in rows) {
      csv.writeln(
        [
          p.ref,
          p.label,
          p.gross,
          p.commission,
          p.net,
          p.status.label,
          mediumDate(p.date),
        ].join(';'),
      );
    }
    final name = 'releve-calandix-${DateFormat('yyyy-MM').format(month)}.csv';
    final saved = await saveTextFile(name, csv.toString());
    if (context.mounted) {
      toast(
        context,
        saved
            ? 'Relevé téléchargé'.tr
            : 'Relevé copié dans le presse-papiers'.tr,
        icon: AppIcons.download,
      );
    }
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.title,
    required this.caption,
    required this.gross,
    required this.status,
    required this.hue,
  });

  final String title;
  final String caption;
  final int gross;
  final String status;
  final Hue hue;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
              Text(caption, style: context.text.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(fcfa(gross), style: context.text.titleSmall),
            const SizedBox(height: 2),
            Tag(label: status, hue: hue),
          ],
        ),
      ],
    ),
  );
}

/// Conseil chiffré : la formule qui laisserait le plus au prestataire ce
/// mois-ci, abonnement déduit. Rien ne s'affiche si la formule actuelle est
/// déjà la meilleure.
class _UpgradeHint extends StatelessWidget {
  const _UpgradeHint({required this.plan, required this.monthly});

  final ProPlan plan;

  /// Reversements nets moyens des six derniers mois : on remonte au
  /// montant encaissé.
  final int monthly;

  @override
  Widget build(BuildContext context) {
    final sales = (monthly / (1 - plan.commission)).round();
    int keep(ProPlan p) => (sales * (1 - p.commission)).round() - p.price;
    final best = ProPlan.values.reduce((a, b) => keep(b) >= keep(a) ? b : a);
    final gain = keep(best) - keep(plan);
    if (best == plan || gain < 1000) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        onTap: () => context.push(Routes.business),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconTile(icon: AppIcons.trendUp, hue: best.hue, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avec {0}, gardez {1} de plus par mois'.trf([
                      best.label,
                      fcfa(gain),
                    ]),
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Commission {0} % au lieu de {1} %, abonnement déduit, d’après vos encaissements moyens des 6 derniers mois.'
                        .trf([best.commissionPercent, plan.commissionPercent]),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.chevron, size: 16),
          ],
        ),
      ),
    );
  }
}

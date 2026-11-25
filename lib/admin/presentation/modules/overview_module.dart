import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../data/admin_demo.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../admin_shell.dart';
import '../widgets/admin_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// Vue d'ensemble : les quatre indicateurs clés, ce qui demande une
/// action, le flux de transactions en direct et l'accès aux modules.
class OverviewModule extends ConsumerWidget {
  const OverviewModule({super.key});

  static const _descriptions = {
    AdminModule.accounts: 'Créer, modifier, suspendre et rétablir des comptes selon les autorisations',
    AdminModule.verification: 'Contrôler les profils, pièces justificatives et informations professionnelles',
    AdminModule.catalog:
        'Administrer catégories, sous-catégories, annonces et contenus',
    AdminModule.bookings:
        'Suivre les commandes, changements, annulations et litiges',
    AdminModule.payments: 'Contrôler les transactions, commissions, remboursements et rapprochements',
    AdminModule.pricing:
        'Paramétrer les commissions, abonnements et frais éventuels',
    AdminModule.marketing:
        'Codes promotionnels, campagnes, parrainage et notifications',
    AdminModule.support: 'Consulter les tickets, attribuer les demandes et suivre leur résolution',
    AdminModule.analytics:
        'Mesurer l’acquisition, l’activité, la rétention et les revenus',
    AdminModule.security:
        'Gérer les rôles, permissions, journaux d’audit et paramètres',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminProvider);
    final me = ref.watch(adminSessionProvider);
    // Seules les alertes que le rôle connecté peut traiter sont listées.
    final perms = me == null
        ? const <AdminPermission>{}
        : s.permissions[me.role]!;
    final alerts = s.alerts.where((a) {
      final p = AdminModule.fromSlug(a.route).permission;
      return p == null || perms.contains(p);
    }).toList();
    final critical = alerts.where((a) => a.critical).length;
    final recent = s.transactions.take(12).toList().reversed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: '${greeting()}, ${me?.name.split(' ').first ?? ''}',
          subtitle:
              'Vue d’ensemble de l’activité · ${longDate(DateTime.now())}',
        ),
        KpiGrid(
          minTile: 230,
          children: [
            Entrance(
              child: KpiCard(
                icon: AppIcons.team,
                hue: Hue.violet,
                label: 'Utilisateurs inscrits',
                value: formatNumber(12480 + s.accounts.length),
                caption:
                    'Tous comptes · ${formatNumber(9840 + s.clients)} clients, ${formatNumber(2640 + s.pros)} pros',
                trend: 11.2,
                spark: [for (final v in AdminDemo.signups) v.toDouble()],
                onTap: () => context.go(adminPath(AdminModule.accounts)),
              ),
            ),
            Entrance(
              index: 1,
              child: KpiCard(
                icon: AppIcons.coins,
                hue: Hue.lagoon,
                label: 'Volume de transactions',
                value: fcfa(s.volumeToday),
                caption:
                    'Aujourd’hui · remboursements ${fcfaCompact(s.refundsToday)}',
                live: true,
                spark: [for (final t in recent) t.amount.abs().toDouble()],
                onTap: () => context.go(adminPath(AdminModule.payments)),
              ),
            ),
            Entrance(
              index: 2,
              child: KpiCard(
                icon: AppIcons.chartUp,
                hue: Hue.gold,
                label: 'Revenus plateforme',
                value: fcfa(s.revenueToday),
                caption:
                    'Commissions ${s.pricing.commission.toStringAsFixed(0)} % + frais ${s.pricing.serviceFee.toStringAsFixed(0)} % + abonnements',
                trend: 12.0,
                spark: AdminDemo.revenue,
                onTap: () => context.go(adminPath(AdminModule.pricing)),
              ),
            ),
            Entrance(
              index: 3,
              child: KpiCard(
                icon: AppIcons.warning,
                hue: alerts.isEmpty ? Hue.lagoon : Hue.coral,
                label: 'Alertes',
                value: '${alerts.length} à traiter',
                caption: '$critical critiques · litiges, anomalies, incidents',
              ),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 920;
            final alertsBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BlockTitle('À traiter'),
                if (alerts.isEmpty)
                  Panel(
                    child: Row(
                      children: [
                        Icon(AppIcons.checkCircle, color: Confetti.lagoon),
                        const SizedBox(width: 10),
                        Text(
                          'Rien à signaler. Bravo à l’équipe !',
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  Panel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        for (final (i, a) in alerts.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          _AlertRow(alert: a),
                        ],
                      ],
                    ),
                  ),
              ],
            );
            final feed = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlockTitle('Transactions en direct', trailing: const LiveDot()),
                Panel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      for (final (i, t) in s.transactions.take(7).indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _TxRow(key: ValueKey(t.ref), tx: t, fresh: i == 0),
                      ],
                    ],
                  ),
                ),
              ],
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: alertsBlock),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: feed),
                    ],
                  )
                : Column(children: [alertsBlock, feed]);
          },
        ),
        const BlockTitle('Les modules administrateur'),
        KpiGrid(
          minTile: 280,
          max: 3,
          children: [
            for (final m in AdminModule.values.skip(1))
              _ModuleCard(module: m, description: _descriptions[m] ?? ''),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Exemple de structure, sans données réelles.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final AdminAlert alert;

  @override
  Widget build(BuildContext context) {
    final (icon, hue) = switch (alert.kind) {
      AlertKind.dispute => (AppIcons.warning, Hue.coral),
      AlertKind.anomaly => (AppIcons.lightning, Hue.mango),
      AlertKind.incident => (AppIcons.timer, Hue.violet),
      AlertKind.verification => (AppIcons.verified, Hue.lagoon),
      AlertKind.support => (AppIcons.headset, Hue.coral),
    };
    return Pressable(
      scale: 0.99,
      onTap: () => context.go(
        adminPath(AdminModule.values.firstWhere((m) => m.slug == alert.route)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            IconTile(icon: icon, hue: hue, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          alert.title,
                          style: context.text.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (alert.critical) ...[
                        const SizedBox(width: 6),
                        Tag(label: 'Critique', hue: Hue.coral, solid: true),
                      ],
                    ],
                  ),
                  Text(
                    alert.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Traiter',
              style: context.text.labelMedium?.copyWith(
                color: Confetti.coralDeep,
              ),
            ),
            Icon(AppIcons.chevron, size: 14, color: Confetti.coralDeep),
          ],
        ),
      ),
    );
  }
}

/// Ligne du flux temps réel ; la plus récente glisse à l'arrivée.
class _TxRow extends StatelessWidget {
  const _TxRow({super.key, required this.tx, this.fresh = false});

  final Transaction tx;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hueOf(tx.status).base,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TwoLines(
              '${tx.kind.label} · ${tx.party}',
              '${timeOf(tx.at)} · ${tx.method} · ${tx.ref}',
            ),
          ),
          Text(
            fcfa(tx.amount),
            style: context.text.titleSmall?.copyWith(
              color: tx.amount < 0 ? Confetti.danger : Confetti.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    if (!fresh) return row;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -10 * (1 - t)),
          child: child,
        ),
      ),
      child: row,
    );
  }
}

class _ModuleCard extends ConsumerWidget {
  const _ModuleCard({required this.module, required this.description});

  final AdminModule module;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked =
        module.permission != null &&
        !ref.watch(adminCanProvider(module.permission!));
    return Panel(
      onTap: () => context.go(adminPath(module)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            icon: module.icon,
            hue: locked ? Hue.ink : Hue.violet,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(module.label, style: context.text.titleSmall),
                    ),
                    if (locked)
                      Icon(AppIcons.lock, size: 14, color: Confetti.inkFaint),
                  ],
                ),
                const SizedBox(height: 3),
                Text(description, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

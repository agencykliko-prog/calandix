import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';
import '../../marketplace/presentation/explore_screen.dart';
import '../domain/pro_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'pro_providers.dart';
import 'pro_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// Exigences du client à préparer pour une commande.
List<String> requirementsOf(ClientRequest r) => [
  'Moodboard validé par le client'.tr,
  ...r.options,
  'Repérage du lieu et accès'.tr,
  'Brief final la veille'.tr,
];

/// D. Commandes & prestations : suivi, exigences, échéances, clôture.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    final pro = ref.watch(proProvider);
    final orders =
        ref
            .watch(requestsProvider)
            .where((r) => r.status == RequestStatus.confirmed)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    bool isClosed(ClientRequest r) =>
        pro.progressOf(r.id).stage == OrderStage.closed;
    final list = orders.where((r) => isClosed(r) == _closed).toList();
    final next = orders.where((r) => !isClosed(r)).firstOrNull;

    return ProPage(
      title: 'Commandes & prestations'.tr,
      subtitle:
          'Chaque réservation confirmée, de la préparation à la clôture.'.tr,
      children: [
        const SizedBox(height: 12),
        KpiGrid.compact(
          children: [
            KpiCard.compact(
              label: 'En cours'.tr,
              value: '${orders.where((r) => !isClosed(r)).length}',
              hue: Hue.lagoon,
              icon: AppIcons.calendarCheck,
            ),
            KpiCard.compact(
              label: 'Prochaine prestation'.tr,
              value: next == null ? '—' : countdownLabel(next.date),
              hue: Hue.coral,
              icon: AppIcons.timer,
            ),
            KpiCard.compact(
              label: 'Clôturées'.tr,
              value: '${orders.where(isClosed).length}',
              hue: Hue.violet,
              icon: AppIcons.checkCircle,
            ),
            KpiCard.compact(
              label: 'Montant en cours'.tr,
              value: fcfaCompact(
                orders
                    .where((r) => !isClosed(r))
                    .fold<int>(0, (s, r) => s + (r.quote ?? 0)),
              ),
              hue: Hue.mango,
              icon: AppIcons.coins,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const OrderPipeline(),
        const SizedBox(height: 18),
        Row(
          children: [
            Choice(
              label: 'En cours'.tr,
              on: !_closed,
              onTap: () => setState(() => _closed = false),
            ),
            const SizedBox(width: 8),
            Choice(
              label: 'Clôturées'.tr,
              on: _closed,
              onTap: () => setState(() => _closed = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Panel(
            child: Text(
              _closed
                  ? 'Aucune prestation clôturée pour l’instant.'.tr
                  : 'Aucune commande en cours.'.tr,
              style: context.text.bodyMedium,
            ),
          ),
        for (final r in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OrderCard(request: r),
          ),
      ],
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.request});

  final ClientRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    final p = ref.watch(proProvider.select((s) => s.progressOf(r.id)));
    final reqs = requirementsOf(r);
    return Panel(
      onTap: () => _detail(context, r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(image: r.avatar, initials: r.client[0], size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.eventName, style: context.text.titleSmall),
                    Text(
                      '{0} · {1}'.trf([r.client, mediumDate(r.date)]),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    countdownLabel(r.date),
                    style: context.text.titleSmall?.copyWith(
                      color: Confetti.coralDeep,
                    ),
                  ),
                  Text(
                    fcfaCompact(r.quote ?? 0),
                    style: context.text.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          StageBar(stage: p.stage),
          const SizedBox(height: 10),
          Row(
            children: [
              Tag(label: p.stage.label, hue: _hue(p.stage)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '{0}/{1} exigences prêtes'.trf([
                    p.checked.length,
                    reqs.length,
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall,
                ),
              ),
              Icon(AppIcons.chevron, size: 14, color: Confetti.inkFaint),
            ],
          ),
        ],
      ),
    );
  }

  void _detail(BuildContext context, ClientRequest r) {
    final note = TextEditingController(
      text: ProviderScope.containerOf(context)
          .read(proProvider)
          .progressOf(r.id)
          .note,
    );
    showEventaSheet<void>(
      context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final pro = ref.watch(proProvider);
          final p = pro.progressOf(r.id);
          final n = ref.read(proProvider.notifier);
          final terms = pro.catalog.terms;
          final reqs = requirementsOf(r);
          final total = r.quote ?? 0;
          final deposit = (total * r.depositPercent / 100).round();
          final balanceDue = r.date.subtract(
            Duration(days: terms.balanceDaysBefore),
          );
          final balancePaid = p.stage.index >= OrderStage.delivering.index;
          final nextStage = p.stage == OrderStage.closed
              ? null
              : OrderStage.values[p.stage.index + 1];

          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Text(r.eventName, style: ctx.text.headlineSmall),
              Text(
                '{0} · {1} · {2}'.trf([
                  r.client,
                  longDate(r.date),
                  timeOf(r.date),
                ]),
                style: ctx.text.bodySmall,
              ),
              if (r.place != null) Text(r.place!, style: ctx.text.bodySmall),
              const SizedBox(height: 14),
              StageBar(stage: p.stage, labels: true),
              const SizedBox(height: 16),
              Text('Exigences du client'.tr, style: ctx.text.titleMedium),
              const SizedBox(height: 4),
              for (final (i, label) in reqs.indexed)
                CheckRow(
                  label: label,
                  value: p.checked.contains(i),
                  onChanged: (_) => n.toggleRequirement(r.id, i),
                ),
              const SizedBox(height: 12),
              Text('Échéances'.tr, style: ctx.text.titleMedium),
              const SizedBox(height: 6),
              _Deadline(
                label: 'Acompte ({0} %)'.trf([r.depositPercent]),
                amount: deposit,
                date: r.receivedAt,
                done: p.stage.index >= OrderStage.confirmed.index,
              ),
              _Deadline(
                label: 'Solde'.tr,
                amount: total - deposit,
                date: balanceDue,
                done: balancePaid,
              ),
              _Deadline(
                label: 'Prestation'.tr,
                date: r.date,
                done: p.stage.index >= OrderStage.done.index,
              ),
              const SizedBox(height: 12),
              AppField(
                label: 'Notes internes'.tr,
                controller: note,
                optional: true,
                maxLines: 2,
                hint: 'Ex. Prévoir rallonges, accès par l’entrée de service'.tr,
                onChanged: (v) => n.setNote(r.id, v),
              ),
              const SizedBox(height: 16),
              if (nextStage != null)
                PillButton(
                  label: switch (nextStage) {
                    OrderStage.confirmed => 'Enregistrer l’acompte reçu'.tr,
                    OrderStage.preparing => 'Confirmer la prestation'.tr,
                    OrderStage.delivering => 'Passer au jour J'.tr,
                    OrderStage.done => 'Déclarer la prestation réalisée'.tr,
                    OrderStage.closed =>
                      'Clôturer et demander le reversement'.tr,
                    OrderStage.accepted => '',
                  },
                  icon: nextStage == OrderStage.closed
                      ? AppIcons.coins
                      : AppIcons.forward,
                  onPressed: () {
                    n.advance(r);
                    ref.read(soundProvider).play(Sfx.success);
                    if (nextStage == OrderStage.closed) {
                      Navigator.of(ctx).pop();
                      toast(
                        context,
                        'Prestation clôturée, reversement de {0} programmé'.trf(
                          [
                            fcfa(
                              (total * (1 - ref.read(proCommissionProvider)))
                                  .round(),
                            ),
                          ],
                        ),
                        icon: AppIcons.coins,
                      );
                    }
                  },
                )
              else
                Text(
                  'Prestation clôturée. Le reversement apparaît dans Revenus.'
                      .tr,
                  textAlign: TextAlign.center,
                  style: ctx.text.bodySmall,
                ),
            ],
          );
        },
      ),
    );
  }
}

Hue _hue(OrderStage s) => switch (s) {
  OrderStage.accepted => Hue.sky,
  OrderStage.confirmed => Hue.violet,
  OrderStage.preparing => Hue.mango,
  OrderStage.delivering => Hue.coral,
  OrderStage.done => Hue.lagoon,
  OrderStage.closed => Hue.ink,
};

/// Barre d'avancement des étapes de la commande.
class StageBar extends StatelessWidget {
  const StageBar({super.key, required this.stage, this.labels = false});

  final OrderStage stage;
  final bool labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final s in OrderStage.values) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 6,
                  decoration: BoxDecoration(
                    color: s.index <= stage.index
                        ? _hue(stage).base
                        : Confetti.lavender,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (s != OrderStage.closed) const SizedBox(width: 4),
            ],
          ],
        ),
        if (labels) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              for (final s in OrderStage.values)
                Expanded(
                  child: Text(
                    s.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      fontSize: 10,
                      color: s == stage ? Confetti.ink : Confetti.inkFaint,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Deadline extends StatelessWidget {
  const _Deadline({
    required this.label,
    required this.date,
    required this.done,
    this.amount,
  });

  final String label;
  final DateTime date;
  final bool done;
  final int? amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(
          done ? AppIcons.checkCircle : AppIcons.timer,
          size: 18,
          color: done ? Confetti.lagoon : Confetti.mango,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            amount == null ? label : '{0} · {1}'.trf([label, fcfa(amount!)]),
            style: context.text.titleSmall,
          ),
        ),
        Text(
          done ? 'Fait'.tr : relativeDue(date),
          style: context.text.labelSmall?.copyWith(
            color: done ? Confetti.lagoonText : Confetti.mangoText,
          ),
        ),
      ],
    ),
  );
}

/// Les 7 statuts du suivi, de la demande à la clôture, avec le nombre de
/// dossiers à chaque étape.
class OrderPipeline extends ConsumerWidget {
  const OrderPipeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    final requests = ref.watch(requestsProvider);
    int stage(Set<OrderStage> s) => requests
        .where(
          (r) =>
              r.status == RequestStatus.confirmed &&
              s.contains(pro.progressOf(r.id).stage),
        )
        .length;
    final steps = <(String, int, Hue)>[
      (
        'Nouvelle demande'.tr,
        requests.where((r) => r.status == RequestStatus.received).length,
        Hue.sky,
      ),
      (
        'Devis envoyé'.tr,
        requests.where((r) => r.status == RequestStatus.quoted).length,
        Hue.peach,
      ),
      ('Devis accepté'.tr, stage({OrderStage.accepted}), Hue.sky),
      ('Acompte payé'.tr, stage({OrderStage.confirmed}), Hue.violet),
      (
        'Prestation confirmée'.tr,
        stage({OrderStage.preparing, OrderStage.delivering}),
        Hue.mango,
      ),
      ('Prestation réalisée'.tr, stage({OrderStage.done}), Hue.lagoon),
      ('Commande clôturée'.tr, stage({OrderStage.closed}), Hue.ink),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suivi des commandes'.tr, style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text(
            'Chaque dossier passe par ces 7 statuts.'.tr,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 10),
          for (final (i, (label, n, hue)) in steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hue.tint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: context.text.labelSmall?.copyWith(color: hue.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: context.text.bodyMedium)),
                  Text(
                    '$n',
                    style: context.text.titleSmall?.copyWith(
                      color: n == 0 ? context.eventa.muted : null,
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

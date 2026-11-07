import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';
import 'pro_providers.dart';
import 'pro_widgets.dart';
import 'calendar_sync.dart';

/// B. Disponibilités : calendrier, dates bloquées, capacité de production
/// et prévention des doubles réservations.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityState();
}

class _AvailabilityState extends ConsumerState<AvailabilityScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final pro = ref.watch(proProvider);
    final a = pro.availability;
    final n = ref.read(proProvider.notifier);
    final requests = ref.watch(requestsProvider);
    final title = DateFormat('MMMM y', L10n.intl).format(_month);

    // Demandes en attente tombant sur un jour déjà complet ou bloqué.
    final conflicts = requests
        .where(
          (r) =>
              (r.status == RequestStatus.received ||
                  r.status == RequestStatus.quoted) &&
              ref.watch(dayFullProvider(r.date)),
        )
        .toList();
    final blockedSoon =
        a.blocked.where((d) => !d.isBefore(dateOnly(DateTime.now()))).toList()
          ..sort();

    return ProPage(
      title: 'Disponibilités'.tr,
      subtitle: 'Votre calendrier ouvert à la réservation. Les jours complets ou bloqués ne reçoivent plus de demandes.'
          .tr,
      children: [
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title[0].toUpperCase() + title.substring(1),
                      style: context.text.titleMedium,
                    ),
                  ),
                  RoundIconButton(
                    icon: AppIcons.chevronLeft,
                    size: 34,
                    tooltip: 'Mois précédent',
                    onTap: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoundIconButton(
                    icon: AppIcons.chevron,
                    size: 34,
                    tooltip: 'Mois suivant',
                    onTap: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MonthGrid(month: _month, onTap: (d) => _day(context, d)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _Legend(Confetti.surface, 'Libre'.tr, border: true),
                  _Legend(Confetti.mangoTint, 'Partiel'.tr),
                  _Legend(Confetti.coralTint, 'Complet'.tr),
                  _Legend(Confetti.lavender, 'Bloqué'.tr, icon: AppIcons.lock),
                ],
              ),
            ],
          ),
        ),
        SectionTitle('Agenda synchronisé'.tr),
        const CalendarSyncPanel(),
        SectionTitle('Capacité de production'.tr),
        Panel(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prestations par jour'.tr,
                          style: context.text.titleSmall,
                        ),
                        Text(
                          'Selon votre équipe et votre matériel'.tr,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    icon: AppIcons.minus,
                    size: 34,
                    tooltip: 'Moins',
                    onTap: () => n.setCapacity(a.capacityPerDay - 1),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${a.capacityPerDay}',
                      textAlign: TextAlign.center,
                      style: context.text.titleLarge,
                    ),
                  ),
                  RoundIconButton(
                    icon: AppIcons.add,
                    size: 34,
                    tooltip: 'Plus',
                    onTap: () => n.setCapacity(a.capacityPerDay + 1),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Empêcher les doubles réservations'.tr,
                          style: context.text.titleSmall,
                        ),
                        Text(
                          'Un jour complet est fermé automatiquement dans Explorer'
                              .tr,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(value: a.preventDouble, onChanged: n.setPreventDouble),
                ],
              ),
            ],
          ),
        ),
        if (conflicts.isNotEmpty) ...[
          SectionTitle('Conflits à régler'.tr),
          for (final r in conflicts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                onTap: () => context.push('/pro/devis/${r.id}'),
                child: Row(
                  children: [
                    IconTile(icon: AppIcons.warning, hue: Hue.coral, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.eventName, style: context.text.titleSmall),
                          Text(
                            '{0} · jour déjà complet ou bloqué'.trf([
                              mediumDate(r.date),
                            ]),
                            style: context.text.bodySmall?.copyWith(
                              color: Confetti.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevron, size: 14, color: Confetti.inkFaint),
                  ],
                ),
              ),
            ),
        ],
        SectionTitle('Dates bloquées'.tr),
        if (blockedSoon.isEmpty)
          Panel(
            child: Text(
              'Aucune date bloquée à venir.'.tr,
              style: context.text.bodyMedium,
            ),
          )
        else
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, d) in blockedSoon.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(AppIcons.lock, size: 17, color: Confetti.inkMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            longDate(d),
                            style: context.text.titleSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => n.toggleBlocked(d),
                          child: Text(
                            'Débloquer'.tr,
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

  void _day(BuildContext context, DateTime day) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final a = ref.watch(proProvider.select((s) => s.availability));
          final blocked = a.blocked.contains(dateOnly(day));
          final jobs = ref
              .watch(requestsProvider)
              .where(
                (r) =>
                    r.status == RequestStatus.confirmed &&
                    dateOnly(r.date) == dateOnly(day),
              )
              .toList();
          final load = jobs.length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(longDate(day), style: ctx.text.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  blocked
                      ? 'Date bloquée : aucune nouvelle demande possible.'.tr
                      : '{0} / {1} prestations ce jour-là'.trf([
                          load,
                          a.capacityPerDay,
                        ]),
                  style: ctx.text.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final r in jobs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Panel(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(timeOf(r.date), style: ctx.text.titleSmall),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '{0} · {1}'.trf([r.eventName, r.client]),
                              style: ctx.text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                PillButton(
                  label: blocked
                      ? 'Rouvrir cette date'.tr
                      : 'Bloquer cette date'.tr,
                  icon: blocked ? AppIcons.checkCircle : AppIcons.lock,
                  tone: blocked ? ButtonTone.dark : ButtonTone.ghost,
                  onPressed: () {
                    ref.read(proProvider.notifier).toggleBlocked(day);
                    Navigator.of(ctx).pop();
                    toast(
                      context,
                      blocked ? 'Date rouverte'.tr : 'Date bloquée'.tr,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month, required this.onTap});

  final DateTime month;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(proProvider.select((s) => s.availability));
    final first = DateTime(month.year, month.month);
    final lead = first.weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final today = dateOnly(DateTime.now());
    final names = [
      for (var i = 0; i < 7; i++)
        DateFormat('EEEEE', L10n.intl).format(DateTime(2024, 1, 1 + i)),
    ];

    return Column(
      children: [
        Row(
          children: [
            for (final d in names)
              Expanded(
                child: Text(
                  d.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: context.text.labelSmall?.copyWith(
                    color: Confetti.inkFaint,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var w = 0; w < ((lead + days) / 7).ceil(); w++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final n = w * 7 + i - lead + 1;
                      if (n < 1 || n > days) return const SizedBox(height: 46);
                      final day = DateTime(month.year, month.month, n);
                      final load = ref.watch(dayLoadProvider(day));
                      final blocked =
                          a.blocked.contains(day) ||
                          ref.watch(calendarSyncProvider).busy.contains(day);
                      final past = day.isBefore(today);
                      final (bg, fg) = blocked
                          ? (Confetti.lavender, Confetti.inkMuted)
                          : load >= a.capacityPerDay
                          ? (Confetti.coralTint, Confetti.coralDeep)
                          : load > 0
                          ? (Confetti.mangoTint, Confetti.mangoText)
                          : (Confetti.surface, Confetti.ink);
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Pressable(
                          onTap: past ? null : () => onTap(day),
                          child: Opacity(
                            opacity: past ? 0.4 : 1,
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: day == today
                                      ? Confetti.ink
                                      : Confetti.line,
                                  width: day == today ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$n',
                                    style: context.text.labelMedium?.copyWith(
                                      color: fg,
                                    ),
                                  ),
                                  if (blocked)
                                    Icon(AppIcons.lock, size: 10, color: fg)
                                  else if (load > 0)
                                    Text(
                                      '$load/${a.capacityPerDay}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: fg,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label, {this.border = false, this.icon});

  final Color color;
  final String label;
  final bool border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: border ? Border.all(color: Confetti.line) : null,
        ),
        child: icon == null
            ? null
            : Icon(icon, size: 9, color: Confetti.inkMuted),
      ),
      const SizedBox(width: 6),
      Text(label, style: context.text.labelSmall),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../premium/presentation/paywall.dart';

/// Collaborateurs offerts avec Découverte.
final freeCollaborators = Plan.free.collaborators;

Future<void> showCollaboratorsSheet(BuildContext context, String eventId) =>
    showEventaSheet<void>(
      context,
      builder: (_) => _Collaborators(eventId: eventId),
    );

class _Collaborators extends ConsumerWidget {
  const _Collaborators({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(eventProvider(eventId)).value;
    if (e == null) return const SizedBox();
    final used = e.collaborators;
    final caps = ref.watch(eventCapsProvider(eventId));
    final limit = caps.collaborators;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Partager l’événement'.tr, style: context.text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '{0} collaborateurs avec votre offre {1}. Chacun a ses propres droits.'
                .trf([
                  limit,
                  caps.pass ? 'Pass Événement'.tr : caps.plan.label,
                ]),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Meter(
                  value: (used / limit).clamp(0, 1),
                  color: used >= limit ? Confetti.coral : Confetti.candy,
                  height: 6,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                caps.pass
                    ? '{0} / {1} · Pass'.trf([used, limit])
                    : '{0} / {1}'.trf([used, limit]),
                style: context.text.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          PillButton(
            label: 'Inviter un collaborateur'.tr,
            icon: AppIcons.userPlus,
            tone: ButtonTone.dark,
            onPressed: () {
              void open() => _invite(context, ref, e);
              if (used < limit) {
                open();
                return;
              }
              final next = caps.plan.nextFor(used, (p) => p.collaborators);
              if (next == null) {
                toast(
                  context,
                  'Votre offre compte jusqu’à {0} collaborateurs par événement.'
                      .trf([limit]),
                  icon: AppIcons.info,
                );
                return;
              }
              requirePremium(
                context,
                ref,
                feature: PremiumFeature.collaborators,
                plan: next,
                onUnlocked: open,
              );
            },
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: () => toast(
              context,
              'Lien d’invitation copié'.tr,
              icon: AppIcons.share,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Confetti.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Confetti.line),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.share, size: 18, color: Confetti.inkMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'eventa.ci/e/${e.id.substring(0, 8)}',
                      style: context.text.bodyMedium?.copyWith(
                        color: Confetti.inkMuted,
                      ),
                    ),
                  ),
                  Text(
                    'Copier'.tr,
                    style: context.text.labelMedium?.copyWith(
                      color: Confetti.coralDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final m in e.team)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                padding: const EdgeInsets.all(12),
                onTap: m.role == TeamRole.owner
                    ? null
                    : () => _editRights(context, ref, e.id, m),
                child: Row(
                  children: [
                    Avatar(
                      image: m.avatar,
                      initials: m.initials,
                      size: 38,
                      online: m.online,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: context.text.titleSmall),
                          Text(
                            m.pending
                                ? 'Invitation envoyée'.tr
                                : _rightsSummary(m),
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Tag(
                      label: m.role.label,
                      hue: m.role == TeamRole.owner
                          ? Hue.candy
                          : (m.role == TeamRole.admin ? Hue.violet : Hue.ink),
                    ),
                    if (m.role != TeamRole.owner) ...[
                      const SizedBox(width: 6),
                      Icon(
                        AppIcons.chevron,
                        size: 14,
                        color: Confetti.inkFaint,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _rightsSummary(TeamMember m) {
    final p = m.permissions;
    final on = [
      if (p.budget) 'budget',
      if (p.tasks) 'tâches'.tr,
      if (p.vendors) 'prestataires',
      if (p.guests) 'invités'.tr,
      if (p.payments) 'paiements',
    ];
    return on.isEmpty
        ? 'Lecture seule'.tr
        : 'Modifie : {0}'.trf([on.join(', ')]);
  }

  void _invite(BuildContext context, WidgetRef ref, Event e) {
    final name = TextEditingController();
    var role = TeamRole.editor;
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouveau collaborateur'.tr, style: ctx.text.headlineSmall),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nom ou numéro WhatsApp'.tr,
                ),
              ),
              const SizedBox(height: 14),
              Text('Rôle'.tr, style: ctx.text.labelMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final r in [
                    TeamRole.admin,
                    TeamRole.editor,
                    TeamRole.viewer,
                  ]) ...[
                    if (r != TeamRole.admin) const SizedBox(width: 8),
                    Expanded(
                      child: Pressable(
                        onTap: () => set(() => role = r),
                        child: AnimatedContainer(
                          duration: Motion.fast,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: role == r ? Confetti.ink : Confetti.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: role == r ? Confetti.ink : Confetti.line,
                            ),
                          ),
                          child: Text(
                            r.label,
                            style: ctx.text.labelMedium?.copyWith(
                              color: role == r ? Confetti.onInk : Confetti.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(switch (role) {
                TeamRole.admin =>
                  'Tous les droits, y compris les paiements.'.tr,
                TeamRole.editor =>
                  'Modifie budget, tâches, prestataires et invités. Pas de paiement.'
                      .tr,
                _ => 'Consulte sans rien modifier.'.tr,
              }, style: ctx.text.bodySmall),
              const SizedBox(height: 16),
              PillButton(
                label: 'Envoyer l’invitation'.tr,
                icon: AppIcons.send,
                onPressed: () {
                  final n = name.text.trim().isEmpty
                      ? 'Invité'.tr
                      : name.text.trim();
                  ref
                      .read(eventsProvider.notifier)
                      .addMember(
                        e.id,
                        TeamMember(
                          id: 'm-${DateTime.now().microsecondsSinceEpoch}',
                          name: n,
                          role: role,
                          pending: true,
                          permissions: switch (role) {
                            TeamRole.admin => Permissions.all,
                            TeamRole.viewer => Permissions.readOnly,
                            _ => const Permissions(),
                          },
                        ),
                      );
                  Navigator.of(ctx).pop();
                  toast(
                    context,
                    'Invitation envoyée à {0}'.trf([n]),
                    icon: AppIcons.send,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editRights(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    TeamMember m,
  ) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final e = ref.watch(eventProvider(eventId)).value;
          final cur = e?.member(m.id);
          if (cur == null) return const SizedBox();
          void set(Permissions p) => ref
              .read(eventsProvider.notifier)
              .updateMember(
                eventId,
                TeamMember(
                  id: cur.id,
                  name: cur.name,
                  role: cur.role,
                  avatar: cur.avatar,
                  online: cur.online,
                  side: cur.side,
                  pending: cur.pending,
                  permissions: p,
                ),
              );
          final p = cur.permissions;
          Widget row(String label, bool v, Permissions Function(bool) f) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: ctx.text.titleSmall)),
                    Switch(value: v, onChanged: (x) => set(f(x))),
                  ],
                ),
              );
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(image: cur.avatar, initials: cur.initials, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cur.name, style: ctx.text.titleLarge),
                          Text(cur.role.label, style: ctx.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                row('Budget'.tr, p.budget, (x) => p.copyWith(budget: x)),
                row('Tâches'.tr, p.tasks, (x) => p.copyWith(tasks: x)),
                row(
                  'Prestataires'.tr,
                  p.vendors,
                  (x) => p.copyWith(vendors: x),
                ),
                row('Invités'.tr, p.guests, (x) => p.copyWith(guests: x)),
                row('Paiements'.tr, p.payments, (x) => p.copyWith(payments: x)),
                const SizedBox(height: 12),
                PillButton(
                  label: 'Retirer de l’événement'.tr,
                  tone: ButtonTone.ghost,
                  icon: AppIcons.trash,
                  onPressed: () {
                    ref
                        .read(eventsProvider.notifier)
                        .removeMember(eventId, cur.id);
                    Navigator.of(ctx).pop();
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

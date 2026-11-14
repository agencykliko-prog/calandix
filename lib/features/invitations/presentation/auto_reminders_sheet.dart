import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'invitations_providers.dart';

/// Quota mensuel de rappels de l'événement : celui de l'abonnement, ou
/// celui de Signature avec un Pass Événement actif.
int reminderQuotaFor(WidgetRef ref, String eventId) =>
    ref.watch(eventCapsProvider(eventId)).plan.reminderQuota;

/// Rappels WhatsApp et SMS envoyés automatiquement par Calandix, dans la
/// limite du quota de l'offre (chaque message a un coût d'envoi).
Future<void> showAutoReminders(BuildContext context, Event e) =>
    showEventaSheet<void>(context, builder: (ctx) => _AutoReminders(event: e));

class _AutoReminders extends ConsumerWidget {
  const _AutoReminders({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderProvider);
    final n = ref.read(reminderProvider.notifier);
    final s = n.of(event.id);
    final quota = reminderQuotaFor(ref, event.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rappels automatiques'.tr, style: context.text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Calandix envoie les rappels à votre place, au bon moment.'.tr,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 14),
          Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quota du mois'.tr,
                        style: context.text.titleSmall,
                      ),
                    ),
                    Text(
                      '{0} / {1} messages'.trf([s.used, quota]),
                      style: context.text.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Meter(
                  value: quota == 0 ? 0 : (s.used / quota).clamp(0, 1),
                  color: Confetti.violet,
                ),
                const SizedBox(height: 8),
                Text(
                  'Les envois s’arrêtent au quota ; il se renouvelle chaque mois.'
                      .tr,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Canal d’envoi'.tr, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in ReminderChannel.values)
                ChoiceChip(
                  avatar: Icon(
                    c == ReminderChannel.whatsapp
                        ? AppIcons.whatsapp
                        : AppIcons.message,
                    size: 16,
                  ),
                  label: Text(c.label),
                  selected: s.channel == c,
                  onSelected: (_) => n.channel(event.id, c),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final r in AutoReminder.values)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: s.enabled.contains(r),
              onChanged: (_) => n.toggle(event.id, r),
              title: Text(r.title, style: context.text.titleSmall),
              subtitle: Text(r.caption, style: context.text.bodySmall),
            ),
          const SizedBox(height: 8),
          Text(
            'Version de démonstration : aucun message n’est réellement envoyé tant que l’envoi WhatsApp et SMS n’est pas branché.'
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

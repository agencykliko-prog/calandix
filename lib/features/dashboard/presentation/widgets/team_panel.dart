import 'package:flutter/material.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../ui/theme/eventa_colors.dart';
import '../../../../ui/widgets/avatars.dart';
import '../../../../ui/widgets/ui.dart';
import '../../../../core/models/models.dart';
import '../../../events/presentation/widgets/task_timeline.dart';

class TeamPanel extends StatelessWidget {
  const TeamPanel({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final c = context.eventa.team;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          for (var i = 0; i < event.team.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Avatar(
                    image: event.team[i].avatar,
                    initials: event.team[i].initials,
                    size: 40,
                    online: event.team[i].online,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.team[i].name,
                          style: context.text.titleSmall,
                        ),
                        Text(
                          [
                            if (event.team[i].side != null &&
                                event.category == EventCategory.wedding)
                              event.team[i].side!,
                            event.team[i].pending
                                ? 'invitation envoyée'.tr
                                : (event.team[i].online
                                      ? 'en ligne'.tr
                                      : 'hors ligne'.tr),
                          ].join(' · '),
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Tag(
                    label: event.team[i].role.label,
                    hue: event.team[i].role == TeamRole.owner
                        ? c
                        : (event.team[i].role == TeamRole.admin
                              ? Hue.violet
                              : Hue.ink),
                  ),
                ],
              ),
            ),
            _Progress(event: event, member: event.team[i]),
          ],
          if (event.activity.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'En direct'.tr,
                  style: context.text.labelMedium?.copyWith(color: c.text),
                ),
              ),
            ),
            for (final a in event.activity)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: moduleHue(a.module).base,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: event.member(a.memberId)?.firstName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(
                              text: ' ${a.text}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        style: context.text.bodySmall?.copyWith(
                          color: Confetti.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// Avancement d'un membre : tâches qui lui sont confiées, faites, en retard.
class _Progress extends StatelessWidget {
  const _Progress({required this.event, required this.member});

  final Event event;
  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final mine = event.tasks.where((t) => t.assigneeId == member.id).toList();
    if (mine.isEmpty) return const SizedBox.shrink();
    final done = mine.where((t) => t.done).length;
    final now = DateTime.now();
    final late = mine.where((t) => !t.done && t.due.isBefore(now)).length;
    final next =
        (mine.where((t) => !t.done).toList()
              ..sort((a, b) => a.due.compareTo(b.due)))
            .firstOrNull;
    final hue = late > 0 ? Hue.coral : Hue.lagoon;
    return Padding(
      padding: const EdgeInsets.only(left: 52, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Meter(
                  value: done / mine.length,
                  color: hue.base,
                  height: 6,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '{0}/{1} tâches'.trf([done, mine.length]),
                style: context.text.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (late > 0) '{0} en retard'.trf([late]),
              if (next != null)
                'Prochaine : {0}'.trf([next.title])
              else
                'Tout est fait'.tr,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: late > 0 ? Hue.coral.text : null,
            ),
          ),
        ],
      ),
    );
  }
}

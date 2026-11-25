import 'package:flutter/material.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../ui/theme/app_icons.dart';
import '../../../../ui/theme/eventa_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../ui/widgets/avatars.dart';
import '../../../../ui/widgets/pressable.dart';
import '../../../../core/models/models.dart';
import 'event_cover.dart';

/// Carte d'événement plein cadre : la photo porte tout, le texte se pose
/// sur un voile dégradé vers la couleur de la catégorie.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hue = event.category.hue;
    return Pressable(
      onTap: onTap,
      semanticLabel: event.name,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: hue.deep.withValues(alpha: 0.22),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'cover-${event.id}',
                // Décodage à la taille d'affichage : défilement plus fluide.
                child: EventCoverImage(
                  event.cover,
                  category: event.category,
                  cacheWidth: 900,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      hue.deep.withValues(alpha: 0.92),
                    ],
                    stops: const [0, 0.38, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    children: [
                      Icon(event.category.icon, size: 13, color: hue.base),
                      const SizedBox(width: 5),
                      Text(
                        event.subcategories.isEmpty
                            ? event.category.short
                            : event.subcategories.first.tr,
                        style: context.text.labelSmall?.copyWith(
                          color: Confetti.inkFixed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      countdownLabel(event.date),
                      style: context.text.headlineMedium?.copyWith(
                        color: Colors.white,
                        height: 1,
                        shadows: const [
                          Shadow(color: Color(0x55000000), blurRadius: 12),
                        ],
                      ),
                    ),
                    Text(
                      shortDate(event.date),
                      style: context.text.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          AppIcons.place,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${event.venue} · ${event.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Stat(
                          '${(event.committedRatio * 100).round()} %',
                          'budget',
                        ),
                        _Stat(
                          '${event.tasksDone}/${event.tasks.length}',
                          'tâches'.tr,
                        ),
                        _Stat('${event.guests.confirmed}', 'RSVP'.tr),
                        const Spacer(),
                        AvatarStack(
                          images: [for (final m in event.team) m.avatar],
                          size: 26,
                          max: 3,
                          ring: hue.deep,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: event.overallProgress,
                        minHeight: 3,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Text.rich(
        TextSpan(
          text: value,
          style: context.text.titleSmall?.copyWith(color: Colors.white),
          children: [
            TextSpan(
              text: ' $label',
              style: context.text.labelSmall?.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

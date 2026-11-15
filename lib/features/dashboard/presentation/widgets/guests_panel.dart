import 'package:flutter/material.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../../ui/theme/app_icons.dart';
import '../../../../ui/theme/eventa_colors.dart';
import '../../../../ui/widgets/ui.dart';
import '../../../../core/models/models.dart';

class GuestsPanel extends StatelessWidget {
  const GuestsPanel({super.key, required this.guests, this.onPending});

  final Guests guests;

  /// Ouvre la liste des invités en attente ; null : bouton masqué.
  final VoidCallback? onPending;

  @override
  Widget build(BuildContext context) {
    final g = guests;
    final total = g.invited == 0 ? 1 : g.invited;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${g.confirmed}', style: context.text.headlineMedium),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'confirmés sur {0}'.trf([g.invited]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      color: context.eventa.muted,
                    ),
                  ),
                ),
              ),
              if (g.todayNew > 0)
                Tag(
                  label: '+{0} aujourd\'hui'.trf([g.todayNew]),
                  hue: Hue.coral,
                  icon: AppIcons.trendUp,
                ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Motion.easeOut,
            builder: (context, t, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: (g.confirmed * t * 1000 / total).round() + 1,
                      child: ColoredBox(color: Confetti.coral),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: (g.declined * t * 1000 / total).round() + 1,
                      child: ColoredBox(color: Confetti.inkMuted),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex:
                          ((g.pending + (1 - t) * (g.confirmed + g.declined)) *
                                  1000 /
                                  total)
                              .round() +
                          1,
                      child: ColoredBox(color: Confetti.lavender),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(
                color: Confetti.coral,
                label: 'Présents'.tr,
                value: g.confirmed,
              ),
              _Legend(
                color: Confetti.inkMuted,
                label: 'Absents'.tr,
                value: g.declined,
              ),
              _Legend(
                color: Confetti.border,
                label: 'En attente'.tr,
                value: g.pending,
              ),
            ],
          ),
          if (onPending != null) ...[
            const SizedBox(height: 16),
            PillButton(
              label: 'Voir les {0} en attente'.trf([g.pending]),
              icon: AppIcons.guests,
              tone: ButtonTone.ghost,
              height: 48,
              onPressed: g.pending > 0 ? onPending : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$value ', style: context.text.titleSmall),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

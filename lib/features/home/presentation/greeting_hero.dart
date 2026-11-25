import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';

/// En-tête d'accueil épuré : la salutation au prénom, une ligne
/// d'accompagnement et l'action principale, sur une carte neutre.
class GreetingHero extends ConsumerWidget {
  const GreetingHero({
    super.key,
    required this.header,
    this.question,
    this.action,
  });

  /// Barre du haut (photo, notifications).
  final Widget header;

  /// Petite ligne sous la salutation.
  final String? question;

  /// Action principale facultative (ex. créer un événement).
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    final first = ref
        .watch(profileProvider.select((p) => p.name))
        .trim()
        .split(RegExp(r'\s+'))
        .first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Container(
            padding: EdgeInsets.fromLTRB(22, compact ? 22 : 26, 22, 22),
            decoration: BoxDecoration(
              color: Confetti.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Confetti.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Rise(
                  child: Text(
                    '${greeting()}, $first',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.font,
                      fontSize: compact ? 30 : 36,
                      height: 1.08,
                      letterSpacing: -1,
                      fontWeight: FontWeight.w800,
                      color: Confetti.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _Rise(
                  delay: 120,
                  child: Text(
                    (question ?? 'Qu’est-ce qu’on célèbre aujourd’hui ?'.tr)
                        .replaceAll(' ?', ' ?'),
                    style: context.text.bodyLarge?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 18),
                  _Rise(
                    delay: 240,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: action!,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Apparition en fondu et légère montée, décalée de [delay] millisecondes.
class _Rise extends StatelessWidget {
  const _Rise({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delay),
      curve: Interval(delay / (480 + delay), 1, curve: Motion.easeOut),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

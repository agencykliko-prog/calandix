import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/theme/eventa_colors.dart';

/// Accès à Candix depuis les accueils : la fourmi, au-dessus de la barre.
class CandixButton extends StatelessWidget {
  const CandixButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.sizeOf(context).width < 720 ? 76.0 : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Pressable(
        onTap: () => context.push(Routes.candix),
        semanticLabel: 'Candix',
        child: Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Confetti.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Confetti.line),
            boxShadow: [
              BoxShadow(
                color: Confetti.inkFixed.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Mascot(size: 50, waving: true),
        ),
      ),
    );
  }
}

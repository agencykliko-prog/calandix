import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/site_footer.dart';
import '../../../ui/widgets/ui.dart';

/// Erreur 404 : la fourmi triste à la place du zéro, puis le pied de page du
/// site (toute page 404 garde le footer).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final big = TextStyle(
      fontFamily: AppTheme.font,
      fontSize: 130,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -6,
      color: Confetti.violet,
    );
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) => ListView(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight * .8),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('4', style: big),
                            const Mascot(size: 150, mood: MascotMood.sad),
                            Text('4', style: big),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cette page n’existe pas.'.tr,
                        textAlign: TextAlign.center,
                        style: context.text.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      PillButton(
                        label: 'Retour à l’accueil'.tr,
                        expand: false,
                        onPressed: () => context.go(Routes.home),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}

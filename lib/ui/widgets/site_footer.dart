import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../core/i18n/tr.dart';
import '../theme/app_theme.dart';
import 'brand.dart';

/// Pied de page du site, repris de la landing : carte sombre, symbole qui
/// déborde du haut, accroche, liens utiles, mention de l'éditeur et grand
/// logo coupé par le bord bas. Toujours présent sous les pages 404.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  static const _night = Color(0xFF221043);
  static const _mango = Color(0xFFFFC233);
  static const _coral = Color(0xFFE01928);

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: .72);
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 720;
        final mark = wide ? 96.0 : 76.0;
        final links = [
          _FootLinks('Calandix', [
            ('À propos'.tr, Routes.about),
            ('Conditions générales'.tr, Routes.terms),
            ('Confidentialité'.tr, Routes.privacy),
          ]),
          _FootLinks('Commencer'.tr, [
            ('Créer un compte'.tr, Routes.signUp),
            ('Se connecter'.tr, Routes.signIn),
            ('Je suis prestataire'.tr, '${Routes.signIn}?profil=creator'),
          ]),
        ];
        return Padding(
          padding: EdgeInsets.fromLTRB(12, mark / 2 + 24, 12, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _night,
                      borderRadius: BorderRadius.circular(wide ? 40 : 28),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 48 : 22,
                            mark / 2 + 24,
                            wide ? 48 : 22,
                            0,
                          ),
                          child: Column(
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Le budget parfait pour '.tr,
                                  children: [
                                    TextSpan(
                                      text: 'célébrer'.tr,
                                      style: const TextStyle(color: _mango),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTheme.font,
                                  fontSize: wide ? 44 : 30,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.6,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Conçu pour la Côte d’Ivoire.'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: soft, fontSize: 15),
                              ),
                              const SizedBox(height: 22),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  _FootButton(
                                    label: 'Organiser gratuitement'.tr,
                                    filled: true,
                                    onTap: () => context.go(Routes.signUp),
                                  ),
                                  _FootButton(
                                    label: 'Je suis prestataire'.tr,
                                    onTap: () => context.go(
                                      '${Routes.signIn}?profil=creator',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),
                              Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: .1),
                              ),
                              const SizedBox(height: 28),
                              Wrap(
                                spacing: 64,
                                runSpacing: 24,
                                alignment: wide
                                    ? WrapAlignment.center
                                    : WrapAlignment.start,
                                children: links,
                              ),
                              const SizedBox(height: 28),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 10,
                                children: [
                                  Text(
                                    '© 2026 Calandix',
                                    style: TextStyle(color: soft, fontSize: 13),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .08,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'Calandix est un service délivré par '
                                            .tr,
                                        children: const [
                                          TextSpan(
                                            text: 'TOOTEBO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: .85,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Grand logo, coupé par le bord bas de la carte.
                        ExcludeSemantics(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 32 : 14,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: .82,
                              child: Image.asset(
                                'assets/brand/calandix_logo_light.png',
                                width: double.infinity,
                                fit: BoxFit.fitWidth,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -mark / 2,
                    left: 0,
                    right: 0,
                    child: Center(child: CalandixMark(size: mark)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FootLinks extends StatelessWidget {
  const _FootLinks(this.title, this.items);

  final String title;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: SiteFooter._mango,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        for (final (label, route) in items)
          InkWell(
            onTap: () => context.go(route),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FootButton extends StatelessWidget {
  const _FootButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? SiteFooter._coral : Colors.transparent,
      shape: StadiumBorder(
        side: filled
            ? BorderSide.none
            : const BorderSide(color: Colors.white, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

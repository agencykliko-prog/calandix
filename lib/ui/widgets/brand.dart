import 'package:flutter/material.dart';

import '../theme/eventa_colors.dart';

/// Symbole Calandix : trois cartes empilées (mangue, corail, violet).
class CalandixMark extends StatelessWidget {
  const CalandixMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/calandix_mark.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: 'Calandix',
  );
}

/// Logo complet (symbole + nom). [size] reprend la taille de texte de
/// l'ancien logo ; [color] clair donne la version blanche, pour les fonds
/// sombres.
class CalandixWordmark extends StatelessWidget {
  const CalandixWordmark({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Sans couleur imposée, la version claire suit le mode sombre.
    final light = color != null
        ? color!.computeLuminance() > 0.5
        : Confetti.dark;
    return Image.asset(
      light
          ? 'assets/brand/calandix_logo_light.png'
          : 'assets/brand/calandix_logo.png',
      height: size * 1.25,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Calandix',
    );
  }
}

/// Drapeau ivoirien dessiné (pas d'emoji).
class CiFlag extends StatelessWidget {
  const CiFlag({super.key, this.width = 22});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: width,
        height: width * 2 / 3,
        child: const Row(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFF77F00))),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: Color(0xFF009E60))),
          ],
        ),
      ),
    );
  }
}

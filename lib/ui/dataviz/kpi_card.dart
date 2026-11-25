import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/eventa_colors.dart';
import '../widgets/ui.dart';
import 'live_dot.dart';
import 'sparkline.dart';

/// Indicateur clé, commun à tous les tableaux de bord (organisateur, pro,
/// administration).
///
/// Deux densités :
/// - par défaut : icône et libellé en tête, valeur, tendance, légende et
///   mini-courbe (console d'administration) ;
/// - [KpiCard.compact] : valeur puis libellé, icône facultative (espace pro,
///   fiches mobiles).
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required IconData this.icon,
    required this.hue,
    required this.label,
    required this.value,
    required String this.caption,
    this.trend,
    this.spark,
    this.live = false,
    this.onTap,
  }) : _compact = false;

  const KpiCard.compact({
    super.key,
    required this.label,
    required this.value,
    required this.hue,
    this.icon,
    this.caption,
  }) : trend = null,
       spark = null,
       live = false,
       onTap = null,
       _compact = true;

  final IconData? icon;
  final Hue hue;
  final String label;
  final String value;
  final String? caption;

  /// Variation en % sur la période (positive = hausse).
  final double? trend;
  final List<double>? spark;
  final bool live;
  final VoidCallback? onTap;
  final bool _compact;

  @override
  Widget build(BuildContext context) =>
      _compact ? _buildCompact(context) : _buildFull(context);

  Widget _buildFull(BuildContext context) {
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon!, hue: hue, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
              ),
              if (live) const LiveDot(),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
            child: FittedBox(
              key: ValueKey(value),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: context.text.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (trend != null) ...[
                Text(
                  '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(1).replaceAll('.', ',')} %',
                  style: context.text.labelSmall?.copyWith(
                    color: trend! >= 0 ? Confetti.success : Confetti.danger,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ),
            ],
          ),
          if (spark != null) ...[
            const SizedBox(height: 10),
            Sparkline(spark!, color: hue.base, height: 34),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) => Panel(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          IconTile(icon: icon!, hue: hue, size: 32),
          const SizedBox(height: 10),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(
          label,
          maxLines: 2,
          style: context.text.labelSmall?.copyWith(
            color: Confetti.inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: context.text.labelSmall?.copyWith(color: hue.text),
          ),
      ],
    ),
  );
}

/// Grille d'indicateurs responsive.
///
/// Par défaut : 1 à [max] colonnes d'au moins [minTile] de large (console).
/// [KpiGrid.compact] : 2 colonnes sur mobile, 4 à partir de 600 px.
class KpiGrid extends StatelessWidget {
  const KpiGrid({
    super.key,
    required this.children,
    this.minTile = 220,
    this.max = 4,
    this.spacing = 12,
  }) : _compact = false;

  const KpiGrid.compact({super.key, required this.children})
    : minTile = 0,
      max = 4,
      spacing = 8,
      _compact = true;

  final List<Widget> children;
  final double minTile;
  final int max;
  final double spacing;
  final bool _compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = _compact
          ? (box.maxWidth >= 600 ? 4 : 2)
          : (box.maxWidth / minTile).floor().clamp(1, max);
      // Une ligne de cartes = une seule hauteur, même quand un libellé ou
      // une légende passe sur deux lignes.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i += n) ...[
            if (i > 0) SizedBox(height: spacing),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + n; j++) ...[
                    if (j > i) SizedBox(width: spacing),
                    Expanded(
                      child: j < children.length
                          ? children[j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

import 'package:flutter/material.dart';

import '../../core/i18n/tr.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/eventa_colors.dart';
import 'pressable.dart';

enum ButtonTone { primary, dark, ghost, light, gold }

/// Bouton pilule. [loading] remplace le libellé sans changer la largeur.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.tone = ButtonTone.primary,
    this.loading = false,
    this.expand = true,
    this.height = 54,
    this.flat = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonTone tone;
  final bool loading;
  final bool expand;
  final double height;

  /// Sans relief ni reflet, coins à 14 px : CTA sobre des écrans d'accès.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = switch (tone) {
      ButtonTone.primary => (
        Confetti.violet,
        Confetti.onViolet,
        Colors.transparent,
      ),
      ButtonTone.dark => (Confetti.ink, Confetti.onInk, Colors.transparent),
      ButtonTone.ghost => (Confetti.surface, Confetti.ink, Confetti.line),
      ButtonTone.light => (Confetti.surface, Confetti.ink, Colors.transparent),
      ButtonTone.gold => (Confetti.gold, Confetti.inkFixed, Colors.transparent),
    };
    final lip = switch (tone) {
      ButtonTone.ghost || ButtonTone.light => Confetti.line,
      ButtonTone.dark => Color.lerp(bg, Colors.black, 0.55)!,
      _ => Color.lerp(bg, Colors.black, 0.28)!,
    };

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: fg),
        ],
      ],
    );

    return Pressable(
      onTap: enabled ? onPressed : null,
      haptic: true,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: onPressed == null ? 0.42 : 1,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(flat ? 14 : height),
            border: Border.all(color: border, width: 1.5),
            // Reflet doux en haut : volume « bonbon » sans effet plastique.
            gradient:
                flat || tone == ButtonTone.ghost || tone == ButtonTone.light
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(bg, Colors.white, 0.14)!, bg],
                  ),
            // Relief net sous le bouton, plus une ombre colorée pour l'action.
            boxShadow: enabled && !flat
                ? [
                    BoxShadow(color: lip, offset: const Offset(0, 3.5)),
                    if (tone == ButtonTone.primary)
                      BoxShadow(
                        color: Confetti.violet.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: Motion.fast,
            switchInCurve: Motion.easeOut,
            child: loading
                ? SizedBox(
                    key: const ValueKey('l'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: fg,
                    ),
                  )
                : KeyedSubtree(key: const ValueKey('c'), child: content),
          ),
        ),
      ),
    );
  }
}

/// Bouton rond (retour, actions d'en-tête).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background,
    this.foreground,
    this.size = 42,
    this.tooltip,
    this.badge = false,
    this.badgeCount,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? foreground;
  final double size;
  final String? tooltip;
  final bool badge;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final background = this.background ?? Confetti.surface;
    final foreground = this.foreground ?? Confetti.ink;
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      semanticLabel: tooltip?.tr,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: background == Confetti.surface
              ? Border.all(color: Confetti.line)
              : null,
          boxShadow: [
            BoxShadow(
              color: background == Confetti.surface
                  ? Confetti.line
                  : Color.lerp(background, Colors.black, 0.3)!,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, color: foreground, size: size * 0.46),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Confetti.coral,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if (badge)
              Positioned(
                top: size * 0.24,
                right: size * 0.26,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Confetti.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: background, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pastille de statut teintée.
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.label,
    required this.hue,
    this.icon,
    this.solid = false,
  });

  final String label;
  final Hue hue;
  final IconData? icon;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final fg = solid ? hue.onBase : hue.text;
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 9 : 7, 4, 9, 4),
      decoration: BoxDecoration(
        color: solid ? hue.base : hue.tint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marqueur Premium : pastille fine, liseré doré, couronne pleine.
/// Lisible sans attirer l'œil ; [onDark] pour les surfaces nuit.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    this.label = 'Premium',
    this.compact = false,
    this.onDark = false,
  });

  final String label;
  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8),
      decoration: BoxDecoration(
        color: onDark
            ? Confetti.gold.withValues(alpha: 0.12)
            : Confetti.goldTint.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Confetti.gold.withValues(alpha: onDark ? 0.5 : 0.7),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.crown,
            size: 11,
            color: onDark ? Confetti.gold : const Color(0xFFB0862A),
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                fontSize: 10.5,
                letterSpacing: 0.2,
                color: onDark ? Confetti.goldTint : const Color(0xFF6B4E12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Titre de section avec action optionnelle.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleLarge)),
          ?trailing,
          if (action != null)
            Pressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      action!,
                      style: context.text.labelMedium?.copyWith(
                        color: context.eventa.muted,
                      ),
                    ),
                    if (onAction != null) ...[
                      const SizedBox(width: 2),
                      Icon(
                        AppIcons.chevron,
                        size: 14,
                        color: context.eventa.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Surface blanche, bordure fine et ombre très douce (façon Linear).
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.radius = 22,
    this.onTap,
    this.border = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Confetti.surface;
    final white = color == Confetti.surface;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: white && border ? Border.all(color: Confetti.line) : null,
        boxShadow: white
            ? [
                BoxShadow(
                  color: Confetti.inkFixed.withValues(
                    alpha: Confetti.dark ? 0.3 : 0.04,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, child: box);
  }
}

/// Carte sombre « premium » (fond nuit).
class NightPanel extends StatelessWidget {
  const NightPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Confetti.night,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Confetti.nightLine),
        boxShadow: [
          BoxShadow(
            color: Confetti.ink.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, child: box);
  }
}

/// Bloc de chargement qui pulse doucement.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Couche isolée : le clignotement ne redessine pas l'écran autour.
    return RepaintBoundary(
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Confetti.lavender,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// État d'erreur : nomme le problème et propose la reprise.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Confetti.coralTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.warning,
                color: Confetti.coralDeep,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger vos événements'.tr,
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'Vérifiez votre connexion puis réessayez.'.tr,
              style: context.text.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PillButton(
              label: 'Réessayer'.tr,
              icon: AppIcons.refresh,
              onPressed: onRetry,
              tone: ButtonTone.dark,
              expand: false,
              height: 46,
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre de progression arrondie, animée à l'apparition.
class Meter extends StatelessWidget {
  const Meter({
    super.key,
    required this.value,
    required this.color,
    this.track,
    this.height = 8,
  });

  final double value;
  final Color color;
  final Color? track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Motion.easeOut,
      builder: (context, v, _) => Container(
        height: height,
        decoration: BoxDecoration(
          color: track ?? Confetti.lavender,
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tuile carrée teintée qui porte une icône.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.hue,
    this.size = 40,
    this.solid = false,
  });

  final IconData icon;
  final Hue hue;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        // Dégradé à peine perceptible : la tuile gagne du volume.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: solid
              ? [Color.lerp(hue.base, Colors.white, 0.18)!, hue.base]
              : [hue.tint, Color.lerp(hue.tint, hue.base, 0.16)!],
        ),
        border: Border(
          bottom: BorderSide(
            color: solid
                ? Color.lerp(hue.base, Colors.black, 0.25)!
                : Color.lerp(hue.tint, hue.base, 0.28)!,
            width: 2,
          ),
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: solid ? hue.onBase : hue.text,
      ),
    );
  }
}

/// Feuille modale maison : marge, coins arrondis, courbe de tiroir iOS.
Future<T?> showEventaSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
  bool dark = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Confetti.inkFixed.withValues(alpha: 0.5),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 420),
      curve: Motion.drawer,
      reverseDuration: Duration(milliseconds: 220),
    ),
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          decoration: BoxDecoration(
            color: dark ? Confetti.night : Confetti.cream,
            borderRadius: BorderRadius.circular(30),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dark ? Confetti.nightLine : Confetti.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Flexible(child: builder(ctx)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void toast(BuildContext context, String text, {IconData? icon}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? AppIcons.checkCircle,
              color: Confetti.lagoon,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
}

/// Étoiles de note.
class Stars extends StatelessWidget {
  const Stars({super.key, required this.rating, this.size = 13, this.reviews});

  final double rating;
  final double size;
  final int? reviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.star, size: size, color: Confetti.mango),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1).replaceAll('.', ','),
          style: context.text.labelMedium?.copyWith(fontSize: size - 0.5),
        ),
        if (reviews != null) ...[
          const SizedBox(width: 3),
          Text(
            '({0} avis)'.trf([reviews]),
            style: context.text.labelSmall?.copyWith(
              color: context.eventa.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

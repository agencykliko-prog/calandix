import 'package:flutter/material.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../ui/theme/app_icons.dart';
import '../../../../ui/theme/eventa_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../ui/widgets/pressable.dart';
import '../../../../core/models/models.dart';
import '../../data/vendor_media.dart';

String priceLabel(Vendor v) => 'dès {0}{1}'.trf([
  fcfa(v.priceFrom),
  v.unit == 'forfait' ? '' : ' / ${v.unit}',
]);

/// Carte prestataire : grande photo qui porte la note et la catégorie,
/// puis nom, accroche, zone et délai de réponse, et le prix en évidence.
/// Les coordonnées restent à portée de main.
class VendorCard extends StatelessWidget {
  const VendorCard({super.key, required this.vendor, required this.onTap});

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    final muted = context.text.labelMedium?.copyWith(color: Confetti.inkMuted);
    return Pressable(
      onTap: onTap,
      semanticLabel: v.name,
      child: Container(
        decoration: BoxDecoration(
          color: Confetti.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Confetti.line),
          boxShadow: [
            BoxShadow(
              color: Confetti.ink.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'vendor-${v.id}',
                    child: VendorPhoto(v.image, cacheWidth: 800),
                  ),
                  const _Veil(stops: [0, 0.45, 1]),
                  if (v.sponsor != null)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: SponsorTag(sponsor: v.sponsor!),
                    ),
                  Positioned(right: 12, top: 12, child: RatingChip(vendor: v)),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _GlassChip(
                      icon: v.category.icon,
                      label: v.category.label,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: AvailabilityPill(vendor: v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  if (v.verified) ...[
                    const SizedBox(width: 5),
                    Icon(AppIcons.verified, size: 17, color: Confetti.violet),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                v.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  color: Confetti.inkMuted,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  Icon(AppIcons.place, size: 14, color: Confetti.inkFaint),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      v.zone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(AppIcons.clock, size: 14, color: Confetti.inkFaint),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Répond en {0}'.trf([v.responseTime]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'à partir de'.tr,
                          style: context.text.labelSmall?.copyWith(
                            color: Confetti.inkFaint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            v.unit == 'forfait'
                                ? fcfa(v.priceFrom)
                                : '${fcfa(v.priceFrom)} / ${v.unit}',
                            style: context.text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Confetti.coralDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ContactDot(icon: AppIcons.phone, label: v.phoneNumber),
                  _ContactDot(icon: AppIcons.mail, label: v.email),
                  _ContactDot(icon: AppIcons.globe, label: v.website),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte vitrine (carrousel horizontal de l'accueil) : photo plein cadre,
/// texte posé sur un voile sombre.
class VendorSpotlight extends StatelessWidget {
  const VendorSpotlight({super.key, required this.vendor, required this.onTap});

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    return Pressable(
      onTap: onTap,
      semanticLabel: v.name,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            VendorPhoto(v.image, cacheWidth: 500),
            const _Veil(stops: [0, 0.3, 1]),
            Positioned(right: 10, top: 10, child: RatingChip(vendor: v)),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassChip(icon: v.category.icon, label: v.category.label),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          v.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (v.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          AppIcons.verified,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceLabel(v),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(
                      color: const Color(0xFFFFC233),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Voile sombre en bas de photo, pour que le texte blanc reste lisible.
class _Veil extends StatelessWidget {
  const _Veil({required this.stops});

  final List<double> stops;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x26000000),
            Colors.transparent,
            Color(0xD91A0637),
          ],
          stops: stops,
        ),
      ),
    );
  }
}

/// Note du prestataire et nombre d'avis, sur une pastille blanche.
class RatingChip extends StatelessWidget {
  const RatingChip({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final r = vendor.rating.toStringAsFixed(1).replaceAll('.', ',');
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.star, size: 12, color: Color(0xFFE5A21A)),
          const SizedBox(width: 3),
          Text(
            '$r · ${vendor.reviews}',
            style: context.text.labelSmall?.copyWith(
              color: Confetti.inkFixed,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille translucide (catégorie) posée sur une photo.
class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Coordonnée affichée en pastille ronde ; le détail est dans l'infobulle.
class _ContactDot extends StatelessWidget {
  const _ContactDot({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: Confetti.lavender,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: Confetti.ink),
      ),
    );
  }
}

class SponsorTag extends StatelessWidget {
  const SponsorTag({super.key, required this.sponsor});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        sponsor == Sponsor.recommended ? 'Recommandé'.tr : 'Sponsorisé'.tr,
        style: context.text.labelSmall?.copyWith(
          color: Confetti.inkFixed,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final ok = vendor.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ok ? Confetti.success : Confetti.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            ok ? 'Disponible'.tr : (vendor.nextAvailable ?? 'Complet'.tr),
            style: context.text.labelSmall?.copyWith(
              color: Confetti.inkFixed,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

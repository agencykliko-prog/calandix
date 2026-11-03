part of 'home_screen.dart';

/// En-tête d'accueil sur téléphone : un ciel violet et ses nuages, la
/// salutation, le budget du prochain événement et les actions rapides.
class _SkyHero extends ConsumerStatefulWidget {
  const _SkyHero({required this.next});

  final Event next;

  @override
  ConsumerState<_SkyHero> createState() => _SkyHeroState();
}

class _SkyHeroState extends ConsumerState<_SkyHero> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final e = widget.next;
    final pct = (e.committedRatio * 100).round();
    final days = daysUntil(e.date);
    const onSky = Colors.white;
    final amount = fcfa(e.targetBudget).replaceAll(RegExp(r'\s*FCFA$'), '');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A27C9), Color(0xFF5B48EA), Color(0xFF9C8FF6)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _CloudsPainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pressable(
                      onTap: () => context.go(Routes.account),
                      child: Avatar(
                        image: p.photoAsset,
                        bytes: p.photoBytes,
                        initials: p.initials,
                        size: 38,
                        ring: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '{0}, {1}'.trf([greeting(), p.firstName]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(color: onSky),
                      ),
                    ),
                    const _MessagesButton(onSky: true),
                    const SizedBox(width: 8),
                    const _Bell(onSky: true),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Budget · {0}'.trf([e.name]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: onSky.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      button: true,
                      label: _hidden
                          ? 'Afficher les montants'.tr
                          : 'Masquer les montants'.tr,
                      child: GestureDetector(
                        onTap: () => setState(() => _hidden = !_hidden),
                        child: Icon(
                          _hidden ? AppIcons.eyeOff : AppIcons.eye,
                          size: 18,
                          color: onSky,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: _hidden ? '••• •••' : amount,
                            style: TextStyle(
                              fontFamily: AppTheme.font,
                              fontSize: 42,
                              height: 1,
                              letterSpacing: -1.2,
                              fontWeight: FontWeight.w800,
                              color: onSky,
                            ),
                            children: [
                              TextSpan(
                                text: ' FCFA',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: onSky.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SkyPill(
                      label: days == 0 ? 'Jour J'.tr : 'J-{0}'.trf([days]),
                      onTap: () => context.push(Routes.event(e.id)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Confetti.lagoon,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _hidden
                        ? '{0} % engagé'.trf([pct])
                        : '{0} engagés · {1} %'.trf([
                            fcfaCompact(e.committed),
                            pct,
                          ]),
                    style: context.text.labelMedium?.copyWith(
                      color: Confetti.inkFixed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _SkyAction(
                        icon: AppIcons.add,
                        label: 'Créer'.tr,
                        onTap: () => context.push(Routes.newEvent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _SkyAction(
                        icon: AppIcons.coins,
                        label: 'Ajouter une dépense'.tr,
                        onTap: () => context.push(Routes.budget(e.id)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SkyAction(
                      icon: AppIcons.more,
                      tooltip: 'Ouvrir l’événement'.tr,
                      onTap: () => context.push(Routes.event(e.id)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton pilule bleu nuit sur le ciel.
class _SkyAction extends StatelessWidget {
  const _SkyAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.tooltip,
  });

  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = Pressable(
      onTap: onTap,
      child: Container(
        height: 50,
        width: label == null ? 50 : null,
        padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
        decoration: BoxDecoration(
          color: const Color(0xFF221266),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            if (label != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return label == null
        ? Semantics(button: true, label: tooltip, child: child)
        : Semantics(button: true, child: child);
  }
}

/// Petite pastille translucide (compte à rebours de l'événement).
class _SkyPill extends StatelessWidget {
  const _SkyPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// Nuages doux, en grappes de cercles blancs translucides.
class _CloudsPainter extends CustomPainter {
  const _CloudsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void cloud(double cx, double cy, double s, double a) {
      final paint = Paint()..color = Colors.white.withValues(alpha: a);
      for (final (dx, dy, r) in const [
        (0.0, 0.0, 1.0),
        (-1.1, 0.35, 0.72),
        (1.05, 0.3, 0.8),
        (-0.45, -0.55, 0.7),
        (0.55, -0.45, 0.62),
        (-1.9, 0.6, 0.5),
        (1.9, 0.62, 0.52),
      ]) {
        canvas.drawCircle(Offset(cx + dx * s, cy + dy * s), r * s, paint);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 2.3 * s, cy + 0.45 * s, 4.6 * s, 0.75 * s),
          Radius.circular(s),
        ),
        paint,
      );
    }

    final w = size.width, h = size.height;
    cloud(w * 0.78, h * 0.33, 26, 0.18);
    cloud(w * 0.58, h * 0.62, 34, 0.14);
    cloud(w * 0.12, h * 0.78, 22, 0.12);
    cloud(w * 0.95, h * 0.86, 30, 0.2);
  }

  @override
  bool shouldRepaint(_CloudsPainter old) => false;
}

/// Carte d'offre sous le ciel : le Pass Événement, pour qui n'a pas d'abonnement.
class _PassPromo extends StatelessWidget {
  const _PassPromo();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(Routes.premium),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pass Événement · {0}'.trf([fcfa(eventPassPrice)]),
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toutes les fonctions Signature pendant 30 jours, pour un seul événement.'
                        .tr,
                    style: context.text.bodySmall?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Mascot(size: 64, mood: MascotMood.cheer),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Confetti.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.forward, size: 16, color: Confetti.cream),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte compacte d'un événement, pour le défilement horizontal.
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final hue = e.category.hue;
    final days = daysUntil(e.date);
    return Pressable(
      onTap: () => context.push(Routes.event(e.id)),
      child: Container(
        width: 164,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Confetti.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Confetti.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hue.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(e.category.icon, size: 20, color: hue.deep),
                ),
                const Spacer(),
                Text(
                  days < 0 ? 'Passé'.tr : 'J-{0}'.trf([days]),
                  style: context.text.labelMedium?.copyWith(color: hue.deep),
                ),
              ],
            ),
            const Spacer(),
            Text(
              e.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                color: Confetti.inkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    fcfaCompact(e.targetBudget),
                    maxLines: 1,
                    style: context.text.titleMedium,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '{0} %'.trf([(e.committedRatio * 100).round()]),
                  style: context.text.labelSmall?.copyWith(
                    color: Confetti.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille d'un prestataire recommandé : photo ronde, nom et note.
class _VendorChip extends StatelessWidget {
  const _VendorChip({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    return Pressable(
      onTap: () => context.push(Routes.vendor(v.id)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
        decoration: BoxDecoration(
          color: Confetti.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Confetti.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: VendorPhoto(
                v.image,
                width: 28,
                height: 28,
                cacheWidth: 96,
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                v.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '★ ${v.rating.toStringAsFixed(1).replaceAll('.', ',')}',
              style: context.text.labelSmall?.copyWith(color: Confetti.success),
            ),
          ],
        ),
      ),
    );
  }
}

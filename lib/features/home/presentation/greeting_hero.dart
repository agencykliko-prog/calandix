import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/mascot.dart';

/// En-tête d'accueil : pleine largeur sur téléphone : la salutation au
/// prénom de l'utilisateur, la fourmi qui salue, un halo et des confettis.
class GreetingHero extends ConsumerStatefulWidget {
  const GreetingHero({
    super.key,
    required this.header,
    this.question,
    this.mascot = MascotColor.organizer,
    this.action,
  });

  /// Barre du haut (photo, notifications).
  final Widget header;

  /// Petite ligne sous la salutation.
  final String? question;

  /// Espace du profil (varie la pose par défaut).
  final MascotColor mascot;

  /// Action principale facultative (ex. créer un événement).
  final Widget? action;

  @override
  ConsumerState<GreetingHero> createState() => _GreetingHeroState();
}

class _GreetingHeroState extends ConsumerState<GreetingHero>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  Offset? _pointer;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((t) => _time.value = t.inMicroseconds / 1e6)
      ..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  Offset? _lookFrom(Offset mascot) {
    final p = _pointer;
    if (p == null) return null;
    final d = p - mascot;
    final len = math.max(d.distance, 1);
    return Offset(d.dx / len, d.dy / len) * math.min(1, len / 140);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 400;
    final bleed = width < 720;
    final cardH = compact ? 330.0 : 350.0;
    final mascotSize = compact ? 196.0 : 240.0;
    final first = ref
        .watch(profileProvider.select((p) => p.name))
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    final accent = Confetti.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header,
        Padding(
          padding: EdgeInsets.fromLTRB(bleed ? 0 : 16, 10, bleed ? 0 : 16, 4),
          child: MouseRegion(
            onHover: (e) => setState(() => _pointer = e.localPosition),
            onExit: (_) => setState(() => _pointer = null),
            child: LayoutBuilder(
              builder: (context, box) {
                final mCenter = Offset(
                  box.maxWidth - mascotSize * 0.42,
                  cardH - mascotSize * 0.45,
                );
                return Container(
                  height: cardH,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: bleed
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(36),
                          )
                        : BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent ?? const Color(0xFF4D39E2),
                        Color.lerp(
                          accent ?? const Color(0xFF4D39E2),
                          const Color(0xFF1A0637),
                          0.72,
                        )!,
                      ],
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _GlowPainter(
                              time: _time,
                              center: mCenter,
                              color: const Color(0xFFE59D1F),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _ConfettiPainter(time: _time, dark: true),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -mascotSize * 0.10,
                        bottom: -mascotSize * 0.04,
                        child: Mascot(
                          size: mascotSize,
                          color: widget.mascot,
                          waving: true,
                          look: _lookFrom(mCenter),
                          onTap: () =>
                              ref.read(soundProvider).play(Sfx.success),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        right: math.max(22, box.maxWidth * 0.2),
                        top: 24,
                        child: _Rise(
                          delay: 200,
                          child: Text(
                            '${greeting()}\n$first !',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.font,
                              fontSize: compact ? 38 : 46,
                              height: 1.02,
                              letterSpacing: -1.4,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        right: mascotSize * 0.62,
                        bottom: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Rise(
                              delay: 340,
                              child: Text(
                                (widget.question ??
                                        'Qu’est-ce qu’on célèbre aujourd’hui ?'
                                            .tr)
                                    .replaceAll(' ?', '\u00A0?'),
                                style: TextStyle(
                                  fontFamily: AppTheme.font,
                                  fontSize: compact ? 15 : 16.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ),
                            if (widget.action != null) ...[
                              const SizedBox(height: 12),
                              _Rise(
                                delay: 460,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: widget.action!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Halo circulaire qui respire derrière la mascotte.
class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.time, required this.center, required this.color})
    : super(repaint: time);

  final ValueNotifier<double> time;
  final Offset center;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 1 + math.sin(time.value * 1.3) * 0.04;
    final r = size.height * 0.62 * pulse;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(
      center,
      r * 0.78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = color.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.center != center || old.color != color;
}

/// Apparition en montée douce, décalée de [delay] millisecondes.
class _Rise extends StatelessWidget {
  const _Rise({required this.child, this.delay = 0});

  final Widget child;
  final int delay;
  static const distance = 18.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 620 + delay),
      curve: Interval(delay / (620 + delay), 1, curve: Curves.easeOutBack),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * distance),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Confettis qui flottent lentement : rubans, pastilles et petites étoiles.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.time, required this.dark})
    : super(repaint: time);

  final ValueNotifier<double> time;
  final bool dark;

  static const _colors = [
    Color(0xFFE5484D),
    Color(0xFF6246EA),
    Color(0xFFE5A21A),
    Color(0xFF0E9F8E),
    Color(0xFFDB4F9E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final rnd = math.Random(7);
    // Confettis qui tombent en voletant, derrière la salutation.
    for (var i = 0; i < 34; i++) {
      final x0 = rnd.nextDouble(), y0 = rnd.nextDouble();
      final speed = 0.04 + rnd.nextDouble() * 0.05;
      final s = 0.9 + rnd.nextDouble() * 0.8;
      final phase = rnd.nextDouble() * math.pi * 2;
      final kind = i % 3;
      final y = ((y0 + t * speed) % 1.1 - 0.05) * size.height;
      final x = x0 * size.width + math.sin(t * 1.4 + phase) * 16;
      final a = dark ? 0.55 : 0.85;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: a);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * (1.2 + rnd.nextDouble() * 1.6) + phase);
      canvas.scale(s, s * (0.35 + 0.65 * math.cos(t * 3 + phase).abs()));
      switch (kind) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-6, -2, 12, 4),
              const Radius.circular(2),
            ),
            paint,
          );
        case 1:
          canvas.drawCircle(Offset.zero, 3.2, paint);
        default:
          final p = Path();
          for (var k = 0; k < 8; k++) {
            final r = k.isEven ? 5.0 : 2.0;
            final ang = k * math.pi / 4;
            final pt = Offset(math.cos(ang) * r, math.sin(ang) * r);
            k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
          }
          canvas.drawPath(p..close(), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.time != time || old.dark != dark;
}

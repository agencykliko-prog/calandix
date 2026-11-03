import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/tr.dart';

/// La mascotte de Calandix : une fourmi rouge pour les organisateurs, jaune
/// dans l'espace Creator.
enum MascotColor { organizer, creator }

/// Humeur affichée : chaque humeur correspond à une pose illustrée.
enum MascotMood { happy, wow, wink, sleepy, cheer, sad }

/// Poses disponibles.
enum _Shot { rire, salut, sport, panneau, triste, idee, yeux, bouee, course }

String _asset(_Shot s, [MascotColor c = MascotColor.organizer]) =>
    'assets/images/mascots/${c == MascotColor.creator ? 'jaune/' : ''}${s.name}.webp';

_Shot _shotFor(MascotMood mood, MascotColor color) => switch (mood) {
  MascotMood.happy => color == MascotColor.creator ? _Shot.idee : _Shot.rire,
  MascotMood.wink => _Shot.idee,
  MascotMood.cheer => _Shot.sport,
  MascotMood.wow => _Shot.course,
  MascotMood.sleepy => _Shot.bouee,
  MascotMood.sad => _Shot.triste,
};

/// Salut animé de la fourmi rouge (WebP animé, fond transparent).
const _waveAnimation = 'assets/images/mascots/salut_anim.webp';

/// Charge les poses à l'avance pour que les changements soient instantanés.
void precacheMascots(BuildContext context) {
  for (final s in _Shot.values) {
    for (final c in MascotColor.values) {
      precacheImage(AssetImage(_asset(s, c)), context);
    }
  }
}

/// Mascotte statique : une pose illustrée, sans mouvement. [cover] lui fait
/// fermer les yeux (champ de mot de passe) ; [waving] affiche la pose qui
/// salue.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.size = 120,
    this.color = MascotColor.organizer,
    this.mood = MascotMood.happy,
    this.look,
    this.cover = false,
    this.waving = false,
    this.animated = false,
    this.arms = true,
    this.legs = true,
    this.idle = true,
    this.onTap,
  });

  /// Côté du widget (carré).
  final double size;
  final MascotColor color;
  final MascotMood mood;
  final bool cover;
  final bool waving;

  /// Avec [waving], la fourmi rouge salue pour de bon : la main et les
  /// antennes bougent (animation en boucle, issue d'une vidéo Higgsfield).
  final bool animated;

  /// Conservés pour compatibilité : la mascotte ne bouge plus.
  final Offset? look;
  final bool arms;
  final bool legs;
  final bool idle;

  final VoidCallback? onTap;

  @override
  State<Mascot> createState() => MascotState();
}

class MascotState extends State<Mascot> {
  /// Conservé pour compatibilité : la mascotte reste immobile.
  void jump() {}

  _Shot get _shot {
    // Même pose que « idee », yeux fermés : le passage ressemble à un clignement.
    if (widget.cover) return _Shot.yeux;
    if (widget.waving) return _Shot.salut;
    return _shotFor(widget.mood, widget.color);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final moving =
        widget.animated &&
        widget.waving &&
        !widget.cover &&
        widget.color == MascotColor.organizer;
    final img = Image.asset(
      moving ? _waveAnimation : _asset(_shot, widget.color),
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    if (widget.onTap == null) return ExcludeSemantics(child: img);
    return Semantics(
      button: true,
      label: 'Mascotte Calandix'.tr,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: img,
        ),
      ),
    );
  }
}

/// Mascotte immobile, entourée de confettis qui volent, pendant les temps
/// d'attente. Les messages défilent sous elle.
class MascotLoader extends StatefulWidget {
  const MascotLoader({
    super.key,
    this.size = 96,
    this.messages = const [],
    this.color = MascotColor.organizer,
  });

  /// Chargement standard, avec des messages de fête qui défilent.
  const MascotLoader.party({super.key, this.color = MascotColor.organizer})
    : size = 96,
      messages = _party;

  static const _party = [
    'On prépare la fête…',
    'On gonfle les ballons…',
    'On compte les FCFA…',
    'On range les confettis…',
  ];

  final double size;
  final List<String> messages;
  final MascotColor color;

  @override
  State<MascotLoader> createState() => _MascotLoaderState();
}

class _MascotLoaderState extends State<MascotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  int _msg = 0;

  static const _confetti = [
    Color(0xFFF0585D),
    Color(0xFF7C63FF),
    Color(0xFF16B4A1),
    Color(0xFFF2B530),
    Color(0xFFE863AD),
  ];

  @override
  void initState() {
    super.initState();
    _c.addListener(_cycle);
  }

  double _last = 0;
  int _beats = 0;

  void _cycle() {
    if (_c.value < _last) {
      _beats++;
      if (_beats % 2 == 0 && widget.messages.length > 1) {
        setState(() => _msg = (_msg + 1) % widget.messages.length);
      }
    }
    _last = _c.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.size;
    final w = h * 1.4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w,
          height: h * 1.55,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final u = _c.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Confettis jonglés en arc au-dessus de la tête.
                  for (var i = 0; i < 3; i++) _piece(i, u, w, h),
                  // La mascotte reste immobile ; seuls les confettis volent.
                  Positioned(
                    left: (w - h) / 2,
                    bottom: 0,
                    child: Image.asset(
                      _asset(_Shot.rire, widget.color),
                      width: h,
                      height: h,
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.messages.isNotEmpty) ...[
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Text(
              widget.messages[_msg % widget.messages.length].tr,
              key: ValueKey(_msg),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _piece(int i, double u, double w, double h) {
    // Chaque confetti suit une parabole décalée d'un tiers de cycle.
    final p = (u + i / 3) % 1;
    final x = w / 2 + math.cos(p * math.pi) * w * 0.34;
    final y = h * 0.42 - math.sin(p * math.pi) * h * 0.38;
    return Positioned(
      left: x - 5,
      top: y,
      child: Transform.rotate(
        angle: p * math.pi * 3 + i,
        child: Container(
          width: 10,
          height: i == 1 ? 10 : 6,
          decoration: BoxDecoration(
            color: _confetti[i % _confetti.length],
            borderRadius: BorderRadius.circular(i == 1 ? 5 : 2),
          ),
        ),
      ),
    );
  }
}

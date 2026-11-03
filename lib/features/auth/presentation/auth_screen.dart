import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/auth/auth_gateway.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../core/sound/sounds.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../account/presentation/photo_cropper.dart';
import '../../../core/backend/backend.dart';
import '../../../core/models/models.dart';
import '../../../core/auth/profile.dart';
import '../../../core/auth/session_provider.dart';

/// Connexion et inscription, pour les deux profils.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.signUp = false,
    this.role = UserRole.organizer,
  });

  final bool signUp;
  final UserRole role;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _signUp = widget.signUp;
  late UserRole _role = widget.role;

  @override
  Widget build(BuildContext context) {
    final creator = _role == UserRole.creator;
    final mascot = creator ? MascotColor.creator : MascotColor.organizer;
    final size = MediaQuery.sizeOf(context);
    // Desktop : une carte en deux volets, l'illustration à gauche et le
    // formulaire à droite.
    final desktop = size.width >= 900 && size.height >= 600;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Entrance(
          index: 1,
          offset: 16,
          child: AnimatedSwitcher(
            duration: Motion.base,
            child: Text(
              _signUp ? 'Créer un compte'.tr : 'Bon retour'.tr,
              key: ValueKey(_signUp),
              style: context.text.headlineMedium?.copyWith(
                fontSize: desktop ? 36 : 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Entrance(
          index: 2,
          offset: 16,
          child: Text(
            _signUp
                ? 'Choisissez votre profil pour commencer.'.tr
                : 'Connectez-vous à votre espace.'.tr,
            style: context.text.bodyLarge?.copyWith(
              color: context.eventa.muted,
            ),
          ),
        ),
      ],
    );
    final intro = Padding(
      padding: EdgeInsets.fromLTRB(20, desktop ? 0 : 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Téléphone : pas d'illustration, la mascotte se tient à côté du
          // titre.
          if (desktop)
            heading
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: heading),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AuthMascot(color: mascot),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Entrance(
            index: 3,
            child: RolePicker(
              value: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
          ),
        ],
      ),
    );
    final forms = AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.easeOut,
      // L'ancien formulaire s'efface vite, sur place, et le
      // nouveau arrive aligné en haut : plus de saut.
      switchOutCurve: const Interval(0.5, 1),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        // En connexion, le formulaire reste le même : seul le
        // profil change, sans fondu.
        key: ValueKey(_signUp ? 'up-$_role' : 'in'),
        child: !_signUp
            ? _SignInForm(
                role: _role,
                onSwitch: () => setState(() => _signUp = true),
              )
            : _role == UserRole.organizer
            ? _OrganizerSignUp(onSwitch: () => setState(() => _signUp = false))
            : _CreatorSignUp(onSwitch: () => setState(() => _signUp = false)),
      ),
    );
    void back() =>
        context.canPop() ? context.pop() : context.go(Routes.onboarding);

    if (desktop) {
      return Scaffold(
        backgroundColor: Confetti.cream,
        body: Center(
          child: Container(
            width: math.min(size.width - 48, 1120),
            height: math.min(size.height - 48, 760),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Confetti.surface,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Confetti.line),
              boxShadow: [
                BoxShadow(
                  color: Confetti.inkFixed.withValues(alpha: 0.08),
                  blurRadius: 48,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: _AuthVisual(color: mascot, onBack: back),
                ),
                Expanded(
                  flex: 11,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          const SizedBox(height: 44),
                          intro,
                          Expanded(child: forms),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Confetti.dark ? Confetti.cream : Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RoundIconButton(
                            icon: AppIcons.back,
                            tooltip: 'Retour',
                            onTap: back,
                          ),
                        ),
                        const Entrance(child: CalandixWordmark(size: 25)),
                      ],
                    ),
                  ),
                ),
                intro,
                Expanded(child: forms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Volet illustré de la carte desktop : le nom Calandix en lettres gonflées
/// dans le ciel, la mascotte qui ferme les yeux pendant la saisie du mot de
/// passe, et la promesse de Calandix.
class _AuthVisual extends StatelessWidget {
  const _AuthVisual({required this.color, required this.onBack});

  final MascotColor color;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Le nom tient en entier dans la largeur ; le même ciel, flouté,
          // comble le haut et le bas quand le volet est plus étroit.
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Image.asset(
              'assets/images/auth_calandix.webp',
              fit: BoxFit.cover,
            ),
          ),
          Image.asset(
            'assets/images/auth_calandix.webp',
            fit: BoxFit.fitWidth,
            alignment: const Alignment(0, -0.35),
          ),
          // Voile sombre en bas, pour la promesse.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Confetti.inkFixed.withValues(alpha: 0),
                  Confetti.inkFixed.withValues(alpha: 0.55),
                ],
                stops: const [0.6, 1],
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: 22,
            right: 22,
            child: Row(
              children: [
                const Spacer(),
                _GlassPill(
                  label: 'Retour'.tr,
                  icon: AppIcons.back,
                  onTap: onBack,
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Entrance(
              offset: 24,
              child: AuthMascot(color: color, size: 210),
            ),
          ),
          Positioned(
            left: 30,
            right: 200,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organisez.\nRéservez.\nCélébrez.'.tr,
                  style: context.text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Le budget parfait pour célébrer.'.tr,
                  style: context.text.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille translucide posée sur l'illustration.
class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.text.labelMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Continuer avec Google » et le séparateur « ou » qui le suit. Absent
/// de l'inscription Creator, qui a besoin des informations de l'activité.
class GoogleSignIn extends ConsumerStatefulWidget {
  const GoogleSignIn({super.key});

  @override
  ConsumerState<GoogleSignIn> createState() => _GoogleSignInState();
}

class _GoogleSignInState extends ConsumerState<GoogleSignIn> {
  bool _busy = false;

  Future<void> _go() async {
    if (!Backend.ready) {
      toast(
        context,
        'Connexion Google indisponible hors ligne. Essayez la démo sans compte.'
            .tr,
        icon: AppIcons.info,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      // Le navigateur part chez Google puis revient sur l'app, connecté.
      await ref.read(authGatewayProvider).signInWithGoogle();
    } on AuthFailure catch (e) {
      if (mounted) toast(context, e.message, icon: AppIcons.warning);
    } catch (_) {
      if (mounted) {
        toast(
          context,
          'Connexion Google impossible pour le moment. Réessayez.'.tr,
          icon: AppIcons.warning,
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final label = 'Continuer avec Google'.tr;
    return Column(
      children: [
        Semantics(
          button: true,
          label: label,
          child: Pressable(
            onTap: _busy ? null : _go,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Confetti.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Confetti.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_busy)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const SizedBox.square(
                      dimension: 20,
                      child: CustomPaint(painter: _GoogleG()),
                    ),
                  const SizedBox(width: 10),
                  ExcludeSemantics(
                    child: Text(label, style: context.text.titleSmall),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Divider(color: Confetti.line, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ou avec votre e-mail'.tr,
                style: context.text.labelSmall?.copyWith(
                  color: Confetti.inkFaint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Confetti.line, height: 1)),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Le « G » de Google, dessiné en quatre couleurs.
class _GoogleG extends CustomPainter {
  const _GoogleG();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final w = s * 0.22;
    final c = Offset(size.width / 2, size.height / 2);
    final r = (s - w) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    double rad(double d) => d * math.pi / 180;
    void arc(double from, double to, int color) => canvas.drawArc(
      rect,
      rad(from),
      rad(to - from),
      false,
      Paint()
        ..color = Color(color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );
    arc(-2, 48, 0xFF4285F4);
    arc(46, 142, 0xFF34A853);
    arc(140, 222, 0xFFFBBC05);
    arc(220, 318, 0xFFEA4335);
    canvas.drawRect(
      Rect.fromLTRB(c.dx, c.dy - w / 2, c.dx + r + w / 2, c.dy + w / 2),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Solidité du mot de passe : quatre segments et un conseil, mis à jour à
/// chaque frappe.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.controller});

  final TextEditingController controller;

  static bool _cases(String p) =>
      RegExp('[a-z]').hasMatch(p) && RegExp('[A-Z]').hasMatch(p);
  static bool _digit(String p) => RegExp(r'\d').hasMatch(p);
  static bool _symbol(String p) => RegExp(r'[^A-Za-z0-9]').hasMatch(p);

  /// Niveau de 0 (vide) à 4 (solide).
  static int score(String p) {
    if (p.isEmpty) return 0;
    if (p.length < 8) return 1;
    var pts = 1;
    if (p.length >= 12) pts++;
    if (_cases(p)) pts++;
    if (_digit(p)) pts++;
    if (_symbol(p)) pts++;
    return pts <= 2 ? 2 : (pts == 3 ? 3 : 4);
  }

  static String _tip(String p) {
    if (p.length < 8) return '8 caractères minimum'.tr;
    final missing = [
      if (!_cases(p)) 'une majuscule'.tr,
      if (!_digit(p)) 'un chiffre'.tr,
      if (!_symbol(p)) 'un symbole'.tr,
    ];
    if (missing.isNotEmpty) {
      return 'Ajoutez {0} pour le renforcer.'.trf([missing.join(', ')]);
    }
    return p.length < 12
        ? '12 caractères ou plus, c’est encore mieux.'.tr
        : 'Parfait, il est difficile à deviner.'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.text;
        final level = score(p);
        final (label, color) = switch (level) {
          1 => ('Trop court'.tr, Confetti.danger),
          2 => ('Faible'.tr, Confetti.coral),
          3 => ('Moyen'.tr, Confetti.warning),
          _ => ('Solide'.tr, Confetti.success),
        };
        return AnimatedSize(
          duration: Motion.fast,
          alignment: Alignment.topCenter,
          child: level == 0
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Semantics(
                    label: 'Solidité du mot de passe : {0}'.trf([label]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var i = 1; i <= 4; i++) ...[
                              if (i > 1) const SizedBox(width: 5),
                              Expanded(
                                child: AnimatedContainer(
                                  duration: Motion.base,
                                  curve: Motion.easeOut,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: i <= level
                                        ? color
                                        : Confetti.lavender,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 76,
                              child: Text(
                                label,
                                textAlign: TextAlign.right,
                                style: context.text.labelMedium?.copyWith(
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ExcludeSemantics(
                          child: Text(
                            _tip(p),
                            style: context.text.bodySmall?.copyWith(
                              color: Confetti.inkMuted,
                            ),
                          ),
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

/// Choix du profil : deux tuiles symétriques.
class RolePicker extends StatelessWidget {
  const RolePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.dark = false,
  });

  final UserRole value;
  final ValueChanged<UserRole> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final left = value == UserRole.organizer;
    Widget tile(UserRole r, IconData icon) {
      final on = r == value;
      final fg = on ? Confetti.onInk : Confetti.ink;
      return Expanded(
        child: Pressable(
          onTap: () {
            if (on) return;
            HapticFeedback.selectionClick();
            onChanged(r);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: fg),
                  duration: Motion.base,
                  builder: (context, c, _) => Icon(icon, size: 20, color: c),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: Motion.base,
                        curve: Motion.easeOut,
                        style: context.text.titleSmall!.copyWith(color: fg),
                        child: Text(r.label),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: Motion.base,
                        curve: Motion.easeOut,
                        style: context.text.labelSmall!.copyWith(
                          color: on ? Colors.white70 : Confetti.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        child: Text(
                          r.pitch,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Une seule pastille sombre qui glisse d'un profil à l'autre : la
    // transition reste continue au lieu de deux cartes qui clignotent.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Confetti.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Confetti.line),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              alignment: left ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Confetti.ink,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Confetti.ink.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              tile(UserRole.organizer, AppIcons.confetti),
              tile(UserRole.creator, AppIcons.vendors),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Création de compte ─────────────────────────────────────────────────

/// Crée un compte réel. Si l'adresse doit être confirmée, l'utilisateur
/// est prévenu et renvoyé vers la connexion ([onConfirm]).
Future<void> createAccount(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
  String password, {
  required VoidCallback onConfirm,
}) async {
  try {
    final outcome = await ref
        .read(sessionProvider.notifier)
        .signUpWithPassword(profile, password);
    if (!context.mounted) return;
    authMascotKey.currentState?.jump();
    ref.read(soundProvider).play(Sfx.success);
    if (outcome == SignUpOutcome.confirmEmail) {
      await showEventaSheet<void>(
        context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vérifiez vos e-mails'.tr, style: ctx.text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Nous avons envoyé un lien de confirmation à {0}. Ouvrez-le pour activer votre compte, puis connectez-vous.'
                    .trf([profile.email]),
                style: ctx.text.bodyMedium,
              ),
              const SizedBox(height: 18),
              PillButton(
                label: 'Compris'.tr,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      );
      onConfirm();
      return;
    }
    if (context.mounted) context.go(Routes.home);
  } on AuthFailure catch (e) {
    if (context.mounted) toast(context, e.message, icon: AppIcons.warning);
  } catch (_) {
    if (context.mounted) {
      toast(
        context,
        'Inscription impossible pour le moment. Vérifiez votre connexion puis réessayez.'
            .tr,
        icon: AppIcons.warning,
      );
    }
  }
}

// ─── Connexion ──────────────────────────────────────────────────────────

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm({required this.role, required this.onSwitch});

  final UserRole role;
  final VoidCallback onSwitch;

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _form = GlobalKey<FormState>();
  bool _accepted = false;
  bool _consentError = false;
  final _id = TextEditingController();
  final _pwd = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _id.dispose();
    _pwd.dispose();
    super.dispose();
  }

  String? _error;

  Future<void> _submit() async {
    final ok = _form.currentState!.validate();
    setState(() => _consentError = !_accepted);
    if (!ok || !_accepted) return;
    final id = _id.text.trim();
    if (!id.contains('@')) {
      setState(
        () => _error = 'La connexion par téléphone arrive bientôt : utilisez votre adresse e-mail.'
            .tr,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signInWithPassword(id, _pwd.text);
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Connexion impossible pour le moment. Vérifiez votre connexion puis réessayez.'
              .tr;
        });
      }
      return;
    }
    if (!mounted) return;
    authMascotKey.currentState?.jump();
    if (!mounted) return;
    context.go(Routes.home);
  }

  Future<void> _forgot() async {
    final email = _id.text.trim();
    if (!email.contains('@')) {
      toast(
        context,
        'Saisissez d’abord votre adresse e-mail.'.tr,
        icon: AppIcons.info,
      );
      return;
    }
    try {
      await ref.read(authGatewayProvider).resetPassword(email);
      if (mounted) {
        toast(
          context,
          'Lien de réinitialisation envoyé à {0}'.trf([email]),
          icon: AppIcons.mail,
        );
      }
    } on AuthFailure catch (e) {
      if (mounted) toast(context, e.message, icon: AppIcons.warning);
    }
  }

  /// Visite sans compte : données fictives, rien n'est enregistré.
  void _demo() {
    ref.read(sessionProvider.notifier).signIn(widget.role);
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const GoogleSignIn(),
          AppField(
            floating: true,
            label: widget.role == UserRole.creator
                ? 'E-mail professionnel ou téléphone'.tr
                : 'E-mail ou téléphone'.tr,
            controller: _id,
            hint: 'nom@exemple.ci',
            keyboard: TextInputType.emailAddress,
            validator: Validators.required,
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Mot de passe'.tr,
            controller: _pwd,
            password: true,
            validator: Validators.required,
            textInputAction: TextInputAction.done,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgot,
              child: Text(
                'Mot de passe oublié ?'.tr,
                style: context.text.labelMedium?.copyWith(
                  color: Confetti.coralDeep,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          LegalConsent(
            value: _accepted,
            error: _consentError,
            onChanged: (v) => setState(() {
              _accepted = v;
              if (v) _consentError = false;
            }),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              key: const ValueKey('auth-error'),
              style: context.text.bodySmall?.copyWith(
                color: Confetti.coralDeep,
              ),
            ),
            const SizedBox(height: 10),
          ],
          PillButton(
            flat: true,
            label: 'Se connecter'.tr,
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              key: const ValueKey('demo-access'),
              onPressed: _demo,
              child: Text(
                'Découvrir la démo sans compte'.tr,
                style: context.text.labelMedium?.copyWith(
                  color: context.eventa.muted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _SwitchLine(
            text: 'Pas encore de compte ?'.tr,
            action: 'Créer un compte'.tr,
            onTap: widget.onSwitch,
          ),
        ],
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: context.text.bodyMedium?.copyWith(color: context.eventa.muted),
        ),
        const SizedBox(width: 6),
        Pressable(
          onTap: onTap,
          child: Text(
            action,
            style: context.text.titleSmall?.copyWith(color: Confetti.coralDeep),
          ),
        ),
      ],
    );
  }
}

// ─── Inscription Organisateur ───────────────────────────────────────────

class _OrganizerSignUp extends ConsumerStatefulWidget {
  const _OrganizerSignUp({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  ConsumerState<_OrganizerSignUp> createState() => _OrganizerSignUpState();
}

class _OrganizerSignUpState extends ConsumerState<_OrganizerSignUp> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _accepted = false;
  bool _consentError = false;
  String? _city = 'Abidjan'.tr;
  Uint8List? _photo;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pwd, _pwd2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _form.currentState!.validate();
    setState(() => _consentError = !_accepted);
    if (!ok || !_accepted) return;
    setState(() => _busy = true);
    await createAccount(
      context,
      ref,
      UserProfile(
        role: UserRole.organizer,
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: '+225 ${_phone.text.trim()}',
        city: _city ?? 'Abidjan'.tr,
        photoBytes: _photo,
      ),
      _pwd.text,
      onConfirm: widget.onSwitch,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
          const GoogleSignIn(),
          Center(
            child: PhotoPicker(
              bytes: _photo,
              initials: _name.text.isEmpty ? '' : _name.text[0].toUpperCase(),
              onPicked: (b) => setState(() => _photo = b),
            ),
          ),
          const SizedBox(height: 20),
          AppField(
            floating: true,
            label: 'Nom et prénom'.tr,
            controller: _name,
            hint: 'Awa Traoré'.tr,
            validator: Validators.required,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Adresse e-mail'.tr,
            controller: _email,
            hint: 'awa@exemple.ci',
            keyboard: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Téléphone'.tr,
            controller: _phone,
            hint: '07 08 12 34 56',
            keyboard: TextInputType.phone,
            prefix: const PhonePrefix(),
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              LengthLimitingTextInputFormatter(14),
            ],
            validator: Validators.phone,
          ),
          const SizedBox(height: 14),
          AppSelect<String>(
            label: 'Ville de résidence'.tr,
            value: _city,
            options: ivoryCities,
            labelOf: (c) => c,
            onChanged: (c) => setState(() => _city = c),
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Mot de passe'.tr,
            controller: _pwd,
            password: true,
            hint: '8 caractères minimum'.tr,
            validator: Validators.password,
          ),
          PasswordStrength(controller: _pwd),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Confirmation du mot de passe'.tr,
            controller: _pwd2,
            password: true,
            textInputAction: TextInputAction.done,
            validator: (v) => v == _pwd.text
                ? null
                : 'Les mots de passe ne correspondent pas'.tr,
          ),
          const SizedBox(height: 16),
          LegalConsent(
            value: _accepted,
            error: _consentError,
            onChanged: (v) => setState(() {
              _accepted = v;
              if (v) _consentError = false;
            }),
          ),
          const SizedBox(height: 16),
          PillButton(
            flat: true,
            label: 'Créer mon compte'.tr,
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 22),
          _SwitchLine(
            text: 'Déjà inscrit ?'.tr,
            action: 'Se connecter'.tr,
            onTap: widget.onSwitch,
          ),
        ],
      ),
    );
  }
}

/// Photo de profil : import, recadrage, aperçu.
class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    super.key,
    required this.bytes,
    required this.onPicked,
    this.asset,
    this.initials = '',
    this.size = 92,
  });

  final Uint8List? bytes;
  final String? asset;
  final String initials;
  final ValueChanged<Uint8List> onPicked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Choisir une photo de profil'.tr,
      onTap: () async {
        final b = await pickAndCropPhoto(context);
        if (b != null) onPicked(b);
      },
      child: Column(
        children: [
          SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (bytes == null && asset == null)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Confetti.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Confetti.line, width: 1.5),
                    ),
                    child: initials.isEmpty
                        ? Icon(
                            AppIcons.user,
                            size: size * 0.36,
                            color: Confetti.inkFaint,
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: context.text.headlineMedium?.copyWith(
                                color: Confetti.violetText,
                              ),
                            ),
                          ),
                  )
                else
                  Avatar(bytes: bytes, image: asset, size: size),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Confetti.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Confetti.cream, width: 2.5),
                    ),
                    child: const Icon(
                      AppIcons.camera,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bytes == null && asset == null
                ? 'Ajouter une photo'.tr
                : 'Modifier la photo'.tr,
            style: context.text.labelMedium?.copyWith(
              color: Confetti.coralDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inscription Creator ────────────────────────────────────────────────

class _CreatorSignUp extends ConsumerStatefulWidget {
  const _CreatorSignUp({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  ConsumerState<_CreatorSignUp> createState() => _CreatorSignUpState();
}

class _CreatorSignUpState extends ConsumerState<_CreatorSignUp> {
  final _forms = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  int _step = 0;
  bool _accepted = false;
  bool _consentError = false;
  bool _busy = false;

  // Informations professionnelles
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pwd = TextEditingController();
  CreatorKind _kind = CreatorKind.freelancer;

  // Activité
  final _business = TextEditingController();
  VendorCategory? _category;
  String? _zone = 'Abidjan'.tr;
  final _rccm = TextEditingController();
  final _desc = TextEditingController();

  // Profil public
  final _display = TextEditingController();
  final _price = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _portfolio = TextEditingController();

  static const _titles = [
    'Informations professionnelles',
    'Activité',
    'Profil public',
  ];

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _pwd,
      _business,
      _rccm,
      _desc,
      _display,
      _price,
      _address,
      _website,
      _portfolio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!_forms[_step].currentState!.validate()) return;
    if (_step == 1 && _category == null) {
      toast(
        context,
        'Choisissez une catégorie commerciale'.tr,
        icon: AppIcons.info,
      );
      return;
    }
    if (_step == 1 && _display.text.isEmpty) _display.text = _business.text;
    if (_step < 2) {
      setState(() => _step++);
    } else if (!_accepted) {
      setState(() => _consentError = true);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    await createAccount(
      context,
      ref,
      UserProfile(
        role: UserRole.creator,
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: '+225 ${_phone.text.trim()}',
        city: _zone ?? 'Abidjan'.tr,
        creator: CreatorInfo(
          kind: _kind,
          businessName: _business.text.trim(),
          category: _category!,
          zone: _zone ?? 'Abidjan'.tr,
          rccm: opt(_rccm),
          description: _desc.text.trim(),
          displayName: _display.text.trim(),
          priceFrom: int.tryParse(_price.text) ?? 0,
          address: _address.text.trim(),
          website: opt(_website),
          portfolio: opt(_portfolio),
        ),
      ),
      _pwd.text,
      onConfirm: widget.onSwitch,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: Motion.base,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? Confetti.ink : Confetti.lavender,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Étape {0}/3'.trf([_step + 1]),
                    style: context.text.labelSmall?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _titles[_step].tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.base,
            switchInCurve: Motion.easeOut,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(a),
                child: c,
              ),
            ),
            child: Form(
              key: _forms[_step],
              child: ListView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  ...switch (_step) {
                    0 => _proInfo(context),
                    1 => _activity(context),
                    _ => _publicProfile(context),
                  },
                  if (_step == 2) ...[
                    const SizedBox(height: 16),
                    LegalConsent(
                      value: _accepted,
                      error: _consentError,
                      onChanged: (v) => setState(() {
                        _accepted = v;
                        if (v) _consentError = false;
                      }),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: PillButton(
                            flat: true,
                            label: 'Retour'.tr,
                            tone: ButtonTone.ghost,
                            onPressed: () => setState(() => _step--),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: PillButton(
                          flat: true,
                          label: _step < 2
                              ? 'Continuer'.tr
                              : 'Créer mon espace Creator'.tr,
                          loading: _busy,
                          onPressed: _next,
                        ),
                      ),
                    ],
                  ),
                  if (_step == 0) ...[
                    const SizedBox(height: 20),
                    _SwitchLine(
                      text: 'Déjà inscrit ?'.tr,
                      action: 'Se connecter'.tr,
                      onTap: widget.onSwitch,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _proInfo(BuildContext context) => [
    FieldLabel('Type de compte'.tr),
    Row(
      children: [
        for (final k in CreatorKind.values) ...[
          if (k != CreatorKind.values.first) const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              onTap: () => setState(() => _kind = k),
              child: AnimatedContainer(
                duration: Motion.fast,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Confetti.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kind == k ? Confetti.ink : Confetti.line,
                    width: _kind == k ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      k == CreatorKind.freelancer
                          ? AppIcons.user
                          : AppIcons.buildings,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(k.label, style: context.text.labelMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Nom et prénom'.tr,
      controller: _name,
      validator: Validators.required,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Adresse e-mail professionnelle'.tr,
      controller: _email,
      keyboard: TextInputType.emailAddress,
      hint: 'contact@monentreprise.ci',
      validator: Validators.email,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Numéro de téléphone'.tr,
      controller: _phone,
      keyboard: TextInputType.phone,
      prefix: const PhonePrefix(),
      hint: '07 08 12 34 56',
      formatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
        LengthLimitingTextInputFormatter(14),
      ],
      validator: Validators.phone,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Mot de passe'.tr,
      controller: _pwd,
      password: true,
      hint: '8 caractères minimum'.tr,
      validator: Validators.password,
    ),
    PasswordStrength(controller: _pwd),
  ];

  List<Widget> _activity(BuildContext context) => [
    AppField(
      floating: true,
      label: _kind == CreatorKind.agency
          ? 'Nom de l’agence'.tr
          : 'Nom commercial'.tr,
      controller: _business,
      validator: Validators.required,
    ),
    const SizedBox(height: 14),
    AppSelect<VendorCategory>(
      label: 'Catégorie commerciale'.tr,
      value: _category,
      options: VendorCategory.values,
      labelOf: (c) => c.label,
      iconOf: (c) => c.icon,
      onChanged: (c) => setState(() => _category = c),
    ),
    const SizedBox(height: 14),
    AppSelect<String>(
      label: 'Ville / zone d’intervention'.tr,
      value: _zone,
      options: [
        'Abidjan'.tr,
        'Abidjan et périphérie'.tr,
        'Grand-Bassam & Assinie'.tr,
        'Yamoussoukro'.tr,
        'Bouaké'.tr,
        'San-Pédro'.tr,
        'Toute la Côte d’Ivoire'.tr,
      ],
      labelOf: (c) => c,
      onChanged: (c) => setState(() => _zone = c),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Numéro RCCM'.tr,
      controller: _rccm,
      optional: true,
      hint: 'CI-ABJ-2024-B-12345'.tr,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Description de votre activité'.tr,
      controller: _desc,
      maxLines: 4,
      hint: 'Vos prestations, votre style, votre expérience…'.tr,
      validator: Validators.required,
    ),
  ];

  List<Widget> _publicProfile(BuildContext context) => [
    AppField(
      floating: true,
      label: 'Nom affiché sur la plateforme'.tr,
      controller: _display,
      validator: Validators.required,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Tarif de départ'.tr,
      controller: _price,
      keyboard: TextInputType.number,
      suffixText: 'FCFA'.tr,
      formatters: [FilteringTextInputFormatter.digitsOnly],
      validator: Validators.required,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Adresse professionnelle'.tr,
      controller: _address,
      hint: 'Rue, quartier, commune'.tr,
      validator: Validators.required,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Site web'.tr,
      controller: _website,
      optional: true,
      hint: 'monentreprise.ci',
      keyboard: TextInputType.url,
      prefix: const Icon(AppIcons.globe, size: 18),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Portfolio ou réseau social'.tr,
      controller: _portfolio,
      optional: true,
      hint: 'instagram.com/…'.tr,
      keyboard: TextInputType.url,
      prefix: const Icon(AppIcons.link, size: 18),
    ),
    const SizedBox(height: 18),
    FieldLabel('Aperçu dans Explorer'.tr),
    Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(
            icon: _category?.icon ?? AppIcons.vendors,
            hue: Hue.mango,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _display.text.isEmpty ? 'Votre nom'.tr : _display.text,
                  style: context.text.titleMedium,
                ),
                Text(
                  _category?.label ?? 'Catégorie'.tr,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _price.text.isEmpty
                ? '—'
                : 'dès {0}'.trf([fcfaCompact(int.tryParse(_price.text) ?? 0)]),
            style: context.text.titleSmall,
          ),
        ],
      ),
    ),
  ];
}

// ─── Mascotte de connexion ──────────────────────────────────────────────

/// Clé de la mascotte de connexion, pour la faire sauter de joie.
final authMascotKey = GlobalKey<MascotState>();

/// La mascotte salue à l'arrivée et ferme les yeux pendant la saisie d'un
/// mot de passe masqué (elle les rouvre si on l'affiche).
class AuthMascot extends ConsumerStatefulWidget {
  const AuthMascot({
    super.key,
    this.color = MascotColor.organizer,
    this.size = 104,
  });

  final MascotColor color;
  final double size;

  @override
  ConsumerState<AuthMascot> createState() => _AuthMascotState();
}

class _AuthMascotState extends ConsumerState<AuthMascot> {
  TextEditingController? _watched;
  Offset? _look;
  bool _cover = false;
  bool _waving = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _waving = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    FocusManager.instance.removeListener(_onFocus);
    _watched?.removeListener(_onText);
    super.dispose();
  }

  EditableText? get _field => FocusManager.instance.primaryFocus?.context
      ?.findAncestorWidgetOfExactType<EditableText>();

  void _onFocus() {
    final field = _field;
    if (field?.controller != _watched) {
      _watched?.removeListener(_onText);
      _watched = field?.controller?..addListener(_onText);
    }
    _onText();
  }

  void _onText() {
    if (!mounted) return;
    final field = _field;
    setState(() {
      if (field == null) {
        _look = null;
        _cover = false;
        return;
      }
      // Le regard glisse le long du texte saisi, vers le formulaire.
      final n = field.controller.text.length.clamp(0, 28);
      _look = Offset(-0.8 + n / 28 * 1.6, 0.9);
      _cover = field.obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Mascot(
      key: authMascotKey,
      size: widget.size,
      color: widget.color,
      // Yeux grands ouverts au repos : ils se ferment pour le mot de passe.
      mood: MascotMood.wink,
      look: _look,
      cover: _cover,
      waving: _waving,
      onTap: () => ref.read(soundProvider).play(Sfx.success),
    );
  }
}

/// Consentement obligatoire, en une ligne sobre : case à cocher animée,
/// liens vers les deux documents.
class LegalConsent extends StatelessWidget {
  const LegalConsent({
    super.key,
    required this.value,
    required this.onChanged,
    this.error = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final link = context.text.bodySmall?.copyWith(
      color: Confetti.ink,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: Confetti.border,
    );
    final border = error ? Confetti.danger : Confetti.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              checked: value,
              label: 'J’accepte les conditions'.tr,
              child: Pressable(
                scale: 0.88,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(!value);
                },
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.easeOut,
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: value ? Confetti.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: value ? Confetti.ink : border,
                      width: 1.6,
                    ),
                  ),
                  child: AnimatedScale(
                    duration: Motion.fast,
                    curve: Curves.easeOutBack,
                    scale: value ? 1 : 0,
                    child: Icon(
                      AppIcons.check,
                      size: 14,
                      color: Confetti.onInk,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'En continuant, vous acceptez nos '.tr),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Pressable(
                        onTap: () => context.push(Routes.terms),
                        child: Text('Conditions d’utilisation'.tr, style: link),
                      ),
                    ),
                    TextSpan(text: ' et notre '.tr),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Pressable(
                        onTap: () => context.push(Routes.privacy),
                        child: Text(
                          'Politique de confidentialité'.tr,
                          style: link,
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: context.text.bodySmall?.copyWith(
                  color: Confetti.inkMuted,
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: Motion.fast,
          child: error
              ? Padding(
                  padding: const EdgeInsets.only(left: 32, top: 6),
                  child: Text(
                    'Cochez la case pour continuer.'.tr,
                    style: TextStyle(color: Confetti.danger, fontSize: 12),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

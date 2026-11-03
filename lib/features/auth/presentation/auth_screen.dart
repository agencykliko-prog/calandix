import 'dart:async';
import 'dart:math' as math;

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
    final size = MediaQuery.sizeOf(context);
    // Desktop : le formulaire devient une carte centrée sur fond crème.
    final desktop = size.width >= 900 && size.height >= 640;
    final content = Column(
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
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.onboarding),
                  ),
                ),
                const Entrance(child: CalandixWordmark(size: 25)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
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
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
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
                    ),
                  ),
                  AuthMascot(
                    color: creator
                        ? MascotColor.creator
                        : MascotColor.organizer,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Entrance(
                index: 3,
                child: RolePicker(
                  value: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
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
                  ? _OrganizerSignUp(
                      onSwitch: () => setState(() => _signUp = false),
                    )
                  : _CreatorSignUp(
                      onSwitch: () => setState(() => _signUp = false),
                    ),
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      // Fond blanc épuré (le mode sombre garde son fond).
      backgroundColor: Confetti.dark || desktop ? Confetti.cream : Colors.white,
      body: SafeArea(
        child: Center(
          child: desktop
              ? Container(
                  width: 480,
                  height: math.min(size.height - 48, _signUp ? 880.0 : 640.0),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Confetti.dark ? Confetti.surface : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Confetti.line),
                    boxShadow: [
                      BoxShadow(
                        color: Confetti.ink.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: content,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: content,
                ),
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
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

/// La mascotte suit la saisie du regard, se cache les yeux pendant la
/// saisie d'un mot de passe masqué, et salue à l'arrivée.
class AuthMascot extends ConsumerStatefulWidget {
  const AuthMascot({super.key, this.color = MascotColor.organizer});

  final MascotColor color;

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
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Mascot(
        key: authMascotKey,
        size: 104,
        color: widget.color,
        look: _look,
        cover: _cover,
        waving: _waving,
        onTap: () => ref.read(soundProvider).play(Sfx.success),
      ),
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

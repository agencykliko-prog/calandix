import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/backend/backend.dart';
import '../../ui/theme/app_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/eventa_colors.dart';
import '../../ui/widgets/avatars.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/forms.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/ui.dart';
import '../data/admin_demo.dart';
import '../domain/admin_models.dart';
import 'admin_providers.dart';
import 'admin_shell.dart';

/// Connexion réservée à l'équipe qui exploite la plateforme, avec code
/// à usage unique (double authentification simulée).
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  AdminMember _member = AdminDemo.team.first;
  // Code de démo prérempli : un seul geste pour entrer.
  final _code = TextEditingController(text: '123456');
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Avec le backend, l'accès demande un vrai compte listé dans admin_members ;
  /// le choix d'un membre et le code de démonstration ne restent que hors ligne.
  bool get _real => Backend.ready;

  @override
  void dispose() {
    _code.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_real) return _submitReal();
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Saisissez les 6 chiffres du code reçu');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    if (!mounted) return;
    ref.read(adminSessionProvider.notifier).signIn(_member);
    ref
        .read(adminProvider.notifier)
        .note('Connexion au centre de contrôle', 'Code à usage unique validé');
    final perms = ref.read(adminProvider).permissions[_member.role] ?? const {};
    context.go(adminPath(AdminModule.homeFor(perms)));
  }

  Future<void> _submitReal() async {
    final email = _email.text.trim();
    if (!email.contains('@') || _password.text.isEmpty) {
      setState(() => _error = 'Saisissez votre e-mail et votre mot de passe');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? problem;
    try {
      final auth = Backend.client.auth;
      await auth.signInWithPassword(email: email, password: _password.text);
      final allowed = await Backend.client.rpc('is_admin');
      if (allowed != true) {
        await auth.signOut();
        problem = 'Ce compte n’a pas accès au centre de contrôle.';
      }
    } catch (_) {
      problem = 'Identifiants incorrects ou connexion impossible.';
    }
    if (!mounted) return;
    _password.clear();
    setState(() {
      _busy = false;
      _error = problem;
    });
    if (problem != null) return;
    ref.read(adminSessionProvider.notifier).signIn(AdminDemo.team.first);
    ref
        .read(adminProvider.notifier)
        .note('Connexion au centre de contrôle', email);
    final perms =
        ref.read(adminProvider).permissions[AdminDemo.team.first.role] ??
        const {};
    context.go(adminPath(AdminModule.homeFor(perms)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Confetti.dark ? const Color(0xFF2B1A5C) : const Color(0xFFE4DEFF),
              Confetti.cream,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Panel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const CalandixWordmark(size: 26),
                          const SizedBox(width: 8),
                          Tag(label: 'Admin', hue: Hue.ink, solid: true),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Centre de contrôle',
                        style: context.text.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Espace réservé à l’équipe qui exploite la plateforme : supervision de l’activité, des revenus, des comptes et des risques.',
                        style: context.text.bodyMedium?.copyWith(
                          color: Confetti.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_real) ...[
                        AppField(
                          label: 'E-mail',
                          controller: _email,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        AppField(
                          label: 'Mot de passe',
                          controller: _password,
                          password: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                      ] else ...[
                        const FieldLabel('Compte de l’équipe (démo)'),
                        for (final m in AdminDemo.team)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Pressable(
                              onTap: () => setState(() => _member = m),
                              child: AnimatedContainer(
                                duration: Motion.fast,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: m == _member
                                      ? Confetti.lavender
                                      : Confetti.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: m == _member
                                        ? Confetti.ink
                                        : Confetti.line,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Avatar(
                                      initials: m.name
                                          .split(' ')
                                          .map((p) => p[0])
                                          .join(),
                                      size: 34,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.name,
                                            style: context.text.titleSmall,
                                          ),
                                          Text(
                                            '${m.role.label} · ${m.role.scope}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context.text.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (m == _member)
                                      Icon(
                                        AppIcons.checkCircle,
                                        size: 18,
                                        color: Confetti.lagoon,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        AppField(
                          label: 'Code de vérification (6 chiffres)',
                          controller: _code,
                          hint: '123456',
                          keyboard: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          textInputAction: TextInputAction.done,
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _error!,
                          style: context.text.bodySmall?.copyWith(
                            color: Confetti.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      PillButton(
                        label: 'Accéder au centre de contrôle',
                        icon: AppIcons.shield,
                        tone: ButtonTone.dark,
                        loading: _busy,
                        onPressed: _submit,
                      ),
                      if (!_real) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Démonstration : choisissez un membre et saisissez n’importe quel code à 6 chiffres. Chaque connexion est inscrite au journal d’audit.',
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

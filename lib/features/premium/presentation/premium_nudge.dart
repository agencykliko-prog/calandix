import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../platform/mobile/prefs_store_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/prefs_store_web.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/auth/session_provider.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';

/// Suggestions Premium proposées à des moments choisis du parcours.
/// Chacune n'apparaît qu'une fois, jamais à moins de 90 s d'une autre,
/// et seulement aux Organisateurs qui n'ont pas encore l'offre.
enum PremiumNudge {
  /// Juste après la création d'un événement.
  newEvent(Plan.azur),

  /// Après une réservation confirmée : contrat et reçus à ranger.
  booking(Plan.signature),

  /// Le budget est consulté souvent : graphiques et export.
  budget(Plan.azur),

  /// Relance des invités : rappels et QR code RSVP.
  guests(Plan.azur);

  const PremiumNudge(this.plan);
  final Plan plan;

  String get title => switch (this) {
    newEvent => 'Votre plan est prêt. Et si l’IA s’occupait du reste ?'.tr,
    booking => 'Date bloquée ! Rangez contrat et reçus à l’abri.'.tr,
    budget => 'Votre budget, en graphiques.'.tr,
    guests => 'Un QR code pour répondre en un geste.'.tr,
  };

  String get pitch => switch (this) {
    newEvent =>
      'Graphiques et export, rappels WhatsApp et SMS, et jusqu’à 5 collaborateurs.'
          .tr,
    booking =>
      'Le coffre-fort chiffré garde vos contrats, devis et reçus, et l’agent IA négocie vos prochains devis.'
          .tr,
    budget =>
      'Suivez chaque poste en graphiques et exportez votre budget pour le partager.'
          .tr,
    guests =>
      'Vos invités scannent le QR code RSVP et répondent ; les rappels WhatsApp et SMS complètent.'
          .tr,
  };

  /// Services inclus sans frais supplémentaires dans l'offre suggérée.
  List<(IconData, String)> get perks => switch (plan) {
    Plan.signature => [
      (AppIcons.lock, 'Coffre-fort chiffré 10 Go'.tr),
      (AppIcons.sparkle, 'Agent IA dédié'.tr),
      (AppIcons.handshake, 'Négociation de devis'.tr),
      (AppIcons.team, 'Collaborateurs illimités'.tr),
    ],
    _ => [
      (AppIcons.lock, 'Coffre-fort 5 Go'.tr),
      (AppIcons.whatsapp, 'Rappels WhatsApp et SMS'.tr),
      (AppIcons.qr, 'QR code RSVP'.tr),
      (AppIcons.chart, 'Graphiques et export'.tr),
    ],
  };
}

DateTime? _lastShown;

/// Propose [nudge] si le moment s'y prête ; ne fait rien sinon.
Future<void> maybeShowPremiumNudge(
  BuildContext context,
  WidgetRef ref,
  PremiumNudge nudge, {
  Duration delay = const Duration(milliseconds: 1200),
}) async {
  final profile = ref.read(sessionProvider);
  if (profile == null || profile.isCreator) return;
  if (ref.read(planProvider).includes(nudge.plan)) return;
  final key = 'nudge.${nudge.name}';
  if (readPref(key) == '1') return;
  final now = DateTime.now();
  if (_lastShown != null &&
      now.difference(_lastShown!) < const Duration(seconds: 90)) {
    return;
  }
  _lastShown = now;
  writePref(key, '1');
  await Future<void>.delayed(delay);
  if (!context.mounted) return;
  await showEventaSheet<void>(
    context,
    builder: (_) => _NudgeSheet(nudge: nudge),
  );
}

class _NudgeSheet extends ConsumerWidget {
  const _NudgeSheet({required this.nudge});

  final PremiumNudge nudge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = nudge.plan;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visuel : mascotte dorée couronnée, confettis qui scintillent.
          Container(
            height: 176,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A1653), Color(0xFF4B2A86)],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: _Sparkles()),
                Positioned(
                  bottom: -6,
                  child: Column(
                    children: [
                      Icon(AppIcons.crown, color: Confetti.gold, size: 28),
                      const Mascot(
                        size: 132,
                        color: MascotColor.organizer,
                        mood: MascotMood.cheer,
                        waving: true,
                        legs: false,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: PremiumBadge(label: plan.label, onDark: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(nudge.title, style: context.text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            nudge.pitch,
            style: context.text.bodyMedium?.copyWith(color: Confetti.inkMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'Inclus sans frais supplémentaires'.tr.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              letterSpacing: 1,
              color: Hue.gold.text,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              for (final (icon, label) in nudge.perks)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Confetti.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Confetti.line),
                  ),
                  child: Row(
                    children: [
                      IconTile(icon: icon, hue: Hue.gold, size: 32),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'Essayer {0} · {1}/mois'.trf([plan.label, fcfa(plan.price)]),
            icon: AppIcons.crown,
            tone: ButtonTone.gold,
            onPressed: () async {
              final r = await showPaymentSheet(
                context,
                title: 'Abonnement {0}'.trf([plan.label]),
                payee: 'Calandix',
                options: [PayOption('Mensuel'.tr, plan.price)],
                onPay: (amount, method) {
                  ref.read(planProvider.notifier).subscribe(plan);
                  return Receipt(
                    ref: receiptRef(),
                    label: 'Abonnement {0}'.trf([plan.label]),
                    amount: amount,
                    method: method,
                    date: DateTime.now(),
                    payee: 'Calandix',
                  );
                },
              );
              if (r != null && context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Plus tard'.tr,
                  style: context.text.labelLarge?.copyWith(
                    color: Confetti.inkMuted,
                  ),
                ),
              ),
              Text('·', style: TextStyle(color: Confetti.inkFaint)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(Routes.premium);
                },
                child: Text(
                  'Comparer les offres'.tr,
                  style: context.text.labelLarge?.copyWith(
                    color: Confetti.coralDeep,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Sans engagement, résiliable à tout moment.'.tr,
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Petites étincelles dorées qui scintillent en décalé.
class _Sparkles extends StatefulWidget {
  const _Sparkles();

  @override
  State<_Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<_Sparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(painter: _SparklePainter(_c.value)),
    ),
  );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);

  final double t;

  static const _spots = [
    (0.12, 0.25, 0.0),
    (0.82, 0.18, 0.3),
    (0.22, 0.7, 0.55),
    (0.9, 0.62, 0.8),
    (0.68, 0.35, 0.15),
    (0.35, 0.12, 0.7),
    (0.06, 0.52, 0.42),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, phase) in _spots) {
      final k = math.sin(((t + phase) % 1) * math.pi);
      final c = Offset(x * size.width, y * size.height);
      final r = 2 + k * 5;
      final p = Paint()
        ..color = const Color(0xFFF6DB98).withValues(alpha: 0.25 + k * 0.7);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 1.6)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 1.6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 1.6),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

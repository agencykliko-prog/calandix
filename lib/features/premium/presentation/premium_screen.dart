import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';

/// Abonnements Organisateur : Azur, Signature, Privilège.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  Receipt _receipt(String label, int amount, PayMethod m) => Receipt(
    ref: receiptRef(),
    label: label,
    amount: amount,
    method: m,
    date: DateTime.now(),
    payee: 'Calandix'.tr,
  );

  Future<void> _subscribe(Plan p) async {
    final r = await showPaymentSheet(
      context,
      title: 'Abonnement {0}'.trf([p.label]),
      payee: 'Calandix'.tr,
      options: [
        PayOption('Mensuel'.tr, p.price),
        PayOption('Annuel · 1 mois offert'.tr, p.yearlyPrice),
      ],
      onPay: (amount, m) {
        ref.read(planProvider.notifier).subscribe(p);
        return _receipt('Abonnement {0}'.trf([p.label]), amount, m);
      },
    );
    if (r != null && mounted) {
      toast(context, 'Bienvenue dans {0}'.trf([p.label]));
    }
  }

  void _trial(Plan p) {
    ref.read(planProvider.notifier).startTrial(p);
    toast(
      context,
      'Essai {0} activé : {1} jours offerts'.trf([p.label, trialDays]),
      icon: AppIcons.sparkle,
    );
  }

  /// Pass Événement : choix de l'événement, puis paiement unique.
  Future<void> _pass() async {
    final events = ref.read(eventsProvider).value ?? const <Event>[];
    final e = await showEventaSheet<Event>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text('Pour quel événement ?'.tr, style: ctx.text.headlineSmall),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text('Créez d’abord un événement.'.tr, style: ctx.text.bodyMedium),
          for (final x in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(x.name),
              subtitle: Text(mediumDate(x.date)),
              trailing: Icon(AppIcons.forward, size: 18),
              onTap: () => Navigator.of(ctx).pop(x),
            ),
        ],
      ),
    );
    if (e == null || !mounted) return;
    final r = await showPaymentSheet(
      context,
      title: 'Pass Événement'.tr,
      payee: 'Calandix'.tr,
      options: [PayOption('Paiement unique · 90 jours'.tr, eventPassPrice)],
      onPay: (amount, m) {
        ref.read(eventPassProvider.notifier).activate(e.id);
        return _receipt('Pass Événement'.tr, amount, m);
      },
    );
    if (r != null && mounted) {
      toast(
        context,
        'Pass actif pour « {0} » pendant {1} jours'.trf([
          e.name,
          eventPassDays,
        ]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Page nuit : encre en clair, fond profond en mode sombre.
      backgroundColor: Confetti.dark ? Confetti.cream : Confetti.ink,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: AppIcons.close,
                      background: Confetti.night,
                      foreground: Colors.white,
                      tooltip: 'Fermer',
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    PremiumBadge(label: 'Calandix Premium'.tr, onDark: true),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organisez comme\nun professionnel.'.tr,
                      style: context.text.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sans engagement. Privilège s’essaie {0} jours gratuitement ; à l’année, 1 mois offert.'
                          .trf([trialDays]),
                      style: context.text.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              sliver: SliverToBoxAdapter(child: _plans()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverToBoxAdapter(child: _PassCard(onTap: _pass)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _plans() {
    final current = ref.watch(planProvider);
    final trialEnds = ref.watch(trialEndsProvider);
    final canTry = !ref.watch(trialUsedProvider);
    return Column(
      key: const ValueKey('plans'),
      children: [
        if (trialEnds != null && current != Plan.free)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              color: Confetti.night,
              child: Text(
                'Essai {0} jusqu’au {1}, puis {2}/mois.'.trf([
                  current.label,
                  mediumDate(trialEnds),
                  fcfa(current.price),
                ]),
                style: context.text.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        for (final (i, p) in [
          Plan.azur,
          Plan.signature,
          Plan.privilege,
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Entrance(
              index: i,
              child: _PlanCard(
                plan: p,
                current: current == p,
                highlight: p == Plan.signature,
                trial: canTry && p.hasTrial,
                onTap: current == p ? null : () => _subscribe(p),
                onTrial: () => _trial(p),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.highlight,
    required this.onTap,
    required this.onTrial,
    this.trial = false,
  });

  final Plan plan;
  final bool current;
  final bool highlight;
  final VoidCallback? onTap;
  final VoidCallback onTrial;

  /// L'essai gratuit est encore disponible.
  final bool trial;

  @override
  Widget build(BuildContext context) {
    final features = Catalog.planFeatures[plan]!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? Colors.white : Confetti.night,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight ? Colors.white : Confetti.nightLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: plan.hue.base,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                plan.label.toUpperCase(),
                style: context.text.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  color: highlight ? Confetti.inkFixed : Colors.white,
                ),
              ),
              const Spacer(),
              if (highlight && !current)
                Tag(label: 'Formule phare'.tr, hue: Hue.coral, solid: true),
              if (current)
                Tag(label: 'Votre offre'.tr, hue: Hue.lagoon, solid: true),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              text: fcfa(plan.price).replaceAll(RegExp(r'\s*FCFA$'), ''),
              style: context.text.headlineMedium?.copyWith(
                color: highlight ? Confetti.inkFixed : Colors.white,
              ),
              children: [
                TextSpan(
                  text: '  FCFA / mois'.tr,
                  style: context.text.bodySmall?.copyWith(
                    color: highlight ? const Color(0xFF645A7C) : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ou {0} par an, 1 mois offert'.trf([fcfa(plan.yearlyPrice)]),
            style: context.text.bodySmall?.copyWith(
              color: highlight ? const Color(0xFF645A7C) : Colors.white60,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.pitch,
            style: context.text.bodySmall?.copyWith(
              color: highlight
                  ? Confetti.inkFixed
                  : Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 14),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    AppIcons.check,
                    size: 16,
                    color: highlight ? Confetti.coral : Confetti.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.tr,
                      style: context.text.bodyMedium?.copyWith(
                        color: highlight
                            ? Confetti.inkFixed
                            : Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (trial && !current) ...[
            PillButton(
              label: 'Essayer {0} jours gratuitement'.trf([trialDays]),
              tone: highlight ? ButtonTone.primary : ButtonTone.gold,
              height: 48,
              onPressed: onTrial,
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: onTap,
                child: Text(
                  'S’abonner directement'.tr,
                  style: context.text.labelMedium?.copyWith(
                    color: highlight ? Confetti.inkFixed : Colors.white70,
                  ),
                ),
              ),
            ),
          ] else
            PillButton(
              label: current
                  ? 'Offre active'.tr
                  : 'Choisir {0}'.trf([plan.label]),
              tone: highlight ? ButtonTone.primary : ButtonTone.light,
              height: 48,
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}

/// Pass Événement : Signature pendant 90 jours, pour un seul événement.
/// Prix, durée et portée se lisent d'un coup d'œil ; les quatre atouts
/// principaux sont visibles, le reste du contenu se déroule à la demande.
class _PassCard extends StatefulWidget {
  const _PassCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PassCard> createState() => _PassCardState();
}

class _PassCardState extends State<_PassCard> {
  bool _open = false;

  /// Atouts mis en avant (tirés du contenu du Pass).
  static const _highlights = <(IconData, String, String)>[
    (AppIcons.guests, 'Jusqu’à 750 invités', 'invités'),
    (AppIcons.team, 'Jusqu’à 15 collaborateurs', 'collaborateurs'),
    (AppIcons.sparkle, 'Agent IA dédié', 'Agent IA'),
    (AppIcons.lock, 'Coffre-fort 10 Go', 'Coffre-fort'),
  ];

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.72);
    // Même durée en abonnement Signature, pour comparer.
    final months = (eventPassDays / 30).round();
    final viaPlan = eventPassPlan.price * months;
    final rest = Catalog.passFeatures
        .where((f) => !_highlights.any((h) => f.contains(h.$3)))
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: Confetti.night,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Confetti.gold.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : nom, prix, portée.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.ticket, color: Confetti.gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PASS ÉVÉNEMENT'.tr,
                        style: context.text.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Confetti.gold,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Sans abonnement'.tr,
                        style: context.text.labelSmall?.copyWith(
                          color: Confetti.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    text: fcfa(eventPassPrice)
                        .replaceAll(RegExp(r'\s*FCFA$'), ''),
                    style: context.text.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: '  FCFA · paiement unique'.tr,
                        style: context.text.bodySmall?.copyWith(color: soft),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toutes les fonctionnalités de Signature, pour un seul événement et pendant 90 jours.'
                      .tr,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Fact(value: '1', label: 'événement'.tr),
                    const SizedBox(width: 8),
                    _Fact(value: '$eventPassDays', label: 'jours'.tr),
                    const SizedBox(width: 8),
                    _Fact(value: eventPassPlan.label, label: 'fonctions'.tr),
                  ],
                ),
              ],
            ),
          ),
          // Atouts principaux, toujours visibles.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            color: Colors.white.withValues(alpha: 0.05),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    for (final (icon, label, _) in _highlights)
                      SizedBox(
                        width: w,
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Confetti.gold.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(icon, size: 16, color: Confetti.gold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label.tr,
                                style: context.text.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          // Le reste du contenu, à la demande.
          Container(
            color: Colors.white.withValues(alpha: 0.05),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _open = !_open),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _open
                                ? 'Masquer le contenu du Pass'.tr
                                : 'Voir tout ce qui est inclus (+{0})'.trf([
                                    rest.length,
                                  ]),
                            style: context.text.labelLarge?.copyWith(
                              color: Confetti.gold,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            AppIcons.chevronDown,
                            size: 18,
                            color: Confetti.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _open
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final f in rest)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          AppIcons.check,
                                          size: 15,
                                          color: Confetti.gold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          f.tr,
                                          style: context.text.bodySmall
                                              ?.copyWith(color: soft),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          // Comparaison et action.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (viaPlan > eventPassPrice)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      '{0} mois de {1} en abonnement : {2}. Avec le Pass : {3}, une seule fois.'
                          .trf([
                            months,
                            eventPassPlan.label,
                            fcfa(viaPlan),
                            fcfa(eventPassPrice),
                          ]),
                      style: context.text.bodySmall?.copyWith(color: soft),
                    ),
                  ),
                PillButton(
                  label: 'Prendre un Pass Événement'.tr,
                  tone: ButtonTone.gold,
                  height: 48,
                  onPressed: widget.onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une donnée clé du Pass : valeur en grand, libellé dessous.
class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

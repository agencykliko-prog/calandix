import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/utils/formatters.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../marketplace/presentation/explore_screen.dart' show Choice;

/// Formules prestataires (pack prestataire) : Découverte gratuite, Starter,
/// Creator et Business. La commission baisse quand la formule monte ;
/// options de visibilité et services à la carte en complément.
class BusinessScreen extends ConsumerStatefulWidget {
  const BusinessScreen({super.key});

  @override
  ConsumerState<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends ConsumerState<BusinessScreen> {
  bool _yearly = false;

  /// Montant encaissé par mois, pour le simulateur.
  int _sales = 500000;

  Future<void> _subscribe(ProPlan plan) async {
    final r = await showPaymentSheet(
      context,
      title: 'Abonnement {0}'.trf([plan.label]),
      payee: 'Calandix'.tr,
      options: [
        PayOption('Mensuel'.tr, plan.price),
        PayOption(
          'Annuel · 2 mois offerts'.tr,
          plan.yearlyPrice,
          caption: '{0} d’économie'.trf([fcfa(plan.yearlySaving)]),
        ),
      ],
      onPay: (amount, m) {
        final receipt = Receipt(
          ref: receiptRef(),
          label: 'Abonnement {0}'.trf([plan.label]),
          amount: amount,
          method: m,
          date: DateTime.now(),
          payee: 'Calandix'.tr,
        );
        ref
            .read(creatorSubProvider.notifier)
            .activate(
              m,
              receipt.ref,
              plan: plan,
              yearly: amount == plan.yearlyPrice,
            );
        return receipt;
      },
    );
    if (r != null && mounted) {
      toast(
        context,
        'Bienvenue dans la formule {0}'.trf([plan.label]),
        icon: AppIcons.crown,
      );
    }
  }

  void _trial(ProPlan plan) {
    ref.read(creatorSubProvider.notifier).startTrial(plan);
    toast(
      context,
      'Essai {0} activé : 14 jours offerts'.trf([plan.label]),
      icon: AppIcons.crown,
    );
  }

  Future<void> _cancel() async {
    final sub = ref.read(creatorSubProvider);
    if (sub == null) return;
    final ok = await showEventaSheet<bool>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Résilier la formule {0} ?'.trf([sub.plan.label]),
              style: ctx.text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos avantages restent actifs jusqu’à la fin de la période payée, puis vous revenez à Découverte. Votre profil et votre catalogue restent en ligne.'
                  .tr,
              style: ctx.text.bodyMedium,
            ),
            const SizedBox(height: 18),
            PillButton(
              label: 'Résilier'.tr,
              tone: ButtonTone.dark,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Garder mon abonnement'.tr,
              tone: ButtonTone.ghost,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      ref.read(creatorSubProvider.notifier).cancel();
      if (mounted) toast(context, 'Résiliation enregistrée'.tr);
    }
  }

  Future<void> _boost(ProBoost b) async {
    final r = await showPaymentSheet(
      context,
      title: b.label,
      payee: 'Calandix'.tr,
      options: [
        PayOption(
          b.days == null
              ? 'Campagne de 14 jours'.tr
              : '{0} jours'.trf([b.days]),
          b.price,
        ),
      ],
      onPay: (amount, m) {
        ref.read(proBoostsProvider.notifier).activate(b);
        return Receipt(
          ref: receiptRef(),
          label: b.label,
          amount: amount,
          method: m,
          date: DateTime.now(),
          payee: 'Calandix'.tr,
        );
      },
    );
    if (r != null && mounted) {
      toast(
        context,
        '{0} activé, signalé « Sponsorisé »'.trf([b.label]),
        icon: AppIcons.rocket,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(creatorSubProvider);
    final current = ref.watch(proPlanProvider);
    final w = MediaQuery.sizeOf(context).width;
    final side = math.max(16.0, (w - 760) / 2);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(side, 8, side, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Hero(
              sub: sub,
              current: current,
              onCancel: _cancel,
              onResume: () => ref.read(creatorSubProvider.notifier).resume(),
            ),
            SectionTitle('Choisir ma formule'.tr),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Choice(
                  label: 'Mensuel'.tr,
                  on: !_yearly,
                  onTap: () => setState(() => _yearly = false),
                ),
                Choice(
                  label: 'Annuel · 2 mois offerts'.tr,
                  on: _yearly,
                  onTap: () => setState(() => _yearly = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final (i, plan) in ProPlan.values.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Entrance(
                  index: i,
                  child: _PlanCard(
                    plan: plan,
                    yearly: _yearly,
                    current: plan == current,
                    canTrial: sub == null,
                    onTrial: () => _trial(plan),
                    onSubscribe: () => _subscribe(plan),
                    onDowngrade: sub == null || sub.cancelled ? null : _cancel,
                  ),
                ),
              ),
            Text(
              'Essai de 14 jours sans carte bancaire, prévenu avant la fin. Rien n’est facturé sans votre accord.'
                  .tr,
              style: context.text.bodySmall?.copyWith(
                color: context.eventa.muted,
              ),
            ),
            SectionTitle('Ce que vous gardez'.tr),
            _Simulator(
              sales: _sales,
              current: current,
              onSales: (v) => setState(() => _sales = v),
            ),
            SectionTitle('Une commission juste'.tr),
            const _Rules(),
            SectionTitle('Booster ma visibilité'.tr),
            Text(
              'Ouvert à toutes les formules, même Découverte : une visibilité ponctuelle, sans abonnement. Toujours signalée « Sponsorisé ».'
                  .tr,
              style: context.text.bodyMedium?.copyWith(
                color: context.eventa.muted,
              ),
            ),
            const SizedBox(height: 12),
            for (final b in ProBoost.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BoostRow(boost: b, onBuy: () => _boost(b)),
              ),
            SectionTitle('Services Calandix'.tr),
            Text(
              'Notre équipe s’en occupe pour vous. Facturés à part.'.tr,
              style: context.text.bodyMedium?.copyWith(
                color: context.eventa.muted,
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (final (i, (label, price, icon))
                      in proServices.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          IconTile(icon: icon, hue: Hue.violet, size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label.tr, style: context.text.titleSmall),
                                Text(
                                  price == null ? 'Sur devis'.tr : fcfa(price),
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => toast(
                              context,
                              'Demande envoyée : un conseiller Calandix vous recontacte.'
                                  .tr,
                              icon: AppIcons.headset,
                            ),
                            child: Text('Demander'.tr),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête : la promesse, puis la formule en cours.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.sub,
    required this.current,
    required this.onCancel,
    required this.onResume,
  });

  final CreatorSubscription? sub;
  final ProPlan current;
  final VoidCallback onCancel;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final sub = this.sub;
    return NightPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tag(label: 'Formules prestataires'.tr, hue: Hue.gold, solid: true),
          const SizedBox(height: 16),
          Text(
            'Gardez plus sur chaque prestation.'.tr,
            style: context.text.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'Commencez gratuitement. Quand votre activité grandit, la commission baisse : de 8 % à 3 %, prélevée seulement sur ce que vous encaissez via Calandix.'
                .tr,
            style: context.text.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          if (sub == null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.info, size: 18, color: Confetti.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Votre formule : {0} · commission {1} %'.trf([
                        current.label,
                        current.commissionPercent,
                      ]),
                      style: context.text.titleSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _ActiveSub(sub: sub, onCancel: onCancel, onResume: onResume),
            if (sub.plan.studio) ...[
              const SizedBox(height: 10),
              PillButton(
                label: 'Ouvrir mon Studio Creator'.tr,
                icon: AppIcons.crown,
                tone: ButtonTone.gold,
                onPressed: () => context.push('/pro/studio'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Une formule : prix, commission, ce qu'elle apporte, et l'action.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.yearly,
    required this.current,
    required this.canTrial,
    required this.onTrial,
    required this.onSubscribe,
    required this.onDowngrade,
  });

  final ProPlan plan;
  final bool yearly;
  final bool current;
  final bool canTrial;
  final VoidCallback onTrial;
  final VoidCallback onSubscribe;
  final VoidCallback? onDowngrade;

  @override
  Widget build(BuildContext context) {
    final hue = plan.hue;
    final recommended = plan == ProPlan.creator;
    final prev = plan.index > 0 ? ProPlan.values[plan.index - 1] : null;
    return AnimatedContainer(
      duration: Motion.base,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Confetti.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: current || recommended ? hue.base : Confetti.line,
          width: current || recommended ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(plan.label, style: context.text.titleLarge),
              if (current)
                Tag(label: 'Votre formule'.tr, hue: hue)
              else if (recommended)
                Tag(label: 'Recommandé'.tr, hue: hue, solid: true),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hue.tint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Commission {0} %'.trf([plan.commissionPercent]),
                  style: context.text.labelMedium?.copyWith(color: hue.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plan.pitch,
            style: context.text.bodySmall?.copyWith(
              color: context.eventa.muted,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: plan.free
                      ? 'Gratuit'.tr
                      : fcfa(yearly ? plan.yearlyPrice : plan.price),
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!plan.free)
                  TextSpan(
                    text: yearly ? ' / an'.tr : ' / mois'.tr,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.eventa.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (!plan.free && yearly)
            Text(
              '{0} d’économie sur l’année'.trf([fcfa(plan.yearlySaving)]),
              style: context.text.labelMedium?.copyWith(
                color: Confetti.success,
              ),
            ),
          const SizedBox(height: 12),
          if (prev != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Tout {0}, plus :'.trf([prev.label]),
                style: context.text.labelMedium,
              ),
            ),
          for (final f in plan.features)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(AppIcons.check, size: 15, color: hue.text),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: context.text.bodyMedium)),
                ],
              ),
            ),
          if (plan.breakEven != null) ...[
            const SizedBox(height: 10),
            Text(
              'Rentable dès {0} encaissés par mois.'.trf([
                fcfaCompact(plan.breakEven!),
              ]),
              style: context.text.bodySmall?.copyWith(
                color: context.eventa.muted,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (current)
            PillButton(
              label: 'Formule actuelle'.tr,
              tone: ButtonTone.ghost,
              height: 46,
              onPressed: null,
            )
          else if (plan.free)
            PillButton(
              label: 'Revenir à Découverte'.tr,
              tone: ButtonTone.ghost,
              height: 46,
              onPressed: onDowngrade,
            )
          else ...[
            if (canTrial) ...[
              PillButton(
                key: ValueKey('trial-${plan.name}'),
                label: 'Essayer 14 jours gratuitement'.tr,
                tone: recommended ? ButtonTone.primary : ButtonTone.dark,
                height: 46,
                onPressed: onTrial,
              ),
              const SizedBox(height: 8),
            ],
            PillButton(
              key: ValueKey('subscribe-${plan.name}'),
              label: canTrial
                  ? 'S’abonner directement'.tr
                  : 'Passer à {0}'.trf([plan.label]),
              tone: canTrial ? ButtonTone.ghost : ButtonTone.dark,
              height: 46,
              onPressed: onSubscribe,
            ),
          ],
        ],
      ),
    );
  }
}

/// Simulateur : ce qui reste au prestataire selon la formule, pour un
/// montant encaissé par mois.
class _Simulator extends StatelessWidget {
  const _Simulator({
    required this.sales,
    required this.current,
    required this.onSales,
  });

  final int sales;
  final ProPlan current;
  final ValueChanged<int> onSales;

  static const _amounts = [250000, 500000, 1000000, 2000000];

  @override
  Widget build(BuildContext context) {
    // Le meilleur net, abonnement déduit.
    int net(ProPlan p) => (sales * (1 - p.commission)).round() - p.price;
    final best = ProPlan.values.reduce((a, b) => net(b) >= net(a) ? b : a);
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous encaissez par mois via Calandix :'.tr,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in _amounts)
                Choice(
                  label: fcfaCompact(a),
                  on: a == sales,
                  onTap: () => onSales(a),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 92,
                child: Text(
                  'Commission'.tr,
                  textAlign: TextAlign.right,
                  style: context.text.labelSmall,
                ),
              ),
              SizedBox(
                width: 108,
                child: Text(
                  'Il vous reste'.tr,
                  textAlign: TextAlign.right,
                  style: context.text.labelSmall,
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          for (final p in ProPlan.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.label,
                            style: context.text.titleSmall?.copyWith(
                              color: p == current ? p.hue.text : null,
                            ),
                          ),
                        ),
                        if (p == best) ...[
                          const SizedBox(width: 6),
                          Icon(AppIcons.star, size: 14, color: Confetti.gold),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 92,
                    child: Text(
                      fcfaCompact((sales * p.commission).round()),
                      textAlign: TextAlign.right,
                      style: context.text.bodySmall,
                    ),
                  ),
                  SizedBox(
                    width: 108,
                    child: Text(
                      fcfaCompact(net(p)),
                      textAlign: TextAlign.right,
                      style: context.text.titleSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Montant restant après commission et abonnement du mois, avant frais du partenaire de paiement. ★ : la formule la plus avantageuse à ce niveau.'
                .tr,
            style: context.text.bodySmall?.copyWith(
              color: context.eventa.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Règles de la commission, en clair.
class _Rules extends StatelessWidget {
  const _Rules();

  @override
  Widget build(BuildContext context) {
    final rules = [
      'Aucune commission sur une demande de devis, ni sur un devis accepté mais pas encore payé.'
          .tr,
      'Calculée à chaque encaissement effectif via Calandix, au prorata en cas de paiement en plusieurs fois.'
          .tr,
      'Un remboursement régularise la commission correspondante.'.tr,
      'Les frais du partenaire de paiement sont affichés à part, avant validation.'
          .tr,
      'Une mise en avant payante est toujours signalée « Sponsorisé » ; le classement naturel reste fondé sur la pertinence, les avis vérifiés et la disponibilité.'
          .tr,
    ];
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final r in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      AppIcons.checkCircle,
                      size: 16,
                      color: Confetti.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r, style: context.text.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Une option de visibilité, achetable à l'unité.
class _BoostRow extends ConsumerWidget {
  const _BoostRow({required this.boost, required this.onBuy});

  final ProBoost boost;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final until = ref.watch(proBoostsProvider)[boost];
    final on = until != null && until.isAfter(DateTime.now());
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(icon: boost.icon, hue: Hue.mango, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(boost.label, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  on
                      ? 'Actif jusqu’au {0}'.trf([mediumDate(until)])
                      : boost.description,
                  style: context.text.bodySmall?.copyWith(
                    color: on ? Confetti.success : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                boost.days == null
                    ? 'Dès {0}'.trf([fcfa(boost.price)])
                    : fcfa(boost.price),
                style: context.text.titleSmall,
              ),
              Text(
                boost.days == null
                    ? 'selon campagne'.tr
                    : '{0} jours'.trf([boost.days]),
                style: context.text.labelSmall,
              ),
              const SizedBox(height: 4),
              if (!on)
                Pressable(
                  onTap: onBuy,
                  child: Text(
                    'Activer'.tr,
                    style: context.text.labelLarge?.copyWith(
                      color: Confetti.coralDeep,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Abonnement en cours : formule, échéance, moyen de paiement.
class _ActiveSub extends StatelessWidget {
  const _ActiveSub({
    required this.sub,
    required this.onCancel,
    required this.onResume,
  });

  final CreatorSubscription sub;
  final VoidCallback onCancel;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final white = context.text.bodySmall?.copyWith(color: Colors.white70);
    final plan = sub.plan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Confetti.gold.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.checkCircle, size: 18, color: Confetti.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sub.cancelled
                      ? 'Formule {0} résiliée'.trf([plan.label])
                      : 'Formule {0} active'.trf([plan.label]),
                  style: context.text.titleSmall?.copyWith(color: Colors.white),
                ),
              ),
              Text(
                'Commission {0} %'.trf([plan.commissionPercent]),
                style: context.text.labelMedium?.copyWith(color: Confetti.gold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub.trial
                ? 'Essai gratuit jusqu’au {0}, puis {1}/mois.'.trf([
                    longDate(sub.renewsOn),
                    fcfa(plan.price),
                  ])
                : sub.cancelled
                ? 'Active jusqu’au {0}, puis retour à Découverte.'.trf([
                    longDate(sub.renewsOn),
                  ])
                : 'Prochain renouvellement le {0} · {1}'.trf([
                    longDate(sub.renewsOn),
                    sub.method.label,
                  ]),
            style: white,
          ),
          if (!sub.trial) Text('Reçu {0}'.trf([sub.receipt]), style: white),
          const SizedBox(height: 12),
          PillButton(
            label: sub.cancelled ? 'Réactiver'.tr : 'Résilier'.tr,
            tone: ButtonTone.light,
            height: 42,
            onPressed: sub.cancelled ? onResume : onCancel,
          ),
        ],
      ),
    );
  }
}

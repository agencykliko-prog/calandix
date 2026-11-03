import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/utils/formatters.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';

/// Offre Creator (dès 15 000 FCFA / mois, 14 jours d'essai) : souscription, état de
/// l'abonnement, résiliation ; et espaces sponsorisés.
class BusinessScreen extends ConsumerWidget {
  const BusinessScreen({super.key});

  Future<void> _subscribe(BuildContext context, WidgetRef ref) async {
    final r = await showPaymentSheet(
      context,
      title: 'Abonnement Creator'.tr,
      payee: 'Calandix'.tr,
      options: [
        PayOption('Mensuel'.tr, creatorPlanPrice),
        PayOption('Annuel · 2 mois offerts'.tr, creatorPlanPrice * 10),
      ],
      onPay: (amount, m) {
        final receipt = Receipt(
          ref: receiptRef(),
          label: 'Abonnement Creator'.tr,
          amount: amount,
          method: m,
          date: DateTime.now(),
          payee: 'Calandix'.tr,
        );
        ref.read(creatorSubProvider.notifier).activate(m, receipt.ref);
        return receipt;
      },
    );
    if (r != null && context.mounted) {
      toast(context, 'Bienvenue dans l’offre Creator'.tr, icon: AppIcons.crown);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showEventaSheet<bool>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Résilier l’offre Creator ?'.tr,
              style: ctx.text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos avantages restent actifs jusqu’à la fin de la période payée. Aucun prélèvement ensuite.'
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
      if (context.mounted) toast(context, 'Résiliation enregistrée'.tr);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(creatorSubProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
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
            NightPanel(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tag(label: 'Offre Creator'.tr, hue: Hue.gold, solid: true),
                  const SizedBox(height: 16),
                  Text(
                    'Votre agence événementielle, dans une seule app.'.tr,
                    style: context.text.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clients, devis, contrats, facturation et équipe. En marque blanche, avec API et automatisations.'
                        .tr,
                    style: context.text.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text.rich(
                    TextSpan(
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                      children: [
                        TextSpan(text: 'À partir de '.tr),
                        TextSpan(
                          text: fcfa(creatorPlanPrice),
                          style: context.text.headlineSmall?.copyWith(
                            color: Confetti.gold,
                          ),
                        ),
                        const TextSpan(text: ' / mois'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (sub == null) ...[
                    PillButton(
                      label: 'Essayer 14 jours gratuitement'.tr,
                      tone: ButtonTone.gold,
                      icon: AppIcons.crown,
                      onPressed: () {
                        ref.read(creatorSubProvider.notifier).startTrial();
                        toast(
                          context,
                          'Essai Creator activé : 14 jours offerts'.tr,
                          icon: AppIcons.crown,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    PillButton(
                      label: 'S’abonner · {0} / mois'.trf([
                        fcfa(creatorPlanPrice),
                      ]),
                      tone: ButtonTone.light,
                      onPressed: () => _subscribe(context, ref),
                    ),
                  ] else ...[
                    _ActiveSub(
                      sub: sub,
                      onCancel: () => _cancel(context, ref),
                      onResume: () =>
                          ref.read(creatorSubProvider.notifier).resume(),
                    ),
                    const SizedBox(height: 10),
                    PillButton(
                      label: 'Ouvrir mon Studio Creator'.tr,
                      icon: AppIcons.crown,
                      tone: ButtonTone.gold,
                      onPressed: () => context.push('/pro/studio'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '14 jours d’essai, puis sans engagement · 2 mois offerts à l’année'
                        .tr,
                    style: context.text.labelSmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            SectionTitle('Pour qui'.tr),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in Catalog.businessAudience)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Confetti.line),
                    ),
                    child: Text(a, style: context.text.labelMedium),
                  ),
              ],
            ),
            SectionTitle('Tout est inclus'.tr),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              padding: EdgeInsets.zero,
              children: [
                for (final (i, (icon, label))
                    in Catalog.businessFeatures.indexed)
                  Entrance(
                    index: i,
                    child: Panel(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      radius: 16,
                      child: Row(
                        children: [
                          IconTile(icon: icon, hue: Hue.violet, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: context.text.labelMedium,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SectionTitle('Publicité Premium'.tr),
            Text(
              'Réservée aux professionnels : gagnez en visibilité auprès des organisateurs qui préparent leur événement.'
                  .tr,
              style: context.text.bodyMedium?.copyWith(
                color: context.eventa.muted,
              ),
            ),
            const SizedBox(height: 14),
            for (final (s, desc) in Catalog.adFormats)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconTile(
                        icon: AppIcons.megaphone,
                        hue: Hue.mango,
                        size: 40,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.label, style: context.text.titleSmall),
                            const SizedBox(height: 2),
                            Text(desc, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            PillButton(
              label: 'Booster ma visibilité'.tr,
              icon: AppIcons.rocket,
              tone: ButtonTone.dark,
              onPressed: () => toast(
                context,
                'Un conseiller Publicité vous contacte bientôt'.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abonnement en cours : statut, échéance, moyen de paiement.
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
                      ? 'Offre Creator résiliée'.tr
                      : 'Offre Creator active'.tr,
                  style: context.text.titleSmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub.trial
                ? 'Essai gratuit jusqu’au {0}, puis {1}/mois.'.trf([
                    longDate(sub.renewsOn),
                    fcfa(creatorPlanPrice),
                  ])
                : sub.cancelled
                ? 'Active jusqu’au {0}, sans renouvellement.'.trf([
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

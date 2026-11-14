import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';

/// Exécute [onUnlocked] si la fonctionnalité est débloquée, sinon ouvre
/// le paywall. Après souscription, l'action reprend d'elle-même.
///
/// [plan] : formule à proposer quand une limite est atteinte (événements
/// actifs, collaborateurs) ; le paywall s'ouvre alors même si la
/// fonctionnalité est déjà incluse dans la formule actuelle.
Future<void> requirePremium(
  BuildContext context,
  WidgetRef ref, {
  required PremiumFeature feature,
  String? eventId,
  Plan? plan,
  required VoidCallback onUnlocked,
}) async {
  if (plan == null && ref.read(featureUnlockedProvider((feature, eventId)))) {
    onUnlocked();
    return;
  }
  final ok = await showEventaSheet<bool>(
    context,
    dark: true,
    builder: (_) => _Paywall(feature: feature, eventId: eventId, plan: plan),
  );
  if (ok == true && context.mounted) onUnlocked();
}

class _Paywall extends ConsumerWidget {
  const _Paywall({required this.feature, this.eventId, this.plan});

  final PremiumFeature feature;

  /// Formule proposée ; par défaut, celle qui ouvre la fonctionnalité.
  final Plan? plan;

  /// Événement concerné : le Pass Événement peut alors suffire.
  final String? eventId;

  Future<void> _pay(
    BuildContext context, {
    required String title,
    required List<PayOption> options,
    required VoidCallback onPaid,
  }) async {
    final r = await showPaymentSheet(
      context,
      title: title,
      payee: 'Calandix'.tr,
      options: options,
      onPay: (amount, method) {
        onPaid();
        return Receipt(
          ref: receiptRef(),
          label: title,
          amount: amount,
          method: method,
          date: DateTime.now(),
          payee: 'Calandix'.tr,
        );
      },
    );
    if (r != null && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = this.plan ?? feature.minPlan;
    // Essai gratuit : Privilège seulement, une fois.
    final canTry = !ref.watch(trialUsedProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Confetti.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(feature.icon, color: Confetti.gold, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            feature.label,
            style: context.text.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Disponible dès l’abonnement {0}, sans engagement, résiliable à tout moment.'
                .trf([plan.label]),
            style: context.text.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          for (final f in Catalog.planFeatures[plan]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(AppIcons.checkCircle, size: 18, color: Confetti.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.tr,
                      style: context.text.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (canTry) ...[
            PillButton(
              label: 'Essayer Privilège gratuitement {0} jours'.trf([
                trialDays,
              ]),
              tone: ButtonTone.gold,
              onPressed: () {
                ref.read(planProvider.notifier).startTrial(Plan.privilege);
                Navigator.of(context).pop(true);
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Toutes les fonctions, ensuite {0}/mois. Rien à payer pendant l’essai.'
                  .trf([fcfa(Plan.privilege.price)]),
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
          ],
          PillButton(
            label: 'S’abonner à {0} · {1}/mois'.trf([
              plan.label,
              fcfa(plan.price),
            ]),
            tone: canTry ? ButtonTone.light : ButtonTone.gold,
            onPressed: () => _pay(
              context,
              title: 'Abonnement {0}'.trf([plan.label]),
              options: [
                PayOption('Mensuel'.tr, plan.price),
                PayOption('Annuel · 1 mois offert'.tr, plan.yearlyPrice),
              ],
              onPaid: () => ref.read(planProvider.notifier).subscribe(plan),
            ),
          ),
          if (eventId != null && eventPassPlan.includes(plan)) ...[
            const SizedBox(height: 10),
            PillButton(
              label: 'Pass Événement · {0} · 90 jours'.trf([
                fcfa(eventPassPrice),
              ]),
              icon: AppIcons.ticket,
              tone: ButtonTone.light,
              onPressed: () => _pay(
                context,
                title: 'Pass Événement'.tr,
                options: [
                  PayOption('Paiement unique · 90 jours'.tr, eventPassPrice),
                ],
                onPaid: () =>
                    ref.read(eventPassProvider.notifier).activate(eventId!),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les fonctions Signature pour cet événement seulement, pendant 90 jours, sans abonnement.'
                  .tr,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                context.push(Routes.premium);
              },
              child: Text(
                'Comparer les offres et les packs'.tr,
                style: context.text.labelMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

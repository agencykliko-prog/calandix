import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';
import '../domain/pro_models.dart';
import '../../commerce/domain/commerce_models.dart';
import 'pro_providers.dart';
import 'studio_providers.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'verification_providers.dart';
import 'verification_screen.dart';
import 'signature_provider.dart';

/// Accès aux sections de l'espace pro, chacune avec son chiffre clé.
class ProHub extends ConsumerWidget {
  const ProHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    final studio = ref.watch(studioUnlockedProvider);
    final verification = ref.watch(verificationProvider);
    final requests = ref.watch(requestsProvider);
    final pending = requests
        .where((r) => r.status == RequestStatus.received)
        .length;
    final running = requests
        .where(
          (r) =>
              r.status == RequestStatus.confirmed &&
              pro.progressOf(r.id).stage != OrderStage.closed,
        )
        .length;
    final expected = pro.payouts
        .where((p) => p.status == PayoutStatus.scheduled)
        .fold<int>(0, (s, p) => s + p.net);
    final blocked = pro.availability.blocked
        .where((d) => !d.isBefore(dateOnly(DateTime.now())))
        .length;

    final tiles = [
      (
        'A',
        AppIcons.vendors,
        Hue.mango,
        'Profil & catalogue'.tr,
        '{0} forfaits · {1} options'.trf([
          pro.catalog.packages.where((p) => p.active).length,
          pro.catalog.options.where((o) => o.active).length,
        ]),
        '/pro/profil',
      ),
      (
        'B',
        AppIcons.agenda,
        Hue.violet,
        'Disponibilités'.tr,
        '{0} dates bloquées · {1}/jour'.trf([
          blocked,
          pro.availability.capacityPerDay,
        ]),
        '/pro/disponibilites',
      ),
      (
        'C',
        AppIcons.inbox,
        Hue.coral,
        'Devis & demandes'.tr,
        pending == 0 ? 'Tout est traité'.tr : '{0} à traiter'.trf([pending]),
        Routes.requests,
      ),
      (
        'D',
        AppIcons.calendarCheck,
        Hue.lagoon,
        'Commandes & prestations'.tr,
        '{0} en cours'.trf([running]),
        '/pro/commandes',
      ),
      (
        'E',
        AppIcons.coins,
        Hue.gold,
        'Revenus & reversements'.tr,
        expected == 0
            ? 'Aucun reversement en attente'.tr
            : '{0} attendus'.trf([fcfaCompact(expected)]),
        '/pro/revenus',
      ),
      (
        'F',
        AppIcons.star,
        Hue.candy,
        'Réputation & performance'.tr,
        '{0} ★ · {1} avis'.trf([
          pro.rating.toStringAsFixed(1).replaceAll('.', ','),
          pro.reviews.length,
        ]),
        '/pro/reputation',
      ),
      (
        'G',
        AppIcons.chart,
        Hue.lagoon,
        'Statistiques & clients'.tr,
        ref.watch(proPlanProvider).includes(ProPlan.starter)
            ? '{0} clients'.trf([ref.watch(studioClientsProvider).length])
            : 'Dès la formule Starter'.tr,
        '/pro/statistiques',
      ),
      (
        'H',
        AppIcons.crown,
        Hue.gold,
        'Studio Creator'.tr,
        studio
            ? 'Créations, CRM, factures'.tr
            : 'Dès la formule Creator · {0}/mois'.trf([
                fcfaCompact(ProPlan.creator.price),
              ]),
        '/pro/studio',
      ),
      (
        'I',
        verification.step.icon,
        verification.step.hue,
        'Vérification'.tr,
        verification.step.label,
        '/pro/verification',
      ),
      (
        'J',
        AppIcons.edit,
        Hue.violet,
        'Ma signature'.tr,
        ref.watch(signatureProvider) == null
            ? 'À enregistrer'.tr
            : 'Sur vos devis et factures'.tr,
        '/pro/signature',
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final n = box.maxWidth >= 900
            ? 4
            : box.maxWidth >= 640
            ? 3
            : 2;
        final w = (box.maxWidth - 8 * (n - 1)) / n;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (letter, icon, hue, title, caption, path) in tiles)
              SizedBox(
                width: w,
                child: Panel(
                  padding: const EdgeInsets.all(14),
                  onTap: () => path == Routes.requests
                      ? context.go(path)
                      : context.push(path),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconTile(icon: icon, hue: hue, size: 36),
                          const Spacer(),
                          Text(
                            letter,
                            style: context.text.labelSmall?.copyWith(
                              color: Confetti.inkFaint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(title, maxLines: 2, style: context.text.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: hue.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../domain/pro_models.dart';
import 'creator_providers.dart';
import 'pro_providers.dart';
import 'verification_providers.dart';

/// Critères du badge de qualité : objectifs et vérifiables.
const qualityMinRating = 4.5;
const qualityMinReviews = 10;
const qualityMinDone = 5;
const qualityMinResponse = 0.9;

/// Les trois badges du profil, à ne pas confondre : la formule souscrite,
/// les pièces contrôlées, et la qualité mesurée sur des critères objectifs.
class ProBadges extends ConsumerWidget {
  const ProBadges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(proPlanProvider);
    final verified =
        ref.watch(verificationProvider).step == VerificationStep.verified;
    final pro = ref.watch(proProvider);
    final requests = ref.watch(requestsProvider);
    final answered = requests
        .where((r) => r.status != RequestStatus.received)
        .length;
    final response = requests.isEmpty ? 0.0 : answered / requests.length;
    final done = requests
        .where(
          (r) =>
              r.status == RequestStatus.confirmed &&
              pro.progressOf(r.id).stage.index >= OrderStage.done.index,
        )
        .length;
    final criteria = [
      (
        'Note moyenne d’au moins {0}'.trf(['4,5']),
        pro.rating >= qualityMinRating,
      ),
      (
        'Au moins {0} avis vérifiés'.trf([qualityMinReviews]),
        pro.reviews.length >= qualityMinReviews,
      ),
      (
        'Au moins {0} prestations réalisées via Calandix'.trf([qualityMinDone]),
        done >= qualityMinDone,
      ),
      ('Réponse à 90 % des demandes'.tr, response >= qualityMinResponse),
      ('Profil vérifié'.tr, verified),
    ];
    final quality = criteria.every((c) => c.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Badges du profil'.tr),
        _Badge(
          icon: AppIcons.crown,
          hue: Hue.gold,
          title: 'Badge d’abonnement'.tr,
          state: plan.free ? 'Aucun'.tr : 'Formule {0}'.trf([plan.label]),
          on: !plan.free,
          caption: 'Indique la formule souscrite. Il ne dit rien de la qualité des prestations.'
              .tr,
          action: plan == ProPlan.business ? null : 'Voir les formules'.tr,
          onAction: () => context.push(Routes.business),
        ),
        const SizedBox(height: 8),
        _Badge(
          icon: AppIcons.verified,
          hue: Hue.lagoon,
          title: 'Badge de vérification'.tr,
          state: verified ? 'Vérifié'.tr : 'Non vérifié'.tr,
          on: verified,
          caption: 'L’équipe Calandix a contrôlé la pièce d’identité, le RCCM, l’adresse et des réalisations.'
              .tr,
          action: verified ? null : 'Faire vérifier mon profil'.tr,
          onAction: () => context.push('/pro/verification'),
        ),
        const SizedBox(height: 8),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Head(
                icon: AppIcons.star,
                hue: Hue.candy,
                title: 'Badge de qualité'.tr,
                state: quality ? 'Obtenu'.tr : 'En cours'.tr,
                on: quality,
              ),
              const SizedBox(height: 8),
              Text(
                'Attribué automatiquement quand tous les critères sont remplis, retiré sinon.'
                    .tr,
                style: context.text.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final (label, ok) in criteria)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        ok ? AppIcons.checkCircle : AppIcons.minus,
                        size: 16,
                        color: ok ? Hue.lagoon.text : context.eventa.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(label, style: context.text.bodySmall),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({
    required this.icon,
    required this.hue,
    required this.title,
    required this.state,
    required this.on,
  });

  final IconData icon;
  final Hue hue;
  final String title;
  final String state;
  final bool on;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconTile(icon: icon, hue: hue, size: 36, solid: on),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: context.text.titleSmall)),
      Tag(label: state, hue: on ? hue : Hue.ink, solid: on),
    ],
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.hue,
    required this.title,
    required this.state,
    required this.on,
    required this.caption,
    required this.onAction,
    this.action,
  });

  final IconData icon;
  final Hue hue;
  final String title;
  final String state;
  final bool on;
  final String caption;
  final String? action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Head(icon: icon, hue: hue, title: title, state: state, on: on),
        const SizedBox(height: 8),
        Text(caption, style: context.text.bodySmall),
        if (action != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onAction, child: Text(action!)),
          ),
      ],
    ),
  );
}

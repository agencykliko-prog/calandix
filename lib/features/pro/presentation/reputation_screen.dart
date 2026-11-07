import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';
import '../domain/pro_models.dart';
import 'pro_providers.dart';
import 'pro_badges.dart';
import 'pro_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// F. Réputation & performance : avis vérifiés, réactivité, indicateurs
/// et satisfaction client.
class ReputationScreen extends ConsumerWidget {
  const ReputationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    final requests = ref.watch(requestsProvider);
    final reviews = pro.reviews;
    final avg = pro.rating;
    final answered = requests
        .where((r) => r.status != RequestStatus.received)
        .length;
    final decided = requests.where(
      (r) =>
          r.status == RequestStatus.confirmed ||
          r.status == RequestStatus.declined,
    );
    final acceptance = decided.isEmpty
        ? 0
        : decided.where((r) => r.status == RequestStatus.confirmed).length /
              decided.length;
    final replied = reviews.where((r) => r.reply != null).length;

    return ProPage(
      title: 'Réputation & performance'.tr,
      subtitle:
          'Ce que disent vos clients et comment Explorer vous met en avant.'.tr,
      children: [
        const SizedBox(height: 12),
        NightPanel(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avg.toStringAsFixed(1).replaceAll('.', ','),
                    style: context.text.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= avg.round() ? AppIcons.star : AppIcons.starLine,
                          size: 16,
                          color: Confetti.gold,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '{0} avis vérifiés'.trf([reviews.length]),
                    style: context.text.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var s = 5; s >= 1; s--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text(
                                '$s',
                                style: context.text.labelSmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Meter(
                                value: reviews.isEmpty
                                    ? 0
                                    : reviews
                                              .where((r) => r.rating == s)
                                              .length /
                                          reviews.length,
                                color: Confetti.gold,
                                track: Colors.white.withValues(alpha: 0.12),
                                height: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionTitle('Indicateurs de performance'.tr),
        KpiGrid.compact(
          children: [
            KpiCard.compact(
              label: 'Taux de réponse'.tr,
              value:
                  '${requests.isEmpty ? 0 : (answered / requests.length * 100).round()} %',
              hue: Hue.lagoon,
              icon: AppIcons.message,
              caption: 'Objectif : 90 %'.tr,
            ),
            KpiCard.compact(
              label: 'Temps de réponse moyen'.tr,
              value: '1 h 12',
              hue: Hue.violet,
              icon: AppIcons.timer,
              caption: 'Top 20 % de votre catégorie'.tr,
            ),
            KpiCard.compact(
              label: 'Taux d’acceptation'.tr,
              value: '${(acceptance * 100).round()} %',
              hue: Hue.mango,
              icon: AppIcons.calendarCheck,
            ),
            KpiCard.compact(
              label: 'Prestations honorées'.tr,
              value: '100 %',
              hue: Hue.coral,
              icon: AppIcons.verified,
              caption: 'Aucune annulation'.tr,
            ),
          ],
        ),
        const ProBadges(),
        SectionTitle('Satisfaction client'.tr),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '94 %',
                    style: context.text.headlineSmall?.copyWith(
                      color: Confetti.lagoonText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'de clients satisfaits ou très satisfaits sur 6 mois'.tr,
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final (label, v) in [
                ('Qualité de la prestation'.tr, 0.96),
                ('Ponctualité'.tr, 0.88),
                ('Communication'.tr, 0.93),
                ('Rapport qualité-prix'.tr, 0.9),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(label, style: context.text.bodySmall),
                      ),
                      Expanded(
                        child: Meter(
                          value: v,
                          color: Confetti.lagoon,
                          height: 6,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${(v * 100).round()} %',
                          textAlign: TextAlign.right,
                          style: context.text.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Point d’attention : la ponctualité. Prévoyez 30 min de marge à l’installation.'
                    .tr,
                style: context.text.bodySmall?.copyWith(
                  color: Confetti.mangoText,
                ),
              ),
            ],
          ),
        ),
        SectionTitle(
          'Avis clients'.tr,
          action: '{0}/{1} répondus'.trf([replied, reviews.length]),
        ),
        for (final r in reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReviewCard(review: r),
          ),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final ProReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = review;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(image: r.avatar, initials: r.author[0], size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: context.text.titleSmall),
                    Text(
                      '{0} · {1}'.trf([r.event, shortDate(r.date)]),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= r.rating ? AppIcons.star : AppIcons.starLine,
                      size: 13,
                      color: Confetti.mango,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.text, style: context.text.bodyMedium),
          const SizedBox(height: 8),
          Tag(
            label: 'Réservation vérifiée'.tr,
            hue: Hue.lagoon,
            icon: AppIcons.verified,
          ),
          if (r.reply != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Confetti.lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Votre réponse : {0}'.trf([r.reply]),
                style: context.text.bodySmall?.copyWith(color: Confetti.ink),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                label: 'Répondre publiquement'.tr,
                icon: AppIcons.message,
                tone: ButtonTone.ghost,
                expand: false,
                height: 38,
                onPressed: () => _reply(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _reply(BuildContext context, WidgetRef ref) {
    final c = TextEditingController(
      text: 'Merci {0} pour votre confiance !'.trf([
        review.author.split(' ').first,
      ]),
    );
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Répondre à l’avis'.tr, style: ctx.text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Votre réponse est visible par tous sur votre fiche.'.tr,
              style: ctx.text.bodySmall,
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Réponse'.tr,
              controller: c,
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Publier la réponse'.tr,
              tone: ButtonTone.dark,
              onPressed: () {
                if (c.text.trim().isEmpty) return;
                ref.read(proProvider.notifier).reply(review.id, c.text.trim());
                Navigator.of(ctx).pop();
                toast(context, 'Réponse publiée'.tr);
              },
            ),
          ],
        ),
      ),
    );
  }
}

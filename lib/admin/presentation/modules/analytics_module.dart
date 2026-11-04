import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import '../../data/admin_demo.dart';
import '../widgets/admin_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// Analytics : acquisition, activité, rétention et revenus (12 mois).
class AnalyticsModule extends ConsumerStatefulWidget {
  const AnalyticsModule({super.key});

  @override
  ConsumerState<AnalyticsModule> createState() => _AnalyticsModuleState();
}

class _AnalyticsModuleState extends ConsumerState<AnalyticsModule> {
  int _metric = 0;

  static const _months = [
    'N',
    'D',
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
  ];

  @override
  Widget build(BuildContext context) {
    final (label, values, color, fmt) = switch (_metric) {
      0 => (
        'Inscriptions',
        [for (final v in AdminDemo.signups) v.toDouble()],
        Confetti.violet,
        (double v) => '${v.round()} comptes',
      ),
      1 => (
        'Volume d’affaires (GMV)',
        [for (final v in AdminDemo.gmv) v.toDouble()],
        Confetti.lagoon,
        (double v) => '${v.round()} M FCFA',
      ),
      _ => (
        'Revenus plateforme',
        AdminDemo.revenue,
        Confetti.gold,
        (double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')} M FCFA',
      ),
    };
    final channelColors = [
      Confetti.violet,
      Confetti.candy,
      Confetti.lagoon,
      Confetti.mango,
      Confetti.coral,
    ];

    final acquisition = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acquisition', style: context.text.titleMedium),
          Text(
            'Canal des nouveaux comptes, 90 jours',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Donut(
                size: 120,
                thickness: 16,
                slices: [
                  for (final (i, v) in AdminDemo.channels.values.indexed)
                    DonutSlice(v, channelColors[i]),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final (i, e) in AdminDemo.channels.entries.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: channelColors[i],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(e.key, style: context.text.bodySmall),
                            ),
                            Text(
                              '${(e.value * 100).round()} %',
                              style: context.text.labelMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final retention = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rétention par cohorte', style: context.text.titleMedium),
          Text(
            '% d’organisateurs actifs après l’inscription',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 90),
              for (final m in ['M+1', 'M+2', 'M+3'])
                Expanded(
                  child: Text(
                    m,
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall,
                  ),
                ),
            ],
          ),
          for (final e in AdminDemo.cohorts.entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(e.key, style: context.text.bodySmall),
                  ),
                  for (final v in e.value)
                    Expanded(
                      child: Container(
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: v == null
                              ? Confetti.lavender.withValues(alpha: 0.4)
                              : Confetti.violet.withValues(
                                  alpha: 0.15 + v / 100 * 0.75,
                                ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          v == null ? '–' : '$v %',
                          style: context.text.labelSmall?.copyWith(
                            color: v != null && v > 55
                                ? Colors.white
                                : Confetti.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminHeader(
          title: 'Analytics',
          subtitle: 'Acquisition, activité, rétention et revenus sur les 12 derniers mois (données fictives).',
        ),
        KpiGrid(
          minTile: 200,
          children: [
            KpiCard(
              icon: AppIcons.userPlus,
              hue: Hue.violet,
              label: 'Nouveaux comptes',
              value: '1 690',
              caption: 'Ce mois-ci',
              trend: 11.2,
            ),
            KpiCard(
              icon: AppIcons.lightning,
              hue: Hue.candy,
              label: 'Actifs mensuels',
              value: '6 820',
              caption: '55 % des inscrits',
              trend: 4.6,
            ),
            KpiCard(
              icon: AppIcons.calendarCheck,
              hue: Hue.lagoon,
              label: 'Conversion devis → réservation',
              value: '38 %',
              caption: 'Moyenne toutes catégories',
              trend: 2.1,
            ),
            KpiCard(
              icon: AppIcons.coins,
              hue: Hue.gold,
              label: 'Panier moyen',
              value: '612 000 FCFA',
              caption: 'Par réservation',
              trend: -1.4,
            ),
          ],
        ),
        BlockTitle(
          label,
          trailing: FilterChips<int>(
            values: const [0, 1, 2],
            selected: _metric,
            labelOf: (v) => const ['Inscriptions', 'GMV', 'Revenus'][v!],
            onChanged: (v) => setState(() => _metric = v!),
          ),
        ),
        Panel(
          child: BarChart(
            key: ValueKey(_metric),
            values: values,
            labels: _months,
            color: color,
            height: 220,
            format: fmt,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 860
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: acquisition),
                    const SizedBox(width: 16),
                    Expanded(child: retention),
                  ],
                )
              : Column(
                  children: [
                    acquisition,
                    const SizedBox(height: 12),
                    retention,
                  ],
                ),
        ),
        const _LiveAudience(),
      ],
    );
  }
}

/// Noms lisibles des écrans mesurés (modèles de chemin).
const _screenNames = {
  '/bienvenue': 'Bienvenue',
  '/connexion': 'Connexion',
  '/inscription': 'Inscription',
  '/accueil': 'Accueil',
  '/explorer': 'Explorer',
  '/demandes': 'Demandes (Creator)',
  '/agenda': 'Agenda',
  '/compte': 'Compte',
  '/messages': 'Messages',
  '/messages/:id': 'Conversation',
  '/prestataire/:id': 'Fiche prestataire',
  '/reservation/:id': 'Réservation',
  '/evenement/:id': 'Tableau de bord événement',
  '/evenement/:id/budget': 'Budget',
  '/evenement/:id/taches': 'Tâches',
  '/evenement/:id/invites': 'Invités',
  '/nouvel-evenement': 'Nouvel événement',
  '/premium': 'Premium',
  '/business': 'Formules prestataires',
  '/pro/devis/:id': 'Demande de devis (Creator)',
  '/pro/verification': 'Vérification (Creator)',
};

/// Mesure d'audience en direct : écrans vus et événements clés enregistrés
/// sur cet appareil depuis l'ouverture de l'app (anonyme).
class _LiveAudience extends ConsumerWidget {
  const _LiveAudience();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(audienceSummaryProvider);
    final consent = ref.watch(audienceConsentProvider);
    final top = a.topScreens.isEmpty ? 1 : a.topScreens.first.$2;
    return Column(
      key: const ValueKey('live-audience'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlockTitle(
          'Mesure d’audience',
          trailing: consent
              ? const LiveDot(label: 'Cet appareil')
              : StatusPill('Désactivée par l’utilisateur', Hue.ink),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final screens = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Écrans les plus vus', style: context.text.titleMedium),
                  Text(
                    '${a.pageViews} écrans vus · chemins sans identifiant',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (a.topScreens.isEmpty)
                    Text(
                      'Aucune visite enregistrée pour l’instant.',
                      style: context.text.bodySmall,
                    ),
                  for (final (path, n) in a.topScreens)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: Text(
                              _screenNames[path] ?? path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: n / top,
                                minHeight: 8,
                                color: Confetti.violet,
                                backgroundColor: Confetti.lavender,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('$n', style: context.text.labelMedium),
                        ],
                      ),
                    ),
                ],
              ),
            );
            final events = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Événements clés', style: context.text.titleMedium),
                  Text(
                    'Parcours organisateur et Creator',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final m in Metric.values)
                    if (m != Metric.pageView)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.label,
                                style: context.text.bodySmall,
                              ),
                            ),
                            Text(
                              '${a.events[m] ?? 0}',
                              style: context.text.labelMedium,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            );
            return box.maxWidth >= 860
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: screens),
                      const SizedBox(width: 16),
                      Expanded(child: events),
                    ],
                  )
                : Column(
                    children: [screens, const SizedBox(height: 12), events],
                  );
          },
        ),
      ],
    );
  }
}

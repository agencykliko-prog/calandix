import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';

// ─── Modèles de devis ───────────────────────────────────────────────────

/// Devis type réutilisable : forfait, options et frais, par type
/// d'événement.
@immutable
class QuoteTemplate {
  const QuoteTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.packageId,
    this.optionIds = const {},
    this.travel = false,
  });

  final String id;
  final String name;
  final EventCategory category;
  final String? packageId;
  final Set<String> optionIds;
  final bool travel;
}

class QuoteTemplatesNotifier extends Notifier<List<QuoteTemplate>> {
  @override
  List<QuoteTemplate> build() => [
    QuoteTemplate(
      id: 't1',
      name: 'Mariage complet'.tr,
      category: EventCategory.wedding,
      packageId: 'p2',
      optionIds: const {'o1', 'o3', 'o4'},
      travel: true,
    ),
    QuoteTemplate(
      id: 't2',
      name: 'Anniversaire'.tr,
      category: EventCategory.birthday,
      packageId: 'p1',
      optionIds: const {'o2'},
    ),
    QuoteTemplate(
      id: 't3',
      name: 'Baby shower'.tr,
      category: EventCategory.baby,
      packageId: 'p3',
      optionIds: const {'o1'},
    ),
  ];

  void add(QuoteTemplate t) => state = [...state, t];
  void remove(String id) => state = state.where((t) => t.id != id).toList();
}

final quoteTemplatesProvider =
    NotifierProvider<QuoteTemplatesNotifier, List<QuoteTemplate>>(
      QuoteTemplatesNotifier.new,
    );

// ─── Relances automatiques ──────────────────────────────────────────────

@immutable
class FollowUpSettings {
  const FollowUpSettings({this.enabled = true, this.days = 3});
  final bool enabled;

  /// Délai sans réponse avant la relance.
  final int days;
}

class FollowUpNotifier extends Notifier<FollowUpSettings> {
  @override
  FollowUpSettings build() => const FollowUpSettings();

  void setEnabled(bool v) =>
      state = FollowUpSettings(enabled: v, days: state.days);
  void setDays(int d) =>
      state = FollowUpSettings(enabled: state.enabled, days: d.clamp(1, 14));
}

final followUpProvider = NotifierProvider<FollowUpNotifier, FollowUpSettings>(
  FollowUpNotifier.new,
);

/// Date de relance prévue d'un devis en attente ; null : rien à relancer
/// (pas de devis, déjà relancé, expiré, ou le client a répondu).
DateTime? followUpDue(ClientRequest r, int days) {
  if (r.status != RequestStatus.quoted || r.expired) return null;
  final sent = r.quotedAt;
  if (sent == null || r.followedUpAt != null) return null;
  final answered = r.thread.any((m) => !m.fromMe && m.at.isAfter(sent));
  if (answered) return null;
  return sent.add(Duration(days: days));
}

/// Devis sans réponse, relancés automatiquement quand le délai est passé.
final pendingQuotesProvider = Provider<List<(ClientRequest, DateTime)>>((ref) {
  final days = ref.watch(followUpProvider).days;
  return [
    for (final r in ref.watch(requestsProvider))
      if (followUpDue(r, days) case final due?) (r, due),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
});

/// Envoie les relances arrivées à échéance ; renvoie le nombre envoyé.
int runFollowUps(WidgetRef ref) {
  if (!ref.read(followUpProvider).enabled) return 0;
  final now = DateTime.now();
  var n = 0;
  for (final (r, due) in ref.read(pendingQuotesProvider)) {
    if (due.isAfter(now)) continue;
    ref.read(requestsProvider.notifier).followUp(r.id);
    n++;
  }
  return n;
}

/// Encart des relances, en tête des demandes.
class FollowUpPanel extends ConsumerStatefulWidget {
  const FollowUpPanel({super.key});

  @override
  ConsumerState<FollowUpPanel> createState() => _FollowUpPanelState();
}

class _FollowUpPanelState extends ConsumerState<FollowUpPanel> {
  @override
  void initState() {
    super.initState();
    // Les relances échues partent à l'ouverture (côté serveur : tâche
    // planifiée quotidienne).
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _run() {
    if (!mounted) return;
    final n = runFollowUps(ref);
    if (n > 0) {
      toast(
        context,
        '{0} devis relancé(s) automatiquement'.trf([n]),
        icon: AppIcons.send,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(followUpProvider);
    final n = ref.read(followUpProvider.notifier);
    final pending = ref.watch(pendingQuotesProvider);
    final followed = ref
        .watch(requestsProvider)
        .where(
          (r) => r.status == RequestStatus.quoted && r.followedUpAt != null,
        )
        .toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: AppIcons.reminder, hue: Hue.mango, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relance automatique des devis'.tr,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      'Un message au client si le devis reste sans réponse après {0} jours.'
                          .trf([s.days]),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: s.enabled,
                onChanged: (v) {
                  n.setEnabled(v);
                  if (v) _run();
                },
              ),
            ],
          ),
          if (s.enabled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Délai sans réponse'.tr,
                    style: context.text.bodySmall,
                  ),
                ),
                RoundIconButton(
                  icon: AppIcons.minus,
                  size: 32,
                  tooltip: 'Moins',
                  onTap: s.days <= 1
                      ? null
                      : () {
                          n.setDays(s.days - 1);
                          _run();
                        },
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '{0} jours'.trf([s.days]),
                    textAlign: TextAlign.center,
                    style: context.text.titleSmall,
                  ),
                ),
                RoundIconButton(
                  icon: AppIcons.add,
                  size: 32,
                  tooltip: 'Plus',
                  onTap: s.days >= 14 ? null : () => n.setDays(s.days + 1),
                ),
              ],
            ),
          ],
          for (final (r, due) in pending)
            _Line(
              title: r.eventName,
              caption: 'Relance prévue le {0}'.trf([mediumDate(due)]),
              action: 'Relancer'.tr,
              onAction: () {
                ref.read(requestsProvider.notifier).followUp(r.id);
                toast(context, 'Relance envoyée à {0}'.trf([r.client]));
              },
              onOpen: () => context.push('/pro/devis/${r.id}'),
            ),
          for (final r in followed)
            _Line(
              title: r.eventName,
              caption: 'Relancé le {0}'.trf([mediumDate(r.followedUpAt!)]),
              onOpen: () => context.push('/pro/devis/${r.id}'),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.title,
    required this.caption,
    required this.onOpen,
    this.action,
    this.onAction,
  });

  final String title;
  final String caption;
  final VoidCallback onOpen;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(caption, style: context.text.bodySmall),
              ],
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

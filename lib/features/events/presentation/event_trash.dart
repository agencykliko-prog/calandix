import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'events_providers.dart';

/// Durée pendant laquelle un événement supprimé reste restaurable.
const trashRetention = Duration(days: 30);

/// Événement mis à la corbeille.
@immutable
class TrashedEvent {
  const TrashedEvent(this.event, this.deletedAt);
  final Event event;
  final DateTime deletedAt;

  /// Date de l'effacement définitif automatique.
  DateTime get purgeAt => deletedAt.add(trashRetention);

  /// Jours restants avant l'effacement (au moins 0).
  int daysLeft([DateTime? now]) {
    final left = purgeAt.difference(now ?? DateTime.now());
    return left.isNegative ? 0 : (left.inHours / 24).ceil();
  }

  bool expired([DateTime? now]) => !purgeAt.isAfter(now ?? DateTime.now());
}

/// La corbeille : supprimer y envoie l'événement, on peut l'en restaurer
/// pendant [trashRetention], et seule la corbeille efface définitivement.
class TrashNotifier extends Notifier<List<TrashedEvent>> {
  @override
  List<TrashedEvent> build() {
    // Compte réel : la corbeille vient de la base.
    final repo = ref.watch(eventsRepositoryProvider);
    unawaited(
      repo.fetchTrash().then((rows) {
        if (rows.isEmpty) return;
        state = _purge([for (final (e, at) in rows) TrashedEvent(e, at)]);
      }, onError: (Object _) {}),
    );
    return const [];
  }

  /// Efface ce qui a dépassé le délai de conservation.
  List<TrashedEvent> _purge(List<TrashedEvent> items) {
    final now = DateTime.now();
    for (final t in items.where((t) => t.expired(now))) {
      unawaited(_deleteRemote(t.event.id));
    }
    return [
      for (final t in items)
        if (!t.expired(now)) t,
    ];
  }

  Future<void> _deleteRemote(String id) => ref
      .read(eventsRepositoryProvider)
      .deleteEvent(id)
      .catchError((Object _) {});

  TrashedEvent? of(String eventId) =>
      state.where((t) => t.event.id == eventId).firstOrNull;

  /// Met l'événement à la corbeille. Renvoie l'élément créé.
  TrashedEvent? trash(String eventId, {DateTime? at}) {
    final e = ref.read(eventsProvider.notifier).detach(eventId);
    if (e == null) return null;
    final t = TrashedEvent(e, at ?? DateTime.now());
    state = _purge([t, ...state.where((x) => x.event.id != eventId)]);
    unawaited(
      ref
          .read(eventsRepositoryProvider)
          .trashEvent(eventId, t.deletedAt)
          .catchError((Object _) {}),
    );
    return t;
  }

  /// Restaure l'événement tel qu'il était (budget, invités, tâches…).
  void restore(String eventId) {
    final t = of(eventId);
    if (t == null) return;
    state = [
      for (final x in state)
        if (x.event.id != eventId) x,
    ];
    ref.read(eventsProvider.notifier).reattach(t.event);
    unawaited(
      ref
          .read(eventsRepositoryProvider)
          .restoreEvent(eventId)
          .catchError((Object _) {}),
    );
  }

  /// Suppression définitive : uniquement depuis la corbeille.
  void deleteForever(String eventId) {
    if (of(eventId) == null) return;
    state = [
      for (final x in state)
        if (x.event.id != eventId) x,
    ];
    unawaited(_deleteRemote(eventId));
  }

  /// Vide la corbeille. Renvoie le nombre d'événements effacés.
  int empty() {
    final n = state.length;
    for (final t in state) {
      unawaited(_deleteRemote(t.event.id));
    }
    state = const [];
    return n;
  }
}

final trashProvider = NotifierProvider<TrashNotifier, List<TrashedEvent>>(
  TrashNotifier.new,
);

/// Réservations encore actives d'un événement (date bloquée ou payée).
List<Booking> activeBookingsOf(List<Booking> all, String eventId) => [
  for (final b in all)
    if (b.eventId == eventId &&
        b.step.index >= BookingStep.reserved.index &&
        b.step.index < BookingStep.closed.index)
      b,
];

/// Demande confirmation puis met l'événement à la corbeille, revient à
/// l'accueil et propose d'annuler.
Future<void> confirmTrashEvent(
  BuildContext context,
  WidgetRef ref,
  Event e,
) async {
  final ok = await showEventaSheet<bool>(
    context,
    builder: (_) => _TrashConfirm(event: e),
  );
  if (ok != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final notifier = ref.read(trashProvider.notifier);
  if (notifier.trash(e.id) == null) return;
  router.go(Routes.home);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          '« {0} » est dans la corbeille pendant {1} jours.'.trf([
            e.name,
            trashRetention.inDays,
          ]),
        ),
        action: SnackBarAction(
          label: 'Annuler'.tr,
          textColor: Confetti.lagoon,
          onPressed: () => notifier.restore(e.id),
        ),
      ),
    );
}

class _TrashConfirm extends ConsumerWidget {
  const _TrashConfirm({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final active = activeBookingsOf(ref.watch(bookingsProvider), e.id);
    final guests = e.guests.list.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconTile(icon: AppIcons.trash, hue: Hue.coral, size: 48),
          ),
          const SizedBox(height: 14),
          Text(
            'Supprimer « {0} » ?'.trf([e.name]),
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'L’événement part dans la corbeille. Vous pouvez le restaurer pendant {0} jours, avec son budget, ses invités et ses tâches. Ensuite, il est effacé définitivement.'
                .trf([trashRetention.inDays]),
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Fact(
                  icon: AppIcons.guests,
                  text: '{0} invité(s), {1} tâche(s), {2} poste(s) de budget'
                      .trf([guests, e.tasks.length, e.budget.length]),
                ),
                _Fact(
                  icon: AppIcons.team,
                  text: 'Les co-organisateurs n’y auront plus accès.'.tr,
                ),
              ],
            ),
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 10),
            Panel(
              color: Confetti.mangoTint,
              border: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.warning, size: 18, color: Confetti.mangoText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '{0} réservation(s) en cours ({1}) ne sont pas annulées : les prestataires gardent la date. Annulez-les d’abord si besoin.'
                          .trf([
                            active.length,
                            [for (final b in active) b.vendor.name].join(', '),
                          ]),
                      style: context.text.bodySmall?.copyWith(
                        color: Confetti.mangoText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          PillButton(
            key: const ValueKey('confirm-trash'),
            label: 'Mettre à la corbeille'.tr,
            icon: AppIcons.trash,
            tone: ButtonTone.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          PillButton(
            label: 'Garder l’événement'.tr,
            tone: ButtonTone.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: context.eventa.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: context.text.bodySmall)),
      ],
    ),
  );
}

/// Écran « Corbeille » : restaurer, ou effacer définitivement.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(trashProvider);
    return Scaffold(
      appBar: AppBar(
        // Ouverte par un lien direct : retour vers l'accueil.
        leading: IconButton(
          tooltip: 'Retour'.tr,
          icon: const Icon(AppIcons.back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text('Corbeille'.tr),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmEmpty(context, ref, items.length),
              child: Text(
                'Vider'.tr,
                style: TextStyle(color: Confetti.coralDeep),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Mascot(size: 110),
                    const SizedBox(height: 16),
                    Text(
                      'La corbeille est vide'.tr,
                      style: context.text.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Un événement supprimé reste ici {0} jours avant d’être effacé.'
                          .trf([trashRetention.inDays]),
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    Text(
                      'Les événements sont effacés automatiquement {0} jours après leur suppression.'
                          .trf([trashRetention.inDays]),
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    for (final t in items) ...[
                      _TrashTile(item: t),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmEmpty(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final ok = await showEventaSheet<bool>(
      context,
      builder: (_) => _ForeverConfirm(
        title: 'Vider la corbeille ?'.tr,
        body: '{0} événement(s) seront effacés définitivement, avec leurs budgets, invités, tâches et documents. Cette action est irréversible.'
            .trf([count]),
        confirmLabel: 'Tout effacer définitivement'.tr,
      ),
    );
    if (ok != true || !context.mounted) return;
    final n = ref.read(trashProvider.notifier).empty();
    toast(
      context,
      '{0} événement(s) effacé(s) définitivement'.trf([n]),
      icon: AppIcons.trash,
    );
  }
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.item});
  final TrashedEvent item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = item.event;
    final left = item.daysLeft();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: e.category.icon, hue: Hue.violet, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '{0} · supprimé le {1}'.trf([
                        mediumDate(e.date),
                        mediumDate(item.deletedAt),
                      ]),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            left <= 1
                ? 'Effacé définitivement demain'.tr
                : 'Effacé définitivement dans {0} jours'.trf([left]),
            style: context.text.labelMedium?.copyWith(
              color: left <= 7 ? Confetti.coralDeep : context.eventa.muted,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PillButton(
                key: ValueKey('restore-${e.id}'),
                label: 'Restaurer'.tr,
                icon: AppIcons.refresh,
                expand: false,
                height: 42,
                onPressed: () {
                  ref.read(trashProvider.notifier).restore(e.id);
                  toast(context, '« {0} » est restauré'.trf([e.name]));
                },
              ),
              PillButton(
                key: ValueKey('forever-${e.id}'),
                label: 'Supprimer définitivement'.tr,
                icon: AppIcons.trash,
                expand: false,
                height: 42,
                tone: ButtonTone.ghost,
                onPressed: () => _forever(context, ref, e),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _forever(BuildContext context, WidgetRef ref, Event e) async {
    final ok = await showEventaSheet<bool>(
      context,
      builder: (_) => _ForeverConfirm(
        title: 'Supprimer définitivement ?'.tr,
        body: '« {0} » sera effacé avec son budget, ses invités, ses tâches et ses documents. Cette action est irréversible.'
            .trf([e.name]),
        confirmLabel: 'Supprimer définitivement'.tr,
        typeToConfirm: e.name,
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(trashProvider.notifier).deleteForever(e.id);
    toast(
      context,
      '« {0} » est effacé définitivement'.trf([e.name]),
      icon: AppIcons.trash,
    );
  }
}

/// Confirmation d'une suppression irréversible. Avec [typeToConfirm], il
/// faut recopier le nom de l'événement pour déverrouiller le bouton.
class _ForeverConfirm extends StatefulWidget {
  const _ForeverConfirm({
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.typeToConfirm,
  });
  final String title;
  final String body;
  final String confirmLabel;
  final String? typeToConfirm;

  @override
  State<_ForeverConfirm> createState() => _ForeverConfirmState();
}

class _ForeverConfirmState extends State<_ForeverConfirm> {
  final _typed = TextEditingController();
  bool _understood = false;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim().toLowerCase();

  bool get _ok =>
      _understood &&
      (widget.typeToConfirm == null ||
          _norm(_typed.text) == _norm(widget.typeToConfirm!));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconTile(icon: AppIcons.warning, hue: Hue.coral, size: 48),
          ),
          const SizedBox(height: 14),
          Text(widget.title, style: context.text.headlineSmall),
          const SizedBox(height: 6),
          Text(widget.body, style: context.text.bodyMedium),
          if (widget.typeToConfirm case final name?) ...[
            const SizedBox(height: 16),
            AppField(
              controller: _typed,
              label: 'Recopiez « {0} » pour confirmer'.trf([name]),
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: 12),
          CheckRow(
            label: 'Je comprends que rien ne pourra être récupéré.'.tr,
            value: _understood,
            onChanged: (v) => setState(() => _understood = v),
          ),
          const SizedBox(height: 16),
          PillButton(
            key: const ValueKey('confirm-forever'),
            label: widget.confirmLabel,
            icon: AppIcons.trash,
            tone: ButtonTone.danger,
            onPressed: _ok ? () => Navigator.of(context).pop(true) : null,
          ),
          const SizedBox(height: 8),
          PillButton(
            label: 'Annuler'.tr,
            tone: ButtonTone.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

/// Écran d'un événement absent : supprimé (à la corbeille) ou introuvable.
/// Toujours une sortie : restaurer, ou revenir à l'accueil.
class MissingEventScreen extends StatelessWidget {
  const MissingEventScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Accueil'.tr,
        icon: const Icon(AppIcons.back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      ),
    ),
    body: MissingEvent(id: id),
  );
}

/// Contenu de l'état « événement absent », pour les écrans d'un événement.
class MissingEvent extends ConsumerWidget {
  const MissingEvent({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(trashProvider);
    final trashed = ref.read(trashProvider.notifier).of(id);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Mascot(size: 110),
              const SizedBox(height: 16),
              Text(
                trashed != null
                    ? '« {0} » est dans la corbeille'.trf([trashed.event.name])
                    : 'Événement introuvable'.tr,
                textAlign: TextAlign.center,
                style: context.text.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                trashed != null
                    ? 'Restaurez-le pour le retrouver tel quel. Sans restauration, il sera effacé dans {0} jours.'
                          .trf([trashed.daysLeft()])
                    : 'Il a peut-être été supprimé, ou le lien n’est plus valable.'
                          .tr,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (trashed != null) ...[
                PillButton(
                  label: 'Restaurer'.tr,
                  icon: AppIcons.refresh,
                  onPressed: () => ref.read(trashProvider.notifier).restore(id),
                ),
                const SizedBox(height: 8),
              ],
              PillButton(
                label: 'Retour à l’accueil'.tr,
                tone: trashed != null ? ButtonTone.ghost : ButtonTone.primary,
                onPressed: () => context.go(Routes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

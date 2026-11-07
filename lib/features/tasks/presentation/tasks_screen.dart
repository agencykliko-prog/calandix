import 'package:flutter/material.dart';

import '../../events/presentation/event_trash.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../events/presentation/widgets/task_timeline.dart';

enum _Filter { open, done, all }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _Filter _filter = _Filter.open;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: RoundIconButton(
              icon: AppIcons.back,
              tooltip: 'Retour',
              onTap: () => context.pop(),
            ),
          ),
        ),
        leadingWidth: 64,
        title: Text('Rétroplanning'.tr),
      ),
      body: async.when(
        loading: () => const Center(child: MascotLoader.party()),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
        data: (e) => e == null ? MissingEvent(id: widget.id) : _body(e),
      ),
    );
  }

  Widget _body(Event e) {
    final c = context.eventa.tasks;
    final tasks = [...e.tasks]..sort((a, b) => a.due.compareTo(b.due));
    final shown = switch (_filter) {
      _Filter.open => tasks.where((t) => !t.done).toList(),
      _Filter.done => tasks.where((t) => t.done).toList().reversed.toList(),
      _Filter.all => tasks,
    };

    // Regroupement par horizon.
    String bucket(EventTask t) {
      if (t.done) return 'Terminées'.tr;
      final d = daysUntil(t.due);
      if (d < 0) return 'En retard'.tr;
      if (d == 0) return 'Aujourd\'hui'.tr;
      if (d < 7) return 'Cette semaine'.tr;
      if (d < 31) return 'Ce mois-ci'.tr;
      return 'Plus tard'.tr;
    }

    final groups = <String, List<EventTask>>{};
    for (final t in shown) {
      groups.putIfAbsent(bucket(t), () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(e.name, style: context.text.bodySmall),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${e.tasksDone}',
              style: context.text.headlineMedium?.copyWith(color: c.text),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'sur {0} terminées'.trf([e.tasks.length]),
                style: context.text.titleSmall?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                countdownLabel(e.date),
                style: context.text.titleMedium?.copyWith(
                  color: e.category.hue.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Meter(value: e.taskProgress, color: c.base, height: 10),
        const SizedBox(height: 18),
        _Segmented(
          value: _filter,
          onChanged: (f) => setState(() => _filter = f),
          counts: {
            _Filter.open: e.tasks.length - e.tasksDone,
            _Filter.done: e.tasksDone,
            _Filter.all: e.tasks.length,
          },
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              _filter == _Filter.open
                  ? 'Tout est coché. Bravo !'.tr
                  : 'Aucune tâche terminée pour l’instant.'.tr,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.eventa.muted,
              ),
            ),
          ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 14),
            child: Row(
              children: [
                Text(
                  entry.key,
                  style: context.text.titleMedium?.copyWith(
                    color: entry.key == 'En retard'.tr ? Confetti.danger : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value.length}',
                  style: context.text.labelMedium?.copyWith(
                    color: context.eventa.muted,
                  ),
                ),
              ],
            ),
          ),
          TaskTimeline(
            entries: [
              for (final t in entry.value) TimelineEntry(task: t, event: e),
            ],
            onToggle: (en) =>
                ref.read(eventsProvider.notifier).toggleTask(e.id, en.task.id),
          ),
        ],
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.onChanged,
    required this.counts,
  });

  final _Filter value;
  final ValueChanged<_Filter> onChanged;
  final Map<_Filter, int> counts;

  static const _labels = {
    _Filter.open: 'À faire',
    _Filter.done: 'Terminées',
    _Filter.all: 'Toutes',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Confetti.lavender,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / _Filter.values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.base,
                curve: Motion.easeOut,
                left: w * value.index,
                width: w,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Confetti.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Confetti.ink.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final f in _Filter.values)
                    Expanded(
                      child: Pressable(
                        scale: 0.96,
                        onTap: () => onChanged(f),
                        child: Center(
                          child: Text(
                            '${_labels[f]?.tr} · ${counts[f]}',
                            style: context.text.labelMedium?.copyWith(
                              fontWeight: f == value
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: f == value
                                  ? Confetti.ink
                                  : context.eventa.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

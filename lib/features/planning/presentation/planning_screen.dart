import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/auth/session_provider.dart';
import '../../pro/presentation/creator_providers.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../events/presentation/widgets/task_timeline.dart';

/// Une entrée d'agenda, quelle que soit sa source.
@immutable
class AgendaItem {
  const AgendaItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.start,
    required this.durationMin,
    required this.hue,
    this.done,
    this.eventId,
    this.task,
    this.allDay = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime start;
  final int durationMin;
  final Hue hue;

  /// Non nul pour une tâche qu'on peut cocher.
  final bool? done;
  final String? eventId;
  final EventTask? task;
  final bool allDay;

  DateTime get end => start.add(Duration(minutes: durationMin));
}

/// Organisateur : tâches et jours J de ses événements.
/// Creator : prestations confirmées ou en devis.
final agendaProvider = Provider<List<AgendaItem>>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile.isCreator) {
    return [
      for (final r in ref.watch(requestsProvider))
        if (r.status == RequestStatus.confirmed ||
            r.status == RequestStatus.quoted)
          AgendaItem(
            id: r.id,
            title: r.eventName,
            subtitle: '${r.client} · ${r.status.label}',
            start: r.date,
            durationMin: r.durationMin,
            hue: r.status == RequestStatus.confirmed ? Hue.lagoon : Hue.mango,
          ),
    ];
  }
  final events = ref.watch(eventsProvider).value ?? const <Event>[];
  return [
    for (final e in events) ...[
      AgendaItem(
        id: 'jj-${e.id}',
        title: e.name,
        subtitle: 'Jour J · {0}'.trf([e.venue]),
        start: e.date,
        durationMin: 360,
        hue: e.category.hue,
        eventId: e.id,
      ),
      for (final t in e.tasks)
        AgendaItem(
          id: t.id,
          title: t.title,
          subtitle: '${moduleLabel(t.module)} · ${e.name}',
          start: t.due,
          durationMin: t.durationMin,
          hue: e.category.hue,
          done: t.done,
          eventId: e.id,
          task: t,
        ),
    ],
  ];
});

enum AgendaView { day, week, month }

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  AgendaView _view = AgendaView.week;
  DateTime _day = dateOnly(DateTime.now());
  final _mascot = GlobalKey<MascotState>();

  DateTime get _today => dateOnly(DateTime.now());

  void _shift(int dir) {
    setState(() {
      _day = switch (_view) {
        AgendaView.day => _day.add(Duration(days: dir)),
        AgendaView.week => _day.add(Duration(days: 7 * dir)),
        AgendaView.month => DateTime(_day.year, _day.month + dir, 1),
      };
    });
  }

  String get _title {
    final m = DateFormat('MMMM y', L10n.intl).format(_day);
    return m[0].toUpperCase() + m.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(agendaProvider);
    final isCreator = ref.watch(profileProvider).isCreator;
    List<AgendaItem> on(DateTime d) =>
        items.where((i) => dateOnly(i.start) == d).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final dayItems = on(_day);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v.abs() > 300) _shift(v < 0 ? 1 : -1);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            physics: const BouncingScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Text('Agenda'.tr, style: context.text.headlineMedium),
                    // La mascotte somnole les jours libres et fête chaque
                    // tâche cochée.
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Mascot(
                        key: _mascot,
                        size: 46,
                        legs: false,
                        arms: false,
                        mood: dayItems.isEmpty
                            ? MascotMood.sleepy
                            : MascotMood.happy,
                        onTap: () =>
                            ref.read(soundProvider).play(Sfx.notification),
                      ),
                    ),
                    const Spacer(),
                    if (_day != _today)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PillButton(
                          label: 'Aujourd\'hui'.tr,
                          tone: ButtonTone.ghost,
                          expand: false,
                          height: 38,
                          onPressed: () => setState(() => _day = _today),
                        ),
                      ),
                    if (!isCreator)
                      RoundIconButton(
                        icon: AppIcons.add,
                        tooltip: 'Ajouter une activité',
                        background: Confetti.ink,
                        foreground: Confetti.onInk,
                        onTap: () => showActivitySheet(context, ref, day: _day),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _ViewSwitch(
                  value: _view,
                  onChanged: (v) => setState(() => _view = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_title, style: context.text.titleLarge),
                    ),
                    _Chevron(
                      icon: AppIcons.chevronLeft,
                      onTap: () => _shift(-1),
                    ),
                    const SizedBox(width: 4),
                    _Chevron(icon: AppIcons.chevron, onTap: () => _shift(1)),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Motion.base,
                switchInCurve: Motion.easeOut,
                child: KeyedSubtree(
                  key: ValueKey(
                    '$_view-${_view == AgendaView.month ? '${_day.year}${_day.month}' : _weekStart(_day)}',
                  ),
                  child: switch (_view) {
                    AgendaView.month => _MonthGrid(
                      month: _day,
                      selected: _day,
                      today: _today,
                      count: (d) => on(d).length,
                      onPick: (d) => setState(() => _day = d),
                    ),
                    _ => _WeekStrip(
                      start: _weekStart(_day),
                      selected: _day,
                      today: _today,
                      count: (d) => on(d).length,
                      onPick: (d) => setState(() => _day = d),
                    ),
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Divider(height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    Text(_dayTitle(_day), style: context.text.titleMedium),
                    const Spacer(),
                    Text(
                      dayItems.isEmpty
                          ? 'Libre'.tr
                          : (dayItems.length > 1
                                    ? '{0} activités'
                                    : '{0} activité')
                                .trf([dayItems.length]),
                      style: context.text.labelMedium?.copyWith(
                        color: Confetti.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Motion.base,
                switchInCurve: Motion.easeOut,
                child: Padding(
                  key: ValueKey(_day),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: dayItems.isEmpty
                      ? _EmptyDay(
                          onAdd: isCreator
                              ? null
                              : () =>
                                    showActivitySheet(context, ref, day: _day),
                        )
                      : Column(
                          children: [
                            for (final it in dayItems)
                              _AgendaRow(
                                item: it,
                                expanded: _view == AgendaView.day,
                                onToggle: it.task == null
                                    ? null
                                    : () {
                                        // Le son de la tâche terminée est
                                        // joué par la liste des événements.
                                        if (!it.task!.done) {
                                          _mascot.currentState?.jump();
                                        }
                                        ref
                                            .read(eventsProvider.notifier)
                                            .toggleTask(
                                              it.eventId!,
                                              it.task!.id,
                                            );
                                      },
                                onTap: it.task == null
                                    ? null
                                    : () => showActivitySheet(
                                        context,
                                        ref,
                                        item: it,
                                      ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _weekStart(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  String _dayTitle(DateTime d) {
    if (d == _today) return 'Aujourd\'hui'.tr;
    if (d == _today.add(const Duration(days: 1))) return 'Demain'.tr;
    final s = DateFormat('EEEE d MMMM', L10n.intl).format(d);
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.value, required this.onChanged});

  final AgendaView value;
  final ValueChanged<AgendaView> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      AgendaView.day: 'Jour',
      AgendaView.week: 'Semaine',
      AgendaView.month: 'Mois',
    };
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Confetti.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / 3;
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
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in AgendaView.values)
                    Expanded(
                      child: Pressable(
                        scale: 0.97,
                        onTap: () => onChanged(v),
                        child: Center(
                          child: Text(
                            labels[v]!,
                            style: context.text.labelMedium?.copyWith(
                              color: v == value
                                  ? Confetti.ink
                                  : Confetti.inkMuted,
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

class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.9,
    child: SizedBox(
      width: 36,
      height: 36,
      child: Icon(icon, size: 18, color: Confetti.ink),
    ),
  );
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.start,
    required this.selected,
    required this.today,
    required this.count,
    required this.onPick,
  });

  final DateTime start;
  final DateTime selected;
  final DateTime today;
  final int Function(DateTime) count;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _DayCell(
                day: start.add(Duration(days: i)),
                selected: selected,
                today: today,
                count: count,
                onPick: onPick,
                showWeekday: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.count,
    required this.onPick,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final int Function(DateTime) count;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final start = first.subtract(Duration(days: first.weekday - 1));
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((first.weekday - 1 + daysInMonth) / 7).ceil();
    const initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              for (final l in initials)
                Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: context.text.labelSmall?.copyWith(
                        color: Confetti.inkFaint,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final d = start.add(Duration(days: r * 7 + c));
                        return Opacity(
                          opacity: d.month == month.month ? 1 : 0.3,
                          child: _DayCell(
                            day: d,
                            selected: selected,
                            today: today,
                            count: count,
                            onPick: onPick,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.count,
    required this.onPick,
    this.showWeekday = false,
  });

  final DateTime day;
  final DateTime selected;
  final DateTime today;
  final int Function(DateTime) count;
  final ValueChanged<DateTime> onPick;
  final bool showWeekday;

  @override
  Widget build(BuildContext context) {
    final on = day == selected;
    final isToday = day == today;
    final n = count(day);
    return Pressable(
      scale: 0.92,
      onTap: () => onPick(day),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            if (showWeekday) ...[
              Text(
                weekdayShort(day),
                style: context.text.labelSmall?.copyWith(
                  color: Confetti.inkFaint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
            ],
            AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.easeOut,
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Confetti.ink : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !on
                    ? Border.all(color: Confetti.coral, width: 1.5)
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: context.text.titleSmall?.copyWith(
                  color: on
                      ? Confetti.onInk
                      : (isToday ? Confetti.coralDeep : Confetti.ink),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < n.clamp(0, 3); i++)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: on ? Confetti.coral : Confetti.inkMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.item,
    required this.expanded,
    this.onToggle,
    this.onTap,
  });

  final AgendaItem item;
  final bool expanded;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = item.done ?? false;
    final dur = item.durationMin >= 60
        ? '${item.durationMin ~/ 60} h${item.durationMin % 60 == 0 ? '' : ' ${item.durationMin % 60}'}'
        : '${item.durationMin} min';
    return Pressable(
      scale: 0.99,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: expanded ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: Confetti.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Confetti.line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeOf(item.start),
                    style: context.text.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    dur,
                    style: context.text.labelSmall?.copyWith(
                      color: Confetti.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 3,
              height: expanded ? 44 : 34,
              decoration: BoxDecoration(
                color: done ? item.hue.tint : item.hue.base,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: Motion.fast,
                    style: context.text.titleSmall!.copyWith(
                      color: done ? Confetti.inkFaint : Confetti.ink,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expanded
                        ? '${timeOf(item.start)} – ${timeOf(item.end)} · ${item.subtitle}'
                        : item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            if (onToggle != null)
              Pressable(
                scale: 0.85,
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: Motion.fast,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? Confetti.ink : Colors.transparent,
                    border: Border.all(
                      color: done ? Confetti.ink : Confetti.border,
                      width: 1.6,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          AppIcons.check,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Mascot(
            size: 88,
            color: MascotColor.organizer,
            mood: MascotMood.sleepy,
          ),
          const SizedBox(height: 10),
          Text('Rien de prévu'.tr, style: context.text.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Profitez-en, ou planifiez une activité.'.tr,
            style: context.text.bodySmall,
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 14),
            PillButton(
              label: 'Ajouter'.tr,
              icon: AppIcons.add,
              tone: ButtonTone.ghost,
              expand: false,
              height: 40,
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ajout ou modification d'une activité (tâche datée d'un événement).
Future<void> showActivitySheet(
  BuildContext context,
  WidgetRef ref, {
  DateTime? day,
  AgendaItem? item,
}) {
  return showEventaSheet<void>(
    context,
    builder: (_) => _ActivitySheet(day: day, item: item),
  );
}

class _ActivitySheet extends ConsumerStatefulWidget {
  const _ActivitySheet({this.day, this.item});

  final DateTime? day;
  final AgendaItem? item;

  @override
  ConsumerState<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends ConsumerState<_ActivitySheet> {
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late String? _eventId = widget.item?.eventId;
  late DateTime _date = dateOnly(
    widget.item?.start ?? widget.day ?? DateTime.now(),
  );
  late TimeOfDay _time = widget.item == null
      ? const TimeOfDay(hour: 10, minute: 0)
      : TimeOfDay.fromDateTime(widget.item!.start);
  late int _duration = widget.item?.durationMin ?? 60;

  bool get _editing => widget.item != null;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final events = ref.read(eventsProvider).value ?? const <Event>[];
    final eventId = _eventId ?? (events.isEmpty ? null : events.first.id);
    if (_title.text.trim().isEmpty || eventId == null) {
      toast(context, 'Ajoutez un titre'.tr, icon: AppIcons.info);
      return;
    }
    final due = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final n = ref.read(eventsProvider.notifier);
    if (_editing) {
      final t = widget.item!.task!;
      if (eventId != widget.item!.eventId) {
        n.removeTask(widget.item!.eventId!, t.id);
        n.addTask(
          eventId,
          t.copyWith(
            title: _title.text.trim(),
            due: due,
            durationMin: _duration,
          ),
        );
      } else {
        n.updateTask(
          eventId,
          t.copyWith(
            title: _title.text.trim(),
            due: due,
            durationMin: _duration,
          ),
        );
      }
    } else {
      n.addTask(
        eventId,
        EventTask(
          id: 'a-${DateTime.now().microsecondsSinceEpoch}',
          title: _title.text.trim(),
          due: due,
          module: Module.tasks,
          durationMin: _duration,
          assigneeId: 'awa',
          icon: AppIcons.calendarCheck,
        ),
      );
    }
    Navigator.of(context).pop();
    toast(
      context,
      _editing
          ? 'Activité modifiée'.tr
          : 'Activité ajoutée à {0}'.trf([timeOf(due)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider).value ?? const <Event>[];
    _eventId ??= events.isEmpty ? null : events.first.id;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editing ? 'Modifier l’activité'.tr : 'Nouvelle activité'.tr,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: 16),
          AppField(
            label: 'Titre'.tr,
            controller: _title,
            hint: 'Ex. Dégustation chez le traiteur'.tr,
            autofocus: !_editing,
          ),
          const SizedBox(height: 14),
          AppSelect<String>(
            label: 'Événement'.tr,
            value: _eventId,
            options: [for (final e in events) e.id],
            labelOf: (id) => events.firstWhere((e) => e.id == id).name,
            onChanged: (id) => setState(() => _eventId = id),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PickerField(
                  label: 'Date'.tr,
                  value: mediumDate(_date),
                  icon: AppIcons.agenda,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerField(
                  label: 'Heure'.tr,
                  value: _time.format(context),
                  icon: AppIcons.clock,
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (t != null) setState(() => _time = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppSelect<int>(
            label: 'Durée'.tr,
            value: _duration,
            options: const [15, 30, 45, 60, 90, 120, 180, 240],
            labelOf: (m) => m < 60
                ? '$m min'
                : '${m ~/ 60} h${m % 60 == 0 ? '' : ' ${m % 60}'}',
            onChanged: (m) => setState(() => _duration = m),
          ),
          const SizedBox(height: 20),
          PillButton(
            label: _editing ? 'Enregistrer'.tr : 'Ajouter'.tr,
            tone: ButtonTone.dark,
            onPressed: _save,
          ),
          if (_editing) ...[
            const SizedBox(height: 8),
            PillButton(
              label: 'Supprimer'.tr,
              icon: AppIcons.trash,
              tone: ButtonTone.ghost,
              onPressed: () {
                ref
                    .read(eventsProvider.notifier)
                    .removeTask(widget.item!.eventId!, widget.item!.task!.id);
                Navigator.of(context).pop();
                toast(context, 'Activité supprimée'.tr, icon: AppIcons.trash);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        Pressable(
          scale: 0.98,
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Confetti.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Confetti.line),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Confetti.inkMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(value, style: context.text.bodyLarge)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

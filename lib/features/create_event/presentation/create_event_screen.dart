import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/data/event_templates.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../events/presentation/widgets/task_timeline.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../premium/presentation/premium_nudge.dart';
import '../../premium/presentation/paywall.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _pages = PageController();
  int _step = 0;

  EventCategory? _category;
  final _subs = <String>{};
  final _name = TextEditingController();
  final _city = TextEditingController(text: 'Abidjan'.tr);
  DateTime _date = DateTime.now().add(const Duration(days: 60));
  double _guests = 80;
  int _budget = 2000000;
  Event? _draft;
  bool _generating = false;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 420),
      curve: Motion.drawer,
    );
  }

  void _pickCategory(EventCategory c) {
    HapticFeedback.selectionClick();
    setState(() {
      _category = c;
      _subs.clear();
      if (_name.text.isEmpty ||
          _name.text.startsWith('Mon ') ||
          _name.text.startsWith('Ma ')) {
        _name.text = switch (c) {
          EventCategory.wedding => 'Mon mariage'.tr,
          EventCategory.birthday => 'Mon anniversaire'.tr,
          EventCategory.baby => 'Ma baby shower'.tr,
          EventCategory.friends => 'Mon EVJF'.tr,
          EventCategory.outing => 'Ma sortie'.tr,
          EventCategory.pro => 'Mon séminaire'.tr,
          _ => 'Mon événement'.tr,
        };
      }
    });
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    ref.read(soundProvider).play(Sfx.success);
    maybeShowPremiumNudge(
      context,
      ref,
      PremiumNudge.newEvent,
      delay: const Duration(milliseconds: 1800),
    );
    setState(() {
      _generating = false;
      _draft = EventTemplates.create(
        category: _category!,
        subcategories: _subs.toList(),
        name: _name.text.trim().isEmpty
            ? 'Mon événement'.tr
            : _name.text.trim(),
        date: DateTime(_date.year, _date.month, _date.day, 16),
        city: _city.text.trim().isEmpty ? 'Abidjan'.tr : _city.text.trim(),
        guests: _guests.round(),
        budget: _budget,
      );
    });
    _go(2);
  }

  /// Découverte : 4 événements actifs à la fois ; au-delà, un abonnement.
  Future<void> _open() async {
    final limit = ref.read(planProvider).activeEvents;
    final today = DateUtils.dateOnly(DateTime.now());
    final active = (ref.read(eventsProvider).value ?? const <Event>[])
        .where((x) => !x.date.isBefore(today))
        .length;
    if (limit != null && active >= limit) {
      await requirePremium(
        context,
        ref,
        feature: PremiumFeature.events,
        onUnlocked: _save,
      );
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    final e = _draft!;
    try {
      final id = await ref.read(eventsProvider.notifier).add(e);
      if (!mounted) return;
      context.pushReplacement(Routes.event(id));
    } catch (_) {
      if (!mounted) return;
      toast(
        context,
        'Enregistrement impossible. Vérifiez votre connexion puis réessayez.'
            .tr,
        icon: AppIcons.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hue = _category?.hue ?? Hue.coral;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: _step == 0 ? AppIcons.close : AppIcons.back,
                    tooltip: _step == 0 ? 'Fermer'.tr : 'Retour'.tr,
                    onTap: () => _step == 0 ? context.pop() : _go(_step - 1),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(
                            child: AnimatedContainer(
                              duration: Motion.base,
                              curve: Motion.easeOut,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i <= _step
                                    ? hue.base
                                    : Confetti.lavender,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _categoryStep(),
                  _detailsStep(),
                  _draft == null ? const SizedBox() : _planStep(_draft!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryStep() {
    final c = _category;
    return AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.easeOut,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: c == null ? _categoryGrid() : _subcategories(c),
    );
  }

  Widget _categoryGrid() {
    return ListView(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('Que célébrez-vous ?'.tr, style: context.text.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'On prépare la checklist et la répartition du budget selon le type.'
              .tr,
          style: context.text.bodyMedium?.copyWith(color: context.eventa.muted),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            for (var i = 0; i < EventCategory.values.length; i++)
              Entrance(
                index: i,
                child: _CategoryTile(
                  category: EventCategory.values[i],
                  selected: _category == EventCategory.values[i],
                  onTap: () => _pickCategory(EventCategory.values[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Sous-catégories affichées dès qu'un type est choisi (un seul choix :
  /// un mariage peut réunir dot, civil et religieux).
  Widget _subcategories(EventCategory c) {
    final h = c.hue;
    return ListView(
      key: ValueKey(c),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Row(
          children: [
            IconTile(icon: c.icon, hue: h, size: 48, solid: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.label, style: context.text.headlineSmall),
                  Pressable(
                    onTap: () => setState(() => _category = null),
                    child: Text(
                      'Changer de type'.tr,
                      style: context.text.labelMedium?.copyWith(
                        color: Confetti.coralDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Précisez (plusieurs choix possibles)'.tr,
          style: context.text.labelMedium,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < c.subcategories.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Entrance(
              index: i,
              child: Pressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    final s = c.subcategories[i];
                    // Un seul choix : toucher à nouveau le retire.
                    final was = _subs.contains(s);
                    _subs.clear();
                    if (!was) {
                      _subs.add(s);
                      _name.text = s;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: _subs.contains(c.subcategories[i])
                        ? h.tint
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _subs.contains(c.subcategories[i])
                          ? h.base
                          : Confetti.line,
                      width: _subs.contains(c.subcategories[i]) ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.subcategories[i],
                          style: context.text.titleMedium?.copyWith(
                            fontSize: 17,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: Motion.fast,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _subs.contains(c.subcategories[i])
                              ? h.base
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _subs.contains(c.subcategories[i])
                                ? h.base
                                : Confetti.border,
                            width: 1.6,
                          ),
                        ),
                        child: _subs.contains(c.subcategories[i])
                            ? Icon(AppIcons.check, size: 13, color: h.onBase)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        PillButton(
          label: _subs.isEmpty ? 'Continuer sans préciser'.tr : 'Continuer'.tr,
          trailingIcon: AppIcons.forward,
          tone: _subs.isEmpty ? ButtonTone.ghost : ButtonTone.primary,
          onPressed: () => _go(1),
        ),
      ],
    );
  }

  Widget _detailsStep() {
    const quick = [500000, 1000000, 2000000, 5000000, 12500000];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('Les essentiels'.tr, style: context.text.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Tout reste modifiable ensuite.'.tr,
          style: context.text.bodyMedium?.copyWith(color: context.eventa.muted),
        ),
        const SizedBox(height: 22),
        _Label('Nom de l’événement'.tr),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Date'.tr),
                  Pressable(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Confetti.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Confetti.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(AppIcons.calendarCheck, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            mediumDate(_date),
                            style: context.text.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Ville'.tr),
                  TextField(controller: _city),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _Label('Invités'.tr),
            const Spacer(),
            Text('${_guests.round()}', style: context.text.titleMedium),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Confetti.coral,
            inactiveTrackColor: Confetti.lavender,
            thumbColor: Confetti.coral,
            overlayColor: Confetti.coral.withValues(alpha: 0.12),
            trackHeight: 6,
          ),
          child: Slider(
            value: _guests,
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: (v) => setState(() => _guests = v),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Label('Budget cible'.tr),
            const Spacer(),
            Text(
              fcfa(_budget),
              style: context.text.titleMedium?.copyWith(
                color: Confetti.lagoonDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in quick)
              Pressable(
                onTap: () => setState(() => _budget = q),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _budget == q
                        ? Confetti.lagoonDeep
                        : Confetti.lagoonTint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    fcfaCompact(q),
                    style: context.text.labelMedium?.copyWith(
                      color: _budget == q ? Colors.white : Confetti.lagoonText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Soit {0} par invité.'.trf([fcfa((_budget / _guests).round())]),
          style: context.text.bodySmall,
        ),
        const SizedBox(height: 28),
        PillButton(
          label: 'Générer mon plan'.tr,
          icon: AppIcons.sparkle,
          loading: _generating,
          onPressed: _generate,
        ),
      ],
    );
  }

  Widget _planStep(Event e) {
    final hue = e.category.hue;
    final tasks = [...e.tasks]..sort((a, b) => a.due.compareTo(b.due));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Entrance(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: hue.base,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(e.category.icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Entrance(
          index: 1,
          child: Text(
            'Votre plan est prêt'.tr,
            style: context.text.headlineMedium,
          ),
        ),
        const SizedBox(height: 6),
        Entrance(
          index: 2,
          child: Text(
            '{0} tâches planifiées à rebours jusqu’au {1} et {2} postes de budget répartis sur {3}.'
                .trf([
                  e.tasks.length,
                  mediumDate(e.date),
                  e.budget.length,
                  fcfa(e.targetBudget),
                ]),
            style: context.text.bodyMedium?.copyWith(
              color: context.eventa.muted,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Entrance(
          index: 3,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final l in e.budget)
                Tag(
                  label: '${l.category.label} ${fcfaCompact(l.estimated)}',
                  hue: Hue.lagoon,
                  icon: l.category.icon,
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Entrance(
          index: 4,
          child: TaskTimeline(
            entries: [
              for (final t in tasks.take(5)) TimelineEntry(task: t, event: e),
            ],
            onToggle: (_) {},
          ),
        ),
        if (tasks.length > 5)
          Padding(
            padding: const EdgeInsets.only(left: 112, bottom: 16),
            child: Text(
              '+ {0} autres étapes'.trf([tasks.length - 5]),
              style: context.text.labelMedium?.copyWith(
                color: context.eventa.muted,
              ),
            ),
          ),
        PillButton(
          label: 'Ouvrir le dashboard'.tr,
          icon: AppIcons.forward,
          onPressed: _open,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: context.text.labelMedium),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final EventCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = category.hue;
    return Pressable(
      onTap: onTap,
      semanticLabel: category.label,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? h.base : h.tint,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              category.icon,
              color: selected ? Colors.white : h.text,
              size: 24,
            ),
            const Spacer(),
            Text(
              category.label,
              maxLines: 2,
              style: context.text.titleMedium?.copyWith(
                fontSize: 16.5,
                height: 1.15,
                color: selected ? Colors.white : h.deep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/ui.dart';
import '../../booking/presentation/quote_compare_screen.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/event_trash.dart';
import '../../events/presentation/events_providers.dart';
import '../../events/presentation/widgets/event_cover.dart';
import '../../events/presentation/widgets/task_timeline.dart';
import '../../export/presentation/export_sheet.dart';
import '../../premium/presentation/paywall.dart';
import 'collaborators_sheet.dart';
import 'widgets/budget_overview.dart';
import 'widgets/guests_panel.dart';
import 'widgets/team_panel.dart';
import '../../marketplace/data/vendor_media.dart';

class EventDashboardScreen extends ConsumerWidget {
  const EventDashboardScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(eventProvider(id))
        .when(
          loading: () =>
              const Scaffold(body: Center(child: MascotLoader.party())),
          error: (e, _) => Scaffold(
            body: ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
          ),
          data: (event) => event == null
              ? MissingEventScreen(id: id)
              : _Dashboard(event: event),
        );
  }
}

class _Dashboard extends ConsumerStatefulWidget {
  const _Dashboard({required this.event});

  final Event event;

  @override
  ConsumerState<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<_Dashboard> {
  static const _coverH = 330.0;
  final _scroll = ScrollController();
  final _vendorsKey = GlobalKey();
  final _teamKey = GlobalKey();
  bool _collapsed = false;

  /// La pastille « Couverture » s'efface dès que la photo se replie, pour
  /// ne pas glisser sous les boutons de la barre.
  bool _coverTools = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > _coverH - 110;
      final t = _scroll.offset < 60;
      if (c != _collapsed || t != _coverTools) {
        setState(() {
          _collapsed = c;
          _coverTools = t;
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 520),
      curve: Motion.easeInOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      alignment: 0.08,
    );
  }

  void _openAgent(Event e) => requirePremium(
    context,
    ref,
    feature: PremiumFeature.agent,
    eventId: e.id,
    onUnlocked: () => context.push(Routes.agent(e.id)),
  );

  /// Ouvre un outil de l'offre, ou propose l'offre qui le débloque.
  void _premium(Event e, PremiumFeature feature, String route) =>
      requirePremium(
        context,
        ref,
        feature: feature,
        eventId: e.id,
        onUnlocked: () => context.push(route),
      );

  /// Options de l'événement : partage, page, statistiques, suppression.
  void _options(Event e) => showEventaSheet<void>(
    context,
    builder: (sheet) {
      Widget row(
        IconData icon,
        String label,
        VoidCallback onTap, {
        bool danger = false,
        Key? key,
      }) => ListTile(
        key: key,
        leading: Icon(icon, color: danger ? Confetti.coralDeep : Confetti.ink),
        title: Text(
          label,
          style: danger ? TextStyle(color: Confetti.coralDeep) : null,
        ),
        onTap: () {
          Navigator.of(sheet).pop();
          onTap();
        },
      );
      return Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ref.read(canEditEventProvider(e.id)))
                row(
                  AppIcons.image,
                  'Changer la couverture'.tr,
                  () => showCoverPicker(context, e),
                  key: const ValueKey('event-cover'),
                ),
              row(
                AppIcons.userPlus,
                'Inviter des co-organisateurs'.tr,
                () => showCollaboratorsSheet(context, e.id),
              ),
              row(
                AppIcons.globe,
                'Page de l’événement'.tr,
                () => context.push(Routes.site(e.id)),
              ),
              row(
                AppIcons.headset,
                'Concierge'.tr,
                () => _premium(
                  e,
                  PremiumFeature.concierge,
                  Routes.concierge(e.id),
                ),
              ),
              row(
                AppIcons.images,
                'Album'.tr,
                () => _premium(e, PremiumFeature.album, Routes.album(e.id)),
              ),
              row(
                AppIcons.chart,
                'Statistiques du budget'.tr,
                () => context.push(Routes.budgetStats(e.id)),
              ),
              const Divider(height: 16),
              row(
                AppIcons.trash,
                'Supprimer l’événement'.tr,
                () => confirmTrashEvent(context, ref, e),
                danger: true,
                key: const ValueKey('event-delete'),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final open = e.tasks.where((t) => !t.done).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    final bookings = ref
        .watch(bookingsProvider)
        .where((b) => b.eventId == e.id)
        .toList();
    final btnBg = _collapsed
        ? Confetti.surface
        : Colors.white.withValues(alpha: 0.9);

    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: _coverH,
            backgroundColor: Confetti.cream,
            automaticallyImplyLeading: false,
            titleSpacing: 12,
            title: Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  background: btnBg,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: _collapsed ? 1 : 0,
                    child: Text(e.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
                RoundIconButton(
                  icon: AppIcons.userPlus,
                  tooltip: 'Partager l’événement',
                  background: btnBg,
                  onTap: () => showCollaboratorsSheet(context, e.id),
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  key: const ValueKey('event-more'),
                  icon: AppIcons.more,
                  tooltip: 'Options de l’événement',
                  background: btnBg,
                  onTap: () => _options(e),
                ),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _Cover(
                event: e,
                showEdit: _coverTools,
                onEdit: ref.watch(canEditEventProvider(e.id))
                    ? () => showCoverPicker(context, e)
                    : null,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Entrance(child: _CountdownPanel(event: e)),
                  const SizedBox(height: 12),
                  Entrance(
                    index: 1,
                    child: Row(
                      children: [
                        _Action(
                          icon: AppIcons.sparkle,
                          label: 'Agent IA'.tr,
                          onTap: () => _openAgent(e),
                        ),
                        _Action(
                          icon: AppIcons.lock,
                          label: 'Coffre-fort'.tr,
                          onTap: () => context.push(Routes.vault),
                        ),
                        _Action(
                          icon: AppIcons.download,
                          label: 'Exporter'.tr,
                          onTap: () => showExportSheet(context, e.id),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Entrance(
                    index: 2,
                    child: _ModuleGrid(
                      event: e,
                      onBudget: () => context.push(Routes.budget(e.id)),
                      onTasks: () => context.push(Routes.tasks(e.id)),
                      onVendors: () => _scrollTo(_vendorsKey),
                      onTeam: () => _scrollTo(_teamKey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionTitle(
              'Budget'.tr,
              action: 'Gérer'.tr,
              onAction: () => context.push(Routes.budget(e.id)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: BudgetOverview(
                event: e,
                onTap: () => context.push(Routes.budget(e.id)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionTitle(
              'Prochaines étapes'.tr,
              action: 'Rétroplanning'.tr,
              onAction: () => context.push(Routes.tasks(e.id)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: open.isEmpty
                  ? Text(
                      'Tout est prêt. Profitez de la fête !'.tr,
                      style: context.text.bodyMedium,
                    )
                  : TaskTimeline(
                      entries: [
                        for (final t in open.take(4))
                          TimelineEntry(task: t, event: e),
                      ],
                      onToggle: (entry) => ref
                          .read(eventsProvider.notifier)
                          .toggleTask(e.id, entry.task.id),
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: PillButton(
                label: 'Voir les {0} tâches'.trf([e.tasks.length]),
                tone: ButtonTone.ghost,
                height: 48,
                onPressed: () => context.push(Routes.tasks(e.id)),
              ),
            ),
          ),
          if (bookings.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionTitle(
                'Réservations'.tr,
                action: ref.watch(quoteGroupsProvider(e.id)).isEmpty
                    ? null
                    : 'Comparer les devis'.tr,
                onAction: () => context.push(Routes.compareQuotes(e.id)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: bookings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = bookings[i];
                  return Panel(
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.push(Routes.booking(b.id)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: VendorPhoto(
                            b.vendor.image,
                            width: 44,
                            height: 44,
                            cacheWidth: 120,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.vendor.name,
                                style: context.text.titleSmall,
                              ),
                              Text(
                                'Étape {0}/7 · {1}'.trf([
                                  b.step.index + 1,
                                  b.step.status,
                                ]),
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          AppIcons.chevron,
                          size: 16,
                          color: Confetti.inkFaint,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          SliverToBoxAdapter(
            key: _vendorsKey,
            child: SectionTitle(
              'Prestataires'.tr,
              action: 'Exporter'.tr,
              onAction: () =>
                  showExportSheet(context, e.id, only: ExportKind.vendors),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: e.vendors.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  if (i == e.vendors.length) {
                    return Pressable(
                      onTap: () => context.go(Routes.explore),
                      child: Container(
                        width: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Confetti.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.add, color: Confetti.inkMuted),
                            const SizedBox(height: 6),
                            Text(
                              'Ajouter un\nprestataire'.tr,
                              textAlign: TextAlign.center,
                              style: context.text.labelMedium?.copyWith(
                                color: Confetti.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return _EventVendorCard(ev: e.vendors[i]);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionTitle(
              'Invités & RSVP'.tr,
              action: 'Voir la liste'.tr,
              onAction: () => context.push(Routes.guests(e.id)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: GuestsPanel(
                guests: e.guests,
                onPending: () => context.push(Routes.guests(e.id)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            key: _teamKey,
            child: SectionTitle(
              'Équipe'.tr,
              action: 'Gérer les accès'.tr,
              onAction: () => showCollaboratorsSheet(context, e.id),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: TeamPanel(event: e)),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 40 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.event, this.onEdit, this.showEdit = true});

  final Event event;

  /// Changer la couverture (organisateurs uniquement).
  final VoidCallback? onEdit;
  final bool showEdit;

  @override
  Widget build(BuildContext context) {
    final hue = event.category.hue;
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'cover-${event.id}',
          child: EventCoverImage(event.cover, category: event.category),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.transparent,
                hue.deep.withValues(alpha: 0.9),
              ],
              stops: const [0, 0.35, 1],
            ),
          ),
        ),
        if (onEdit != null)
          Positioned(
            right: 16,
            top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            child: IgnorePointer(
              ignoring: !showEdit,
              child: AnimatedOpacity(
                duration: Motion.fast,
                opacity: showEdit ? 1 : 0,
                child: _CoverButton(onTap: onEdit!),
              ),
            ),
          ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Tag(
                    label: event.category.label,
                    hue: hue,
                    icon: event.category.icon,
                    solid: true,
                  ),
                  for (final s in event.subcategories)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        s,
                        style: context.text.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                event.name,
                style: context.text.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_cap(longDate(event.date))} · ${timeOf(event.date)}\n${event.venue}, ${event.city}',
                style: context.text.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _CountdownPanel extends StatelessWidget {
  const _CountdownPanel({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final hue = event.category.hue;
    final progress = event.overallProgress;
    return Panel(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                countdownLabel(event.date),
                style: context.text.displaySmall?.copyWith(
                  color: hue.text,
                  fontSize: 42,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'avant la fête'.tr,
                  style: context.text.titleSmall?.copyWith(
                    color: context.eventa.muted,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Avancement global'.tr, style: context.text.labelMedium),
              const Spacer(),
              Text(
                '${(progress * 100).round()} %',
                style: context.text.titleSmall?.copyWith(color: hue.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Meter(value: progress, color: hue.base, height: 8),
        ],
      ),
    );
  }
}

/// Raccourci neutre : surface claire, bordure fine, icône à l'encre.
class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Pressable(
          onTap: onTap,
          semanticLabel: label,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: _neutralBox(radius: 16),
            // Icône et libellé côte à côte quand la place le permet, l'un
            // sous l'autre sur téléphone : le libellé n'est jamais tronqué.
            child: LayoutBuilder(
              builder: (context, box) {
                final text = Text(
                  label,
                  maxLines: 1,
                  style: context.text.labelMedium?.copyWith(
                    color: Confetti.ink,
                    fontWeight: FontWeight.w600,
                  ),
                );
                final glyph = Icon(icon, size: 18, color: Confetti.ink);
                if (box.maxWidth >= 140) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      glyph,
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(fit: BoxFit.scaleDown, child: text),
                      ),
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    glyph,
                    const SizedBox(height: 6),
                    FittedBox(fit: BoxFit.scaleDown, child: text),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Surface commune des tuiles du tableau de bord : claire, bordure fine,
/// ombre très légère (plus marquée en mode sombre).
BoxDecoration _neutralBox({double radius = 18}) => BoxDecoration(
  color: Confetti.surface,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Confetti.line),
  boxShadow: [
    BoxShadow(
      color: Confetti.inkFixed.withValues(alpha: Confetti.dark ? 0.28 : 0.035),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ],
);

/// Les quatre indicateurs de l'événement : surfaces neutres, valeur lisible,
/// libellé, précision et petite jauge. Deux colonnes sur téléphone, quatre
/// sur grand écran.
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({
    required this.event,
    required this.onBudget,
    required this.onTasks,
    required this.onVendors,
    required this.onTeam,
  });

  final Event event;
  final VoidCallback onBudget;
  final VoidCallback onTasks;
  final VoidCallback onVendors;
  final VoidCallback onTeam;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final tiles = [
      _ModuleTile(
        icon: AppIcons.wallet,
        label: 'Budget'.tr,
        value: '${(e.committedRatio * 100).round()} %',
        caption: 'engagé'.tr,
        progress: e.committedRatio,
        alert: e.committedRatio > 1,
        onTap: onBudget,
      ),
      _ModuleTile(
        icon: AppIcons.tasks,
        label: 'Tâches'.tr,
        value: '${e.tasksDone} / ${e.tasks.length}',
        caption: 'terminées'.tr,
        progress: e.taskProgress,
        onTap: onTasks,
      ),
      _ModuleTile(
        icon: AppIcons.vendors,
        label: 'Prestataires'.tr,
        value: '{0} confirmés'.trf([e.vendorsConfirmed]),
        caption: 'sur {0}'.trf([e.vendors.length]),
        progress: e.vendors.isEmpty ? 0 : e.vendorsConfirmed / e.vendors.length,
        onTap: onVendors,
      ),
      _ModuleTile(
        icon: AppIcons.team,
        label: 'Équipe'.tr,
        value: '{0} en ligne'.trf([e.onlineCount]),
        caption: '{0} membres'.trf([e.team.length]),
        footer: AvatarStack(
          images: [for (final m in e.team) m.avatar],
          size: 20,
          ring: Confetti.surface,
        ),
        onTap: onTeam,
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 680 ? 4 : 2;
        const gap = 10.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.onTap,
    this.progress,
    this.alert = false,
    this.footer,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final VoidCallback onTap;

  /// Jauge de 0 à 1 ; [footer] la remplace (avatars de l'équipe).
  final double? progress;
  final bool alert;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label : $value $caption',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _neutralBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Confetti.lavender,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: Confetti.ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(
                      color: Confetti.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(AppIcons.chevron, size: 14, color: Confetti.inkFaint),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: context.text.titleLarge?.copyWith(
                  color: alert ? Confetti.danger : Confetti.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: Confetti.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    footer ??
                    Meter(
                      value: progress ?? 0,
                      color: alert ? Confetti.danger : Confetti.ink,
                      track: Confetti.lavender,
                      height: 5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille givrée « Couverture » posée sur la photo.
class _CoverButton extends StatelessWidget {
  const _CoverButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: const ValueKey('cover-edit'),
      onTap: onTap,
      semanticLabel: 'Changer la couverture'.tr,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.camera, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Couverture'.tr,
              style: context.text.labelMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventVendorCard extends StatelessWidget {
  const _EventVendorCard({required this.ev});

  final EventVendor ev;

  @override
  Widget build(BuildContext context) {
    final v = ev.vendor;
    final hue = switch (ev.status) {
      VendorStatus.contacted => Hue.ink,
      VendorStatus.quoted => Hue.mango,
      VendorStatus.booked => Hue.violet,
      VendorStatus.paid => Hue.lagoon,
    };
    return Pressable(
      onTap: () => context.push(Routes.vendor(v.id)),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 100,
                width: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VendorPhoto(v.image, cacheWidth: 400),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Tag(label: ev.status.label, hue: hue, solid: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              v.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
            Text(
              ev.amount > 0 ? fcfa(ev.amount) : v.category.label,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

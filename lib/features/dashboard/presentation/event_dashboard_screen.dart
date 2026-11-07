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
import '../../../ui/widgets/ui.dart';
import '../../booking/presentation/quote_compare_screen.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../events/presentation/widgets/task_timeline.dart';
import '../../guests/presentation/remind_sheet.dart';
import '../../export/presentation/export_sheet.dart';
import '../../premium/presentation/paywall.dart';
import '../../premium/presentation/premium_nudge.dart';
import '../../invitations/presentation/auto_reminders_sheet.dart';
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
              ? Scaffold(
                  appBar: AppBar(),
                  body: Center(child: Text('Événement introuvable'.tr)),
                )
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

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > _coverH - 110;
      if (c != _collapsed) setState(() => _collapsed = c);
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
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _Cover(event: e),
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
                          hue: e.category.hue,
                          onTap: () => _openAgent(e),
                        ),
                        _Action(
                          icon: AppIcons.lock,
                          label: 'Coffre-fort'.tr,
                          hue: Hue.violet,
                          onTap: () => context.push(Routes.vault),
                        ),
                        _Action(
                          icon: AppIcons.download,
                          label: 'Exporter'.tr,
                          hue: Hue.lagoon,
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
                  const SizedBox(height: 12),
                  Entrance(index: 3, child: _ToolsPanel(event: e)),
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
                onRemind: () async {
                  await showRemindSheet(context, e);
                  if (context.mounted) {
                    maybeShowPremiumNudge(context, ref, PremiumNudge.guests);
                  }
                },
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
  const _Cover({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final hue = event.category.hue;
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'cover-${event.id}',
          child: Image.asset(event.cover, fit: BoxFit.cover),
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

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.hue,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Hue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Confetti.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Confetti.line),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: hue.text),
              const SizedBox(height: 6),
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outils des invités et du jour J, et services de l'offre : chacun indique
/// s'il demande une offre supérieure.
class _ToolsPanel extends ConsumerWidget {
  const _ToolsPanel({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final tools = [
      (
        PremiumFeature.invitations,
        AppIcons.mail,
        Hue.coral,
        'Invitation'.tr,
        () => context.push(Routes.invitation(e.id)),
      ),
      (
        PremiumFeature.entries,
        AppIcons.qr,
        Hue.violet,
        'Entrées'.tr,
        () => context.push(Routes.entries(e.id)),
      ),
      (
        PremiumFeature.reminders,
        AppIcons.reminder,
        Hue.lagoon,
        'Rappels'.tr,
        () => showAutoReminders(context, e),
      ),
      (
        PremiumFeature.concierge,
        AppIcons.headset,
        Hue.gold,
        'Concierge'.tr,
        () => context.push(Routes.concierge(e.id)),
      ),
      (
        PremiumFeature.album,
        AppIcons.images,
        Hue.candy,
        'Album'.tr,
        () => context.push(Routes.album(e.id)),
      ),
      (
        PremiumFeature.invitations,
        AppIcons.globe,
        Hue.sky,
        'Page'.tr,
        () => context.push(Routes.site(e.id)),
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 8 * 5) / 6;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (feature, icon, hue, label, open) in tools)
              SizedBox(
                width: w < 64 ? (box.maxWidth - 8 * 2) / 3 : w,
                child: Pressable(
                  semanticLabel: label,
                  onTap: () => requirePremium(
                    context,
                    ref,
                    feature: feature,
                    eventId: e.id,
                    onUnlocked: open,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: hue.tint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(icon, size: 22, color: hue.text),
                            if (!ref.watch(
                              featureUnlockedProvider((feature, e.id)),
                            ))
                              Positioned(
                                right: -10,
                                top: -6,
                                child: Icon(
                                  AppIcons.lock,
                                  size: 12,
                                  color: hue.text,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall?.copyWith(
                            color: hue.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Les quatre tuiles de la palette, une couleur par module.
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
    final c = context.eventa;
    final tiles = [
      (
        c.budget,
        AppIcons.wallet,
        'Budget'.tr,
        '${(event.committedRatio * 100).round()} %',
        'engagé'.tr,
        onBudget,
      ),
      (
        c.tasks,
        AppIcons.tasks,
        'Tâches'.tr,
        '${event.tasksDone} / ${event.tasks.length}',
        'terminées'.tr,
        onTasks,
      ),
      (
        c.vendors,
        AppIcons.vendors,
        'Prestataires'.tr,
        '{0} confirmés'.trf([event.vendorsConfirmed]),
        'sur {0}'.trf([event.vendors.length]),
        onVendors,
      ),
      (
        c.team,
        AppIcons.team,
        'Équipe'.tr,
        '{0} en ligne'.trf([event.onlineCount]),
        '{0} membres'.trf([event.team.length]),
        onTeam,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      padding: EdgeInsets.zero,
      children: [
        for (final (hue, icon, label, value, caption, onTap) in tiles)
          Pressable(
            onTap: onTap,
            semanticLabel: label,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hue.tint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: hue.text),
                      const Spacer(),
                      Icon(
                        AppIcons.outward,
                        size: 14,
                        color: hue.text.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: context.text.labelMedium?.copyWith(color: hue.text),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: context.text.titleLarge?.copyWith(
                        color: hue.deep,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  Text(
                    caption,
                    style: context.text.labelSmall?.copyWith(
                      color: hue.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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

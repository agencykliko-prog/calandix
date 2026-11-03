import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../core/sound/sounds.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/auth/session_provider.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../dashboard/presentation/widgets/budget_overview.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../marketplace/presentation/widgets/vendor_card.dart';
import '../../premium/presentation/premium_nudge.dart';
import '../../events/presentation/widgets/event_card.dart';
import 'event_carousel.dart';
import 'greeting_hero.dart';
import 'notifications_sheet.dart';
import '../../inbox/presentation/inbox_providers.dart';
import '../../notifications/presentation/notifications_provider.dart';
import '../../guests/presentation/remind_sheet.dart';

/// Accueil Organisateur. Ordre de lecture : le diaporama des événements
/// (le prochain en premier), son budget, les prochaines échéances, ce qui
/// demande une action, puis les prestataires à la une.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final hero = GreetingHero(
      header: HomeHeader(subtitle: _today()),
      action: PillButton(
        label: 'Créer un événement'.tr,
        icon: AppIcons.add,
        expand: false,
        height: 46,
        onPressed: () => context.push(Routes.newEvent),
      ),
    );
    return Scaffold(
      // Accueil sur fond blanc (le mode sombre garde son fond).
      backgroundColor: Confetti.dark || MediaQuery.sizeOf(context).width >= 720
          ? null
          : Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final desktop = box.maxWidth >= _desktop;
            // En desktop, le héros entre dans la grille dès qu'il y a des
            // événements ; sinon il reste en tête, comme sur mobile.
            final heroInGrid =
                desktop &&
                !events.hasError &&
                (events.value?.isNotEmpty ?? false);
            return RefreshIndicator(
              color: Confetti.coral,
              onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (!heroInGrid) SliverToBoxAdapter(child: hero),
                  ...events.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const [
                      SliverToBoxAdapter(child: _Loading()),
                    ],
                    error: (e, _) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ErrorState(
                          onRetry: () => ref.invalidate(eventsProvider),
                        ),
                      ),
                    ],
                    data: (list) => list.isEmpty
                        ? [
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _Empty(),
                            ),
                          ]
                        : desktop
                        ? [
                            SliverToBoxAdapter(
                              child: _desktopContent(context, ref, list, hero),
                            ),
                          ]
                        : _content(context, ref, list),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: desktop ? 48 : 120),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Données communes aux deux mises en page.
  ({
    Event next,
    List<Event> upcoming,
    List<Vendor> featured,
    List<(Event, EventTask)> deadlines,
  })
  _prepare(List<Event> list) {
    final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
    final next = sorted.firstWhere(
      (e) => daysUntil(e.date) >= 0,
      orElse: () => sorted.first,
    );
    return (
      next: next,
      upcoming: [next, ...sorted.where((e) => e.id != next.id)],
      featured: [...Catalog.vendors]
        ..sort((a, b) => b.rating.compareTo(a.rating)),
      deadlines: [
        for (final e in sorted)
          for (final t in e.tasks)
            if (!t.done) (e, t),
      ]..sort((a, b) => a.$2.due.compareTo(b.$2.due)),
    );
  }

  Widget _budget(BuildContext context, Event next) => Entrance(
    index: 1,
    child: BudgetOverview(
      event: next,
      onTap: () => context.push(Routes.budget(next.id)),
    ),
  );

  Widget _deadlinesPanel(
    BuildContext context,
    WidgetRef ref,
    List<(Event, EventTask)> deadlines,
  ) => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      children: [
        for (final (i, (e, t)) in deadlines.take(4).indexed) ...[
          if (i > 0) const Divider(height: 1),
          _DeadlineRow(
            event: e,
            task: t,
            onToggle: () =>
                ref.read(eventsProvider.notifier).toggleTask(e.id, t.id),
            onTap: () => context.push(Routes.event(e.id)),
          ),
        ],
      ],
    ),
  );

  /// Lignes « À faire en priorité » : devis, paiement, relance RSVP.
  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    List<Event> list,
    Event next,
  ) {
    final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
    final payments = [
      for (final e in sorted)
        if (e.nextPayment != null) (e, e.nextPayment!),
    ]..sort((a, b) => a.$2.due.compareTo(b.$2.due));
    final quotes = ref
        .watch(bookingsProvider)
        .where(
          (b) => b.step == BookingStep.quoted || b.step == BookingStep.reserved,
        )
        .toList();
    final pendingRsvp = next.guests.pending;
    return [
      for (final b in quotes)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ActionRow(
            icon: AppIcons.file,
            hue: Hue.mango,
            title: b.step == BookingStep.quoted
                ? 'Devis reçu · {0}'.trf([b.vendor.name])
                : 'Acompte à régler · {0}'.trf([b.vendor.name]),
            caption: b.quote == null
                ? ''
                : fcfa(
                    b.step == BookingStep.quoted
                        ? b.quote!.total
                        : b.quote!.deposit,
                  ),
            action: b.step == BookingStep.quoted ? 'Voir'.tr : 'Payer'.tr,
            onTap: () => context.push(Routes.booking(b.id)),
          ),
        ),
      if (payments.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ActionRow(
            icon: AppIcons.coins,
            hue: Hue.lagoon,
            title: payments.first.$2.label,
            caption:
                '${fcfa(payments.first.$2.amount)} · ${relativeDue(payments.first.$2.due).toLowerCase()}',
            action: 'Payer'.tr,
            onTap: () =>
                _pay(context, ref, payments.first.$1, payments.first.$2),
          ),
        ),
      if (pendingRsvp > 0)
        _ActionRow(
          icon: AppIcons.guests,
          hue: Hue.coral,
          title: '{0} invités sans réponse'.trf([pendingRsvp]),
          caption: next.name,
          action: 'Relancer'.tr,
          onTap: () async {
            await showRemindSheet(context, next);
            if (context.mounted) {
              maybeShowPremiumNudge(context, ref, PremiumNudge.guests);
            }
          },
        ),
    ];
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, List<Event> list) {
    final d = _prepare(list);
    final next = d.next;
    final featured = d.featured;

    return [
      if (ref.watch(planProvider) == Plan.free)
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: Entrance(child: _PassPromo())),
        ),
      SliverToBoxAdapter(child: SectionTitle('Mes événements'.tr)),
      SliverToBoxAdapter(
        child: Entrance(
          child: EventCarousel(
            events: d.upcoming,
            height: MediaQuery.sizeOf(context).width < 400 ? 280 : 320,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SectionTitle(
          'Budget'.tr,
          action: next.name,
          onAction: () => context.push(Routes.budget(next.id)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(child: _budget(context, next)),
      ),
      SliverToBoxAdapter(
        child: SectionTitle(
          'Prochaines échéances'.tr,
          action: 'Agenda'.tr,
          onAction: () => context.go(Routes.planning),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: _deadlinesPanel(context, ref, d.deadlines),
        ),
      ),
      SliverToBoxAdapter(child: SectionTitle('À faire en priorité'.tr)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.list(children: _actions(context, ref, list, next)),
      ),
      SliverToBoxAdapter(
        child: SectionTitle(
          'Prestataires à la une'.tr,
          action: 'Tout voir'.tr,
          onAction: () => context.go(Routes.explore),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: math.min(8, featured.length),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => Entrance(
              index: i.clamp(0, 4),
              child: SizedBox(
                width: 176,
                child: VendorSpotlight(
                  vendor: featured[i],
                  onTap: () => context.push(Routes.vendor(featured[i].id)),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// Desktop : héros et budget côte à côte, événements en grille, puis
  /// échéances et priorités à gauche, prestataires à droite.
  Widget _desktopContent(
    BuildContext context,
    WidgetRef ref,
    List<Event> list,
    Widget hero,
  ) {
    final d = _prepare(list);
    final next = d.next;
    const pad = EdgeInsets.symmetric(horizontal: 16);

    Widget grid({
      required int columns,
      required double height,
      required List<Widget> children,
    }) => Padding(
      padding: pad,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in children)
                SizedBox(width: w, height: height, child: c),
            ],
          );
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: hero),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    'Budget'.tr,
                    action: next.name,
                    onAction: () => context.push(Routes.budget(next.id)),
                  ),
                  Padding(padding: pad, child: _budget(context, next)),
                ],
              ),
            ),
          ],
        ),
        if (ref.watch(planProvider) == Plan.free)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _PassPromo(),
          ),
        SectionTitle('Mes événements'.tr),
        grid(
          columns: 3,
          height: 300,
          children: [
            for (final (i, e) in d.upcoming.take(6).indexed)
              Entrance(
                index: i.clamp(0, 4),
                child: EventCard(
                  event: e,
                  onTap: () => context.push(Routes.event(e.id)),
                ),
              ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    'Prochaines échéances'.tr,
                    action: 'Agenda'.tr,
                    onAction: () => context.go(Routes.planning),
                  ),
                  Padding(
                    padding: pad,
                    child: _deadlinesPanel(context, ref, d.deadlines),
                  ),
                  SectionTitle('À faire en priorité'.tr),
                  Padding(
                    padding: pad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _actions(context, ref, list, next),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    'Prestataires à la une'.tr,
                    action: 'Tout voir'.tr,
                    onAction: () => context.go(Routes.explore),
                  ),
                  grid(
                    columns: 3,
                    height: 236,
                    children: [
                      for (final v in d.featured.take(6))
                        VendorSpotlight(
                          vendor: v,
                          onTap: () => context.push(Routes.vendor(v.id)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _pay(BuildContext context, WidgetRef ref, Event e, Payment p) {
    showPaymentSheet(
      context,
      title: p.label,
      payee: p.label.replaceFirst('Solde ', ''),
      options: [PayOption('Solde'.tr, p.amount)],
      onPay: (amount, m) {
        final r = Receipt(
          ref: receiptRef(),
          label: p.label,
          amount: amount,
          method: m,
          date: DateTime.now(),
          payee: p.label.replaceFirst('Solde ', ''),
        );
        ref
            .read(eventsProvider.notifier)
            .addExpense(
              e.id,
              Expense(
                id: r.ref,
                category: BudgetCategory.music,
                label: p.label,
                amount: amount,
                date: r.date,
                method: m.label,
              ),
            );
        return r;
      },
    );
  }
}

/// Largeur à partir de laquelle l'accueil passe en mise en page desktop.
const _desktop = 960.0;

/// Date du jour, capitalisée (« Lundi 26 octobre »).
String _today() {
  final s = longDate(DateTime.now()).replaceAll(RegExp(r' \d{4}$'), '');
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// En-tête commun aux deux profils : photo, salutation, notifications.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final plan = ref.watch(planProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
      child: Row(
        children: [
          Pressable(
            onTap: () => context.go(Routes.account),
            child: Avatar(
              image: p.photoAsset,
              bytes: p.photoBytes,
              initials: p.initials,
              size: 44,
              ring: Confetti.cream,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle ?? '${greeting()},',
                  style: context.text.bodyMedium?.copyWith(
                    color: Confetti.inkMuted,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.isCreator
                            ? (p.creator?.displayName ?? p.name)
                            : p.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.headlineSmall,
                      ),
                    ),
                    if (plan != Plan.free) ...[
                      const SizedBox(width: 8),
                      PremiumBadge(label: plan.label),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const _MessagesButton(),
          const SizedBox(width: 8),
          const _Bell(),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({
    required this.event,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  final Event event;
  final EventTask task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = task.due.isBefore(DateTime.now());
    return Pressable(
      scale: 0.99,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeOf(task.due),
                    style: context.text.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    relativeDue(task.due),
                    style: context.text.labelSmall?.copyWith(
                      color: overdue ? Confetti.danger : Confetti.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: event.category.hue.base,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Pressable(
              scale: 0.85,
              onTap: onToggle,
              semanticLabel: 'Marquer comme terminée'.tr,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Confetti.border, width: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.hue,
    required this.title,
    required this.caption,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Hue hue;
  final String title;
  final String caption;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          IconTile(icon: icon, hue: hue, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                if (caption.isNotEmpty)
                  Text(caption, style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(
            label: action,
            tone: ButtonTone.dark,
            expand: false,
            height: 36,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 40, 16, 0),
    child: Center(child: MascotLoader.party()),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Votre première fête commence ici'.tr,
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Créez un événement : on prépare la checklist et le budget selon son type.'
              .tr,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: Confetti.inkMuted),
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Créer un événement'.tr,
          icon: AppIcons.add,
          expand: false,
          onPressed: () => context.push(Routes.newEvent),
        ),
      ],
    ),
  );
}

/// Accès à la messagerie, avec le nombre de messages non lus.
class _MessagesButton extends ConsumerWidget {
  const _MessagesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => RoundIconButton(
    icon: AppIcons.message,
    tooltip: 'Messages',
    badgeCount: ref.watch(unreadMessagesProvider),
    onTap: () => context.push(Routes.messages),
  );
}

/// Cloche des notifications, avec le nombre de non lues. Une fois par
/// session, la cloche sonne peu après l'ouverture ; elle sonne aussi à
/// chaque nouvelle notification.
class _Bell extends ConsumerStatefulWidget {
  const _Bell();

  static bool _rang = false;

  @override
  ConsumerState<_Bell> createState() => _BellState();
}

class _BellState extends ConsumerState<_Bell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _fresh = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_Bell._rang) return;
    _Bell._rang = true;
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _ring();
    });
  }

  void _ring() {
    ref.read(soundProvider).play(Sfx.notification);
    setState(() => _fresh = true);
    _swing.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(unreadNoticesProvider, (prev, next) {
      if (prev != null && next > prev) _ring();
    });
    final unread = ref.watch(unreadNoticesProvider);
    return AnimatedBuilder(
      animation: _swing,
      builder: (context, child) {
        final t = _swing.value;
        // Oscillation amortie autour de l'attache de la cloche.
        final angle = math.sin(t * math.pi * 6) * 0.35 * (1 - t);
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: RoundIconButton(
        icon: AppIcons.bell,
        tooltip: 'Notifications',
        badge: !_fresh && unread > 0,
        badgeCount: _fresh ? unread : null,
        onTap: () {
          setState(() => _fresh = true);
          showNotificationsSheet(context);
        },
      ),
    );
  }
}

class _PassPromo extends StatelessWidget {
  const _PassPromo();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(Routes.premium),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pass Événement · {0}'.trf([fcfa(eventPassPrice)]),
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toutes les fonctions Signature pendant 30 jours, pour un seul événement.'
                        .tr,
                    style: context.text.bodySmall?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Mascot(size: 64, mood: MascotMood.cheer),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Confetti.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.forward, size: 16, color: Confetti.cream),
            ),
          ],
        ),
      ),
    );
  }
}

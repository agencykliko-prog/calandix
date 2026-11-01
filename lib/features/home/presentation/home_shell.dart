import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../core/auth/session_provider.dart';
import '../../pro/presentation/creator_providers.dart';

/// Branches du shell (ordre fixe) : accueil, explorer, demandes, agenda, compte.
abstract final class Branch {
  static const home = 0;
  static const explore = 1;
  static const requests = 2;
  static const agenda = 3;
  static const account = 4;
}

class _Tab {
  const _Tab(this.branch, this.icon, this.iconOn, this._label);
  final int branch;
  final IconData icon;
  final IconData iconOn;
  final String _label;
  String get label => _label.tr;
}

const _organizerTabs = [
  _Tab(Branch.home, AppIcons.home, AppIcons.homeOn, 'Accueil'),
  _Tab(Branch.explore, AppIcons.explore, AppIcons.exploreOn, 'Explorer'),
  _Tab(Branch.agenda, AppIcons.agenda, AppIcons.agendaOn, 'Agenda'),
  _Tab(Branch.account, AppIcons.account, AppIcons.accountOn, 'Compte'),
];

const _creatorTabs = [
  _Tab(Branch.home, AppIcons.home, AppIcons.homeOn, 'Accueil'),
  _Tab(Branch.requests, AppIcons.inbox, AppIcons.inbox, 'Demandes'),
  _Tab(Branch.agenda, AppIcons.agenda, AppIcons.agendaOn, 'Agenda'),
  _Tab(Branch.account, AppIcons.account, AppIcons.accountOn, 'Compte'),
];

/// Navigation principale. Organisateur : bouton central « nouvel événement ».
/// Creator : onglet Demandes à la place d'Explorer. Rail latéral dès 720 px.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int branch) {
    if (branch != shell.currentIndex) HapticFeedback.selectionClick();
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(profileProvider).isCreator;
    final tabs = creator ? _creatorTabs : _organizerTabs;
    final pending = creator
        ? ref
              .watch(requestsProvider)
              .where((r) => r.status == RequestStatus.received)
              .length
        : 0;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    if (wide) {
      return Scaffold(
        backgroundColor: Confetti.surface,
        body: Row(
          children: [
            _Rail(
              tabs: tabs,
              current: shell.currentIndex,
              onTap: _go,
              creator: creator,
              badge: pending,
            ),
            Expanded(
              // Le contenu est posé dans un cadre arrondi, comme l'admin.
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Confetti.cream,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: ConstrainedBox(
                    // Les accueils (tableaux de bord) prennent plus de largeur ;
                    // les autres onglets gardent la largeur de lecture.
                    constraints: BoxConstraints(
                      maxWidth:
                          shell.currentIndex == Branch.home ||
                              shell.currentIndex == Branch.requests
                          ? 1240
                          : 760,
                    ),
                    child: shell,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget tab(_Tab t) => _BottomTab(
      tab: t,
      selected: shell.currentIndex == t.branch,
      badge: t.branch == Branch.requests ? pending : 0,
      onTap: () => _go(t.branch),
    );
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottom > 0 ? bottom : 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Confetti.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Confetti.surface),
                boxShadow: [
                  BoxShadow(
                    color: Confetti.inkFixed.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  tab(tabs[0]),
                  tab(tabs[1]),
                  if (!creator)
                    Expanded(
                      child: Center(
                        child: Pressable(
                          scale: 0.9,
                          semanticLabel: 'Nouvel événement'.tr,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push(Routes.newEvent);
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Confetti.ink,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              AppIcons.add,
                              color: Confetti.onInk,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    ),
                  tab(tabs[2]),
                  tab(tabs[3]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.tab,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        scale: 0.92,
        semanticLabel: tab.label,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? tab.iconOn : tab.icon,
                  size: 23,
                  color: selected ? Confetti.ink : Confetti.inkFaint,
                ),
                if (badge > 0)
                  Positioned(right: -6, top: -4, child: _Badge(badge)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Confetti.ink : Confetti.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.tabs,
    required this.current,
    required this.onTap,
    required this.creator,
    required this.badge,
  });

  final List<_Tab> tabs;
  final int current;
  final ValueChanged<int> onTap;
  final bool creator;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1100;
    return Container(
      width: extended ? 220 : 84,
      color: Confetti.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: extended
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extended ? 20 : 0, 20, 0, 24),
              child: extended
                  ? const CalandixWordmark(size: 18)
                  : const CalandixMark(size: 30),
            ),
            if (!creator)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: extended ? 16 : 0,
                  vertical: 4,
                ),
                child: Pressable(
                  onTap: () => context.push(Routes.newEvent),
                  semanticLabel: 'Nouvel événement'.tr,
                  child: Container(
                    height: 46,
                    width: extended ? double.infinity : 46,
                    decoration: BoxDecoration(
                      color: Confetti.violet,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.add, color: Confetti.onViolet, size: 21),
                        if (extended) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Nouvel événement'.tr,
                            style: context.text.labelMedium?.copyWith(
                              color: Confetti.onViolet,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            for (final t in tabs)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: extended ? 12 : 10,
                  vertical: 2,
                ),
                child: Pressable(
                  scale: 0.96,
                  onTap: () => onTap(t.branch),
                  semanticLabel: t.label,
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    height: extended ? 44 : 56,
                    width: extended ? double.infinity : 64,
                    padding: EdgeInsets.symmetric(
                      horizontal: extended ? 12 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: current == t.branch
                          ? Confetti.mango
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: extended
                        ? Row(
                            children: [
                              Icon(
                                current == t.branch ? t.iconOn : t.icon,
                                size: 21,
                                color: current == t.branch
                                    ? Confetti.inkFixed
                                    : Confetti.ink,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t.label,
                                  style: context.text.titleSmall?.copyWith(
                                    color: current == t.branch
                                        ? Confetti.inkFixed
                                        : Confetti.ink,
                                  ),
                                ),
                              ),
                              if (t.branch == Branch.requests && badge > 0)
                                _Badge(badge),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                current == t.branch ? t.iconOn : t.icon,
                                size: 21,
                                color: current == t.branch
                                    ? Confetti.inkFixed
                                    : Confetti.ink,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: current == t.branch
                                      ? Confetti.inkFixed
                                      : Confetti.ink,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.n);

  final int n;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 16),
    height: 16,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Confetti.coral,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Text(
      '$n',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

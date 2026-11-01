import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/theme/app_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/eventa_colors.dart';
import '../../ui/widgets/avatars.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/pressable.dart';
import '../domain/admin_models.dart';
import 'admin_providers.dart';
import 'modules/accounts_module.dart';
import 'modules/analytics_module.dart';
import 'modules/bookings_module.dart';
import 'modules/catalog_module.dart';
import 'modules/marketing_module.dart';
import 'modules/overview_module.dart';
import 'modules/payments_module.dart';
import 'modules/pricing_module.dart';
import 'modules/security_module.dart';
import 'modules/support_module.dart';
import 'modules/verification_module.dart';
import '../../ui/dataviz/dataviz.dart';

/// Modules du centre de contrôle, dans l'ordre du menu.
enum AdminModule {
  overview(
    'vue-ensemble',
    'Vue d’ensemble',
    AppIcons.grid,
    'Pilotage',
    AdminPermission.overview,
  ),
  analytics(
    'analytics',
    'Analytics',
    AppIcons.chartUp,
    'Pilotage',
    AdminPermission.analytics,
  ),
  accounts(
    'comptes',
    'Comptes',
    AppIcons.team,
    'Communauté',
    AdminPermission.accounts,
  ),
  verification(
    'verification',
    'Vérification prestataires',
    AppIcons.verified,
    'Communauté',
    AdminPermission.verification,
  ),
  catalog(
    'catalogue',
    'Catalogue',
    AppIcons.vendors,
    'Communauté',
    AdminPermission.catalog,
  ),
  bookings(
    'reservations',
    'Réservations',
    AppIcons.calendarCheck,
    'Opérations',
    AdminPermission.bookings,
  ),
  payments(
    'paiements',
    'Paiements',
    AppIcons.wallet,
    'Opérations',
    AdminPermission.payments,
  ),
  support(
    'support',
    'Service client',
    AppIcons.headset,
    'Opérations',
    AdminPermission.support,
  ),
  pricing(
    'modele-economique',
    'Modèle économique',
    AppIcons.calculator,
    'Croissance',
    AdminPermission.pricing,
  ),
  marketing(
    'marketing',
    'Marketing & fidélisation',
    AppIcons.megaphone,
    'Croissance',
    AdminPermission.marketing,
  ),
  security(
    'securite',
    'Paramètres & sécurité',
    AppIcons.shield,
    'Système',
    AdminPermission.security,
  );

  const AdminModule(
    this.slug,
    this.label,
    this.icon,
    this.group,
    this.permission,
  );
  final String slug;
  final String label;
  final IconData icon;
  final String group;

  /// Permission requise pour ouvrir le module (`null` = tout le monde).
  final AdminPermission? permission;

  /// Premier module accessible avec ces permissions : la vue d'ensemble
  /// pour la direction et la finance, sinon le module du métier.
  static AdminModule homeFor(Set<AdminPermission> perms) => values.firstWhere(
    (m) => m.permission == null || perms.contains(m.permission),
    orElse: () => overview,
  );

  static AdminModule fromSlug(String? s) =>
      values.where((m) => m.slug == s).firstOrNull ?? overview;

  Widget get page => switch (this) {
    overview => const OverviewModule(),
    analytics => const AnalyticsModule(),
    accounts => const AccountsModule(),
    verification => const VerificationModule(),
    catalog => const CatalogModule(),
    bookings => const BookingsModule(),
    payments => const PaymentsModule(),
    support => const SupportModule(),
    pricing => const PricingModule(),
    marketing => const MarketingModule(),
    security => const SecurityModule(),
  };
}

String adminPath(AdminModule m) => '/admin/${m.slug}';

/// Coque du centre de contrôle : menu latéral (ou tiroir sur mobile),
/// barre du haut avec indicateur temps réel et rôle courant.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.module});

  final AdminModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(liveFeedProvider);
    final width = MediaQuery.sizeOf(context).width;
    final drawer = width < 900;
    final allowed =
        module.permission == null ||
        ref.watch(adminCanProvider(module.permission!));

    final body = Column(
      children: [
        _TopBar(module: module, menu: drawer),
        Expanded(
          child: SingleChildScrollView(
            key: PageStorageKey(module.slug),
            padding: EdgeInsets.fromLTRB(
              drawer ? 16 : 28,
              8,
              drawer ? 16 : 28,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  switchInCurve: Motion.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey(module),
                    child: allowed ? module.page : _Denied(module: module),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      drawer: drawer
          ? Drawer(
              backgroundColor: Confetti.surface,
              child: _Menu(current: module, inDrawer: true),
            )
          : null,
      body: SafeArea(
        child: drawer
            ? body
            : Row(
                children: [
                  SizedBox(width: 256, child: _Menu(current: module)),
                  VerticalDivider(width: 1, color: Confetti.line),
                  Expanded(child: body),
                ],
              ),
      ),
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu({required this.current, this.inDrawer = false});

  final AdminModule current;
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminProvider);
    int? badge(AdminModule m) => switch (m) {
      AdminModule.verification =>
        s.checks.where((c) => c.status == VerifyStatus.pending).length,
      AdminModule.bookings =>
        s.orders.where((o) => o.status == OrderStatus.dispute).length,
      AdminModule.support =>
        s.tickets.where((t) => t.status == TicketStatus.open).length,
      AdminModule.payments =>
        s.transactions.where((t) => t.status == TxStatus.failed).length,
      _ => null,
    };

    return Container(
      color: Confetti.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
            child: Row(
              children: [
                const Flexible(child: CalandixWordmark(size: 17)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Confetti.ink,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ADMIN',
                    style: context.text.labelSmall?.copyWith(
                      color: Confetti.onInk,
                      fontSize: 9.5,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
            child: Text('Centre de contrôle', style: context.text.bodySmall),
          ),
          for (final (i, m) in AdminModule.values.indexed) ...[
            if (i == 0 || AdminModule.values[i - 1].group != m.group)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                child: Text(
                  m.group,
                  style: context.text.labelSmall?.copyWith(
                    color: Confetti.inkMuted,
                  ),
                ),
              ),
            _MenuItem(
              module: m,
              selected: m == current,
              badge: badge(m),
              locked:
                  m.permission != null &&
                  !ref.watch(adminCanProvider(m.permission!)),
              onTap: () {
                if (inDrawer) Navigator.of(context).pop();
                context.go(adminPath(m));
              },
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Confetti.goldTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Exemple de structure : toutes les données affichées sont fictives.',
              style: context.text.bodySmall?.copyWith(color: Hue.gold.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.module,
    required this.selected,
    required this.onTap,
    this.badge,
    this.locked = false,
  });

  final AdminModule module;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Confetti.mango : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              module.icon,
              size: 19,
              color: selected ? Confetti.inkFixed : Confetti.inkMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                module.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Confetti.inkFixed
                      : locked
                      ? Confetti.inkFaint
                      : Confetti.ink,
                ),
              ),
            ),
            if (locked)
              Icon(AppIcons.lock, size: 14, color: Confetti.inkFaint)
            else if (badge != null && badge! > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Confetti.coral,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$badge',
                  textAlign: TextAlign.center,
                  style: context.text.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.module, required this.menu});

  final AdminModule module;
  final bool menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(adminSessionProvider);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: menu ? 8 : 28),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Confetti.line)),
      ),
      child: Row(
        children: [
          if (menu)
            Builder(
              builder: (c) => IconButton(
                tooltip: 'Menu',
                icon: Icon(AppIcons.grid, color: Confetti.ink),
                onPressed: () => Scaffold.of(c).openDrawer(),
              ),
            ),
          Expanded(
            child: Text(
              menu ? module.label : 'Calandix · Centre de contrôle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: menu ? context.text.titleMedium : context.text.bodySmall,
            ),
          ),
          if (!narrow) ...[
            const LiveDot(label: 'Flux en direct'),
            const SizedBox(width: 16),
          ],
          if (me != null)
            PopupMenuButton<Object>(
              tooltip: 'Mon compte et rôle',
              color: Confetti.surface,
              position: PopupMenuPosition.under,
              onSelected: (v) {
                if (v is AdminRole) {
                  ref.read(adminSessionProvider.notifier).actAs(v);
                } else {
                  ref.read(adminSessionProvider.notifier).signOut();
                  context.go('/admin');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<Object>(
                  enabled: false,
                  child: Text(
                    'Voir l’interface en tant que… (démo)',
                    style: context.text.labelSmall,
                  ),
                ),
                for (final r in AdminRole.values)
                  PopupMenuItem<Object>(
                    value: r,
                    child: Row(
                      children: [
                        Icon(
                          r == me.role ? AppIcons.checkCircle : AppIcons.user,
                          size: 17,
                          color: r == me.role
                              ? Confetti.lagoon
                              : Confetti.inkMuted,
                        ),
                        const SizedBox(width: 10),
                        Text(r.label, style: context.text.bodyMedium),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem<Object>(
                  value: 'out',
                  child: Row(
                    children: [
                      Icon(AppIcons.signOut, size: 17, color: Confetti.danger),
                      const SizedBox(width: 10),
                      Text('Se déconnecter', style: context.text.bodyMedium),
                    ],
                  ),
                ),
              ],
              child: Row(
                children: [
                  Avatar(initials: _initials(me.name), size: 34),
                  if (!narrow) ...[
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.name, style: context.text.titleSmall),
                        Text(me.role.label, style: context.text.bodySmall),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      AppIcons.chevronDown,
                      size: 14,
                      color: Confetti.inkMuted,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _initials(String name) =>
    name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();

class _Denied extends ConsumerWidget {
  const _Denied({required this.module});

  final AdminModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(adminSessionProvider)?.role;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            Icon(AppIcons.lock, size: 40, color: Confetti.inkFaint),
            const SizedBox(height: 14),
            Text(module.label, style: context.text.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Ce module n’est pas accessible au rôle « ${role?.label} ».\nUn super administrateur peut accorder la permission dans Paramètres & sécurité.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: Confetti.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../../core/models/models.dart';
import 'widgets/vendor_card.dart';

enum VendorSort {
  relevance('Pertinence'),
  priceAsc('Prix croissant'),
  priceDesc('Prix décroissant'),
  rating('Mieux notés');

  const VendorSort(this._label);
  final String _label;
  String get label => _label.tr;
}

/// Marketplace des prestataires : recherche, catégories, filtres et tri.
/// Un seul résultat sponsorisé, épinglé en tête et signalé comme tel.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialCategory});

  final VendorCategory? initialCategory;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late VendorCategory? _category = widget.initialCategory;
  String _query = '';
  VendorSort _sort = VendorSort.relevance;
  bool _onlyAvailable = false;
  bool _onlyVerified = false;
  String? _zone;

  static final _zones = {for (final v in Catalog.vendors) v.zone}.toList()
    ..sort();

  int get _activeFilters =>
      (_onlyAvailable ? 1 : 0) +
      (_onlyVerified ? 1 : 0) +
      (_zone != null ? 1 : 0) +
      (_sort != VendorSort.relevance ? 1 : 0);

  List<Vendor> _results() {
    final q = _query.toLowerCase();
    final list = Catalog.vendors.where((v) {
      if (_category != null && v.category != _category) return false;
      if (_onlyAvailable && !v.available) return false;
      if (_onlyVerified && !v.verified) return false;
      if (_zone != null && v.zone != _zone) return false;
      if (q.isNotEmpty &&
          !'${v.name} ${v.tagline} ${v.category.label} ${v.zone}'
              .toLowerCase()
              .contains(q)) {
        return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case VendorSort.priceAsc:
        list.sort((a, b) => a.priceFrom.compareTo(b.priceFrom));
      case VendorSort.priceDesc:
        list.sort((a, b) => b.priceFrom.compareTo(a.priceFrom));
      case VendorSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case VendorSort.relevance:
        list.sort(
          (a, b) => (b.rating * b.reviews).compareTo(a.rating * a.reviews),
        );
    }
    final sponsored = list
        .where((v) => v.sponsor != null && v.sponsor != Sponsor.recommended)
        .firstOrNull;
    if (sponsored != null && _sort == VendorSort.relevance) {
      list
        ..remove(sponsored)
        ..insert(0, sponsored);
    }
    return list;
  }

  Future<void> _openFilters() => showEventaSheet<void>(
    context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheet) {
        void set(VoidCallback f) {
          setState(f);
          setSheet(() {});
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtres'.tr,
                      style: context.text.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => set(() {
                      _sort = VendorSort.relevance;
                      _onlyAvailable = false;
                      _onlyVerified = false;
                      _zone = null;
                    }),
                    child: Text('Réinitialiser'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Trier par'.tr, style: context.text.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in VendorSort.values)
                    Choice(
                      label: s.label,
                      on: _sort == s,
                      onTap: () => set(() => _sort = s),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Localisation'.tr, style: context.text.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Choice(
                    label: 'Partout'.tr,
                    on: _zone == null,
                    onTap: () => set(() => _zone = null),
                  ),
                  for (final z in _zones)
                    Choice(
                      label: z,
                      on: _zone == z,
                      onTap: () => set(() => _zone = z),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _SwitchRow(
                label: 'Disponible à ma date'.tr,
                value: _onlyAvailable,
                onChanged: (v) => set(() => _onlyAvailable = v),
              ),
              _SwitchRow(
                label: 'Profils vérifiés uniquement'.tr,
                value: _onlyVerified,
                onChanged: (v) => set(() => _onlyVerified = v),
              ),
              const SizedBox(height: 14),
              PillButton(
                label: 'Voir {0} prestataires'.trf([_results().length]),
                tone: ButtonTone.dark,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final results = _results();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Text('Explorer'.tr, style: context.text.headlineMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Traiteur, salle, DJ, Assinie…'.tr,
                          prefixIcon: Icon(AppIcons.search, size: 19),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Pressable(
                      onTap: _openFilters,
                      semanticLabel: 'Filtres et tri'.tr,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _activeFilters > 0
                              ? Confetti.ink
                              : Confetti.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _activeFilters > 0
                                ? Confetti.ink
                                : Confetti.line,
                          ),
                        ),
                        child: Icon(
                          AppIcons.filters,
                          size: 19,
                          color: _activeFilters > 0
                              ? Confetti.onInk
                              : Confetti.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_query.trim().length >= 3)
              SliverToBoxAdapter(child: _Suggestions(query: _query)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  physics: const BouncingScrollPhysics(),
                  itemCount: VendorCategory.values.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = i == 0 ? null : VendorCategory.values[i - 1];
                    return Choice(
                      label: c?.label ?? 'Tous'.tr,
                      icon: c?.icon,
                      on: c == _category,
                      onTap: () => setState(() => _category = c),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Text(
                      (results.length > 1
                              ? '{0} prestataires'
                              : '{0} prestataire')
                          .trf([results.length]),
                      style: context.text.labelMedium?.copyWith(
                        color: Confetti.inkMuted,
                      ),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: _openFilters,
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.sort,
                            size: 15,
                            color: Confetti.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(_sort.label, style: context.text.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 32,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Aucun prestataire ne correspond'.tr,
                        style: context.text.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Élargissez la zone ou retirez un filtre.'.tr,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // Une colonne sur téléphone, deux dès 560 px de large.
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.crossAxisExtent >= 560 ? 2 : 1;
                    final colW =
                        (constraints.crossAxisExtent - 14 * (cols - 1)) / cols;
                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                        mainAxisExtent: colW * 10 / 16 + 162,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, i) => Entrance(
                        index: i.clamp(0, 5),
                        child: VendorCard(
                          vendor: results[i],
                          onTap: () =>
                              context.push(Routes.vendor(results[i].id)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

/// Pastille de choix (catégorie, tri, zone).
class Choice extends StatelessWidget {
  const Choice({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? Confetti.ink : Confetti.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? Confetti.ink : Confetti.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: on ? Confetti.onInk : Confetti.inkMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: on ? Confetti.onInk : Confetti.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.text.titleSmall)),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

/// Dès trois lettres : prestataires et agences proposés, les noms qui
/// commencent par la saisie d'abord.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    int rank(Vendor v) {
      final name = v.name.toLowerCase();
      if (name.startsWith(q)) return 0;
      if (name.split(' ').any((w) => w.startsWith(q))) return 1;
      if (v.category.label.toLowerCase().contains(q)) return 2;
      return 3;
    }

    final found =
        Catalog.vendors
            .where(
              (v) => '${v.name} ${v.category.label} ${v.zone} ${v.tagline}'
                  .toLowerCase()
                  .contains(q),
            )
            .toList()
          ..sort((a, b) => rank(a).compareTo(rank(b)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Panel(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: found.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Aucun prestataire ne correspond.'.tr,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.eventa.muted,
                  ),
                ),
              )
            : Column(
                children: [
                  for (final v in found.take(5))
                    Pressable(
                      scale: 0.99,
                      onTap: () => context.push(Routes.vendor(v.id)),
                      semanticLabel: v.name,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.search,
                              size: 16,
                              color: Confetti.inkMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.titleSmall,
                                  ),
                                  Text(
                                    '${v.category.label} · ${v.zone}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              AppIcons.chevron,
                              size: 14,
                              color: Confetti.inkMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

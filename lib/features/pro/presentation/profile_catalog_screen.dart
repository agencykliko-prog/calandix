import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/auth/session_provider.dart';
import '../../marketplace/presentation/explore_screen.dart';
import '../domain/pro_models.dart';
import 'pro_providers.dart';
import 'pro_widgets.dart';
import 'verification_providers.dart';
import 'verification_screen.dart';

/// A. Profil & catalogue : présentation, portfolio, coordonnées, zone,
/// catégories, forfaits, options et conditions de vente.
class ProfileCatalogScreen extends ConsumerWidget {
  const ProfileCatalogScreen({super.key});

  static const _zonePool = [
    'Abidjan',
    'Grand-Bassam',
    'Assinie',
    'Bingerville',
    'Yamoussoukro',
    'Bouaké',
    'San-Pédro',
    'Toute la Côte d’Ivoire',
  ];
  static const _categoryPool = [
    'Fleurs',
    'Ballons',
    'Scénographie',
    'Location de mobilier',
    'Éclairage',
    'Papeterie',
  ];
  static const _photoPool = [
    'assets/images/v/rental_1.jpg',
    'assets/images/v/rental_2.jpg',
    'assets/images/v/venue_2.jpg',
    'assets/images/onboarding_balloons.jpg',
    'assets/images/cover_birthday.jpg',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final c = profile.creator;
    final cat = ref.watch(proProvider.select((s) => s.catalog));
    final n = ref.read(proProvider.notifier);
    final verification = ref.watch(verificationProvider.select((v) => v.step));

    return ProPage(
      title: 'Profil & catalogue'.tr,
      subtitle: 'Ce que voient les organisateurs sur votre fiche publique.'.tr,
      children: [
        const SizedBox(height: 8),
        // Présentation de l'entreprise.
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (c != null)
                    IconTile(icon: c.category.icon, hue: Hue.mango, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c?.displayName ?? profile.name,
                          style: context.text.titleLarge,
                        ),
                        Text(
                          '${c?.category.label ?? ''} · ${c?.kind.label ?? ''}',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Tag(
                    label: verification.label,
                    hue: verification.hue,
                    icon: verification.icon,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(c?.description ?? '', style: context.text.bodyMedium),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: PillButton(
                  label: 'Modifier la présentation'.tr,
                  icon: AppIcons.edit,
                  tone: ButtonTone.ghost,
                  expand: false,
                  height: 40,
                  onPressed: () => _editDescription(context, ref),
                ),
              ),
            ],
          ),
        ),
        SectionTitle(
          'Portfolio'.tr,
          action: '{0} photos'.trf([cat.portfolio.length]),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 600 ? 4 : 3;
            final w = (box.maxWidth - 8 * (cols - 1)) / cols;
            final next = _photoPool
                .where((p) => !cat.portfolio.contains(p))
                .firstOrNull;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in cat.portfolio)
                  _Photo(
                    path: p,
                    size: w,
                    onRemove: () => n.setCatalog(
                      cat.copyWith(portfolio: [...cat.portfolio]..remove(p)),
                    ),
                  ),
                if (next != null)
                  Pressable(
                    onTap: () {
                      n.setCatalog(
                        cat.copyWith(portfolio: [...cat.portfolio, next]),
                      );
                      toast(context, 'Photo ajoutée au portfolio'.tr);
                    },
                    child: Container(
                      width: w,
                      height: w,
                      decoration: BoxDecoration(
                        color: Confetti.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Confetti.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.add, color: Confetti.inkMuted),
                          const SizedBox(height: 4),
                          Text('Ajouter'.tr, style: context.text.labelSmall),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Appui long sur une photo pour la retirer.'.tr,
            style: context.text.bodySmall,
          ),
        ),
        SectionTitle(
          'Coordonnées'.tr,
          action: 'Modifier'.tr,
          onAction: () => context.push(Routes.editProfile),
        ),
        Panel(
          child: Column(
            children: [
              InfoLine('Téléphone'.tr, profile.phone),
              InfoLine('E-mail'.tr, profile.email),
              InfoLine('Adresse'.tr, c?.address ?? '—'),
              if (c?.website != null) InfoLine('Site web'.tr, c!.website!),
              if (c?.portfolio != null) InfoLine('Réseaux'.tr, c!.portfolio!),
              if (c?.rccm != null) InfoLine('RCCM'.tr, c!.rccm!),
            ],
          ),
        ),
        SectionTitle('Zone d’intervention'.tr),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final z in _zonePool)
              Choice(
                label: z.tr,
                on: cat.zones.contains(z.tr) || cat.zones.contains(z),
                onTap: () {
                  final on = cat.zones.contains(z.tr) || cat.zones.contains(z);
                  n.setCatalog(
                    cat.copyWith(
                      zones: on
                          ? cat.zones.where((x) => x != z && x != z.tr).toList()
                          : [...cat.zones, z.tr],
                    ),
                  );
                },
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Hors zone : frais de déplacement de {0}.'.trf([
              fcfa(cat.terms.travelFee),
            ]),
            style: context.text.bodySmall,
          ),
        ),
        SectionTitle('Catégories'.tr),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (c != null)
              Choice(label: c.category.label, on: true, onTap: () {}),
            for (final k in _categoryPool)
              Choice(
                label: k.tr,
                on: cat.categories.contains(k.tr),
                onTap: () => n.setCatalog(
                  cat.copyWith(
                    categories: cat.categories.contains(k.tr)
                        ? cat.categories.where((x) => x != k.tr).toList()
                        : [...cat.categories, k.tr],
                  ),
                ),
              ),
          ],
        ),
        SectionTitle(
          'Forfaits'.tr,
          action: 'Ajouter'.tr,
          onAction: () => _addPackage(context, ref),
        ),
        _CatalogQuota(used: cat.packages.length),
        for (final p in cat.packages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              onTap: () => _editPackage(context, ref, p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.name, style: context.text.titleMedium),
                      ),
                      Text(
                        fcfa(p.price),
                        style: context.text.titleMedium?.copyWith(
                          color: p.active ? null : Confetti.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final i in p.includes)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.check,
                            size: 14,
                            color: Confetti.lagoon,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(i, style: context.text.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        p.active ? 'Visible sur la fiche'.tr : 'Masqué'.tr,
                        style: context.text.labelSmall,
                      ),
                      const Spacer(),
                      Switch(
                        value: p.active,
                        onChanged: (v) => n.savePackage(p.copyWith(active: v)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        SectionTitle(
          'Options'.tr,
          action: 'Ajouter'.tr,
          onAction: () => _editOption(context, ref, null),
        ),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, o) in cat.options.indexed) ...[
                if (i > 0) const Divider(height: 1),
                Pressable(
                  scale: 0.99,
                  onTap: () => _editOption(context, ref, o),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(o.name, style: context.text.titleSmall),
                        ),
                        Text(
                          '+ ${fcfa(o.price)}',
                          style: context.text.bodySmall,
                        ),
                        Switch(
                          value: o.active,
                          onChanged: (v) => n.saveOption(o.copyWith(active: v)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SectionTitle(
          'Conditions de vente'.tr,
          action: 'Modifier'.tr,
          onAction: () => _editTerms(context, ref),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLine(
                'Acompte à la réservation'.tr,
                '${cat.terms.depositPercent} %',
              ),
              InfoLine('Solde'.tr, 'J-{0}'.trf([cat.terms.balanceDaysBefore])),
              InfoLine(
                'Annulation gratuite'.tr,
                'jusqu’à J-{0}'.trf([cat.terms.freeCancelDays]),
              ),
              InfoLine(
                'Validité des devis'.tr,
                '{0} jours'.trf([cat.terms.quoteValidityDays]),
              ),
              InfoLine('Frais de déplacement'.tr, fcfa(cat.terms.travelFee)),
              InfoLine(
                'Dernière offre'.tr,
                '−{0} %'.trf([cat.terms.lastOfferPercent]),
              ),
              const SizedBox(height: 8),
              Text(cat.terms.notes, style: context.text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  void _editDescription(BuildContext context, WidgetRef ref) {
    final p = ref.read(profileProvider);
    final c = p.creator;
    if (c == null) return;
    final text = TextEditingController(text: c.description);
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Présentation'.tr, style: ctx.text.headlineSmall),
            const SizedBox(height: 12),
            AppField(
              label: 'Votre activité en quelques lignes'.tr,
              controller: text,
              maxLines: 5,
              autofocus: true,
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Enregistrer'.tr,
              tone: ButtonTone.dark,
              onPressed: () {
                ref
                    .read(sessionProvider.notifier)
                    .update(
                      p.copyWith(
                        creator: c.copyWith(description: text.text.trim()),
                      ),
                    );
                Navigator.of(ctx).pop();
                toast(context, 'Présentation mise à jour'.tr);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Ajout d'un forfait, dans la limite de la formule.
  void _addPackage(BuildContext context, WidgetRef ref) {
    final plan = ref.read(proPlanProvider);
    final limit = plan.catalogLimit;
    final used = ref.read(proProvider).catalog.packages.length;
    if (limit != null && used >= limit) {
      _catalogFull(context, plan.label, limit);
      return;
    }
    _editPackage(context, ref, null);
  }

  void _catalogFull(BuildContext context, String plan, int limit) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Catalogue complet'.tr, style: ctx.text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'La formule {0} compte jusqu’à {1} prestations. Passez à la formule supérieure pour en ajouter, avec une commission plus basse.'
                  .trf([plan, limit]),
              style: ctx.text.bodyMedium,
            ),
            const SizedBox(height: 18),
            PillButton(
              label: 'Voir les formules'.tr,
              icon: AppIcons.crown,
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push(Routes.business);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editPackage(BuildContext context, WidgetRef ref, ProPackage? p) {
    final name = TextEditingController(text: p?.name);
    final price = TextEditingController(text: p == null ? '' : '${p.price}');
    final inc = TextEditingController(text: p?.includes.join('\n'));
    showEventaSheet<void>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text(
            p == null ? 'Nouveau forfait'.tr : 'Modifier le forfait'.tr,
            style: ctx.text.headlineSmall,
          ),
          const SizedBox(height: 12),
          AppField(label: 'Nom'.tr, controller: name, autofocus: p == null),
          const SizedBox(height: 12),
          AppField(
            label: 'Prix'.tr,
            controller: price,
            suffixText: 'FCFA',
            keyboard: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Ce qui est inclus (une ligne par élément)'.tr,
            controller: inc,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          PillButton(
            label: 'Enregistrer'.tr,
            tone: ButtonTone.dark,
            onPressed: () {
              final v = int.tryParse(price.text) ?? 0;
              if (name.text.trim().isEmpty || v <= 0) return;
              final includes = inc.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              ref
                  .read(proProvider.notifier)
                  .savePackage(
                    p?.copyWith(
                          name: name.text.trim(),
                          price: v,
                          includes: includes,
                        ) ??
                        ProPackage(
                          id: 'p${DateTime.now().millisecondsSinceEpoch}',
                          name: name.text.trim(),
                          price: v,
                          includes: includes,
                        ),
                  );
              Navigator.of(ctx).pop();
              toast(context, 'Forfait enregistré'.tr);
            },
          ),
        ],
      ),
    );
  }

  void _editOption(BuildContext context, WidgetRef ref, ProOption? o) {
    final name = TextEditingController(text: o?.name);
    final price = TextEditingController(text: o == null ? '' : '${o.price}');
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              o == null ? 'Nouvelle option'.tr : 'Modifier l’option'.tr,
              style: ctx.text.headlineSmall,
            ),
            const SizedBox(height: 12),
            AppField(label: 'Nom'.tr, controller: name, autofocus: o == null),
            const SizedBox(height: 12),
            AppField(
              label: 'Prix'.tr,
              controller: price,
              suffixText: 'FCFA',
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Enregistrer'.tr,
              tone: ButtonTone.dark,
              onPressed: () {
                final v = int.tryParse(price.text) ?? 0;
                if (name.text.trim().isEmpty || v <= 0) return;
                ref
                    .read(proProvider.notifier)
                    .saveOption(
                      o?.copyWith(name: name.text.trim(), price: v) ??
                          ProOption(
                            id: 'o${DateTime.now().millisecondsSinceEpoch}',
                            name: name.text.trim(),
                            price: v,
                          ),
                    );
                Navigator.of(ctx).pop();
                toast(context, 'Option enregistrée'.tr);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editTerms(BuildContext context, WidgetRef ref) {
    var t = ref.read(proProvider).catalog.terms;
    final notes = TextEditingController(text: t.notes);
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          Widget stepper(
            String label,
            String value,
            VoidCallback minus,
            VoidCallback plus,
          ) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(label, style: ctx.text.titleSmall)),
                RoundIconButton(
                  icon: AppIcons.minus,
                  size: 34,
                  tooltip: 'Moins',
                  onTap: minus,
                ),
                SizedBox(
                  width: 78,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: ctx.text.titleSmall,
                  ),
                ),
                RoundIconButton(
                  icon: AppIcons.add,
                  size: 34,
                  tooltip: 'Plus',
                  onTap: plus,
                ),
              ],
            ),
          );
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Text('Conditions de vente'.tr, style: ctx.text.headlineSmall),
              const SizedBox(height: 12),
              stepper(
                'Acompte'.tr,
                '${t.depositPercent} %',
                () => set(
                  () => t = t.copyWith(
                    depositPercent: (t.depositPercent - 5).clamp(0, 100),
                  ),
                ),
                () => set(
                  () => t = t.copyWith(
                    depositPercent: (t.depositPercent + 5).clamp(0, 100),
                  ),
                ),
              ),
              stepper(
                'Solde dû'.tr,
                'J-{0}'.trf([t.balanceDaysBefore]),
                () => set(
                  () => t = t.copyWith(
                    balanceDaysBefore: (t.balanceDaysBefore - 1).clamp(0, 60),
                  ),
                ),
                () => set(
                  () => t = t.copyWith(
                    balanceDaysBefore: (t.balanceDaysBefore + 1).clamp(0, 60),
                  ),
                ),
              ),
              stepper(
                'Annulation gratuite'.tr,
                'J-{0}'.trf([t.freeCancelDays]),
                () => set(
                  () => t = t.copyWith(
                    freeCancelDays: (t.freeCancelDays - 5).clamp(0, 120),
                  ),
                ),
                () => set(
                  () => t = t.copyWith(
                    freeCancelDays: (t.freeCancelDays + 5).clamp(0, 120),
                  ),
                ),
              ),
              stepper(
                'Validité des devis'.tr,
                '{0} jours'.trf([t.quoteValidityDays]),
                () => set(
                  () => t = t.copyWith(
                    quoteValidityDays: (t.quoteValidityDays - 1).clamp(1, 60),
                  ),
                ),
                () => set(
                  () => t = t.copyWith(
                    quoteValidityDays: (t.quoteValidityDays + 1).clamp(1, 60),
                  ),
                ),
              ),
              stepper(
                'Frais de déplacement'.tr,
                fcfaCompact(t.travelFee),
                () => set(
                  () => t = t.copyWith(
                    travelFee: (t.travelFee - 5000).clamp(0, 500000),
                  ),
                ),
                () => set(
                  () => t = t.copyWith(
                    travelFee: (t.travelFee + 5000).clamp(0, 500000),
                  ),
                ),
              ),
              stepper(
                'Dernière offre'.tr,
                '−{0} %'.trf([t.lastOfferPercent]),
                () => set(
                  () => t = t.copyWith(
                    lastOfferPercent: (t.lastOfferPercent - 1).clamp(0, 30),
                  ),
                ),
                () => set(
                  () => t = t.copyWith(
                    lastOfferPercent: (t.lastOfferPercent + 1).clamp(0, 30),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppField(
                label: 'Conditions particulières'.tr,
                controller: notes,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              PillButton(
                label: 'Enregistrer'.tr,
                tone: ButtonTone.dark,
                onPressed: () {
                  final n = ref.read(proProvider.notifier);
                  n.setCatalog(
                    ref
                        .read(proProvider)
                        .catalog
                        .copyWith(terms: t.copyWith(notes: notes.text.trim())),
                  );
                  Navigator.of(ctx).pop();
                  toast(context, 'Conditions de vente mises à jour'.tr);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.path,
    required this.size,
    required this.onRemove,
  });

  final String path;
  final double size;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () {
      onRemove();
      toast(context, 'Photo retirée du portfolio'.tr);
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(path, width: size, height: size, fit: BoxFit.cover),
    ),
  );
}

/// Prestations utilisées sur le quota de la formule, avec un lien vers les
/// formules quand la limite approche.
class _CatalogQuota extends ConsumerWidget {
  const _CatalogQuota({required this.used});

  final int used;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(proPlanProvider);
    final limit = plan.catalogLimit;
    if (limit == null) return const SizedBox.shrink();
    final near = used >= limit - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '{0} prestations sur {1} · formule {2}'.trf([
                used,
                limit,
                plan.label,
              ]),
              style: context.text.bodySmall?.copyWith(
                color: near ? Confetti.warning : Confetti.inkMuted,
              ),
            ),
          ),
          if (near)
            Pressable(
              onTap: () => context.push(Routes.business),
              child: Text(
                'Plus de place'.tr,
                style: context.text.labelMedium?.copyWith(
                  color: Confetti.coralDeep,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

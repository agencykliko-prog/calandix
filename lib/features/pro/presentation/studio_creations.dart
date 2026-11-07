import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/mobile/download_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/download_web.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import '../domain/pro_models.dart';
import 'pro_providers.dart';
import 'studio_providers.dart';

/// Ce que le Studio permet de créer, à partir du catalogue et de la marque.
enum CreationKind {
  catalog('Catalogue', 'Toutes vos offres sur une page.', AppIcons.grid, 1.414),
  sheet(
    'Fiche d’offre',
    'Une offre détaillée, prête à envoyer.',
    AppIcons.file,
    1.414,
  ),
  promo(
    'Visuel promotionnel',
    'Une offre mise en avant, format carré.',
    AppIcons.megaphone,
    1,
  ),
  brochure(
    'Brochure numérique',
    'Présentation de votre activité.',
    AppIcons.scroll,
    1.414,
  ),
  social(
    'Publication réseaux',
    'Format story pour WhatsApp et Instagram.',
    AppIcons.share,
    1.777,
  ),
  proposal(
    'Proposition commerciale',
    'Une offre personnalisée pour un client.',
    AppIcons.handshake,
    1.414,
  );

  const CreationKind(this._title, this._caption, this.icon, this.ratio);
  final String _title;
  final String _caption;
  final IconData icon;

  /// Hauteur / largeur du visuel.
  final double ratio;
  String get title => _title.tr;
  String get caption => _caption.tr;
}

/// Atelier de création : des modèles remplis avec le catalogue et la
/// marque du prestataire, téléchargeables en image.
class StudioCreations extends StatelessWidget {
  const StudioCreations({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Créer'.tr),
        Text(
          'Des modèles prêts à l’emploi, remplis avec votre catalogue et votre marque.'
              .tr,
          style: context.text.bodySmall,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            final n = box.maxWidth >= 640 ? 3 : 2;
            final w = (box.maxWidth - 8 * (n - 1)) / n;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in CreationKind.values)
                  SizedBox(
                    width: w,
                    child: Panel(
                      padding: const EdgeInsets.all(14),
                      onTap: () => showEventaSheet<void>(
                        context,
                        builder: (_) => _Editor(kind: k),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconTile(icon: k.icon, hue: Hue.violet, size: 34),
                          const SizedBox(height: 10),
                          Text(k.title, style: context.text.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            k.caption,
                            maxLines: 2,
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.kind});

  final CreationKind kind;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final _key = GlobalKey();
  final _client = TextEditingController();
  int _package = 0;
  bool _saving = false;

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() => _saving = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final ok = await saveBytesFile(
        'calandix-${widget.kind.name}.png',
        data!.buffer.asUint8List(),
      );
      if (mounted) {
        toast(
          context,
          ok
              ? 'Image téléchargée'.tr
              : 'Le téléchargement d’image arrive avec l’application mobile.'
                    .tr,
          icon: ok ? AppIcons.checkCircle : AppIcons.info,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    final catalog = ref.watch(proProvider.select((s) => s.catalog));
    final studio = ref.watch(studioProvider);
    final packages = [
      for (final p in catalog.packages)
        if (p.active) p,
    ];
    final single =
        k == CreationKind.sheet ||
        k == CreationKind.promo ||
        k == CreationKind.social ||
        k == CreationKind.proposal;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(k.title, style: context.text.headlineSmall),
          const SizedBox(height: 12),
          if (single && packages.length > 1) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, p) in packages.indexed)
                  ChoiceChip(
                    label: Text(p.name),
                    selected: _package == i,
                    onSelected: (_) => setState(() => _package = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (k == CreationKind.proposal) ...[
            TextField(
              controller: _client,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'Nom du client'.tr),
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: RepaintBoundary(
                key: _key,
                child: AspectRatio(
                  aspectRatio: 1 / k.ratio,
                  child: _Visual(
                    kind: k,
                    brand: studio.brandName,
                    color: Color(studio.brandColor),
                    packages: single
                        ? [
                            if (packages.isNotEmpty)
                              packages[_package.clamp(0, packages.length - 1)],
                          ]
                        : packages,
                    photo: catalog.portfolio.isEmpty
                        ? null
                        : catalog.portfolio.first,
                    client: _client.text.trim(),
                    validity: catalog.terms.quoteValidityDays,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PillButton(
            label: 'Télécharger l’image'.tr,
            icon: AppIcons.download,
            loading: _saving,
            onPressed: packages.isEmpty ? null : _download,
          ),
          if (packages.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ajoutez d’abord une offre à votre catalogue.'.tr,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Visual extends StatelessWidget {
  const _Visual({
    required this.kind,
    required this.brand,
    required this.color,
    required this.packages,
    required this.photo,
    required this.client,
    required this.validity,
  });

  final CreationKind kind;
  final String brand;
  final Color color;
  final List<ProPackage> packages;
  final String? photo;
  final String client;
  final int validity;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1A0637);
    final dark = kind == CreationKind.promo || kind == CreationKind.social;
    final fg = dark ? Colors.white : ink;
    final soft = fg.withValues(alpha: 0.72);
    TextStyle title(double s) => TextStyle(
      fontFamily: AppTheme.font,
      fontWeight: FontWeight.w800,
      fontSize: s,
      height: 1.05,
      color: fg,
      letterSpacing: -0.3,
    );
    final heading = switch (kind) {
      CreationKind.catalog => 'Nos offres'.tr,
      CreationKind.brochure => 'Votre événement, notre savoir-faire'.tr,
      CreationKind.proposal =>
        client.isEmpty
            ? 'Proposition commerciale'.tr
            : 'Proposition pour {0}'.trf([client]),
      _ => packages.isEmpty ? '' : packages.first.name,
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? color : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: dark ? null : Border.all(color: const Color(0xFFDDD8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo != null &&
              kind != CreationKind.catalog &&
              kind != CreationKind.proposal)
            Expanded(
              flex: kind == CreationKind.social ? 5 : 4,
              child: Image.asset(photo!, fit: BoxFit.cover),
            ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.toUpperCase(),
                    style: TextStyle(
                      color: dark ? Colors.white : color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    heading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: title(kind == CreationKind.promo ? 22 : 18),
                  ),
                  const SizedBox(height: 8),
                  if (kind == CreationKind.catalog ||
                      kind == CreationKind.brochure)
                    for (final p in packages.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: fg, fontSize: 12),
                              ),
                            ),
                            Text(
                              fcfa(p.price),
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )
                  else if (packages.isNotEmpty) ...[
                    for (final line in packages.first.includes.take(
                      kind == CreationKind.promo ? 2 : 4,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $line',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: soft, fontSize: 11.5),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      fcfa(packages.first.price),
                      style: title(kind == CreationKind.promo ? 24 : 20)
                          .copyWith(color: dark ? Colors.white : color),
                    ),
                  ],
                  if (kind == CreationKind.proposal) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Proposition valable {0} jours.'.trf([validity]),
                      style: TextStyle(color: soft, fontSize: 10.5),
                    ),
                  ],
                  if (kind == CreationKind.catalog ||
                      kind == CreationKind.brochure)
                    const Spacer(),
                  const SizedBox(height: 6),
                  Text(
                    'Réservez sur Calandix'.tr,
                    style: TextStyle(
                      color: soft,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

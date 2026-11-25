import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/i18n/tr.dart';
import '../../../../core/models/models.dart';
import '../../../../ui/theme/app_icons.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../../ui/theme/eventa_colors.dart';
import '../../../../ui/widgets/pressable.dart';
import '../../../../ui/widgets/ui.dart';
import '../../data/event_templates.dart';
import '../events_providers.dart';

/// Image de couverture d'un événement, quelle que soit sa source : photo
/// de l'application, photo importée gardée sur l'appareil (`data:`) ou
/// photo déposée en ligne (`https:`).
class EventCoverImage extends StatelessWidget {
  const EventCoverImage(
    this.cover, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.category,
  });

  final String cover;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;

  /// Pour retomber sur la couverture de la famille si la photo manque.
  final EventCategory? category;

  static final _bytes = <String, Uint8List>{};

  static Uint8List _decode(String uri) =>
      _bytes.putIfAbsent(uri, () => UriData.parse(uri).contentAsBytes());

  Widget _fallback(BuildContext context, Object _, StackTrace? _) {
    final c = category;
    if (c == null) {
      return Container(width: width, height: height, color: Confetti.lavender);
    }
    return Image.asset(
      EventTemplates.cover(c),
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cover.startsWith('data:')) {
      return Image.memory(
        _decode(cover),
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder: _fallback,
      );
    }
    if (cover.startsWith('http')) {
      return Image.network(
        cover,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder: _fallback,
      );
    }
    return Image.asset(
      cover,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      errorBuilder: _fallback,
    );
  }
}

/// Couvertures proposées : celle de la famille de l'événement d'abord.
List<String> suggestedCovers(EventCategory category) {
  const img = 'assets/images';
  const all = [
    '$img/cover_wedding.jpg',
    '$img/cover_birthday.jpg',
    '$img/cover_babyshower.jpg',
    '$img/onboarding_wedding.jpg',
    '$img/onboarding_confetti.jpg',
    '$img/onboarding_balloons.jpg',
    '$img/v/venue_1.jpg',
    '$img/v/venue_2.jpg',
    '$img/v/venue_3.jpg',
    '$img/v/decor_1.jpg',
    '$img/v/decor_2.jpg',
    '$img/v/decor_3.jpg',
    '$img/v/food_3.jpg',
    '$img/v/music_1.jpg',
    '$img/v/activity_1.jpg',
    '$img/shop/tabledeco.jpg',
    '$img/shop/candles.jpg',
    '$img/shop/balloons.jpg',
  ];
  final own = EventTemplates.cover(category);
  return [own, ...all.where((c) => c != own)];
}

/// Feuille « Photo de couverture » : importer une photo ou choisir une
/// couverture proposée, avec aperçu, puis enregistrer.
Future<void> showCoverPicker(BuildContext context, Event event) =>
    showEventaSheet<void>(context, builder: (_) => _CoverSheet(event: event));

class _CoverSheet extends ConsumerStatefulWidget {
  const _CoverSheet({required this.event});

  final Event event;

  @override
  ConsumerState<_CoverSheet> createState() => _CoverSheetState();
}

class _CoverSheetState extends ConsumerState<_CoverSheet> {
  String? _asset;
  Uint8List? _bytes;
  String _mime = 'image/jpeg';
  bool _saving = false;

  bool get _changed =>
      _bytes != null || (_asset != null && _asset != widget.event.cover);

  Future<void> _import() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    // Limite du stockage en ligne : 5 Mo.
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      toast(
        context,
        'Photo trop lourde (5 Mo maximum)'.tr,
        icon: AppIcons.warning,
      );
      return;
    }
    final type = file.mimeType;
    setState(() {
      _bytes = bytes;
      _asset = null;
      _mime = type == 'image/png' || type == 'image/webp'
          ? type!
          : 'image/jpeg';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = Navigator.of(context);
    try {
      await ref
          .read(eventsProvider.notifier)
          .setCover(
            widget.event.id,
            asset: _bytes == null ? _asset : null,
            bytes: _bytes,
            mimeType: _mime,
          );
      if (!mounted) return;
      messenger.pop();
      toast(context, 'Couverture mise à jour'.tr);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      toast(
        context,
        'Impossible d’enregistrer la couverture. Réessayez.'.tr,
        icon: AppIcons.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final current = _asset ?? e.cover;
    final covers = suggestedCovers(e.category);
    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Photo de couverture'.tr, style: context.text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Elle s’affiche en haut de l’événement et sur vos cartes.'.tr,
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 16),
            // Aperçu fidèle : même voile et même titre que l'écran.
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.fast,
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      child: _bytes != null
                          ? Image.memory(
                              _bytes!,
                              key: ValueKey(_bytes.hashCode),
                              fit: BoxFit.cover,
                            )
                          : EventCoverImage(
                              current,
                              key: ValueKey(current),
                              category: e.category,
                              cacheWidth: 1000,
                            ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            e.category.hue.deep.withValues(alpha: 0.85),
                          ],
                          stops: const [0.4, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Text(
                        e.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            PillButton(
              key: const ValueKey('cover-import'),
              label: 'Importer une photo'.tr,
              icon: AppIcons.image,
              tone: ButtonTone.ghost,
              height: 48,
              onPressed: _saving ? null : _import,
            ),
            const SizedBox(height: 18),
            Text('Couvertures proposées'.tr, style: context.text.titleSmall),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, box) {
                final cols = box.maxWidth >= 520 ? 4 : 3;
                const gap = 8.0;
                final w = (box.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final c in covers)
                      _Thumb(
                        path: c,
                        width: w,
                        selected: _bytes == null && c == current,
                        onTap: _saving
                            ? null
                            : () => setState(() {
                                _asset = c;
                                _bytes = null;
                              }),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            PillButton(
              key: const ValueKey('cover-save'),
              label: 'Enregistrer la couverture'.tr,
              loading: _saving,
              onPressed: _changed && !_saving ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.path,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final String path;
  final double width;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Couverture proposée'.tr,
      child: AnimatedContainer(
        duration: Motion.fast,
        width: width,
        height: width * 0.66,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Confetti.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(path, fit: BoxFit.cover, cacheWidth: 360),
              if (selected)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Confetti.ink,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.check,
                      size: 13,
                      color: Confetti.onInk,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

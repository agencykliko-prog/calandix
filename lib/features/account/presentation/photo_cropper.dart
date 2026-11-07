import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';

/// Importe une image, laisse l'utilisateur la recadrer (glisser, pincer,
/// curseur de zoom) dans un cercle, et renvoie le résultat en PNG.
Future<Uint8List?> pickAndCropPhoto(BuildContext context) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
  );
  if (file == null || !context.mounted) return null;
  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;
  return Navigator.of(context, rootNavigator: true).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _CropScreen(source: bytes),
    ),
  );
}

class _CropScreen extends StatefulWidget {
  const _CropScreen({required this.source});

  final Uint8List source;

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _boundary = GlobalKey();
  final _controller = TransformationController();
  double _zoom = 1;
  bool _preview = false;
  Uint8List? _result;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setZoom(double z) {
    final m = _controller.value.clone();
    final current = m.getMaxScaleOnAxis();
    final f = z / current;
    // Zoom autour du centre du cadre.
    const c = 140.0;
    m
      ..translateByDouble(c, c, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-c, -c, 0, 1);
    _controller.value = m;
    setState(() => _zoom = z);
  }

  Future<void> _capture() async {
    setState(() => _busy = true);
    final ro =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = data!.buffer.asUint8List();
      _preview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Confetti.dark ? Confetti.cream : Confetti.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: _preview ? AppIcons.back : AppIcons.close,
                    background: Confetti.night,
                    foreground: Colors.white,
                    tooltip: _preview ? 'Retour au recadrage'.tr : 'Annuler'.tr,
                    onTap: () => _preview
                        ? setState(() => _preview = false)
                        : Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    _preview ? 'Aperçu'.tr : 'Recadrer'.tr,
                    style: context.text.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _preview && _result != null
                      ? Column(
                          key: const ValueKey('p'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundImage: MemoryImage(_result!),
                            ),
                            const SizedBox(height: 18),
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: MemoryImage(_result!),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Voici comment votre photo apparaîtra.'.tr,
                              style: context.text.bodySmall?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          key: const ValueKey('c'),
                          width: 280,
                          height: 280,
                          child: Stack(
                            children: [
                              RepaintBoundary(
                                key: _boundary,
                                child: ClipOval(
                                  child: InteractiveViewer(
                                    transformationController: _controller,
                                    minScale: 1,
                                    maxScale: 4,
                                    onInteractionEnd: (_) => setState(
                                      () => _zoom = _controller.value
                                          .getMaxScaleOnAxis(),
                                    ),
                                    child: Image.memory(
                                      widget.source,
                                      width: 280,
                                      height: 280,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  if (!_preview) ...[
                    Text(
                      'Glissez pour cadrer, pincez ou utilisez le curseur pour zoomer.'
                          .tr,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          AppIcons.minus,
                          color: Colors.white54,
                          size: 16,
                        ),
                        Expanded(
                          child: Slider(
                            value: _zoom.clamp(1, 4),
                            min: 1,
                            max: 4,
                            activeColor: Colors.white,
                            inactiveColor: Confetti.nightLine,
                            onChanged: _setZoom,
                          ),
                        ),
                        const Icon(
                          AppIcons.add,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PillButton(
                      label: 'Aperçu'.tr,
                      tone: ButtonTone.light,
                      loading: _busy,
                      onPressed: _capture,
                    ),
                  ] else
                    PillButton(
                      label: 'Utiliser cette photo'.tr,
                      icon: AppIcons.check,
                      onPressed: () => Navigator.of(context).pop(_result),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import 'signature_provider.dart';

/// Tracé de la signature, enregistré une fois pour toutes les pièces à venir.
class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  final _strokes = <List<Offset>>[];
  Size _size = Size.zero;
  bool _agreed = false;
  bool _busy = false;
  bool _redo = false;

  bool get _drawn => _strokes.fold<int>(0, (s, l) => s + l.length) >= 8;

  Future<void> _save() async {
    setState(() => _busy = true);
    final png = await renderSignature(_strokes, _size);
    final ok = await ref.read(signatureProvider.notifier).save(png);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _redo = false;
      _strokes.clear();
      _agreed = false;
    });
    toast(
      context,
      ok
          ? 'Signature enregistrée'.tr
          : 'Signature non enregistrée. Vérifiez votre connexion puis réessayez.'
                .tr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(signatureProvider);
    final drawing = saved == null || _redo;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: RoundIconButton(
              icon: AppIcons.back,
              tooltip: 'Retour',
              onTap: () => context.pop(),
            ),
          ),
        ),
        leadingWidth: 64,
        title: Text('Ma signature'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        // Le doigt signe : la page ne défile pas pendant le tracé.
        physics: drawing ? const NeverScrollableScrollPhysics() : null,
        children: [
          Text(
            'Elle s’ajoute automatiquement à vos devis et factures.'.tr,
            style: context.text.bodyMedium?.copyWith(
              color: context.eventa.muted,
            ),
          ),
          const SizedBox(height: 16),
          if (drawing) ...[
            _Pad(
              strokes: _strokes,
              onSize: (s) => _size = s,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Signez dans le cadre'.tr,
                    style: context.text.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: _strokes.isEmpty
                      ? null
                      : () => setState(_strokes.clear),
                  child: Text('Effacer'.tr),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CheckRow(
              label: 'Je reconnais cette signature comme la mienne et j’autorise Calandix à l’apposer sur mes devis et factures.'
                  .tr,
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v),
            ),
            const SizedBox(height: 16),
            PillButton(
              label: 'Enregistrer ma signature'.tr,
              icon: AppIcons.check,
              loading: _busy,
              onPressed: _drawn && _agreed ? _save : null,
            ),
            if (saved != null) ...[
              const SizedBox(height: 8),
              PillButton(
                label: 'Annuler'.tr,
                tone: ButtonTone.ghost,
                onPressed: () => setState(() {
                  _redo = false;
                  _strokes.clear();
                }),
              ),
            ],
          ] else ...[
            SignatureBlock(image: saved),
            const SizedBox(height: 16),
            PillButton(
              label: 'Refaire ma signature'.tr,
              icon: AppIcons.edit,
              tone: ButtonTone.ghost,
              onPressed: () => setState(() => _redo = true),
            ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Supprimer ma signature'.tr,
              icon: AppIcons.trash,
              tone: ButtonTone.ghost,
              onPressed: () => ref.read(signatureProvider.notifier).clear(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Image PNG transparente du tracé, en encre fixe (lisible sur fond blanc).
Future<Uint8List> renderSignature(List<List<Offset>> strokes, Size size) async {
  const scale = 2.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  _paintStrokes(canvas, strokes, Confetti.inkFixed);
  final image = await recorder.endRecording().toImage(
    (size.width * scale).ceil(),
    (size.height * scale).ceil(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void _paintStrokes(Canvas canvas, List<List<Offset>> strokes, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final s in strokes) {
    if (s.length == 1) {
      canvas.drawCircle(s.first, 1.3, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      continue;
    }
    final path = Path()..moveTo(s.first.dx, s.first.dy);
    // Courbes entre les milieux des points : un trait souple, sans angles.
    for (var i = 1; i < s.length - 1; i++) {
      final mid = (s[i] + s[i + 1]) / 2;
      path.quadraticBezierTo(s[i].dx, s[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(s.last.dx, s.last.dy);
    canvas.drawPath(path, paint);
  }
}

class _Pad extends StatelessWidget {
  const _Pad({
    required this.strokes,
    required this.onSize,
    required this.onChanged,
  });

  final List<List<Offset>> strokes;
  final ValueChanged<Size> onSize;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, 220);
        onSize(size);
        return Semantics(
          label: 'Zone de signature'.tr,
          child: ClipRRect(
            key: const ValueKey('signature-pad'),
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) {
                strokes.add([d.localPosition]);
                onChanged();
              },
              onPanUpdate: (d) {
                strokes.last.add(d.localPosition);
                onChanged();
              },
              child: CustomPaint(size: size, painter: _PadPainter(strokes)),
            ),
          ),
        );
      },
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    // Ligne de signature.
    final y = size.height * .74;
    canvas.drawLine(
      Offset(24, y),
      Offset(size.width - 24, y),
      Paint()
        ..color = const Color(0xFFDDD8E8)
        ..strokeWidth = 1,
    );
    _paintStrokes(canvas, strokes, Confetti.inkFixed);
  }

  @override
  bool shouldRepaint(_PadPainter old) => true;
}

/// Bloc de signature d'un devis ou d'une facture : l'image sur fond blanc,
/// le signataire et la date.
class SignatureBlock extends ConsumerWidget {
  const SignatureBlock({super.key, required this.image, this.signedAt});

  final Uint8List image;
  final DateTime? signedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final who = p.creator?.displayName ?? p.name;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Confetti.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.memory(image, height: 70, gaplessPlayback: true),
          const SizedBox(height: 4),
          Text(
            signedAt == null
                ? 'Signature de {0}'.trf([who])
                : 'Signé électroniquement par {0} le {1}'.trf([
                    who,
                    mediumDate(signedAt!),
                  ]),
            style: context.text.bodySmall?.copyWith(color: Confetti.inkFixed),
          ),
        ],
      ),
    );
  }
}

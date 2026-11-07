import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../pro/presentation/signature_screen.dart';

/// « Bon pour accord » signé par l'organisateur avant que le devis soit
/// validé : qui a signé, quand, pour quel montant, avec quelle signature.
@immutable
class QuoteSignature {
  const QuoteSignature({
    required this.signer,
    required this.at,
    required this.png,
    required this.reference,
    required this.total,
    required this.deposit,
  });
  final String signer;
  final DateTime at;
  final Uint8List png;

  /// Référence horodatée (empreinte de démonstration).
  final String reference;

  /// Montants acceptés au moment de la signature.
  final int total;
  final int deposit;
}

class QuoteSignaturesNotifier extends Notifier<Map<String, QuoteSignature>> {
  @override
  Map<String, QuoteSignature> build() => const {};

  void sign(String bookingId, QuoteSignature s) =>
      state = {...state, bookingId: s};
}

final quoteSignaturesProvider =
    NotifierProvider<QuoteSignaturesNotifier, Map<String, QuoteSignature>>(
      QuoteSignaturesNotifier.new,
    );

/// Référence courte et horodatée d'une signature.
String signatureRef(String prefix, String seed, DateTime at) {
  final h = (seed.hashCode ^ at.millisecondsSinceEpoch)
      .toUnsigned(32)
      .toRadixString(16)
      .toUpperCase()
      .padLeft(8, '0');
  return '$prefix-$h';
}

/// Ouvre la signature du devis. Renvoie `true` si l'organisateur a signé :
/// le devis est alors accepté et la date bloquée.
Future<bool> showQuoteSignSheet(BuildContext context, Booking booking) async {
  final ok = await showEventaSheet<bool>(
    context,
    builder: (_) => _QuoteSignSheet(booking: booking),
  );
  return ok ?? false;
}

class _QuoteSignSheet extends ConsumerStatefulWidget {
  const _QuoteSignSheet({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_QuoteSignSheet> createState() => _QuoteSignSheetState();
}

class _QuoteSignSheetState extends ConsumerState<_QuoteSignSheet> {
  final _strokes = <List<Offset>>[];
  late final _name = TextEditingController(
    text: ref.read(sessionProvider)?.name ?? '',
  );
  Size _size = Size.zero;
  bool _agreed = false;
  bool _busy = false;

  bool get _drawn => _strokes.fold<int>(0, (s, l) => s + l.length) >= 8;
  bool get _ready => _drawn && _agreed && _name.text.trim().length >= 2;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _sign() async {
    setState(() => _busy = true);
    final b = widget.booking;
    final q = b.quote!;
    final png = await renderSignature(_strokes, _size);
    final now = DateTime.now();
    final signer = _name.text.trim();
    final reference = signatureRef('DV', b.id, now);
    ref
        .read(quoteSignaturesProvider.notifier)
        .sign(
          b.id,
          QuoteSignature(
            signer: signer,
            at: now,
            png: png,
            reference: reference,
            total: q.total,
            deposit: q.deposit,
          ),
        );
    // Le devis signé rejoint le coffre-fort de l'événement.
    ref
        .read(vaultProvider.notifier)
        .add(
          VaultDoc(
            name: 'Devis signé {0}.pdf'.trf([b.vendor.name]),
            folder: VaultFolder.quotes,
            sizeKb: 180,
            date: now,
            eventId: b.eventId,
          ),
        );
    ref
        .read(bookingsProvider.notifier)
        .accept(
          b.id,
          note: 'Devis signé électroniquement par {0} · réf. {1}'.trf([
            signer,
            reference,
          ]),
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final q = b.quote!;
    Widget line(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.text.bodySmall)),
          Text(
            value,
            style: strong ? context.text.titleSmall : context.text.bodyMedium,
          ),
        ],
      ),
    );
    // La case et le bouton restent fixés en bas : une fois la signature
    // tracée, la feuille ne défile plus (le doigt signe) et tout reste
    // atteignable.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            physics: _strokes.isNotEmpty
                ? const NeverScrollableScrollPhysics()
                : null,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              Text('Signer le devis'.tr, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Votre signature vaut bon pour accord : le prestataire bloque la date et vous recevez une copie horodatée.'
                    .tr,
                style: context.text.bodySmall,
              ),
              const SizedBox(height: 14),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.vendor.name, style: context.text.titleSmall),
                    Text(
                      longDate(b.request.date),
                      style: context.text.bodySmall,
                    ),
                    const Divider(height: 20),
                    for (final l in q.lines) line(l.label, fcfa(l.amount)),
                    if (q.fees > 0) line('Frais de service'.tr, fcfa(q.fees)),
                    const Divider(height: 16),
                    line('Total TTC'.tr, fcfa(q.total), strong: true),
                    line('Acompte à la réservation'.tr, fcfa(q.deposit)),
                    if (q.conditions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        q.conditions.join(' · '),
                        style: context.text.labelSmall?.copyWith(
                          color: context.eventa.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppField(
                controller: _name,
                label: 'Nom du signataire'.tr,
                prefix: const Icon(AppIcons.user, size: 18),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Votre signature'.tr,
                      style: context.text.titleSmall,
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
              SignaturePad(
                strokes: _strokes,
                onSize: (s) => _size = s,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Confetti.line)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckRow(
                label: 'J’accepte ce devis, ses conditions et la politique d’annulation. Ma signature électronique a la même valeur qu’une signature manuscrite.'
                    .tr,
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v),
              ),
              const SizedBox(height: 14),
              PillButton(
                key: const ValueKey('sign-quote'),
                label: 'Signer et accepter le devis'.tr,
                icon: AppIcons.edit,
                loading: _busy,
                onPressed: _ready ? _sign : null,
              ),
              const SizedBox(height: 8),
              Text(
                _ready
                    ? 'Vous pourrez encore annuler selon les conditions du prestataire.'
                          .tr
                    : 'Signez dans le cadre et cochez la case pour continuer.'
                          .tr,
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Trace de l'accord dans la réservation : signataire, date, référence.
class QuoteSignatureCard extends ConsumerWidget {
  const QuoteSignatureCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quoteSignaturesProvider)[booking.id];
    if (s == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(context, s),
    );
  }

  Widget _card(BuildContext context, QuoteSignature s) {
    return Panel(
      child: Row(
        children: [
          IconTile(icon: AppIcons.edit, hue: Hue.lagoon, size: 40, solid: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Devis signé'.tr, style: context.text.titleSmall),
                Text(
                  'Par {0} le {1} à {2} · réf. {3}'.trf([
                    s.signer,
                    mediumDate(s.at),
                    timeOf(s.at),
                    s.reference,
                  ]),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(
            label: 'Voir'.tr,
            expand: false,
            height: 38,
            tone: ButtonTone.ghost,
            onPressed: () => showEventaSheet<void>(
              context,
              builder: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Devis signé'.tr, style: context.text.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      '{0} · {1}'.trf([booking.vendor.name, fcfa(s.total)]),
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ColoredBox(
                        color: Colors.white,
                        child: Image.memory(
                          s.png,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Signé par {0} le {1} à {2}'.trf([
                        s.signer,
                        mediumDate(s.at),
                        timeOf(s.at),
                      ]),
                      style: context.text.titleSmall,
                    ),
                    Text(
                      'Référence {0} · horodatée'.trf([s.reference]),
                      style: context.text.labelSmall?.copyWith(
                        color: context.eventa.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

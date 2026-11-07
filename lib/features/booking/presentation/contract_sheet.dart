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

/// Contrat signé par l'organisateur, dans la réservation.
@immutable
class SignedContract {
  const SignedContract({
    required this.signer,
    required this.at,
    required this.png,
    required this.reference,
  });
  final String signer;
  final DateTime at;
  final Uint8List png;

  /// Référence du contrat (horodatage et empreinte de démonstration).
  final String reference;
}

class ContractsNotifier extends Notifier<Map<String, SignedContract>> {
  @override
  Map<String, SignedContract> build() => const {};

  void sign(String bookingId, SignedContract c) =>
      state = {...state, bookingId: c};
}

final contractsProvider =
    NotifierProvider<ContractsNotifier, Map<String, SignedContract>>(
      ContractsNotifier.new,
    );

/// Encart « Contrat de prestation » de la réservation.
class ContractCard extends ConsumerWidget {
  const ContractCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(contractsProvider)[booking.id];
    return Panel(
      child: Row(
        children: [
          IconTile(
            icon: AppIcons.contract,
            hue: c == null ? Hue.mango : Hue.lagoon,
            size: 40,
            solid: c != null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contrat de prestation'.tr,
                  style: context.text.titleSmall,
                ),
                Text(
                  c == null
                      ? 'Signé par {0} · en attente de votre signature'.trf([
                          booking.vendor.name,
                        ])
                      : 'Signé par les deux parties le {0}'.trf([
                          mediumDate(c.at),
                        ]),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(
            key: ValueKey('contract-${booking.id}'),
            label: c == null ? 'Signer'.tr : 'Voir'.tr,
            expand: false,
            height: 38,
            tone: c == null ? ButtonTone.primary : ButtonTone.ghost,
            onPressed: () => showEventaSheet<void>(
              context,
              builder: (_) => _ContractSheet(booking: booking),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractSheet extends ConsumerStatefulWidget {
  const _ContractSheet({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_ContractSheet> createState() => _ContractSheetState();
}

class _ContractSheetState extends ConsumerState<_ContractSheet> {
  final _strokes = <List<Offset>>[];
  Size _size = Size.zero;
  bool _agreed = false;
  bool _busy = false;

  bool get _drawn => _strokes.fold<int>(0, (s, l) => s + l.length) >= 8;

  Future<void> _sign() async {
    setState(() => _busy = true);
    final b = widget.booking;
    final png = await renderSignature(_strokes, _size);
    final now = DateTime.now();
    final name = ref.read(sessionProvider)?.name ?? '';
    final ref6 = (b.id.hashCode ^ now.millisecondsSinceEpoch)
        .toUnsigned(32)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0');
    ref
        .read(contractsProvider.notifier)
        .sign(
          b.id,
          SignedContract(
            signer: name,
            at: now,
            png: png,
            reference: 'CT-$ref6',
          ),
        );
    // Copie du contrat signé dans le coffre-fort.
    ref
        .read(vaultProvider.notifier)
        .add(
          VaultDoc(
            name: 'Contrat signé {0}.pdf'.trf([b.vendor.name]),
            folder: VaultFolder.contracts,
            sizeKb: 240,
            date: now,
            eventId: b.eventId,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    toast(
      context,
      'Contrat signé, copie rangée dans le coffre-fort'.tr,
      icon: AppIcons.contract,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final q = b.quote!;
    final signed = ref.watch(contractsProvider)[b.id];
    final me = ref.watch(sessionProvider)?.name ?? '';
    Widget clause(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall),
          const SizedBox(height: 2),
          Text(body, style: context.text.bodySmall),
        ],
      ),
    );
    // Case et bouton fixés en bas : la feuille ne défile plus pendant la
    // signature, ils restent donc atteignables.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            physics: signed == null && _strokes.isNotEmpty
                ? const NeverScrollableScrollPhysics()
                : null,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              Text(
                'Contrat de prestation'.tr,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: 12),
              clause(
                '1. Parties'.tr,
                '{0} (organisateur) et {1} (prestataire), mis en relation par Calandix.'
                    .trf([me, b.vendor.name]),
              ),
              clause(
                '2. Prestation'.tr,
                '{0}, le {1}.'.trf([
                  [for (final l in q.lines) l.label].join(', '),
                  longDate(b.request.date),
                ]),
              ),
              clause(
                '3. Prix et paiement'.tr,
                'Total {0} TTC. Acompte de {1} à la réservation, solde avant la prestation, payés via Calandix.'
                    .trf([fcfa(q.total), fcfa(q.deposit)]),
              ),
              if (q.conditions.isNotEmpty)
                clause(
                  '4. Conditions du prestataire'.tr,
                  q.conditions.join(' · '),
                ),
              clause(
                q.conditions.isNotEmpty
                    ? '5. Annulation et litiges'.tr
                    : '4. Annulation et litiges'.tr,
                'Les conditions d’annulation du devis s’appliquent. En cas de désaccord, la médiation Calandix intervient avant toute autre démarche.'
                    .tr,
              ),
              const Divider(height: 24),
              if (signed != null) ...[
                Text(
                  'Signé par {0} le {1} à {2}'.trf([
                    signed.signer,
                    mediumDate(signed.at),
                    timeOf(signed.at),
                  ]),
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    signed.png,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Référence {0} · horodatée'.trf([signed.reference]),
                  style: context.text.labelSmall?.copyWith(
                    color: context.eventa.muted,
                  ),
                ),
              ] else ...[
                Text('Votre signature'.tr, style: context.text.titleSmall),
                const SizedBox(height: 8),
                SignaturePad(
                  strokes: _strokes,
                  onSize: (s) => _size = s,
                  onChanged: () => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => setState(_strokes.clear),
                    child: Text('Effacer'.tr),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (signed == null)
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
                  label: 'J’ai lu le contrat et je l’accepte. Ma signature électronique a la même valeur qu’une signature manuscrite.'
                      .tr,
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v),
                ),
                const SizedBox(height: 14),
                PillButton(
                  label: 'Signer le contrat'.tr,
                  icon: AppIcons.contract,
                  loading: _busy,
                  onPressed: _drawn && _agreed ? _sign : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/ui.dart';
import '../../domain/admin_models.dart';
import '../admin_providers.dart';
import '../widgets/admin_widgets.dart';
import '../../../ui/dataviz/dataviz.dart';

/// Modèle économique : commissions, frais, abonnements, avec simulateur.
class PricingModule extends ConsumerStatefulWidget {
  const PricingModule({super.key});

  @override
  ConsumerState<PricingModule> createState() => _PricingModuleState();
}

class _PricingModuleState extends ConsumerState<PricingModule> {
  late PricingModel _draft = ref.read(adminProvider).pricing;
  double _sample = 1000000;

  bool get _dirty => !identical(_draft, ref.read(adminProvider).pricing);

  @override
  Widget build(BuildContext context) {
    ref.watch(adminProvider.select((s) => s.pricing));
    final p = _draft;
    final fee = _sample * p.serviceFee / 100;
    final mm = (_sample + fee) * p.mobileMoneyFee / 100;
    final commission = _sample * p.commission / 100;
    final clientPays = _sample + fee + mm;
    final vendorGets = _sample - commission;
    final eventa = fee + commission;

    Widget slider(
      String label,
      String caption,
      double value,
      double max,
      ValueChanged<double> onChanged, {
      String unit = '%',
      int divisions = 40,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TwoLines(label, caption)),
              Text(
                '${value.toStringAsFixed(unit == '%' ? 1 : 0).replaceAll('.', ',')} $unit',
                style: context.text.titleMedium,
              ),
            ],
          ),
          Slider(
            value: value,
            max: max,
            min: unit == '%' ? 0 : 1,
            divisions: divisions,
            activeColor: Confetti.violet,
            onChanged: onChanged,
          ),
        ],
      ),
    );

    final settings = Panel(
      child: Column(
        children: [
          slider(
            'Commission prestataire',
            'Prélevée sur chaque réservation payée',
            p.commission,
            20,
            (v) => setState(() => _draft = p.copyWith(commission: v)),
          ),
          slider(
            'Frais de service client',
            'Ajoutés au montant payé par l’organisateur',
            p.serviceFee,
            10,
            (v) => setState(() => _draft = p.copyWith(serviceFee: v)),
          ),
          slider(
            'Frais Mobile Money répercutés',
            'Coût opérateur refacturé au client',
            p.mobileMoneyFee,
            3,
            (v) => setState(() => _draft = p.copyWith(mobileMoneyFee: v)),
            divisions: 30,
          ),
          slider(
            'Délai de reversement',
            'Après validation de la prestation',
            p.payoutDelayDays.toDouble(),
            7,
            (v) =>
                setState(() => _draft = p.copyWith(payoutDelayDays: v.round())),
            unit: 'j',
            divisions: 6,
          ),
        ],
      ),
    );

    final simulator = NightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulateur',
            style: context.text.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            'Réservation de ${fcfa(_sample)}',
            style: context.text.bodySmall?.copyWith(color: Colors.white60),
          ),
          Slider(
            value: _sample,
            min: 100000,
            max: 5000000,
            divisions: 49,
            activeColor: Confetti.gold,
            onChanged: (v) => setState(() => _sample = v),
          ),
          for (final (k, v, strong) in [
            ('L’organisateur paie', clientPays, false),
            ('Le prestataire reçoit', vendorGets, false),
            ('Calandix encaisse', eventa, true),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      k,
                      style: context.text.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Text(
                    fcfa(v.round()),
                    style:
                        (strong
                                ? context.text.titleLarge
                                : context.text.titleSmall)
                            ?.copyWith(
                              color: strong ? Confetti.gold : Colors.white,
                            ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Taux de prise : ${(eventa / _sample * 100).toStringAsFixed(1).replaceAll('.', ',')} % du montant de la prestation',
            style: context.text.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Modèle économique',
          subtitle: 'Commissions, frais et abonnements. Les changements s’appliquent aux nouvelles réservations.',
          actions: [
            AdminButton(
              label: 'Annuler',
              tone: ButtonTone.ghost,
              onPressed: _dirty
                  ? () =>
                        setState(() => _draft = ref.read(adminProvider).pricing)
                  : null,
            ),
            AdminButton(
              label: 'Enregistrer',
              icon: AppIcons.check,
              onPressed: _dirty
                  ? () {
                      if (!guard(context, ref, AdminPermission.pricing)) return;
                      ref
                          .read(adminProvider.notifier)
                          .setPricing(
                            _draft,
                            'Commission ${_draft.commission.toStringAsFixed(1)} %, frais ${_draft.serviceFee.toStringAsFixed(1)} %',
                          );
                      _draft = ref.read(adminProvider).pricing;
                      toast(context, 'Modèle économique enregistré');
                    }
                  : null,
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 860
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: settings),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: simulator),
                  ],
                )
              : Column(
                  children: [settings, const SizedBox(height: 12), simulator],
                ),
        ),
        const BlockTitle('Commissions par catégorie'),
        Panel(
          child: Column(
            children: [
              for (final e in p.categoryCommission.entries)
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(e.key, style: context.text.titleSmall),
                    ),
                    Expanded(
                      child: Slider(
                        value: e.value,
                        max: 20,
                        divisions: 40,
                        activeColor: Confetti.violet,
                        onChanged: (v) => setState(
                          () => _draft = p.copyWith(
                            categoryCommission: {
                              ...p.categoryCommission,
                              e.key: v,
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        '${e.value.toStringAsFixed(1).replaceAll('.', ',')} %',
                        textAlign: TextAlign.right,
                        style: context.text.labelMedium,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const BlockTitle('Abonnements mensuels'),
        KpiGrid(
          minTile: 220,
          children: [
            for (final e in p.subscriptions.entries)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key, style: context.text.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: '${e.value}',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: context.text.titleMedium,
                      decoration: const InputDecoration(
                        suffixText: 'FCFA / mois',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n == null) return;
                        setState(
                          () => _draft = _draft.copyWith(
                            subscriptions: {..._draft.subscriptions, e.key: n},
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.key.endsWith('(prestataire)')
                          ? 'Formule prestataire'
                          : 'Offre Organisateur',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

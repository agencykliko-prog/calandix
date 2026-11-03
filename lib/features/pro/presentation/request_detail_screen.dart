import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';
import '../../marketplace/presentation/explore_screen.dart';
import '../domain/pro_models.dart';
import 'pro_providers.dart';
import 'pro_widgets.dart';
import 'signature_provider.dart';
import 'signature_screen.dart';

/// C. Devis & demandes : détail d'une demande, questions au client,
/// devis détaillé avec options et validité, acceptation ou refus.
class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailState();
}

class _RequestDetailState extends ConsumerState<RequestDetailScreen> {
  final _question = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ref
        .watch(requestsProvider)
        .where((x) => x.id == widget.id)
        .firstOrNull;
    if (r == null) {
      return ProPage(
        title: 'Demande introuvable'.tr,
        subtitle: '',
        children: const [],
      );
    }
    final full = ref.watch(dayFullProvider(r.date));
    final load = ref.watch(dayLoadProvider(r.date));
    final terms = ref.watch(proProvider.select((s) => s.catalog.terms));
    final (statusHue, statusLabel) = switch (r.status) {
      RequestStatus.received => (Hue.coral, r.status.label),
      RequestStatus.quoted when r.expired => (Hue.ink, 'Devis expiré'.tr),
      RequestStatus.quoted => (Hue.mango, r.status.label),
      RequestStatus.confirmed => (Hue.lagoon, r.status.label),
      RequestStatus.declined => (Hue.ink, r.status.label),
    };

    return ProPage(
      title: r.eventName,
      subtitle: 'Demande reçue {0}'.trf([_since(r.receivedAt)]),
      children: [
        const SizedBox(height: 8),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(image: r.avatar, initials: r.client[0], size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.client, style: context.text.titleMedium),
                        Text(r.category.label, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  Tag(label: statusLabel, hue: statusHue),
                ],
              ),
              const Divider(height: 24),
              InfoLine('Date'.tr, '${longDate(r.date)} · ${timeOf(r.date)}'),
              InfoLine(
                'Durée'.tr,
                '{0} h'.trf([
                  (r.durationMin / 60).toStringAsFixed(1).replaceAll('.0', ''),
                ]),
              ),
              if (r.place != null) InfoLine('Lieu'.tr, r.place!),
              InfoLine('Invités'.tr, '${r.guests}'),
              if (r.budget != null)
                InfoLine('Budget indicatif'.tr, fcfa(r.budget!)),
              const SizedBox(height: 10),
              Text('« ${r.message} »', style: context.text.bodyMedium),
              if (r.options.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final o in r.options) Tag(label: o, hue: Hue.violet),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Contrôle de disponibilité (prévention des doubles réservations).
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: full && r.status != RequestStatus.confirmed
                ? Confetti.coralTint
                : Confetti.lagoonTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                full && r.status != RequestStatus.confirmed
                    ? AppIcons.warning
                    : AppIcons.calendarCheck,
                size: 18,
                color: full && r.status != RequestStatus.confirmed
                    ? Confetti.coralDeep
                    : Confetti.lagoonText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  full && r.status != RequestStatus.confirmed
                      ? 'Vous êtes complet ou indisponible ce jour-là. Libérez la date avant d’accepter.'
                            .tr
                      : 'Disponible : {0} / {1} prestations prévues ce jour-là.'
                            .trf([
                              load,
                              ref
                                  .watch(proProvider)
                                  .availability
                                  .capacityPerDay,
                            ]),
                  style: context.text.bodySmall?.copyWith(
                    color: full && r.status != RequestStatus.confirmed
                        ? Confetti.coralDeep
                        : Confetti.lagoonText,
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionTitle('Questions au client'.tr),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (r.thread.isEmpty)
                Text(
                  'Une précision avant de chiffrer ? Posez votre question ici.'
                      .tr,
                  style: context.text.bodySmall,
                ),
              for (final m in r.thread)
                Align(
                  alignment: m.fromMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: m.fromMe ? Confetti.ink : Confetti.lavender,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m.text,
                      style: context.text.bodyMedium?.copyWith(
                        color: m.fromMe ? Confetti.onInk : Confetti.ink,
                      ),
                    ),
                  ),
                ),
              if (r.status != RequestStatus.declined &&
                  r.status != RequestStatus.confirmed) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _question,
                        style: context.text.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Ex. Le lieu dispose-t-il de prises ?'.tr,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _ask(r),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: AppIcons.send,
                      tooltip: 'Envoyer',
                      background: Confetti.ink,
                      foreground: Confetti.onInk,
                      onTap: () => _ask(r),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (r.items.isNotEmpty || r.quote != null) ...[
          SectionTitle('Devis'.tr),
          Panel(
            child: Column(
              children: [
                for (final i in r.items)
                  InfoLine(
                    i.option ? '{0} (option)'.trf([i.label]) : i.label,
                    fcfa(i.amount),
                  ),
                if (r.items.isNotEmpty) const Divider(height: 20),
                InfoLine('Total'.tr, fcfa(r.quote ?? 0), strong: true),
                InfoLine(
                  'Acompte ({0} %)'.trf([r.depositPercent]),
                  fcfa(((r.quote ?? 0) * r.depositPercent / 100).round()),
                ),
                if (r.lastOffer != null)
                  InfoLine('Dernière offre'.tr, fcfa(r.lastOffer!)),
                InfoLine(
                  'Vous recevrez (après commission 8 %)'.tr,
                  fcfa(((r.quote ?? 0) * (1 - proCommissionRate)).round()),
                ),
                if (r.validUntil != null)
                  InfoLine('Valable jusqu’au'.tr, mediumDate(r.validUntil!)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _QuoteSignature(request: r),
        ],
        if (r.status == RequestStatus.declined && r.declineReason != null) ...[
          const SizedBox(height: 12),
          Text(
            'Refusée : {0}'.trf([r.declineReason]),
            style: context.text.bodySmall,
          ),
        ],
        const SizedBox(height: 18),
        ..._actions(context, r, full, terms),
      ],
    );
  }

  List<Widget> _actions(
    BuildContext context,
    ClientRequest r,
    bool full,
    SaleTerms terms,
  ) {
    final n = ref.read(requestsProvider.notifier);
    switch (r.status) {
      case RequestStatus.received:
        return [
          PillButton(
            label: 'Établir le devis'.tr,
            icon: AppIcons.file,
            onPressed: full ? null : () => _quote(context, r, terms),
          ),
          const SizedBox(height: 8),
          PillButton(
            label: 'Refuser la demande'.tr,
            tone: ButtonTone.ghost,
            onPressed: () => _decline(context, r),
          ),
        ];
      case RequestStatus.quoted:
        return [
          PillButton(
            label: 'Accepter la commande'.tr,
            icon: AppIcons.calendarCheck,
            onPressed: full
                ? null
                : () {
                    n.confirm(r.id);
                    ref.read(soundProvider).play(Sfx.booking);
                    toast(
                      context,
                      'Commande acceptée, date ajoutée à votre agenda'.tr,
                    );
                  },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              'À utiliser quand le client a validé votre devis et réglé l’acompte.'
                  .tr,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ),
          PillButton(
            label: r.expired
                ? 'Renouveler le devis'.tr
                : 'Modifier le devis'.tr,
            icon: AppIcons.edit,
            tone: ButtonTone.ghost,
            onPressed: () => _quote(context, r, terms),
          ),
          const SizedBox(height: 8),
          PillButton(
            label: 'Refuser'.tr,
            tone: ButtonTone.ghost,
            onPressed: () => _decline(context, r),
          ),
        ];
      case RequestStatus.confirmed:
        return [
          PillButton(
            label: 'Suivre la commande'.tr,
            icon: AppIcons.forward,
            tone: ButtonTone.dark,
            onPressed: () => context.push('/pro/commandes'),
          ),
        ];
      case RequestStatus.declined:
        return const [];
    }
  }

  void _ask(ClientRequest r) {
    final q = _question.text.trim();
    if (q.isEmpty) return;
    ref
        .read(requestsProvider.notifier)
        .ask(
          r.id,
          q,
          simulatedReply:
              'Merci pour la question ! Je vous confirme cela dès que possible.'
                  .tr,
        );
    _question.clear();
    FocusScope.of(context).unfocus();
  }

  void _decline(BuildContext context, ClientRequest r) {
    var reason = 'Date indisponible'.tr;
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Refuser la demande'.tr, style: ctx.text.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Le client est prévenu avec le motif choisi.'.tr,
                style: ctx.text.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in [
                    'Date indisponible'.tr,
                    'Hors de ma zone'.tr,
                    'Budget insuffisant'.tr,
                    'Prestation hors catalogue'.tr,
                  ])
                    Choice(
                      label: m,
                      on: reason == m,
                      onTap: () => set(() => reason = m),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'Confirmer le refus'.tr,
                tone: ButtonTone.dark,
                onPressed: () {
                  ref
                      .read(requestsProvider.notifier)
                      .decline(r.id, reason: reason);
                  Navigator.of(ctx).pop();
                  toast(context, 'Demande refusée'.tr);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quote(BuildContext context, ClientRequest r, SaleTerms terms) {
    final cat = ref.read(proProvider).catalog;
    final packages = cat.packages.where((p) => p.active).toList();
    final options = cat.options.where((o) => o.active).toList();
    ProPackage? pkg = packages.isEmpty ? null : packages.first;
    final picked = <String>{};
    var validity = terms.quoteValidityDays;
    var deposit = terms.depositPercent;
    var travel = false;
    final customLabel = TextEditingController();
    final customAmount = TextEditingController();
    final lastOffer = TextEditingController();

    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final custom = int.tryParse(customAmount.text) ?? 0;
          final items = [
            if (pkg != null)
              QuoteItem('Forfait {0}'.trf([pkg!.name]), pkg!.price),
            for (final o in options.where((o) => picked.contains(o.id)))
              QuoteItem(o.name, o.price, option: true),
            if (travel) QuoteItem('Frais de déplacement'.tr, terms.travelFee),
            if (custom > 0 && customLabel.text.trim().isNotEmpty)
              QuoteItem(customLabel.text.trim(), custom),
          ];
          final total = items.fold<int>(0, (s, i) => s + i.amount);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Text('Devis détaillé'.tr, style: ctx.text.headlineSmall),
              Text(
                '{0} · {1} invités'.trf([r.eventName, r.guests]),
                style: ctx.text.bodySmall,
              ),
              const SizedBox(height: 14),
              FieldLabel('Forfait'.tr),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in packages)
                    Choice(
                      label: '{0} · {1}'.trf([p.name, fcfaCompact(p.price)]),
                      on: pkg == p,
                      onTap: () => set(() => pkg = p),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              FieldLabel('Options proposées'.tr),
              for (final o in options)
                CheckRow(
                  label: '{0} · +{1}'.trf([o.name, fcfa(o.price)]),
                  value: picked.contains(o.id),
                  onChanged: (v) =>
                      set(() => v ? picked.add(o.id) : picked.remove(o.id)),
                ),
              CheckRow(
                label: 'Frais de déplacement · +{0}'.trf([
                  fcfa(terms.travelFee),
                ]),
                value: travel,
                onChanged: (v) => set(() => travel = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppField(
                      label: 'Ligne libre'.tr,
                      controller: customLabel,
                      optional: true,
                      hint: 'Ex. Fleurs importées'.tr,
                      onChanged: (_) => set(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: AppField(
                      label: 'Montant'.tr,
                      controller: customAmount,
                      keyboard: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => set(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FieldLabel('Validité du devis'.tr),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in [3, 7, 14, 30])
                    Choice(
                      label: '{0} jours'.trf([d]),
                      on: validity == d,
                      onTap: () => set(() => validity = d),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              FieldLabel('Acompte demandé'.tr),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in [20, 30, 50])
                    Choice(
                      label: '$d %',
                      on: deposit == d,
                      onTap: () => set(() => deposit = d),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppField(
                label: 'Dernière offre'.tr,
                controller: lastOffer,
                optional: true,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'Ex. {0} (−{1} %)'.trf([
                  fcfa(
                    (total * (100 - terms.lastOfferPercent) / 100 / 500)
                            .round() *
                        500,
                  ),
                  terms.lastOfferPercent,
                ]),
                onChanged: (_) => set(() {}),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(
                  'Votre plus bas tarif pour ce devis : le client le découvre s’il demande votre dernière offre.'
                      .tr,
                  style: ctx.text.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              Panel(
                color: Confetti.lavender,
                border: false,
                child: Column(
                  children: [
                    InfoLine('Total TTC'.tr, fcfa(total), strong: true),
                    InfoLine(
                      'Acompte à la réservation'.tr,
                      fcfa((total * deposit / 100).round()),
                    ),
                    InfoLine(
                      'Vous recevrez'.tr,
                      fcfa((total * (1 - proCommissionRate)).round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PillButton(
                label: 'Envoyer le devis'.tr,
                icon: AppIcons.send,
                onPressed: total <= 0
                    ? null
                    : () {
                        ref
                            .read(requestsProvider.notifier)
                            .sendDetailedQuote(
                              r.id,
                              items: items,
                              validityDays: validity,
                              depositPercent: deposit,
                              lastOffer: switch (int.tryParse(lastOffer.text)) {
                                final v? when v > 0 && v < total => v,
                                _ => null,
                              },
                            );
                        ref.read(soundProvider).play(Sfx.success);
                        Navigator.of(ctx).pop();
                        toast(
                          context,
                          'Devis de {0} envoyé à {1}'.trf([
                            fcfa(total),
                            r.client,
                          ]),
                          icon: AppIcons.send,
                        );
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Signature du devis, ou invitation à en enregistrer une.
class _QuoteSignature extends ConsumerWidget {
  const _QuoteSignature({required this.request});

  final ClientRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = request.signature ?? ref.watch(signatureProvider);
    if (image != null) {
      return SignatureBlock(image: image, signedAt: request.signedAt);
    }
    return PillButton(
      label: 'Ajouter ma signature'.tr,
      icon: AppIcons.edit,
      tone: ButtonTone.ghost,
      height: 46,
      onPressed: () => context.push('/pro/signature'),
    );
  }
}

String _since(DateTime d) {
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 60) return 'il y a {0} min'.trf([m]);
  if (m < 60 * 24) return 'il y a {0} h'.trf([m ~/ 60]);
  return 'le {0}'.trf([shortDate(d)]);
}

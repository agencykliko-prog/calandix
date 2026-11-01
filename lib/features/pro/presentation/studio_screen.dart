import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'creator_providers.dart';
import 'pro_widgets.dart';
import 'studio_providers.dart';
import '../../../ui/dataviz/dataviz.dart';
import 'signature_screen.dart';

/// Studio Creator : CRM, facturation, équipe, automatisations, marque
/// blanche, statistiques avancées et API. Réservé à l'offre Creator.
class StudioScreen extends ConsumerWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(studioUnlockedProvider);
    return ProPage(
      title: 'Studio Creator'.tr,
      subtitle: unlocked
          ? 'Les outils de votre offre Creator, au même endroit.'.tr
          : 'Réservé aux abonnés de l’offre Creator.'.tr,
      children: unlocked
          ? const [
              _SubBanner(),
              _Stats(),
              _Crm(),
              _Invoices(),
              _Team(),
              _Automations(),
              _Brand(),
              _Api(),
            ]
          : const [_Locked()],
    );
  }
}

// ─── Accès verrouillé ───────────────────────────────────────────────────

class _Locked extends StatelessWidget {
  const _Locked();

  @override
  Widget build(BuildContext context) {
    const features = [
      (AppIcons.crm, 'CRM clients avec notes privées'),
      (AppIcons.invoice, 'Factures en un geste, suivi des paiements'),
      (AppIcons.team, 'Équipe multi-utilisateurs'),
      (AppIcons.lightning, 'Automatisations des relances'),
      (AppIcons.palette, 'Marque blanche sur vos documents'),
      (AppIcons.chart, 'Statistiques avancées'),
      (AppIcons.code, 'Clé d’API et intégrations'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: NightPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tag(
              label: 'Offre Creator'.tr,
              hue: Hue.gold,
              solid: true,
              icon: AppIcons.lock,
            ),
            const SizedBox(height: 14),
            for (final (icon, label) in features)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: Confetti.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label.tr,
                        style: context.text.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Débloquer · {0} / mois'.trf([fcfa(creatorPlanPrice)]),
              icon: AppIcons.crown,
              tone: ButtonTone.gold,
              onPressed: () => context.push(Routes.business),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Statut de l'abonnement ─────────────────────────────────────────────

class _SubBanner extends ConsumerWidget {
  const _SubBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(creatorSubProvider)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Panel(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push(Routes.business),
        child: Row(
          children: [
            IconTile(icon: AppIcons.crown, hue: Hue.gold, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.cancelled
                        ? 'Offre Creator résiliée'.tr
                        : 'Offre Creator active'.tr,
                    style: context.text.titleSmall,
                  ),
                  Text(
                    sub.cancelled
                        ? 'Accès jusqu’au {0}'.trf([mediumDate(sub.renewsOn)])
                        : 'Renouvellement le {0}'.trf([
                            mediumDate(sub.renewsOn),
                          ]),
                    style: context.text.bodySmall?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.chevron, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Statistiques avancées ──────────────────────────────────────────────

class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studioStatsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Statistiques avancées'.tr),
        KpiGrid.compact(
          children: [
            KpiCard.compact(
              label: 'Taux de conversion'.tr,
              value: '${(s.conversion * 100).round()} %',
              hue: Hue.violet,
              icon: AppIcons.trendUp,
            ),
            KpiCard.compact(
              label: 'Panier moyen'.tr,
              value: fcfaCompact(s.averageBasket),
              hue: Hue.lagoon,
              icon: AppIcons.coins,
            ),
            KpiCard.compact(
              key: const ValueKey('stat-invoiced'),
              label: 'Facturé'.tr,
              value: fcfaCompact(s.invoiced),
              hue: Hue.mango,
              icon: AppIcons.invoice,
            ),
            KpiCard.compact(
              key: const ValueKey('stat-outstanding'),
              label: 'Reste à encaisser'.tr,
              value: fcfaCompact(s.outstanding),
              hue: Hue.coral,
              icon: AppIcons.handCoins,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── CRM ────────────────────────────────────────────────────────────────

class _Crm extends ConsumerWidget {
  const _Crm();

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    StudioClient c,
  ) async {
    final text = await showEventaSheet<String>(
      context,
      builder: (ctx) => _FieldSheet(
        initial: ref.read(studioProvider).notes[c.name] ?? '',
        builder: (ctx, ctrl) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(c.name, style: ctx.text.headlineSmall),
              const SizedBox(height: 12),
              AppField(
                label: 'Note privée'.tr,
                controller: ctrl,
                maxLines: 3,
                hint: 'Préférences, contacts, points d’attention…'.tr,
              ),
              const SizedBox(height: 14),
              PillButton(
                label: 'Enregistrer la note'.tr,
                onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              ),
            ],
          ),
        ),
      ),
    );
    if (text != null) {
      ref.read(studioProvider.notifier).note(c.name, text);
      if (context.mounted) toast(context, 'Note enregistrée'.tr);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(studioClientsProvider);
    final notes = ref.watch(studioProvider.select((s) => s.notes));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('CRM clients'.tr),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (final (i, c) in clients.indexed) ...[
                if (i > 0) Divider(height: 1, color: Confetti.line),
                InkWell(
                  onTap: () => _edit(context, ref, c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Confetti.violetTint,
                          child: Text(
                            c.name.characters.first,
                            style: context.text.titleSmall?.copyWith(
                              color: Confetti.violetText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: context.text.titleSmall),
                              Text(
                                notes[c.name]?.isNotEmpty == true
                                    ? notes[c.name]!
                                    : '{0} demandes · {1} confirmées'.trf([
                                        c.requests,
                                        c.confirmed,
                                      ]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall?.copyWith(
                                  color: Confetti.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.revenue == 0 ? '—' : fcfaCompact(c.revenue),
                          style: context.text.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Facturation ────────────────────────────────────────────────────────

class _Invoices extends ConsumerWidget {
  const _Invoices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studio = ref.watch(studioProvider);
    final toBill = ref
        .watch(requestsProvider)
        .where(
          (r) =>
              r.status == RequestStatus.confirmed &&
              r.quote != null &&
              !studio.invoices.any((i) => i.requestId == r.id),
        )
        .toList();
    final brand = Color(studio.brandColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Facturation'.tr),
        for (final r in toBill)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconTile(icon: AppIcons.calendarCheck, hue: Hue.lagoon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.eventName, style: context.text.titleSmall),
                        Text(
                          '{0} · {1}'.trf([r.client, fcfa(r.quote!)]),
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PillButton(
                    key: ValueKey('bill-${r.id}'),
                    label: 'Facturer'.tr,
                    expand: false,
                    height: 38,
                    onPressed: () {
                      final inv = ref.read(studioProvider.notifier).invoice(r);
                      if (inv != null) {
                        toast(
                          context,
                          'Facture {0} envoyée'.trf([inv.number]),
                          icon: AppIcons.invoice,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        if (studio.invoices.isEmpty && toBill.isEmpty)
          Text(
            'Aucune prestation confirmée à facturer.'.tr,
            style: context.text.bodyMedium,
          ),
        for (final inv in studio.invoices.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '{0} · {1}'.trf([inv.number, inv.client]),
                          style: context.text.titleSmall,
                        ),
                        Text(
                          inv.paid
                              ? 'Payée · {0}'.trf([fcfa(inv.amount)])
                              : 'Échéance {0} · {1}'.trf([
                                  shortDate(inv.due),
                                  fcfa(inv.amount),
                                ]),
                          style: context.text.bodySmall,
                        ),
                        if (inv.signature != null) ...[
                          const SizedBox(height: 8),
                          SignatureBlock(
                            image: inv.signature!,
                            signedAt: inv.issued,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (inv.paid)
                    Tag(
                      label: 'Payée'.tr,
                      hue: Hue.lagoon,
                      icon: AppIcons.check,
                    )
                  else
                    PillButton(
                      key: ValueKey('paid-${inv.number}'),
                      label: 'Encaisser'.tr,
                      tone: ButtonTone.ghost,
                      expand: false,
                      height: 38,
                      onPressed: () => ref
                          .read(studioProvider.notifier)
                          .markPaid(inv.number),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Équipe ─────────────────────────────────────────────────────────────

class _Team extends ConsumerWidget {
  const _Team();

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    var role = TeamRole.planner;
    final name = await showEventaSheet<String>(
      context,
      builder: (ctx) => _FieldSheet(
        builder: (ctx, ctrl) => StatefulBuilder(
          builder: (ctx, set) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Inviter un membre'.tr, style: ctx.text.headlineSmall),
                const SizedBox(height: 12),
                AppField(
                  label: 'Nom et prénom'.tr,
                  controller: ctrl,
                  hint: 'Koffi Yao',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final r in TeamRole.values)
                      ChoiceChip(
                        label: Text(r.label),
                        selected: role == r,
                        onSelected: (_) => set(() => role = r),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                PillButton(
                  label: 'Envoyer l’invitation'.tr,
                  onPressed: () => Navigator.of(ctx).pop(ctrl.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (name != null) {
      final added = ref.read(studioProvider.notifier).invite(name, role);
      if (context.mounted) {
        toast(
          context,
          added
              ? 'Invitation envoyée'.tr
              : 'Nom manquant ou membre déjà invité'.tr,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(studioProvider.select((s) => s.team));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Équipe'.tr,
          action: 'Inviter'.tr,
          onAction: () => _invite(context, ref),
        ),
        if (team.isEmpty)
          Text(
            'Invitez vos chefs de projet et votre équipe terrain.'.tr,
            style: context.text.bodyMedium,
          ),
        for (final m in team)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              child: Row(
                children: [
                  IconTile(icon: AppIcons.team, hue: Hue.violet, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: context.text.titleSmall),
                        Text(
                          m.pending
                              ? '{0} · invitation envoyée'.trf([m.role.label])
                              : m.role.label,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retirer {0}'.trf([m.name]),
                    icon: const Icon(AppIcons.trash, size: 18),
                    onPressed: () =>
                        ref.read(studioProvider.notifier).remove(m.name),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Automatisations ────────────────────────────────────────────────────

class _Automations extends ConsumerWidget {
  const _Automations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(studioProvider.select((s) => s.automations));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Automatisations'.tr),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (final (i, a) in Automation.values.indexed) ...[
                if (i > 0) Divider(height: 1, color: Confetti.line),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: context.text.titleSmall),
                            Text(a.caption, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      Switch(
                        key: ValueKey('auto-${a.name}'),
                        value: on.contains(a),
                        onChanged: (_) =>
                            ref.read(studioProvider.notifier).toggle(a),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Marque blanche ─────────────────────────────────────────────────────

class _Brand extends ConsumerStatefulWidget {
  const _Brand();

  @override
  ConsumerState<_Brand> createState() => _BrandState();
}

class _BrandState extends ConsumerState<_Brand> {
  late final _name = TextEditingController(
    text: ref.read(studioProvider).brandName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(studioProvider);
    final color = Color(s.brandColor);
    final n = ref.read(studioProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Marque blanche'.tr),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppField(
                label: 'Nom affiché sur vos devis et factures'.tr,
                controller: _name,
                hint: 'Maison Inès Déco',
                onChanged: (v) => n.setBrand(name: v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final c in studioBrandColors)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Semantics(
                        button: true,
                        selected: c == s.brandColor,
                        label: 'Couleur de marque'.tr,
                        child: GestureDetector(
                          onTap: () => n.setBrand(color: c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c == s.brandColor
                                    ? Confetti.ink
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Aperçu de l'en-tête des documents.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: color, width: 4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.brandName.isEmpty ? 'Votre marque'.tr : s.brandName,
                        style: context.text.titleMedium?.copyWith(color: color),
                      ),
                    ),
                    Text('DEVIS'.tr, style: context.text.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── API ────────────────────────────────────────────────────────────────

class _Api extends ConsumerWidget {
  const _Api();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(studioProvider.select((s) => s.apiKey));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('API & intégrations'.tr),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connectez votre site ou votre outil de gestion pour recevoir les demandes automatiquement.'
                    .tr,
                style: context.text.bodyMedium,
              ),
              if (key != null) ...[
                const SizedBox(height: 10),
                SelectableText(
                  key,
                  style: context.text.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              PillButton(
                label: key == null
                    ? 'Générer une clé d’API'.tr
                    : 'Copier la clé'.tr,
                icon: AppIcons.code,
                tone: ButtonTone.dark,
                onPressed: () {
                  final k =
                      key ?? ref.read(studioProvider.notifier).generateApiKey();
                  Clipboard.setData(ClipboardData(text: k));
                  toast(context, 'Clé copiée'.tr);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Feuille avec un champ de saisie : le contrôleur vit aussi longtemps que
/// la feuille, animation de fermeture comprise.
class _FieldSheet extends StatefulWidget {
  const _FieldSheet({required this.builder, this.initial = ''});

  final String initial;
  final Widget Function(BuildContext, TextEditingController) builder;

  @override
  State<_FieldSheet> createState() => _FieldSheetState();
}

class _FieldSheetState extends State<_FieldSheet> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _ctrl);
}

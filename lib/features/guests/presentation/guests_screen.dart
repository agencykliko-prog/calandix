import 'package:flutter/material.dart';

import '../../events/presentation/event_trash.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../dashboard/presentation/widgets/guests_panel.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../premium/presentation/premium_nudge.dart';
import '../../../app/router/app_router.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../invitations/presentation/auto_reminders_sheet.dart';
import '../../premium/presentation/paywall.dart';
import 'remind_sheet.dart';
import '../../../core/utils/formatters.dart';
import '../../commerce/presentation/commerce_providers.dart';

enum _Filter { all, yes, pending, no }

/// Liste des invités d'un événement : réponses, accompagnants, ajout et
/// modification.
class GuestsScreen extends ConsumerStatefulWidget {
  const GuestsScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends ConsumerState<GuestsScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventProvider(widget.id));
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
        title: Text('Invités & RSVP'.tr),
      ),
      body: async.when(
        loading: () => const Center(child: MascotLoader.party()),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
        data: (e) => e == null ? MissingEvent(id: widget.id) : _body(e),
      ),
      bottomNavigationBar: async.value == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: PillButton(
                label: 'Ajouter un invité'.tr,
                icon: AppIcons.userPlus,
                onPressed: () => showGuestSheet(context, ref, widget.id),
              ),
            ),
    );
  }

  Widget _body(Event e) {
    final g = e.guests;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final x in g.list)
        if (switch (_filter) {
              _Filter.all => true,
              _Filter.yes => x.rsvp == Rsvp.yes,
              _Filter.pending => x.rsvp == Rsvp.pending,
              _Filter.no => x.rsvp == Rsvp.no,
            } &&
            (q.isEmpty ||
                x.name.toLowerCase().contains(q) ||
                (x.group?.toLowerCase().contains(q) ?? false)))
          x,
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          sliver: SliverList.list(
            children: [
              Text(e.name, style: context.text.bodySmall),
              const SizedBox(height: 10),
              GuestsPanel(
                guests: g,
                onRemind: () async {
                  await showRemindSheet(context, e);
                  if (mounted) {
                    maybeShowPremiumNudge(context, ref, PremiumNudge.guests);
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (feature, icon, label, open) in [
                    (
                      PremiumFeature.invitations,
                      AppIcons.mail,
                      'Invitation'.tr,
                      () => context.push(Routes.invitation(e.id)),
                    ),
                    (
                      PremiumFeature.entries,
                      AppIcons.qr,
                      'Entrées'.tr,
                      () => context.push(Routes.entries(e.id)),
                    ),
                    (
                      PremiumFeature.reminders,
                      AppIcons.reminder,
                      'Rappels auto'.tr,
                      () => showAutoReminders(context, e),
                    ),
                  ]) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => requirePremium(
                          context,
                          ref,
                          feature: feature,
                          eventId: e.id,
                          onUnlocked: open,
                        ),
                        icon: Icon(icon, size: 16),
                        label: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (feature != PremiumFeature.reminders)
                      const SizedBox(width: 6),
                  ],
                ],
              ),
              if (g.list.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '{0} personnes attendues avec les accompagnants'.trf([
                    g.headcount,
                  ]),
                  style: context.text.bodySmall?.copyWith(
                    color: context.eventa.muted,
                  ),
                ),
                const SizedBox(height: 18),
                if (g.list.length > 8) ...[
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Chercher un nom ou un groupe'.tr,
                      prefixIcon: Icon(AppIcons.search, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _FilterBar(
                  value: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                  counts: {
                    _Filter.all: g.list.length,
                    _Filter.yes: g.confirmed,
                    _Filter.pending: g.list.length - g.confirmed - g.declined,
                    _Filter.no: g.declined,
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        if (g.list.isEmpty)
          SliverToBoxAdapter(child: _Empty(expected: g.expected))
        else if (shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'Aucun invité ne correspond.'.tr,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Confetti.line),
              itemBuilder: (context, i) => _GuestRow(
                guest: shown[i],
                onTap: () =>
                    showGuestSheet(context, ref, widget.id, guest: shown[i]),
                onRsvp: (r) => ref
                    .read(eventsProvider.notifier)
                    .setRsvp(widget.id, shown[i].id, r),
              ),
            ),
          ),
      ],
    );
  }
}

extension RsvpLabel on Rsvp {
  String get label => switch (this) {
    Rsvp.yes => 'Présent'.tr,
    Rsvp.no => 'Absent'.tr,
    Rsvp.pending => 'En attente'.tr,
  };

  Hue get hue => switch (this) {
    Rsvp.yes => Hue.coral,
    Rsvp.no => Hue.ink,
    Rsvp.pending => Hue.violet,
  };
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({
    required this.guest,
    required this.onTap,
    required this.onRsvp,
  });

  final Guest guest;
  final VoidCallback onTap;
  final ValueChanged<Rsvp> onRsvp;

  @override
  Widget build(BuildContext context) {
    final g = guest;
    final initials = g.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    final details = [
      ?g.group,
      if (g.companions > 0) '+{0}'.trf([g.companions]),
    ].join(' · ');
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: g.rsvp.hue.tint,
              child: Text(
                initials,
                style: context.text.labelMedium?.copyWith(
                  color: g.rsvp.hue.text,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<Rsvp>(
              tooltip: 'Changer la réponse'.tr,
              onSelected: onRsvp,
              itemBuilder: (_) => [
                for (final r in Rsvp.values)
                  PopupMenuItem(value: r, child: Text(r.label)),
              ],
              child: Tag(label: g.rsvp.label, hue: g.rsvp.hue),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.expected});

  final int expected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        children: [
          Icon(AppIcons.guests, size: 36, color: context.eventa.muted),
          const SizedBox(height: 12),
          Text(
            'Aucun invité dans la liste'.tr,
            style: context.text.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            expected > 0
                ? '{0} invités prévus. Ajoutez-les pour suivre leurs réponses.'
                      .trf([expected])
                : 'Ajoutez vos invités pour suivre leurs réponses.'.tr,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: context.eventa.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.value,
    required this.onChanged,
    required this.counts,
  });

  final _Filter value;
  final ValueChanged<_Filter> onChanged;
  final Map<_Filter, int> counts;

  static const _labels = {
    _Filter.all: 'Tous',
    _Filter.yes: 'Présents',
    _Filter.pending: 'En attente',
    _Filter.no: 'Absents',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _Filter.values) ...[
            if (f != _Filter.all) const SizedBox(width: 8),
            Pressable(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: Motion.fast,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: f == value ? Confetti.ink : Confetti.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: f == value ? Confetti.ink : Confetti.line,
                  ),
                ),
                child: Text(
                  '${_labels[f]?.tr} · ${counts[f]}',
                  style: context.text.labelMedium?.copyWith(
                    color: f == value ? Confetti.onInk : Confetti.ink,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ajout ou modification d'un invité.
Future<void> showGuestSheet(
  BuildContext context,
  WidgetRef ref,
  String eventId, {
  Guest? guest,
}) {
  final name = TextEditingController(text: guest?.name);
  final phone = TextEditingController(text: guest?.phone);
  final group = TextEditingController(text: guest?.group);
  final diet = TextEditingController(text: guest?.diet);
  var rsvp = guest?.rsvp ?? Rsvp.pending;
  var companions = guest?.companions ?? 0;
  String? error;

  String? clean(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  return showEventaSheet<void>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guest == null ? 'Nouvel invité'.tr : 'Modifier l’invité'.tr,
              style: ctx.text.headlineSmall,
            ),
            const SizedBox(height: 14),
            AppField(
              label: 'Nom'.tr,
              controller: name,
              autofocus: guest == null,
              hint: 'Prénom et nom'.tr,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(
                  error!,
                  style: ctx.text.bodySmall?.copyWith(color: Confetti.danger),
                ),
              ),
            const SizedBox(height: 12),
            AppField(
              label: 'WhatsApp'.tr,
              controller: phone,
              optional: true,
              keyboard: TextInputType.phone,
              prefix: const PhonePrefix(),
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Groupe'.tr,
              controller: group,
              optional: true,
              hint: 'Famille, amis, collègues…'.tr,
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Régime ou allergies'.tr,
              controller: diet,
              optional: true,
            ),
            const SizedBox(height: 16),
            FieldLabel('Réponse'.tr),
            Row(
              children: [
                for (final r in Rsvp.values) ...[
                  if (r != Rsvp.pending) const SizedBox(width: 8),
                  Expanded(
                    child: Pressable(
                      onTap: () => set(() => rsvp = r),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rsvp == r ? Confetti.ink : Confetti.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: rsvp == r ? Confetti.ink : Confetti.line,
                          ),
                        ),
                        child: Text(
                          r.label,
                          style: ctx.text.labelMedium?.copyWith(
                            color: rsvp == r ? Confetti.onInk : Confetti.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Accompagnants'.tr, style: ctx.text.labelMedium),
                ),
                RoundIconButton(
                  icon: AppIcons.minus,
                  tooltip: 'Retirer un accompagnant',
                  onTap: companions == 0 ? null : () => set(() => companions--),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$companions',
                    textAlign: TextAlign.center,
                    style: ctx.text.titleMedium,
                  ),
                ),
                RoundIconButton(
                  icon: AppIcons.add,
                  tooltip: 'Ajouter un accompagnant',
                  onTap: companions >= 20
                      ? null
                      : () => set(() => companions++),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PillButton(
              label: guest == null ? 'Ajouter'.tr : 'Enregistrer'.tr,
              icon: AppIcons.check,
              onPressed: () {
                final n = clean(name);
                if (n == null) {
                  set(() => error = 'Indiquez le nom de l’invité.'.tr);
                  return;
                }
                final caps = ref.read(passCapsProvider(eventId));
                final current = ref.read(eventProvider(eventId)).value;
                if (caps != null && current != null) {
                  final others = current.guests.list
                      .where((x) => x.id != guest?.id)
                      .fold<int>(0, (s, x) => s + 1 + x.companions);
                  if (others + 1 + companions > caps.guests) {
                    set(
                      () => error = 'Le Pass Événement compte jusqu’à {0} invités, accompagnants compris.'
                          .trf([formatNumber(caps.guests)]),
                    );
                    return;
                  }
                }
                final events = ref.read(eventsProvider.notifier);
                final saved = Guest(
                  id: guest?.id ?? 'g-${DateTime.now().microsecondsSinceEpoch}',
                  name: n,
                  phone: clean(phone),
                  group: clean(group),
                  rsvp: rsvp,
                  companions: companions,
                  diet: clean(diet),
                  addedAt: guest?.addedAt ?? DateTime.now(),
                );
                if (guest == null) {
                  events.addGuest(eventId, saved);
                } else {
                  events.updateGuest(eventId, saved);
                }
                Navigator.of(ctx).pop();
                toast(
                  context,
                  guest == null
                      ? '{0} ajouté à la liste'.trf([n])
                      : 'Invité mis à jour'.tr,
                );
              },
            ),
            if (guest != null) ...[
              const SizedBox(height: 10),
              PillButton(
                label: 'Retirer de la liste'.tr,
                icon: AppIcons.trash,
                tone: ButtonTone.ghost,
                onPressed: () {
                  ref
                      .read(eventsProvider.notifier)
                      .removeGuest(eventId, guest.id);
                  Navigator.of(ctx).pop();
                  toast(
                    context,
                    '{0} retiré de la liste'.trf([guest.name]),
                    icon: AppIcons.trash,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

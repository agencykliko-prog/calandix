import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/presentation/events_providers.dart';
import 'invitation_screen.dart';
import 'invitations_providers.dart';

/// Contrôle des entrées le jour J : le code (ou le QR code) de l'invité est
/// vérifié, seul un invité confirmé entre, et une seule fois.
class EntriesScreen extends ConsumerStatefulWidget {
  const EntriesScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends ConsumerState<EntriesScreen> {
  final _code = TextEditingController();
  (CheckResult, Guest?)? _last;
  String _query = '';

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _check(Event e, String raw) {
    if (raw.trim().isEmpty) return;
    final r = ref.read(checkInProvider.notifier).check(e, raw);
    setState(() => _last = r);
    _code.clear();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventProvider(widget.id));
    ref.watch(checkInProvider);
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
        title: Text('Contrôle des entrées'.tr),
      ),
      body: async.when(
        loading: () => const Center(child: MascotLoader.party()),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
        data: (e) => e == null ? const SizedBox() : _body(e),
      ),
    );
  }

  Widget _body(Event e) {
    final ins = ref.read(checkInProvider.notifier).of(e.id);
    final confirmed = [
      for (final g in e.guests.list)
        if (g.rsvp == Rsvp.yes) g,
    ];
    final expected = confirmed.fold<int>(0, (s, g) => s + 1 + g.companions);
    final arrived = ins.values.fold<int>(0, (s, c) => s + c.people);
    final q = _query.trim().toLowerCase();
    final shown =
        [
          for (final g in confirmed)
            if (q.isEmpty ||
                g.name.toLowerCase().contains(q) ||
                guestCode(e.id, g.id).toLowerCase().contains(q))
              g,
        ]..sort(
          (a, b) => (ins.containsKey(a.id) ? 1 : 0).compareTo(
            ins.containsKey(b.id) ? 1 : 0,
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(e.name, style: context.text.bodySmall),
        const SizedBox(height: 12),
        NightPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONNES ARRIVÉES'.tr,
                style: context.text.labelSmall?.copyWith(
                  color: Colors.white60,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: '$arrived',
                  style: const TextStyle(
                    fontFamily: AppTheme.font,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: ' / $expected',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Meter(
                value: expected == 0 ? 0 : (arrived / expected).clamp(0, 1),
                color: Confetti.lagoon,
                track: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 10),
              Text(
                '{0} invités entrés sur {1} confirmés, accompagnants compris dans le total.'
                    .trf([ins.length, confirmed.length]),
                style: context.text.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Offline(event: e),
        const SizedBox(height: 18),
        SectionTitle('Scanner un invité'.tr),
        const SizedBox(height: 8),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconTile(icon: AppIcons.qr, hue: Hue.violet, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Saisissez le code inscrit sous le QR code de l’invité. Le scan par la caméra arrive avec l’application mobile.'
                          .tr,
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppField(
                label: 'Code d’entrée'.tr,
                controller: _code,
                hint: 'CX-ABC-123',
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => _check(e, v),
              ),
              const SizedBox(height: 10),
              PillButton(
                label: 'Vérifier l’entrée'.tr,
                icon: AppIcons.checkCircle,
                height: 48,
                onPressed: () => _check(e, _code.text),
              ),
              if (_last != null) ...[
                const SizedBox(height: 12),
                _Result(result: _last!.$1, guest: _last!.$2, ins: ins),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle('Invités confirmés'.tr),
        const SizedBox(height: 8),
        if (confirmed.isEmpty)
          Panel(
            child: Text(
              'Aucun invité confirmé pour l’instant. Les réponses arrivent depuis l’invitation.'
                  .tr,
              style: context.text.bodyMedium,
            ),
          )
        else ...[
          TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Nom ou code'.tr,
              prefixIcon: Icon(AppIcons.search, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          for (final g in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, style: context.text.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            ins.containsKey(g.id)
                                ? 'Entré à {0} · {1} pers.'.trf([
                                    timeOf(ins[g.id]!.at),
                                    ins[g.id]!.people,
                                  ])
                                : '{0} · {1} pers.'.trf([
                                    guestCode(e.id, g.id),
                                    1 + g.companions,
                                  ]),
                            style: context.text.bodySmall?.copyWith(
                              color: ins.containsKey(g.id)
                                  ? Hue.lagoon.text
                                  : context.eventa.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RoundIconButton(
                      icon: AppIcons.qr,
                      tooltip: 'Voir son invitation'.tr,
                      onTap: () => showGuestInvitation(context, e, g),
                    ),
                    const SizedBox(width: 6),
                    if (ins.containsKey(g.id))
                      TextButton(
                        onPressed: () =>
                            ref.read(checkInProvider.notifier).undo(e.id, g.id),
                        child: Text('Annuler'.tr),
                      )
                    else
                      TextButton(
                        onPressed: () => _check(e, g.id),
                        child: Text('Faire entrer'.tr),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.result, required this.guest, required this.ins});

  final CheckResult result;
  final Guest? guest;
  final Map<String, CheckIn> ins;

  @override
  Widget build(BuildContext context) {
    final name = guest?.name ?? '';
    final (hue, icon, title, caption) = switch (result) {
      CheckResult.admitted => (
        Hue.lagoon,
        AppIcons.checkCircle,
        'Bienvenue, {0}'.trf([name]),
        '{0} personne(s) enregistrée(s).'.trf([1 + (guest?.companions ?? 0)]),
      ),
      CheckResult.already => (
        Hue.mango,
        AppIcons.warning,
        'Déjà entré : {0}'.trf([name]),
        'Ce code a été utilisé à {0}. Vérifiez l’identité avant de laisser entrer.'
            .trf([timeOf(ins[guest!.id]!.at)]),
      ),
      CheckResult.notConfirmed => (
        Hue.coral,
        AppIcons.warning,
        '{0} n’a pas confirmé'.trf([name]),
        'Sa présence n’est pas confirmée : voyez avec l’organisateur.'.tr,
      ),
      CheckResult.unknown => (
        Hue.coral,
        AppIcons.close,
        'Code inconnu'.tr,
        'Ce code ne correspond à aucun invité de l’événement.'.tr,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hue.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: hue.text, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleSmall?.copyWith(color: hue.text),
                ),
                const SizedBox(height: 2),
                Text(caption, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mode hors ligne : liste gardée sur l'appareil, entrées synchronisées
/// au retour du réseau.
class _Offline extends ConsumerWidget {
  const _Offline({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final o = ref.watch(offlineEntriesProvider)[e.id] ?? const OfflineEntries();
    ref.watch(checkInProvider);
    final pending = ref.read(checkInProvider.notifier).pending(e.id);
    return Panel(
      color: o.enabled ? Confetti.mangoTint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                o.enabled ? Icons.wifi_off_rounded : AppIcons.download,
                size: 20,
                color: o.enabled ? Confetti.mangoText : context.eventa.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.enabled
                          ? 'Mode hors ligne'.tr
                          : 'Réseau faible sur place ?'.tr,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      o.enabled
                          ? 'Liste de {0} invités sur l’appareil, téléchargée à {1}.'
                                .trf([o.guests, timeOf(o.preparedAt!)])
                          : 'Téléchargez la liste : les entrées se valident sans réseau.'
                                .tr,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: o.enabled,
                onChanged: (v) {
                  final n = ref.read(offlineEntriesProvider.notifier);
                  if (v) {
                    n.enable(e);
                    toast(
                      context,
                      'Liste des invités disponible hors ligne'.tr,
                    );
                  } else {
                    n.disable(e.id);
                    final sent = ref.read(checkInProvider.notifier).sync(e.id);
                    if (sent > 0) {
                      toast(
                        context,
                        '{0} entrée(s) synchronisée(s)'.trf([sent]),
                        icon: AppIcons.checkCircle,
                      );
                    }
                  }
                },
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '{0} entrée(s) en attente de synchronisation'.trf([
                      pending,
                    ]),
                    style: context.text.labelMedium?.copyWith(
                      color: Confetti.mangoText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final sent = ref.read(checkInProvider.notifier).sync(e.id);
                    toast(
                      context,
                      '{0} entrée(s) synchronisée(s)'.trf([sent]),
                      icon: AppIcons.checkCircle,
                    );
                  },
                  child: Text('Synchroniser'.tr),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

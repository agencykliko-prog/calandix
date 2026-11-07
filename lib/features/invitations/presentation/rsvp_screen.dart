import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/presentation/events_providers.dart';
import 'invitation_screen.dart';
import 'invitations_providers.dart';

/// Lien personnel de l'invité : il ouvre l'invitation et répond lui-même.
String rsvpPath(String eventId, String guestId) =>
    '/r/$eventId/${guestCode(eventId, guestId)}';

String rsvpLink(String eventId, String guestId) =>
    'https://calandix.ci${rsvpPath(eventId, guestId)}';

/// Page ouverte par l'invité depuis son lien : invitation, présence,
/// accompagnants et message à l'organisateur. Sa réponse met à jour la
/// liste des invités.
class GuestRsvpScreen extends ConsumerStatefulWidget {
  const GuestRsvpScreen({super.key, required this.eventId, required this.code});

  final String eventId;
  final String code;

  @override
  ConsumerState<GuestRsvpScreen> createState() => _GuestRsvpScreenState();
}

class _GuestRsvpScreenState extends ConsumerState<GuestRsvpScreen> {
  Rsvp? _answer;
  int? _companions;
  final _diet = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _diet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider).value ?? const <Event>[];
    final e = events.where((x) => x.id == widget.eventId).firstOrNull;
    final code = widget.code.toUpperCase();
    final g = e?.guests.list
        .where((x) => guestCode(e.id, x.id) == code)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Votre invitation'.tr),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Retour'.tr,
                icon: const Icon(AppIcons.back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: e == null || g == null ? _NotFound() : _body(context, e, g),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Event e, Guest g) {
    final d = ref.watch(invitationProvider)[e.id] ?? const InvitationDesign();
    final answer = _answer ?? (g.rsvp == Rsvp.pending ? null : g.rsvp);
    final companions = _companions ?? g.companions;
    final max = d.maxCompanions;
    final late = DateTime.now().isAfter(d.deadlineFor(e));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        InvitationCard(event: e, design: d, guest: g),
        const SizedBox(height: 18),
        if (_sent)
          Panel(
            child: Row(
              children: [
                IconTile(
                  icon: answer == Rsvp.yes
                      ? AppIcons.checkCircle
                      : AppIcons.heart,
                  hue: answer == Rsvp.yes ? Hue.lagoon : Hue.coral,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    answer == Rsvp.yes
                        ? 'Merci {0}, votre présence est confirmée.'.trf([
                            g.name.split(' ').first,
                          ])
                        : 'Merci {0}, l’organisateur est prévenu.'.trf([
                            g.name.split(' ').first,
                          ]),
                    style: context.text.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        if (_sent && answer == Rsvp.yes && d.withQr) ...[
          const SizedBox(height: 16),
          Text(
            'Présentez ce QR code à l’entrée.'.tr,
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 8),
          Center(
            child: GuestQr(event: e, guest: g),
          ),
        ],
        if (!_sent) ...[
          Text('Serez-vous présent ?'.tr, style: context.text.titleMedium),
          const SizedBox(height: 4),
          Text(
            late
                ? 'La date limite de réponse est passée, mais vous pouvez encore répondre.'
                      .tr
                : 'Merci de répondre avant le {0}.'.trf([
                    mediumDate(d.deadlineFor(e)),
                  ]),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AnswerButton(
                  label: 'Je serai là'.tr,
                  icon: AppIcons.checkCircle,
                  hue: Hue.lagoon,
                  on: answer == Rsvp.yes,
                  onTap: () => setState(() => _answer = Rsvp.yes),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnswerButton(
                  label: 'Je ne pourrai pas venir'.tr,
                  icon: AppIcons.close,
                  hue: Hue.coral,
                  on: answer == Rsvp.no,
                  onTap: () => setState(() => _answer = Rsvp.no),
                ),
              ),
            ],
          ),
          if (answer == Rsvp.yes && max > 0) ...[
            const SizedBox(height: 18),
            Panel(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accompagnants'.tr,
                          style: context.text.titleSmall,
                        ),
                        Text(
                          'Jusqu’à {0} personnes avec vous.'.trf([max]),
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    icon: AppIcons.minus,
                    size: 36,
                    tooltip: 'Moins',
                    onTap: companions <= 0
                        ? null
                        : () => setState(() => _companions = companions - 1),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${companions.clamp(0, max)}',
                      textAlign: TextAlign.center,
                      style: context.text.titleMedium,
                    ),
                  ),
                  RoundIconButton(
                    icon: AppIcons.add,
                    size: 36,
                    tooltip: 'Plus',
                    onTap: companions >= max
                        ? null
                        : () => setState(() => _companions = companions + 1),
                  ),
                ],
              ),
            ),
          ],
          if (answer == Rsvp.yes) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _diet,
              decoration: InputDecoration(
                labelText: 'Allergies ou régime alimentaire (facultatif)'.tr,
              ),
            ),
          ],
          const SizedBox(height: 20),
          PillButton(
            label: 'Envoyer ma réponse'.tr,
            icon: AppIcons.send,
            onPressed: answer == null
                ? null
                : () {
                    final diet = _diet.text.trim();
                    ref
                        .read(eventsProvider.notifier)
                        .updateGuest(
                          e.id,
                          g.copyWith(
                            rsvp: answer,
                            companions: answer == Rsvp.yes
                                ? companions.clamp(0, max)
                                : 0,
                            diet: diet.isEmpty ? null : diet,
                          ),
                        );
                    setState(() => _sent = true);
                  },
          ),
        ] else ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => setState(() => _sent = false),
            child: Text('Modifier ma réponse'.tr),
          ),
        ],
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.hue,
    required this.on,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Hue hue;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Panel(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    color: on ? hue.tint : null,
    child: Column(
      children: [
        Icon(icon, color: on ? hue.text : context.eventa.muted),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.text.titleSmall?.copyWith(color: on ? hue.text : null),
        ),
      ],
    ),
  );
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.mail, size: 40, color: context.eventa.muted),
        const SizedBox(height: 12),
        Text(
          'Invitation introuvable'.tr,
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Le lien est incomplet ou l’invitation a été retirée. Demandez un nouveau lien à l’organisateur.'
              .tr,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: 16),
        PillButton(
          label: 'Découvrir Calandix'.tr,
          expand: false,
          onPressed: () => context.go(Routes.onboarding),
        ),
      ],
    ),
  );
}

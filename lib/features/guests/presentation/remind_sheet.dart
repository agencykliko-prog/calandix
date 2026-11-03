import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/mobile/open_link_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/open_link_web.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/presentation/events_providers.dart';

/// Numéro au format international sans « + » (ce qu'attend wa.me). Un numéro
/// ivoirien saisi sans indicatif reçoit le 225 ; null si inutilisable.
String? whatsappNumber(String? phone) {
  if (phone == null) return null;
  var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('00')) d = d.substring(2);
  if (d.length == 10) d = '225$d';
  return d.length >= 11 && d.length <= 15 ? d : null;
}

/// Message de relance, rédigé au nom de l'organisateur.
String reminderText(Event e, Guest g) {
  final first = g.name.trim().split(RegExp(r'\s+')).first;
  final where = e.venue.trim().isEmpty ? '' : ' · ${e.venue.trim()}';
  return 'Bonjour {0} ! Petit rappel : vous êtes invité à « {1} », le {2}{3}. Pouvez-vous me confirmer votre présence ? Merci !'
      .trf([first, e.name, longDate(e.date), where]);
}

/// Lien WhatsApp qui ouvre la conversation avec le message prêt à envoyer.
/// Espaces en %20 : WhatsApp afficherait les « + » tels quels.
Uri reminderLink(String number, String text) =>
    Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(text)}');

/// Relance des invités sans réponse : WhatsApp s'ouvre pour chacun avec le
/// message pré-rempli, l'organisateur l'envoie lui-même (aucun envoi
/// automatique depuis un numéro Calandix), puis note la réponse reçue : la
/// liste et les compteurs RSVP se mettent à jour.
Future<void> showRemindSheet(BuildContext context, Event e) {
  // Les invités joignables d'abord : ce sont eux qu'on relance.
  final pending =
      [
        for (final g in e.guests.list)
          if (g.rsvp == Rsvp.pending) g,
      ]..sort(
        (a, b) => (whatsappNumber(a.phone) == null ? 1 : 0).compareTo(
          whatsappNumber(b.phone) == null ? 1 : 0,
        ),
      );
  return showEventaSheet<void>(
    context,
    builder: (ctx) => _RemindSheet(event: e, guests: pending),
  );
}

class _RemindSheet extends ConsumerStatefulWidget {
  const _RemindSheet({required this.event, required this.guests});

  final Event event;
  final List<Guest> guests;

  @override
  ConsumerState<_RemindSheet> createState() => _RemindSheetState();
}

class _RemindSheetState extends ConsumerState<_RemindSheet> {
  final _sent = <String>{};

  /// Réponses notées depuis cette feuille.
  final _answers = <String, Rsvp>{};

  void _answer(Guest g, Rsvp r) {
    ref.read(eventsProvider.notifier).setRsvp(widget.event.id, g.id, r);
    setState(() => _answers[g.id] = r);
  }

  Future<void> _remind(Guest g, String number) async {
    await openLink(
      reminderLink(number, reminderText(widget.event, g)).toString(),
    );
    if (mounted) setState(() => _sent.add(g.id));
  }

  @override
  Widget build(BuildContext context) {
    final reachable = widget.guests
        .where((g) => whatsappNumber(g.phone) != null)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Relancer par WhatsApp'.tr, style: context.text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            widget.guests.isEmpty
                ? 'Tous vos invités ont répondu.'.tr
                : 'Touchez « Relancer » : WhatsApp s’ouvre avec le message prêt, vous l’envoyez. Dès qu’un invité répond, notez sa réponse ici.'
                      .tr,
            style: context.text.bodyMedium?.copyWith(
              color: context.eventa.muted,
            ),
          ),
          if (widget.guests.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '{0} relancés sur {1} joignables'.trf([_sent.length, reachable]),
              style: context.text.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [for (final g in widget.guests) _row(g)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Guest g) {
    final number = whatsappNumber(g.phone);
    final sent = _sent.contains(g.id);
    final answer = _answers[g.id];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: context.text.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  switch (answer) {
                    Rsvp.yes => 'Présent · réponse notée'.tr,
                    Rsvp.no => 'Absent · réponse notée'.tr,
                    _ =>
                      number == null
                          ? 'Pas de numéro WhatsApp'.tr
                          : (g.group ?? g.phone!),
                  },
                  style: context.text.bodySmall?.copyWith(
                    color: answer == null
                        ? context.eventa.muted
                        : Confetti.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (answer == null && (sent || number == null)) ...[
            _AnswerButton(
              icon: AppIcons.check,
              label: 'Vient'.tr,
              color: Confetti.success,
              onTap: () => _answer(g, Rsvp.yes),
            ),
            const SizedBox(width: 6),
            _AnswerButton(
              icon: AppIcons.close,
              label: 'Ne vient pas'.tr,
              color: Confetti.danger,
              onTap: () => _answer(g, Rsvp.no),
            ),
          ] else if (answer == null && number != null)
            TextButton.icon(
              onPressed: () => _remind(g, number),
              icon: const Icon(AppIcons.whatsapp, size: 18),
              label: Text('Relancer'.tr),
            ),
        ],
      ),
    );
  }
}

/// Petit bouton rond pour noter la réponse d'un invité.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

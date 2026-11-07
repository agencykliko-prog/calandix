import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/mobile/open_link_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/open_link_web.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/presentation/events_providers.dart';
import '../../guests/presentation/remind_sheet.dart';
import 'invitations_providers.dart';
import 'rsvp_screen.dart';
import 'event_site_screen.dart';

/// Message d'invitation envoyé à un invité, avec son code d'entrée.
String invitationText(
  Event e,
  InvitationDesign d,
  Guest g, {
  bool site = false,
}) {
  final first = g.name.trim().split(RegExp(r'\s+')).first;
  final where = [
    e.venue.trim(),
    e.city.trim(),
  ].where((s) => s.isNotEmpty).join(', ');
  final b = StringBuffer()
    ..writeln('Bonjour {0} !'.trf([first]))
    ..writeln()
    ..writeln('« {0} »'.trf([d.titleFor(e)]))
    ..writeln(d.messageFor(e))
    ..writeln()
    ..writeln('Le {0}'.trf([longDate(e.date)]));
  if (where.isNotEmpty) b.writeln(where);
  if (d.dressCode.trim().isNotEmpty) {
    b.writeln('Tenue : {0}'.trf([d.dressCode.trim()]));
  }
  b
    ..writeln()
    ..writeln(
      'Merci de confirmer votre présence avant le {0} :'.trf([
        mediumDate(d.deadlineFor(e)),
      ]),
    )
    ..writeln(rsvpLink(e.id, g.id));
  if (site) {
    b.writeln('Programme, accès et hébergements : {0}'.trf([siteLink(e.id)]));
  }
  if (d.withQr) {
    b.writeln('Votre code d’entrée : {0}'.trf([guestCode(e.id, g.id)]));
  }
  return b.toString().trim();
}

/// Invitation numérique : mise en page, contenu, envoi à chaque invité par
/// WhatsApp ou par lien, et QR code d'entrée personnel.
class InvitationScreen extends ConsumerStatefulWidget {
  const InvitationScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _dress = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _dress.dispose();
    super.dispose();
  }

  InvitationDesign get _design =>
      ref.read(invitationProvider.notifier).of(widget.id);

  void _save(InvitationDesign d) =>
      ref.read(invitationProvider.notifier).save(widget.id, d);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventProvider(widget.id));
    ref.watch(invitationProvider);
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
        title: Text('Invitation numérique'.tr),
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
    final d = _design;
    if (!_loaded) {
      _loaded = true;
      _title.text = d.title ?? '';
      _message.text = d.message ?? '';
      _dress.text = d.dressCode;
    }
    final guests = e.guests.list;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(e.name, style: context.text.bodySmall),
        const SizedBox(height: 12),
        InvitationCard(event: e, design: d),
        const SizedBox(height: 22),
        SectionTitle('Mise en page'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in InvitationStyle.values)
              ChoiceChip(
                label: Text(s.label),
                selected: d.style == s,
                onSelected: (_) => _save(d.copyWith(style: s)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        AppField(
          label: 'Titre'.tr,
          controller: _title,
          hint: e.name,
          onChanged: (v) => _save(_design.copyWith(title: v)),
        ),
        const SizedBox(height: 12),
        AppField(
          label: 'Mot d’accueil'.tr,
          controller: _message,
          hint: 'Nous serions heureux de vous compter parmi nous pour célébrer ce moment.'
              .tr,
          maxLines: 3,
          onChanged: (v) => _save(_design.copyWith(message: v)),
        ),
        const SizedBox(height: 12),
        AppField(
          label: 'Tenue souhaitée (facultatif)'.tr,
          controller: _dress,
          hint: 'Tenue traditionnelle, touche de doré'.tr,
          onChanged: (v) => _save(_design.copyWith(dressCode: v)),
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          onTap: () async {
            final now = DateTime.now();
            final first = now.isAfter(e.date) ? e.date : now;
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(first.year, first.month, first.day),
              lastDate: e.date,
              initialDate: d.deadlineFor(e).isBefore(first)
                  ? first
                  : d.deadlineFor(e),
            );
            if (picked != null) _save(_design.copyWith(rsvpBefore: picked));
          },
          child: Row(
            children: [
              IconTile(icon: AppIcons.calendarCheck, hue: Hue.violet, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réponse attendue avant le'.tr,
                      style: context.text.bodySmall,
                    ),
                    Text(
                      longDate(d.deadlineFor(e)),
                      style: context.text.titleSmall,
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.edit, size: 18, color: context.eventa.muted),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: d.withQr,
          onChanged: (v) => _save(_design.copyWith(withQr: v)),
          title: Text(
            'QR code d’entrée personnel'.tr,
            style: context.text.titleSmall,
          ),
          subtitle: Text(
            'Chaque invité reçoit son code ; il est scanné à l’entrée le jour J.'
                .tr,
            style: context.text.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accompagnants par invité'.tr,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      'Chaque invité les déclare depuis son lien de réponse.'
                          .tr,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: AppIcons.minus,
                size: 34,
                tooltip: 'Moins',
                onTap: d.maxCompanions <= 0
                    ? null
                    : () => _save(
                        _design.copyWith(maxCompanions: d.maxCompanions - 1),
                      ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${d.maxCompanions}',
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
              ),
              RoundIconButton(
                icon: AppIcons.add,
                size: 34,
                tooltip: 'Plus',
                onTap: d.maxCompanions >= 10
                    ? null
                    : () => _save(
                        _design.copyWith(maxCompanions: d.maxCompanions + 1),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle(
          'Envoyer aux invités'.tr,
          action: d.withQr ? 'Contrôle des entrées'.tr : null,
          onAction: d.withQr ? () => context.push(Routes.entries(e.id)) : null,
        ),
        const SizedBox(height: 8),
        if (guests.isEmpty)
          Panel(
            child: Column(
              children: [
                Text(
                  'Ajoutez vos invités pour leur envoyer l’invitation.'.tr,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: 12),
                PillButton(
                  label: 'Ajouter des invités'.tr,
                  icon: AppIcons.userPlus,
                  expand: false,
                  onPressed: () => context.push(Routes.guests(e.id)),
                ),
              ],
            ),
          )
        else
          for (final g in guests) _GuestRow(event: e, design: d, guest: g),
      ],
    );
  }
}

class _GuestRow extends ConsumerWidget {
  const _GuestRow({
    required this.event,
    required this.design,
    required this.guest,
  });

  final Event event;
  final InvitationDesign design;
  final Guest guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final number = whatsappNumber(guest.phone);
    final (label, hue) = switch (guest.rsvp) {
      Rsvp.yes => ('Présent'.tr, Hue.lagoon),
      Rsvp.no => ('Absent'.tr, Hue.coral),
      Rsvp.pending => ('Sans réponse'.tr, Hue.mango),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guest.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Tag(label: label, hue: hue),
                      if (design.withQr)
                        Text(
                          guestCode(event.id, guest.id),
                          style: context.text.labelSmall?.copyWith(
                            color: context.eventa.muted,
                            letterSpacing: 0.8,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            RoundIconButton(
              icon: AppIcons.eye,
              tooltip: 'Voir son invitation'.tr,
              onTap: () => showGuestInvitation(context, event, guest),
            ),
            const SizedBox(width: 6),
            RoundIconButton(
              icon: number == null ? AppIcons.link : AppIcons.whatsapp,
              tooltip: number == null
                  ? 'Copier le message'.tr
                  : 'Envoyer par WhatsApp'.tr,
              background: number == null ? null : Hue.lagoon.tint,
              foreground: number == null ? null : Hue.lagoon.text,
              onTap: () async {
                final text = invitationText(
                  event,
                  design,
                  guest,
                  site:
                      ref.read(eventSiteProvider)[event.id]?.published ?? false,
                );
                if (number == null) {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    toast(
                      context,
                      'Message copié : collez-le dans la conversation de votre choix.'
                          .tr,
                    );
                  }
                } else {
                  await openLink(reminderLink(number, text).toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Aperçu de l'invitation telle que l'invité la reçoit : carte, QR code et
/// réponse. La réponse notée ici met à jour la liste des invités.
Future<void> showGuestInvitation(BuildContext context, Event e, Guest g) {
  return showEventaSheet<void>(
    context,
    builder: (ctx) => _GuestInvitation(event: e, guestId: g.id),
  );
}

class _GuestInvitation extends ConsumerWidget {
  const _GuestInvitation({required this.event, required this.guestId});

  final Event event;
  final String guestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(eventProvider(event.id)).value ?? event;
    final g = e.guests.list.firstWhere(
      (x) => x.id == guestId,
      orElse: () => Guest(id: guestId, name: ''),
    );
    final d = ref.watch(invitationProvider)[e.id] ?? const InvitationDesign();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invitation de {0}'.trf([g.name]),
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: 12),
          InvitationCard(event: e, design: d, guest: g),
          if (d.withQr) ...[
            const SizedBox(height: 16),
            Center(
              child: GuestQr(event: e, guest: g),
            ),
          ],
          const SizedBox(height: 16),
          Text('Réponse de l’invité'.tr, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (r, label) in [
                (Rsvp.yes, 'Présent'.tr),
                (Rsvp.no, 'Absent'.tr),
                (Rsvp.pending, 'Sans réponse'.tr),
              ]) ...[
                Expanded(
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                    selected: g.rsvp == r,
                    onSelected: (_) => ref
                        .read(eventsProvider.notifier)
                        .setRsvp(e.id, g.id, r),
                  ),
                ),
                if (r != Rsvp.pending) const SizedBox(width: 6),
              ],
            ],
          ),
          if (g.rsvp == Rsvp.yes) ...[
            const SizedBox(height: 10),
            Text(
              'Accompagnants : {0}'.trf([g.companions]),
              style: context.text.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text('Lien de réponse'.tr, style: context.text.titleSmall),
          const SizedBox(height: 4),
          SelectableText(rsvpLink(e.id, g.id), style: context.text.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Copier le lien'.tr,
                  icon: AppIcons.link,
                  tone: ButtonTone.ghost,
                  height: 44,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: rsvpLink(e.id, g.id)),
                    );
                    if (context.mounted) toast(context, 'Lien copié'.tr);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  label: 'Ouvrir comme l’invité'.tr,
                  icon: AppIcons.eye,
                  height: 44,
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(rsvpPath(e.id, g.id));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// QR code d'entrée d'un invité, avec son code lisible en dessous.
class GuestQr extends StatelessWidget {
  const GuestQr({
    super.key,
    required this.event,
    required this.guest,
    this.size = 168,
  });

  final Event event;
  final Guest guest;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Confetti.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: guestQrData(event.id, guest.id),
            size: size,
            padding: EdgeInsets.zero,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1A0637),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A0637),
            ),
            semanticsLabel: 'QR code d’entrée'.tr,
          ),
          const SizedBox(height: 8),
          Text(
            guestCode(event.id, guest.id),
            style: const TextStyle(
              fontFamily: AppTheme.font,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 1.6,
              color: Color(0xFF1A0637),
            ),
          ),
        ],
      ),
    );
  }
}

/// La carte d'invitation, dans la mise en page choisie.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.event,
    required this.design,
    this.guest,
  });

  final Event event;
  final InvitationDesign design;
  final Guest? guest;

  @override
  Widget build(BuildContext context) {
    final hue = event.category.hue;
    final (bg, fg, accent) = switch (design.style) {
      InvitationStyle.elegant => (
        const Color(0xFF1A0637),
        Colors.white,
        const Color(0xFFE59D1F),
      ),
      InvitationStyle.festive => (hue.base, hue.onBase, Colors.white),
      InvitationStyle.minimal => (
        Colors.white,
        const Color(0xFF1A0637),
        const Color(0xFF4D39E2),
      ),
    };
    final soft = fg.withValues(alpha: 0.78);
    final where = [
      event.venue.trim(),
      event.city.trim(),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(26),
        border: design.style == InvitationStyle.minimal
            ? Border.all(color: const Color(0xFFDDD8EE))
            : null,
      ),
      child: Column(
        children: [
          Icon(event.category.icon, color: accent, size: 28),
          const SizedBox(height: 10),
          if (guest != null && guest!.name.isNotEmpty) ...[
            Text(
              guest!.name,
              textAlign: TextAlign.center,
              style: TextStyle(color: soft, fontSize: 14),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'VOUS ÊTES INVITÉ'.tr,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            design.titleFor(event),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.font,
              color: fg,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            design.messageFor(event),
            textAlign: TextAlign.center,
            style: TextStyle(color: soft, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(height: 2, width: 48, color: accent),
          const SizedBox(height: 16),
          Text(
            longDate(event.date),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (where.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              where,
              textAlign: TextAlign.center,
              style: TextStyle(color: soft, fontSize: 14),
            ),
          ],
          if (design.dressCode.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Tenue : {0}'.trf([design.dressCode.trim()]),
              textAlign: TextAlign.center,
              style: TextStyle(color: soft, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Réponse souhaitée avant le {0}'.trf([
              mediumDate(design.deadlineFor(event)),
            ]),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

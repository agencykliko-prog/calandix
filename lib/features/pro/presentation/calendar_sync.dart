import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/mobile/download_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/download_web.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';
import 'creator_providers.dart';

/// Synchronisation avec Google Agenda : les créneaux occupés de l'agenda
/// bloquent les dates sur Calandix, et les prestations confirmées
/// s'ajoutent à l'agenda. Évite les doubles réservations prises ailleurs.
@immutable
class CalendarSync {
  const CalendarSync({
    this.account,
    this.busy = const {},
    this.lastSync,
    this.pushBookings = true,
  });

  /// Compte Google connecté ; null : non connecté.
  final String? account;

  /// Jours occupés dans l'agenda externe.
  final Set<DateTime> busy;
  final DateTime? lastSync;

  /// Ajouter les prestations Calandix à l'agenda.
  final bool pushBookings;

  bool get connected => account != null;

  CalendarSync copyWith({
    String? account,
    bool disconnect = false,
    Set<DateTime>? busy,
    DateTime? lastSync,
    bool? pushBookings,
  }) => CalendarSync(
    account: disconnect ? null : account ?? this.account,
    busy: busy ?? this.busy,
    lastSync: lastSync ?? this.lastSync,
    pushBookings: pushBookings ?? this.pushBookings,
  );
}

class CalendarSyncNotifier extends Notifier<CalendarSync> {
  @override
  CalendarSync build() => const CalendarSync();

  /// Démo : la connexion importe trois créneaux occupés à venir.
  void connect() {
    final email = ref.read(sessionProvider)?.email ?? '';
    state = state.copyWith(account: email);
    sync();
  }

  void sync() {
    if (!state.connected) return;
    final t = dateOnly(DateTime.now());
    state = state.copyWith(
      busy: {
        for (final d in const [6, 13, 27]) t.add(Duration(days: d)),
      },
      lastSync: DateTime.now(),
    );
  }

  void disconnect() => state = const CalendarSync();

  void setPush(bool v) => state = state.copyWith(pushBookings: v);
}

final calendarSyncProvider =
    NotifierProvider<CalendarSyncNotifier, CalendarSync>(
      CalendarSyncNotifier.new,
    );

String _ics(DateTime d) =>
    '${d.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';

/// Prestations confirmées au format iCalendar (Google, Apple, Outlook).
String bookingsIcs(List<ClientRequest> requests) {
  final b = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//Calandix//Prestations//FR');
  for (final r in requests) {
    if (r.status != RequestStatus.confirmed) continue;
    b
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${r.id}@calandix.ci')
      ..writeln('DTSTAMP:${_ics(DateTime.now())}')
      ..writeln('DTSTART:${_ics(r.date)}')
      ..writeln('DTEND:${_ics(r.date.add(const Duration(hours: 5)))}')
      ..writeln('SUMMARY:${r.eventName} · ${r.client}')
      ..writeln('LOCATION:${r.place ?? ''}')
      ..writeln('END:VEVENT');
  }
  b.writeln('END:VCALENDAR');
  return b.toString();
}

/// Encart « Agenda Google » des disponibilités.
class CalendarSyncPanel extends ConsumerWidget {
  const CalendarSyncPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(calendarSyncProvider);
    final n = ref.read(calendarSyncProvider.notifier);
    final soon =
        s.busy.where((d) => !d.isBefore(dateOnly(DateTime.now()))).toList()
          ..sort();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: AppIcons.calendarDots, hue: Hue.sky, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Google Agenda'.tr, style: context.text.titleSmall),
                    Text(
                      s.connected
                          ? 'Connecté · {0}'.trf([s.account!])
                          : 'Vos rendez-vous pris hors Calandix bloquent vos dates.'
                                .tr,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!s.connected)
            PillButton(
              label: 'Connecter Google Agenda'.tr,
              icon: AppIcons.link,
              height: 44,
              onPressed: () {
                n.connect();
                toast(
                  context,
                  'Agenda connecté : {0} jours occupés importés'.trf([
                    ref.read(calendarSyncProvider).busy.length,
                  ]),
                  icon: AppIcons.calendarDots,
                );
              },
            )
          else ...[
            if (soon.isNotEmpty) ...[
              Text(
                'Occupé dans votre agenda'.tr,
                style: context.text.labelMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in soon) Tag(label: mediumDate(d), hue: Hue.sky),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: s.pushBookings,
                onChanged: n.setPush,
                title: Text(
                  'Ajouter mes prestations Calandix à l’agenda'.tr,
                  style: context.text.bodyMedium,
                ),
              ),
            ),
            if (s.lastSync != null)
              Text(
                'Dernière synchronisation à {0}'.trf([timeOf(s.lastSync!)]),
                style: context.text.bodySmall,
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillButton(
                  label: 'Synchroniser'.tr,
                  icon: AppIcons.refresh,
                  expand: false,
                  height: 40,
                  tone: ButtonTone.ghost,
                  onPressed: () {
                    n.sync();
                    toast(context, 'Agenda synchronisé'.tr);
                  },
                ),
                PillButton(
                  label: 'Exporter (.ics)'.tr,
                  icon: AppIcons.download,
                  expand: false,
                  height: 40,
                  tone: ButtonTone.ghost,
                  onPressed: () async {
                    final ok = await saveTextFile(
                      'calandix-prestations.ics',
                      bookingsIcs(ref.read(requestsProvider)),
                    );
                    if (!ok && context.mounted) {
                      toast(context, 'Export disponible sur le web'.tr);
                    }
                  },
                ),
                PillButton(
                  label: 'Déconnecter'.tr,
                  expand: false,
                  height: 40,
                  tone: ButtonTone.ghost,
                  onPressed: n.disconnect,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

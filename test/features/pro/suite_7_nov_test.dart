import 'package:eventa/core/auth/profile.dart';
import 'package:eventa/core/auth/session_provider.dart';
import 'package:eventa/core/models/models.dart';
import 'package:eventa/core/utils/formatters.dart';
import 'package:eventa/features/budget/presentation/budget_stats_screen.dart';
import 'package:eventa/features/events/data/demo_data.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/features/invitations/presentation/event_site_screen.dart';
import 'package:eventa/features/invitations/presentation/invitations_providers.dart';
import 'package:eventa/features/notifications/presentation/push_prefs.dart';
import 'package:eventa/features/pro/presentation/calendar_sync.dart';
import 'package:eventa/features/pro/presentation/creator_providers.dart';
import 'package:eventa/features/pro/presentation/pro_providers.dart';
import 'package:eventa/features/pro/presentation/quote_tools.dart';
import 'package:eventa/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  ProviderContainer creator() {
    final c = ProviderContainer();
    c.read(sessionProvider.notifier).signIn(UserRole.creator);
    return c;
  }

  test('notifications push : types par profil, coupables un à un', () {
    expect(PushKind.forRole(creator: true), contains(PushKind.newRequest));
    expect(
      PushKind.forRole(creator: true),
      isNot(contains(PushKind.quoteReceived)),
    );
    expect(PushKind.forRole(creator: false), contains(PushKind.quoteReceived));
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(pushPrefsProvider), containsAll(PushKind.values));
    c.read(pushPrefsProvider.notifier).toggle(PushKind.dayBefore, false);
    expect(c.read(pushPrefsProvider), isNot(contains(PushKind.dayBefore)));
  });

  test('Google Agenda : les jours occupés bloquent les réservations', () {
    final c = creator();
    addTearDown(c.dispose);
    final day = dateOnly(DateTime.now()).add(const Duration(days: 6));
    expect(c.read(dayFullProvider(day)), isFalse);
    c.read(calendarSyncProvider.notifier).connect();
    expect(c.read(calendarSyncProvider).connected, isTrue);
    expect(c.read(dayFullProvider(day)), isTrue);
    final ics = bookingsIcs(c.read(requestsProvider));
    expect(ics, startsWith('BEGIN:VCALENDAR'));
    expect(ics, contains('BEGIN:VEVENT'));
  });

  test('relance automatique d’un devis sans réponse', () {
    final c = creator();
    addTearDown(c.dispose);
    final r3 = c.read(requestsProvider).firstWhere((r) => r.id == 'r3');
    // Envoyé il y a 2 jours : relance prévue à J+3.
    expect(followUpDue(r3, 3), isNotNull);
    expect(followUpDue(r3, 3)!.isAfter(DateTime.now()), isTrue);
    c.read(requestsProvider.notifier).followUp('r3');
    final after = c.read(requestsProvider).firstWhere((r) => r.id == 'r3');
    expect(after.followedUpAt, isNotNull);
    expect(after.thread.last.fromMe, isTrue);
    expect(followUpDue(after, 3), isNull);
  });

  test('modèles de devis par type d’événement', () {
    final c = creator();
    addTearDown(c.dispose);
    final t = c.read(quoteTemplatesProvider);
    expect(t.map((x) => x.category), contains(EventCategory.wedding));
  });

  test('page de l’événement : programme et réponses connues', () {
    final e = DemoData.wedding();
    final s = defaultSite(e, const InvitationDesign(dressCode: 'Blanc'));
    expect(s.program, isNotEmpty);
    expect(s.faq.map((f) => f.answer), contains('Blanc'));
    expect(s.addressFor(e), isNotEmpty);
    expect(directionsUrl('Cocody, Abidjan'), contains('destination=Cocody'));
  });

  test('statistiques : réel = engagé ou payé, parts du budget', () {
    const l = BudgetLine(
      category: BudgetCategory.venue,
      estimated: 100,
      committed: 120,
      paid: 50,
    );
    expect(realOf(l), 120);
    final e = DemoData.wedding();
    final shares = sharesOf(e);
    expect(shares.values.fold<double>(0, (a, b) => a + b), closeTo(100, 0.01));
  });

  test('entrées hors ligne : en attente puis synchronisées', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.organizer);
    final e = (await c.read(eventsProvider.future)).first;
    final g = e.guests.list.firstWhere((x) => x.rsvp == Rsvp.yes);
    c.read(offlineEntriesProvider.notifier).enable(e);
    c.read(checkInProvider.notifier).check(e, guestCode(e.id, g.id));
    expect(c.read(checkInProvider.notifier).pending(e.id), 1);
    expect(c.read(checkInProvider.notifier).sync(e.id), 1);
    expect(c.read(checkInProvider.notifier).pending(e.id), 0);
  });

  for (final size in const [Size(375, 812), Size(1280, 800)]) {
    testWidgets('nouveaux écrans sans débordement (${size.width.toInt()} px)', (
      tester,
    ) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionProvider.notifier).signIn(UserRole.organizer);
      final e = (await tester.runAsync(() => c.read(eventsProvider.future)))!
          .first;
      for (final screen in [
        EventSiteEditor(id: e.id),
        EventSitePage(id: e.id),
        BudgetStatsScreen(id: e.id),
      ]) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(theme: AppTheme.current(), home: screen),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

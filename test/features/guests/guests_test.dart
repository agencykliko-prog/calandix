import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/features/events/data/demo_data.dart';
import 'package:eventa/features/events/data/event_templates.dart';
import 'package:eventa/features/events/data/events_repository.dart';
import 'package:eventa/core/models/models.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/features/guests/presentation/guests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Événement neuf, sans liste d'invités, et trace des enregistrements.
class _Recorder extends EventsRepository {
  _Recorder(this.event);

  final Event event;
  final saved = <Guest>[];
  final deleted = <String>[];

  @override
  Future<List<Event>> fetchEvents() async => [event];

  @override
  Future<void> saveGuest(String eventId, Guest g) async => saved.add(g);

  @override
  Future<void> deleteGuest(String guestId) async => deleted.add(guestId);
}

Event _fresh() => EventTemplates.create(
  category: EventCategory.birthday,
  subcategories: const [],
  name: 'Anniversaire test',
  date: DateTime.now().add(const Duration(days: 60)),
  city: 'Abidjan',
  guests: 40,
  budget: 1000000,
);

ProviderContainer _container(EventsRepository repo) {
  final c = ProviderContainer(
    overrides: [eventsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('la liste de démo retombe sur les compteurs affichés', () {
    final g = DemoData.wedding().guests;
    expect(g.list, hasLength(250));
    expect(g.invited, 250);
    expect(g.confirmed, 162);
    expect(g.declined, 18);
    expect(g.todayNew, 8);
    expect(g.list.map((x) => x.name).toSet(), hasLength(250));
    expect(g.headcount, greaterThan(g.confirmed));
  });

  test('ajouter, répondre puis retirer un invité', () async {
    final repo = _Recorder(_fresh());
    final c = _container(repo);
    final e = (await c.read(eventsProvider.future)).single;
    expect(
      e.guests.invited,
      40,
      reason: 'nombre prévu tant que la liste est vide',
    );

    final events = c.read(eventsProvider.notifier);
    final id = events.addGuest(
      e.id,
      const Guest(id: 'g-1', name: 'Yao Kouassi', companions: 1),
    );
    var g = c.read(eventProvider(e.id)).value!.guests;
    expect(g.invited, 1);
    expect(g.pending, 1);

    events.setRsvp(e.id, id, Rsvp.yes);
    g = c.read(eventProvider(e.id)).value!.guests;
    expect(g.confirmed, 1);
    expect(g.headcount, 2);

    events.removeGuest(e.id, id);
    g = c.read(eventProvider(e.id)).value!.guests;
    expect(g.list, isEmpty);
    expect(g.invited, 40, reason: 'le nombre prévu reprend la main');

    await Future<void>.delayed(Duration.zero);
    expect(repo.saved.map((x) => x.rsvp), [Rsvp.pending, Rsvp.yes]);
    expect(repo.deleted, [id]);
  });

  testWidgets('ajouter un invité depuis la liste', (tester) async {
    tester.view.physicalSize = const Size(430, 932) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final event = _fresh();
    final c = _container(_Recorder(event));

    final router = GoRouter(
      initialLocation: '/evenement/${event.id}/invites',
      routes: [
        GoRoute(
          path: '/evenement/:id/invites',
          builder: (_, s) => GuestsScreen(id: s.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: AppTheme.current(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Aucun invité dans la liste'), findsOneWidget);
    expect(
      find.text('40 invités prévus. Ajoutez-les pour suivre leurs réponses.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ajouter un invité'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvel invité'), findsOneWidget);

    // Sans nom, rien n'est ajouté.
    await tester.tap(find.text('Ajouter'));
    await tester.pump();
    expect(find.text('Indiquez le nom de l’invité.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Aya Konan');
    await tester.tap(find.text('Présent'));
    await tester.pump();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    expect(find.text('Aya Konan'), findsOneWidget);
    expect(find.text('Tous · 1'), findsOneWidget);
    expect(find.text('Présents · 1'), findsOneWidget);
    expect(c.read(eventProvider(event.id)).value!.guests.confirmed, 1);
  });
}

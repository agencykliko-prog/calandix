import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/features/booking/presentation/quote_compare_screen.dart';
import 'package:eventa/features/commerce/data/catalog.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/events/data/events_repository.dart';
import 'package:eventa/core/models/models.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      eventsRepositoryProvider.overrideWithValue(
        const DemoEventsRepository(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// Demande un devis à deux photographes et à un traiteur pour le même
/// événement, puis attend les devis simulés.
Future<(String, List<String>)> _threeQuotes(ProviderContainer c) async {
  final events = await c.read(eventsProvider.future);
  final e = events.first;
  final photo = Catalog.vendors
      .where((v) => v.category == VendorCategory.photo)
      .take(2);
  final food = Catalog.vendors.firstWhere(
    (v) => v.category == VendorCategory.catering,
  );
  final bookings = c.read(bookingsProvider.notifier);
  final ids = [
    for (final v in [...photo, food])
      bookings.request(
        v,
        e.id,
        QuoteRequest(date: e.date, guests: 80, message: 'Bonjour'),
      ),
  ];
  await Future<void>.delayed(const Duration(milliseconds: 3200));
  return (e.id, ids);
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test(
    'les devis sont groupés par catégorie, du moins cher au plus cher',
    () async {
      final c = _container();
      final (eventId, ids) = await _threeQuotes(c);

      final groups = c.read(quoteGroupsProvider(eventId));
      expect(groups, hasLength(2));
      final photo = groups.first;
      expect(photo.category, VendorCategory.photo);
      expect(photo.offers, hasLength(2));
      expect(
        photo.offers.first.quote!.total,
        lessThanOrEqualTo(photo.offers.last.quote!.total),
      );
      expect(
        photo.spread,
        photo.offers.last.quote!.total - photo.offers.first.quote!.total,
      );
      expect(c.read(rivalQuotesProvider(ids[0])), 1);
      expect(c.read(rivalQuotesProvider(ids[2])), 0);

      // Une fois un devis accepté, la catégorie a son prestataire retenu.
      c.read(bookingsProvider.notifier).accept(photo.cheapest.id);
      expect(
        c.read(quoteGroupsProvider(eventId)).first.chosen?.id,
        photo.cheapest.id,
      );
    },
  );

  testWidgets('comparer puis choisir le devis le moins cher', (tester) async {
    tester.view.physicalSize = const Size(430, 932) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = _container();
    final (eventId, _) = (await tester.runAsync(() => _threeQuotes(c)))!;
    final cheapest = c.read(quoteGroupsProvider(eventId)).first.cheapest;

    final router = GoRouter(
      initialLocation: '/evenement/$eventId/devis',
      routes: [
        GoRoute(
          path: '/evenement/:id/devis',
          builder: (_, s) =>
              QuoteCompareScreen(eventId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/reservation/:id',
          builder: (_, s) => Text('réservation ${s.pathParameters['id']}'),
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

    expect(find.text('Comparer les devis'), findsOneWidget);
    expect(find.text('Le moins cher'), findsOneWidget);
    expect(find.text(cheapest.vendor.name), findsOneWidget);

    // L'analyse Calandix précède les devis : on fait défiler jusqu'au bouton.
    final choose = find.byKey(ValueKey('choose-${cheapest.id}'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pump();
    await tester.ensureVisible(choose);
    await tester.pump();
    await tester.tap(choose);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('réservation ${cheapest.id}'), findsOneWidget);
  });
}

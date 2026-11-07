import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/core/auth/profile.dart';
import 'package:eventa/core/auth/session_provider.dart';
import 'package:eventa/features/commerce/data/catalog.dart';
import 'package:eventa/core/models/models.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/features/marketplace/data/vendor_media.dart';
import 'package:eventa/features/marketplace/presentation/vendor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('chaque catégorie compte au moins 5 prestataires, 5 photos chacun', () {
    for (final c in VendorCategory.values) {
      final list = Catalog.vendors.where((v) => v.category == c).toList();
      expect(list.length, greaterThanOrEqualTo(5), reason: c.name);
      for (final v in list) {
        final photos = VendorMedia.portfolioOf(v);
        expect(photos.length, 5);
        expect(photos.toSet().length, 5, reason: v.id);
      }
    }
  });

  testWidgets('fiche traiteur : portfolio, devis adapté et invités saisis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.organizer);
    // Les événements sont chargés par l'accueil dans l'app : on les écoute.
    c.listen(eventsProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.current(),
          home: const VendorScreen(id: 'chez-mamie-adjoua'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.text('Portfolio'), findsOneWidget);

    // Téléphone étroit : libellé court, jamais tronqué.
    expect(find.text('Devis'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('request-quote')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Service'), findsOneWidget);
    expect(find.text('Buffet'), findsWidgets);
    expect(find.textContaining('Régimes'), findsOneWidget);

    // Nombre d'invités saisi au clavier : l'estimation suit.
    await tester.enterText(find.byType(TextField).first, '275');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('275 invités'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

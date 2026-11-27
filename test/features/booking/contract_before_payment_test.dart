import 'dart:typed_data';

import 'package:eventa/core/auth/profile.dart';
import 'package:eventa/core/auth/session_provider.dart';
import 'package:eventa/features/booking/presentation/booking_screen.dart';
import 'package:eventa/features/booking/presentation/contract_sheet.dart';
import 'package:eventa/features/commerce/data/catalog.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('aucun paiement avant la signature du contrat de prestation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.organizer);
    final e = (await tester.runAsync(() => c.read(eventsProvider.future)))!
        .first;
    final bookings = c.read(bookingsProvider.notifier);
    final id = bookings.request(
      Catalog.vendor('studio-lumiere'),
      e.id,
      QuoteRequest(date: e.date, guests: 60, message: 'Bonjour'),
    );
    await tester.pump(const Duration(seconds: 3));
    bookings.accept(id);
    expect(c.read(bookingProvider(id))!.step, BookingStep.reserved);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.current(),
          home: BookingScreen(id: id),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Contrat non signé : le bouton l'annonce, et ouvre le contrat au lieu
    // du paiement.
    expect(find.text('Signer le contrat et payer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('booking-pay')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1. Parties'), findsOneWidget);
    expect(find.textContaining('Réservation Studio'), findsNothing);
    expect(c.read(bookingProvider(id))!.paidAmount, 0);

    // Fermer le contrat sans signer : toujours aucun paiement.
    Navigator.of(tester.element(find.text('1. Parties'))).pop();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Réservation Studio'), findsNothing);

    // Une fois signé, le paiement redevient possible.
    c
        .read(contractsProvider.notifier)
        .sign(
          id,
          SignedContract(
            signer: 'Test',
            at: DateTime(2026, 11, 27),
            png: Uint8List(0),
            reference: 'CT-TEST',
          ),
        );
    await tester.pump();
    expect(find.text('Payer en toute sécurité'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('booking-pay')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Réservation Studio'), findsOneWidget);
  });
}

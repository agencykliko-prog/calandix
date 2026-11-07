import 'package:eventa/core/auth/profile.dart';
import 'package:eventa/core/auth/session_provider.dart';
import 'package:eventa/features/booking/presentation/quote_signature.dart';
import 'package:eventa/features/commerce/data/catalog.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/events/presentation/event_trash.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/features/pro/presentation/creator_providers.dart';
import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/ui/widgets/forms.dart';
import 'package:eventa/ui/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  ProviderContainer organizer() {
    final c = ProviderContainer();
    c.read(sessionProvider.notifier).signIn(UserRole.organizer);
    return c;
  }

  test('corbeille : supprimer, restaurer, effacer définitivement', () async {
    final c = organizer();
    addTearDown(c.dispose);
    final events = await c.read(eventsProvider.future);
    final e = events.first;
    final trash = c.read(trashProvider.notifier);

    trash.trash(e.id);
    expect(c.read(eventsProvider).value!.any((x) => x.id == e.id), isFalse);
    expect(c.read(trashProvider).single.event.id, e.id);
    expect(c.read(trashProvider).single.daysLeft(), trashRetention.inDays);

    // Restauré tel qu'il était.
    trash.restore(e.id);
    final back = c.read(eventsProvider).value!.firstWhere((x) => x.id == e.id);
    expect(back.guests.list.length, e.guests.list.length);
    expect(back.budget.length, e.budget.length);
    expect(c.read(trashProvider), isEmpty);

    // La suppression définitive ne passe que par la corbeille.
    trash.deleteForever(e.id);
    expect(c.read(eventsProvider).value!.any((x) => x.id == e.id), isTrue);
    trash.trash(e.id);
    trash.deleteForever(e.id);
    expect(c.read(trashProvider), isEmpty);
    expect(c.read(eventsProvider).value!.any((x) => x.id == e.id), isFalse);
  });

  test('corbeille : effacement automatique après 30 jours', () async {
    final c = organizer();
    addTearDown(c.dispose);
    final events = await c.read(eventsProvider.future);
    final trash = c.read(trashProvider.notifier);
    trash.trash(
      events[0].id,
      at: DateTime.now().subtract(const Duration(days: 31)),
    );
    expect(c.read(trashProvider), isEmpty);
    trash.trash(
      events[1].id,
      at: DateTime.now().subtract(const Duration(days: 25)),
    );
    expect(c.read(trashProvider).single.daysLeft(), 5);
  });

  test('le prestataire voit le bon pour accord signé du client', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.creator);
    final accepted = c
        .read(requestsProvider)
        .where((r) => r.status == RequestStatus.confirmed);
    expect(accepted.every((r) => r.clientSignatureRef != null), isTrue);
    final r3 = c.read(requestsProvider).firstWhere((r) => r.id == 'r3');
    expect(r3.clientSignedAt, isNull);
    c.read(requestsProvider.notifier).confirm('r3');
    final after = c.read(requestsProvider).firstWhere((r) => r.id == 'r3');
    expect(after.clientSignatureRef, startsWith('DV-'));
  });

  testWidgets('effacer définitivement : il faut recopier le nom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = organizer();
    addTearDown(c.dispose);
    final e = (await tester.runAsync(() => c.read(eventsProvider.future)))!
        .first;
    c.read(trashProvider.notifier).trash(e.id);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.current(),
          home: const TrashScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(e.name), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('forever-${e.id}')));
    await tester.pumpAndSettle();
    PillButton confirm() => tester.widget<PillButton>(
      find.byKey(const ValueKey('confirm-forever')),
    );
    await tester.tap(find.byType(CheckRow));
    await tester.pump();
    expect(confirm().onPressed, isNull, reason: 'nom pas encore recopié');
    await tester.enterText(find.byType(TextField), e.name.toUpperCase());
    await tester.pump();
    expect(confirm().onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('confirm-forever')));
    await tester.pumpAndSettle();
    expect(c.read(trashProvider), isEmpty);
    expect(find.text('La corbeille est vide'), findsOneWidget);
  });

  testWidgets('le devis n’est validé qu’après la signature de l’organisateur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = organizer();
    addTearDown(c.dispose);
    final e = (await tester.runAsync(() => c.read(eventsProvider.future)))!
        .first;
    final id = c
        .read(bookingsProvider.notifier)
        .request(
          Catalog.vendor('studio-lumiere'),
          e.id,
          QuoteRequest(date: e.date, guests: 60, message: 'Bonjour'),
        );
    await tester.pump(const Duration(seconds: 3));
    expect(c.read(bookingProvider(id))!.step, BookingStep.quoted);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.current(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showQuoteSignSheet(context, c.read(bookingProvider(id))!),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    PillButton sign() =>
        tester.widget<PillButton>(find.byKey(const ValueKey('sign-quote')));
    expect(sign().onPressed, isNull);

    await tester.drag(
      find.byKey(const ValueKey('signature-pad')),
      const Offset(180, 30),
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await tester.timedDrag(
      find.byKey(const ValueKey('signature-pad')),
      const Offset(-120, 40),
      const Duration(milliseconds: 300),
    );
    await tester.pump();
    expect(sign().onPressed, isNull, reason: 'accord pas encore coché');
    await tester.tap(find.byType(CheckRow));
    await tester.pump();
    expect(sign().onPressed, isNotNull);
    // Toujours au stade « devis » tant que rien n'est signé.
    expect(c.read(bookingProvider(id))!.step, BookingStep.quoted);

    await tester.runAsync(() async {
      sign().onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pumpAndSettle();
    final b = c.read(bookingProvider(id))!;
    expect(b.step, BookingStep.reserved);
    final s = c.read(quoteSignaturesProvider)[id]!;
    expect(s.reference, startsWith('DV-'));
    expect(s.total, b.quote!.total);
    expect(b.messages.last.text, contains(s.reference));
    expect(
      c.read(vaultProvider).any((d) => d.folder == VaultFolder.quotes),
      isTrue,
    );
  });
}

import 'package:eventa/features/commerce/data/catalog.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/events/data/event_templates.dart';
import 'package:eventa/features/events/data/events_repository.dart';
import 'package:eventa/core/models/models.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  test('chaque catégorie de prestataires a au moins 2 prestataires', () {
    for (final cat in VendorCategory.values) {
      expect(
        Catalog.vendors.where((v) => v.category == cat).length,
        greaterThanOrEqualTo(2),
        reason: cat.label,
      );
    }
  });

  test('chaque type d’événement a des sous-catégories et un agent IA', () {
    for (final c in EventCategory.values) {
      expect(c.subcategories, isNotEmpty);
      expect(Catalog.agent(c).skills, isNotEmpty);
    }
  });

  test(
    'parcours de réservation : devis, réservation, paiement, clôture',
    () async {
      final c = _container();
      final events = await c.read(eventsProvider.future);
      final e = events.firstWhere((x) => x.category == EventCategory.birthday);
      final vendor = Catalog.vendor('studio-lumiere');
      final committedBefore = e.committed;
      final paidBefore = e.paid;

      final bookings = c.read(bookingsProvider.notifier);
      final id = bookings.request(
        vendor,
        e.id,
        QuoteRequest(date: e.date, guests: 60, message: 'Bonjour'),
      );
      expect(c.read(bookingProvider(id))!.step, BookingStep.requested);

      // Le devis arrive après le délai simulé.
      await Future<void>.delayed(const Duration(milliseconds: 2800));
      final quoted = c.read(bookingProvider(id))!;
      expect(quoted.step, BookingStep.quoted);
      expect(quoted.quote!.total, greaterThan(0));

      bookings.accept(id);
      final afterAccept = c.read(eventProvider(e.id)).value!;
      expect(afterAccept.committed, committedBefore + quoted.quote!.subtotal);

      final deposit = quoted.quote!.deposit;
      final receipt = bookings.pay(id, deposit, PayMethod.wave);
      expect(receipt.amount, deposit);
      expect(c.read(bookingProvider(id))!.step, BookingStep.executing);
      expect(c.read(eventProvider(e.id)).value!.paid, paidBefore + deposit);
      expect(c.read(vaultProvider).first.name, contains(receipt.ref));

      bookings.pay(id, c.read(bookingProvider(id))!.balance, PayMethod.card);
      expect(c.read(bookingProvider(id))!.fullyPaid, isTrue);

      bookings.close(id);
      final closed = c.read(bookingProvider(id))!;
      expect(closed.step, BookingStep.closed);
      expect(closed.payoutDone, isTrue);
    },
  );

  test('une dépense met à jour le payé et le reste à dépenser', () async {
    final c = _container();
    final events = await c.read(eventsProvider.future);
    final e = events.first;
    c
        .read(eventsProvider.notifier)
        .addExpense(
          e.id,
          Expense(
            id: 't',
            category: BudgetCategory.drinks,
            label: 'Boissons',
            amount: 100000,
            date: DateTime.now(),
          ),
        );
    final after = c.read(eventProvider(e.id)).value!;
    expect(after.paid, e.paid + 100000);
    expect(after.remainingToSpend, e.remainingToSpend - 100000);
  });

  test('le budget IA conserve les montants déjà engagés', () async {
    final c = _container();
    final events = await c.read(eventsProvider.future);
    final e = events.firstWhere((x) => x.category == EventCategory.wedding);
    final lines = EventTemplates.aiBudget(e);
    for (final l in e.budget) {
      final n = lines.firstWhere((x) => x.category == l.category);
      expect(n.committed, l.committed);
      expect(n.estimated, greaterThanOrEqualTo(l.committed));
    }
  });

  test('les fonctionnalités Premium suivent l’abonnement', () {
    final c = _container();
    bool unlocked(PremiumFeature f) =>
        c.read(featureUnlockedProvider((f, null)));

    expect(unlocked(PremiumFeature.events), isFalse);
    expect(Plan.free.activeEvents, 4);
    c.read(planProvider.notifier).subscribe(Plan.azur);
    expect(unlocked(PremiumFeature.events), isTrue);
    // Coffre-fort : 1 Go offert, l'espace étendu dès Azur.
    expect(unlocked(PremiumFeature.vault), isTrue);
    expect(Plan.free.vaultMb, 1024);
    expect(unlocked(PremiumFeature.agent), isFalse);
    c.read(planProvider.notifier).subscribe(Plan.signature);
    expect(unlocked(PremiumFeature.agent), isTrue);
    // À l'année : deux mois offerts.
    expect(Plan.signature.yearlyPrice, 29000);
  });

  test('essai gratuit de 14 jours et Pass Événement', () {
    final c = _container();
    bool unlocked(PremiumFeature f, [String? id]) =>
        c.read(featureUnlockedProvider((f, id)));

    c.read(planProvider.notifier).startTrial(Plan.signature);
    expect(unlocked(PremiumFeature.agent), isTrue);
    expect(
      c.read(trialEndsProvider)!.difference(DateTime.now()).inDays,
      closeTo(trialDays, 1),
    );
    expect(c.read(trialUsedProvider), isTrue);

    // Sans abonnement, le pass ne débloque que son événement.
    final d = _container();
    bool passUnlocked(PremiumFeature f, String? id) =>
        d.read(featureUnlockedProvider((f, id)));
    d.read(eventPassProvider.notifier).activate('ev-1');
    expect(passUnlocked(PremiumFeature.agent, 'ev-1'), isTrue);
    expect(passUnlocked(PremiumFeature.agent, 'ev-2'), isFalse);
    expect(passUnlocked(PremiumFeature.agent, null), isFalse);
  });
}

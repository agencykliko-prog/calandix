import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/core/auth/profile.dart';
import 'package:eventa/core/auth/session_provider.dart';
import 'package:eventa/features/pro/presentation/creator_providers.dart';
import 'package:eventa/features/pro/domain/pro_models.dart';
import 'package:eventa/features/pro/presentation/availability_screen.dart';
import 'package:eventa/features/pro/presentation/orders_screen.dart';
import 'package:eventa/features/pro/presentation/profile_catalog_screen.dart';
import 'package:eventa/features/pro/presentation/pro_providers.dart';
import 'package:eventa/features/pro/presentation/pro_stats_screen.dart';
import 'package:eventa/features/pro/presentation/reputation_screen.dart';
import 'package:eventa/features/pro/presentation/studio_screen.dart';
import 'package:eventa/features/pro/presentation/request_detail_screen.dart';
import 'package:eventa/features/pro/presentation/revenue_screen.dart';
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

  final screens = <String, Widget>{
    'profil': const ProfileCatalogScreen(),
    'disponibilités': const AvailabilityScreen(),
    'devis': const RequestDetailScreen(id: 'r1'),
    'devis envoyé': const RequestDetailScreen(id: 'r3'),
    'commandes': const OrdersScreen(),
    'revenus': const RevenueScreen(),
    'réputation': const ReputationScreen(),
    'statistiques': const ProStatsScreen(),
    'studio': const StudioScreen(),
  };

  for (final size in const [Size(375, 812), Size(1280, 860)]) {
    for (final e in screens.entries) {
      testWidgets('${e.key} s’affiche sans débordement à ${size.width}', (
        tester,
      ) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final c = creator();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(theme: AppTheme.current(), home: e.value),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }

  test('un devis détaillé fixe le total, la validité et l’acompte', () {
    final c = creator();
    addTearDown(c.dispose);
    c
        .read(requestsProvider.notifier)
        .sendDetailedQuote(
          'r1',
          items: const [
            QuoteItem('Forfait Signature', 1200000),
            QuoteItem('Arche de ballons', 85000, option: true),
          ],
          validityDays: 14,
          depositPercent: 50,
        );
    final r = c.read(requestsProvider).firstWhere((x) => x.id == 'r1');
    expect(r.status, RequestStatus.quoted);
    expect(r.quote, 1285000);
    expect(r.depositPercent, 50);
    // 14 jours à quelques millisecondes près, selon la précision de l'horloge.
    expect(
      r.validUntil!.difference(DateTime.now()).inMinutes,
      inInclusiveRange(14 * 24 * 60 - 1, 14 * 24 * 60),
    );
  });

  test('un refus garde son motif', () {
    final c = creator();
    addTearDown(c.dispose);
    c.read(requestsProvider.notifier).decline('r2', reason: 'Hors de ma zone');
    final r = c.read(requestsProvider).firstWhere((x) => x.id == 'r2');
    expect(r.status, RequestStatus.declined);
    expect(r.declineReason, 'Hors de ma zone');
  });

  test('clôturer une commande programme le reversement net', () {
    final c = creator();
    addTearDown(c.dispose);
    final r = c.read(requestsProvider).firstWhere((x) => x.id == 'r5');
    final n = c.read(proProvider.notifier);
    final before = c.read(proProvider).payouts.length;
    for (var i = 0; i < OrderStage.values.length; i++) {
      n.advance(r);
    }
    final s = c.read(proProvider);
    expect(s.progressOf('r5').stage, OrderStage.closed);
    expect(s.payouts.length, before + 1);
    expect(s.payouts.first.status, PayoutStatus.scheduled);
    expect(s.payouts.first.net, (1100000 * (1 - proCommissionRate)).round());
  });

  test('une date bloquée est complète (anti-double réservation)', () {
    final c = creator();
    addTearDown(c.dispose);
    final day = DateTime.now().add(const Duration(days: 30));
    expect(c.read(dayFullProvider(day)), isFalse);
    c.read(proProvider.notifier).toggleBlocked(day);
    expect(c.read(dayFullProvider(day)), isTrue);
  });
}

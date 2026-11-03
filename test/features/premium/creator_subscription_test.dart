import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/premium/presentation/business_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('parcours complet de l’abonnement Creator à 15 000 FCFA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.current(),
          home: const BusinessScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(creatorSubProvider), isNull);
    expect(find.text('Offre Creator'), findsOneWidget);

    // 1. Souscription : la feuille de paiement s'ouvre au bon montant.
    await tester.tap(find.textContaining('S’abonner'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Abonnement Creator'), findsOneWidget);
    expect(find.textContaining(RegExp(r'15.000')), findsWidgets);

    // 2. Paiement Mobile Money, puis reçu.
    final pay = find.textContaining('Payer');
    await tester.ensureVisible(pay);
    await tester.pump();
    await tester.tap(pay);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Terminé'), findsOneWidget);
    final sub = c.read(creatorSubProvider);
    expect(sub, isNotNull);
    expect(sub!.cancelled, isFalse);
    expect(sub.renewsOn.difference(sub.since).inDays, 30);

    // 3. Retour à l'offre : l'abonnement apparaît comme actif.
    await tester.tap(find.text('Terminé'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Offre Creator active'), findsOneWidget);

    // 4. Résiliation confirmée, puis réactivation.
    await tester.tap(find.text('Résilier').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Résilier').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(creatorSubProvider)!.cancelled, isTrue);
    expect(find.text('Offre Creator résiliée'), findsOneWidget);
    await tester.tap(find.text('Réactiver'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.read(creatorSubProvider)!.cancelled, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/premium/presentation/business_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('la commission baisse avec la formule, et chaque formule est rentable '
      'au bon seuil', () {
    expect([for (final p in ProPlan.values) p.commissionPercent], [6, 5, 4, 2]);
    expect(
      [for (final p in ProPlan.values) p.yearlyPrice],
      [0, 30000, 59000, 99000],
    );
    expect(ProPlan.decouverte.catalogLimit, 5);
    expect(ProPlan.starter.catalogLimit, 15);
    expect(ProPlan.creator.catalogLimit, isNull);
    // 3 000 FCFA d'abonnement / 1 point de commission en moins.
    expect(ProPlan.starter.breakEven, 300000);
    expect(ProPlan.starter.studio, isFalse);
    expect(ProPlan.creator.studio, isTrue);
  });

  testWidgets('parcours complet d’une formule prestataire', (tester) async {
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
    expect(c.read(proPlanProvider), ProPlan.decouverte);
    expect(c.read(proCommissionProvider), 0.06);
    expect(find.text('Formules prestataires'), findsOneWidget);

    // 1. Souscription Creator : la feuille de paiement s'ouvre au bon montant.
    final subscribe = find.byKey(const ValueKey('subscribe-creator'));
    await tester.scrollUntilVisible(
      subscribe,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(subscribe);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Abonnement Creator'), findsOneWidget);
    expect(find.textContaining(RegExp(r'5.900')), findsWidgets);

    // 2. Paiement Mobile Money, puis reçu : commission passée à 4 %.
    final pay = find.textContaining('Payer');
    await tester.ensureVisible(pay);
    await tester.pump();
    await tester.tap(pay);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Terminé'), findsOneWidget);
    final sub = c.read(creatorSubProvider);
    expect(sub, isNotNull);
    expect(sub!.plan, ProPlan.creator);
    expect(sub.cancelled, isFalse);
    expect(sub.renewsOn.difference(sub.since).inDays, 30);
    expect(c.read(proCommissionProvider), 0.04);

    // 3. Retour aux formules : l'abonnement apparaît comme actif.
    await tester.tap(find.text('Terminé'));
    await tester.pump(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.text('Formule Creator active'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Formule Creator active'), findsOneWidget);

    // 4. Résiliation confirmée, puis réactivation.
    await tester.ensureVisible(find.text('Résilier').first);
    await tester.pump();
    await tester.tap(find.text('Résilier').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Résilier').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(creatorSubProvider)!.cancelled, isTrue);
    expect(find.text('Formule Creator résiliée'), findsOneWidget);
    await tester.tap(find.text('Réactiver'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.read(creatorSubProvider)!.cancelled, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

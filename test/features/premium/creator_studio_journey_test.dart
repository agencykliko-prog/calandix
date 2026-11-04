import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/premium/presentation/business_screen.dart';
import 'package:eventa/features/pro/presentation/studio_providers.dart';
import 'package:eventa/features/pro/presentation/studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await settle(tester);
  }

  testWidgets('parcours Creator : abonnement 14 900 FCFA puis Studio complet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final router = GoRouter(
      initialLocation: '/pro/studio',
      routes: [
        GoRoute(path: '/pro/studio', builder: (_, _) => const StudioScreen()),
        GoRoute(path: '/business', builder: (_, _) => const BusinessScreen()),
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
    await settle(tester);

    // 1. Sans abonnement, le Studio est verrouillé.
    expect(c.read(studioUnlockedProvider), isFalse);
    expect(
      find.text('Inclus dans les formules Creator et Business.'),
      findsOneWidget,
    );
    expect(find.text('Facturation'), findsNothing);

    // 2. « Débloquer » mène aux formules, paiement Creator de 14 900 FCFA.
    await tapVisible(tester, find.textContaining('Débloquer'));
    expect(find.text('Formules prestataires'), findsOneWidget);
    final subscribe = find.byKey(const ValueKey('subscribe-creator'));
    await tester.scrollUntilVisible(
      subscribe,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, subscribe);
    expect(find.text('Abonnement Creator'), findsOneWidget);
    expect(find.textContaining(RegExp(r'14.900')), findsWidgets);
    final pay = find.textContaining('Payer');
    await tester.ensureVisible(pay);
    await tester.pump();
    await tester.tap(pay);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Terminé'));
    await settle(tester);
    expect(c.read(creatorSubProvider), isNotNull);
    expect(c.read(studioUnlockedProvider), isTrue);
    await tester.scrollUntilVisible(
      find.text('Formule Creator active'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Formule Creator active'), findsOneWidget);

    // 3. Retour au Studio, désormais ouvert.
    await tapVisible(tester, find.text('Ouvrir mon Studio Creator'));
    expect(find.text('Statistiques avancées'), findsOneWidget);
    expect(find.text('CRM clients'), findsOneWidget);

    // 4. CRM : les clients sont consolidés depuis les demandes.
    final clients = c.read(studioClientsProvider);
    expect(clients, isNotEmpty);
    expect(find.text(clients.first.name), findsWidgets);
    await tapVisible(tester, find.text(clients.first.name).first);
    await tester.enterText(find.byType(TextField).last, 'Aime le doré');
    await tapVisible(tester, find.text('Enregistrer la note'));
    expect(c.read(studioProvider).notes[clients.first.name], 'Aime le doré');

    // 5. Facturation : facturer une prestation confirmée, puis l'encaisser.
    final bill = find.byKey(const ValueKey('bill-r4'));
    await tapVisible(tester, bill);
    final invoices = c.read(studioProvider).invoices;
    expect(invoices, hasLength(1));
    expect(invoices.single.amount, 150000);
    expect(invoices.single.paid, isFalse);
    expect(c.read(studioStatsProvider).outstanding, 150000);
    // Une seule facture par prestation.
    expect(bill, findsNothing);
    await tapVisible(
      tester,
      find.byKey(ValueKey('paid-${invoices.single.number}')),
    );
    expect(c.read(studioProvider).invoices.single.paid, isTrue);
    expect(c.read(studioStatsProvider).outstanding, 0);
    expect(c.read(studioStatsProvider).collected, 150000);

    // 6. Équipe : inviter un membre, refuser un doublon, le retirer.
    await tapVisible(tester, find.text('Inviter'));
    await tester.enterText(find.byType(TextField).last, 'Koffi Yao');
    await tapVisible(tester, find.text('Envoyer l’invitation'));
    expect(c.read(studioProvider).team.single.name, 'Koffi Yao');
    expect(
      c.read(studioProvider.notifier).invite('koffi yao', TeamRole.staff),
      isFalse,
    );
    await tester.pump();
    await tapVisible(tester, find.byTooltip('Retirer Koffi Yao'));
    expect(c.read(studioProvider).team, isEmpty);

    // 7. Automatisations : activer la relance d'acompte.
    expect(
      c.read(studioProvider).automations,
      isNot(contains(Automation.depositReminder)),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('auto-depositReminder')),
    );
    expect(
      c.read(studioProvider).automations,
      contains(Automation.depositReminder),
    );

    // 8. Marque blanche : nom affiché sur l'aperçu des documents.
    final brandField = find.widgetWithText(TextField, 'Maison Inès Déco');
    await tester.ensureVisible(find.text('Marque blanche'));
    await tester.pump();
    await tester.enterText(
      brandField.evaluate().isEmpty ? find.byType(TextField).last : brandField,
      'Studio Lumière',
    );
    await settle(tester);
    expect(c.read(studioProvider).brandName, 'Studio Lumière');

    // 9. API : génération d'une clé.
    await tapVisible(tester, find.text('Générer une clé d’API'));
    expect(c.read(studioProvider).apiKey, startsWith('evt_live_'));
    expect(find.text('Copier la clé'), findsOneWidget);

    // 10. Résiliation : l'accès reste ouvert jusqu'à la fin de la période.
    c.read(creatorSubProvider.notifier).cancel();
    await settle(tester);
    expect(c.read(studioUnlockedProvider), isTrue);
    await tester.scrollUntilVisible(
      find.text('Formule Creator résiliée'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Formule Creator résiliée'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });
}

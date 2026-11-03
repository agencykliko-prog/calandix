import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/features/auth/presentation/auth_screen.dart';
import 'package:eventa/core/auth/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final router = GoRouter(
      initialLocation: '/connexion',
      routes: [
        GoRoute(path: '/connexion', builder: (_, _) => const AuthScreen()),
        GoRoute(path: '/accueil', builder: (_, _) => const Text('accueil')),
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
    await tester.pump(const Duration(seconds: 2));
    return c;
  }

  testWidgets('un numéro de téléphone est refusé avant tout envoi', (
    tester,
  ) async {
    final c = await pump(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0707000000');
    await tester.enterText(fields.at(1), 'motdepasse');
    // Case des conditions : à gauche du texte d'acceptation.
    final consent = tester.getTopLeft(find.byType(LegalConsent));
    await tester.tapAt(consent + const Offset(11, 11));
    await tester.pump();
    await tester.tap(find.text('Se connecter'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        'La connexion par téléphone arrive bientôt : utilisez votre adresse e-mail.',
      ),
      findsOneWidget,
    );
    expect(c.read(sessionProvider), isNull);
  });

  testWidgets('la démo reste accessible sans compte', (tester) async {
    final c = await pump(tester);
    final demo = find.byKey(const ValueKey('demo-access'));
    // Le lien est en bas du formulaire, sous le bandeau illustré.
    await tester.scrollUntilVisible(
      demo,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(demo);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(c.read(sessionProvider), isNotNull);
    expect(c.read(liveSessionProvider), isFalse);
    expect(find.text('accueil'), findsOneWidget);
  });
}

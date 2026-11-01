import 'dart:typed_data';

import 'package:eventa/features/pro/presentation/creator_providers.dart';
import 'package:eventa/features/pro/presentation/signature_provider.dart';
import 'package:eventa/features/pro/presentation/studio_providers.dart';
import 'package:eventa/features/pro/presentation/signature_screen.dart';
import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/ui/widgets/forms.dart';
import 'package:eventa/ui/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final sample = Uint8List.fromList([1, 2, 3]);

  test(
    'la signature est posée sur le devis et la facture, puis figée',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(signatureProvider.notifier).save(sample);

      final requests = c.read(requestsProvider.notifier);
      final id = c
          .read(requestsProvider)
          .firstWhere((r) => r.status == RequestStatus.received)
          .id;
      requests.sendDetailedQuote(
        id,
        items: const [QuoteItem('Forfait', 100000)],
        validityDays: 7,
        depositPercent: 30,
      );
      final quoted = c.read(requestsProvider).firstWhere((r) => r.id == id);
      expect(quoted.signature, sample);
      expect(quoted.signedAt, isNotNull);

      final confirmed = c
          .read(requestsProvider)
          .firstWhere((r) => r.status == RequestStatus.confirmed);
      final inv = c.read(studioProvider.notifier).invoice(confirmed)!;
      expect(inv.signature, sample);

      // Une nouvelle signature ne change pas les pièces déjà émises.
      await c.read(signatureProvider.notifier).save(Uint8List.fromList([9]));
      expect(
        c.read(requestsProvider).firstWhere((r) => r.id == id).signature,
        sample,
      );
      c.read(studioProvider.notifier).markPaid(inv.number);
      expect(c.read(studioProvider).invoices.single.signature, sample);
    },
  );

  test(
    'sans signature enregistrée, les pièces restent sans signature',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(signatureProvider.notifier).clear();
      final confirmed = c
          .read(requestsProvider)
          .firstWhere((r) => r.status == RequestStatus.confirmed);
      expect(
        c.read(studioProvider.notifier).invoice(confirmed)!.signature,
        isNull,
      );
    },
  );

  testWidgets('signer au doigt : le bouton attend le tracé et l’accord', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(signatureProvider.notifier).clear();
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const SignatureScreen())],
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
    await tester.pumpAndSettle();
    PillButton save() => tester.widget<PillButton>(
      find.widgetWithText(PillButton, 'Enregistrer ma signature'),
    );
    expect(save().onPressed, isNull);

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
    expect(save().onPressed, isNull, reason: 'accord pas encore donné');

    await tester.tap(find.byType(CheckRow));
    await tester.pump();
    expect(save().onPressed, isNotNull);
  });
}

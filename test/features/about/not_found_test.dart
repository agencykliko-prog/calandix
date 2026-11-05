import 'package:eventa/features/about/presentation/not_found_screen.dart';
import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/ui/widgets/site_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(375, 812), Size(1280, 800)]) {
    testWidgets('la page 404 garde le footer (${size.width.toInt()} px)', (
      tester,
    ) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.current(),
            home: const NotFoundScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SiteFooter), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('TOOTEBO', findRichText: true),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('TOOTEBO', findRichText: true),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
}

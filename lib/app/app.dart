import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/prefs/prefs_provider.dart';
import '../core/sound/sounds.dart';
import 'router/app_router.dart';
import '../ui/theme/app_theme.dart';

class EventaApp extends ConsumerWidget {
  const EventaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final en = prefs.language == AppLanguage.en;
    // Sons préchargés dès l'ouverture : chacun part sans délai.
    if (prefs.sounds) ref.read(soundProvider).warmUp();
    return MaterialApp.router(
      title: 'Calandix',
      debugShowCheckedModeBanner: false,
      // Le thème suit Confetti.dark, mis à jour avec les préférences.
      theme: AppTheme.current(),
      themeAnimationDuration: Duration.zero,
      // Glisser à la souris aussi (aperçu web sur ordinateur).
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      routerConfig: ref.watch(routerProvider),
      locale: en ? const Locale('en', 'US') : const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

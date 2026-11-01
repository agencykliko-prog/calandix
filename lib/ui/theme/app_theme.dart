import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'eventa_colors.dart';

/// Courbes et durées partagées (ease-out franc, jamais ease-in).
abstract final class Motion {
  static const easeOut = Cubic(0.23, 1, 0.32, 1);
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);
  static const drawer = Cubic(0.32, 0.72, 0, 1);
  static const press = Duration(milliseconds: 140);
  static const fast = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 280);
}

abstract final class AppTheme {
  static const font = 'RedHatDisplay';

  /// Thème du mode courant ([Confetti.dark]).
  static ThemeData current() {
    final dark = Confetti.dark;
    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: Confetti.coral,
      onPrimary: Colors.white,
      primaryContainer: Confetti.coralTint,
      onPrimaryContainer: Confetti.coralDeep,
      secondary: Confetti.violet,
      onSecondary: Colors.white,
      secondaryContainer: Confetti.violetTint,
      onSecondaryContainer: Confetti.violetDeep,
      tertiary: Confetti.lagoon,
      onTertiary: Colors.white,
      error: Confetti.danger,
      onError: Colors.white,
      surface: Confetti.cream,
      onSurface: Confetti.ink,
      onSurfaceVariant: Confetti.inkMuted,
      surfaceContainerLowest: Confetti.surface,
      surfaceContainerLow: dark
          ? const Color(0xFF170B2C)
          : const Color(0xFFFBFAF8),
      surfaceContainer: Confetti.surface,
      surfaceContainerHigh: Confetti.lavender,
      outline: Confetti.border,
      outlineVariant: Confetti.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: Confetti.cream,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    final t = base.textTheme.apply(
      fontFamily: font,
      bodyColor: Confetti.ink,
      displayColor: Confetti.ink,
    );

    // Red Hat Display : géométrique et nette, approche resserrée sur les titres.
    return base.copyWith(
      extensions: [EventaColors.current],
      textTheme: t.copyWith(
        displaySmall: t.displaySmall?.copyWith(
          fontSize: 36,
          height: 1.06,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontSize: 27,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontSize: 21,
          height: 1.18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontSize: 17.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        bodyLarge: t.bodyLarge?.copyWith(
          fontSize: 15.5,
          height: 1.48,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        bodyMedium: t.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.44,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        bodySmall: t.bodySmall?.copyWith(
          fontSize: 12.5,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: Confetti.inkMuted,
        ),
        labelLarge: t.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
        ),
        labelMedium: t.labelMedium?.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        labelSmall: t.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Confetti.ink,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: Confetti.ink,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Confetti.cream,
        modalBackgroundColor: Confetti.cream,
      ),
      dialogTheme: DialogThemeData(backgroundColor: Confetti.surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Confetti.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: Confetti.inkFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Confetti.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Confetti.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Confetti.ink, width: 1.4),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Confetti.coral,
        selectionColor: Confetti.coral.withValues(alpha: 0.22),
        selectionHandleColor: Confetti.coral,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Confetti.night,
        elevation: 0,
        contentTextStyle: const TextStyle(
          fontFamily: font,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Confetti.lagoon
              : Confetti.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: Confetti.line, thickness: 1),
      // Changement de page bref : l'écran suivant apparaît presque aussitôt.
      // L'iPhone garde son geste de retour.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _QuickTransition(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _QuickTransition(),
          TargetPlatform.macOS: _QuickTransition(),
          TargetPlatform.linux: _QuickTransition(),
        },
      ),
    );
  }
}

class _QuickTransition extends PageTransitionsBuilder {
  const _QuickTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    ),
    child: child,
  );
}

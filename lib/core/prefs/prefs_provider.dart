import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/tr.dart';
import '../../ui/theme/eventa_colors.dart';
import '../../platform/mobile/prefs_store_mobile.dart'
    if (dart.library.js_interop) '../../platform/web/prefs_store_web.dart';

enum AppLanguage {
  fr('Français', 'fr'),
  en('English', 'en');

  const AppLanguage(this.label, this.code);
  final String label;
  final String code;
}

/// Préférences d'affichage : mode sombre, langue, sons.
@immutable
class AppPrefs {
  const AppPrefs({
    this.dark = false,
    this.language = AppLanguage.fr,
    this.sounds = true,
    this.accent,
    this.backdrop,
  });

  final bool dark;
  final AppLanguage language;
  final bool sounds;

  /// Thème choisi dans Compte (null = couleurs Calandix).
  final int? accent;
  final int? backdrop;

  AppPrefs copyWith({bool? dark, AppLanguage? language, bool? sounds}) =>
      AppPrefs(
        dark: dark ?? this.dark,
        language: language ?? this.language,
        sounds: sounds ?? this.sounds,
        accent: accent,
        backdrop: backdrop,
      );
}

class PrefsNotifier extends Notifier<AppPrefs> {
  @override
  AppPrefs build() {
    final p = AppPrefs(
      dark: readPref('dark') == '1',
      language: readPref('lang') == 'en' ? AppLanguage.en : AppLanguage.fr,
      sounds: readPref('sounds') != '0',
      accent: int.tryParse(readPref('accent') ?? ''),
      backdrop:
          const [
            0xFFFFFFFF,
            0xFFD4FDD1,
            0xFFC8F0FD,
          ].contains(int.tryParse(readPref('backdrop') ?? ''))
          ? int.tryParse(readPref('backdrop')!)
          : null,
    );
    _apply(p);
    return p;
  }

  void setDark(bool v) => _set(state.copyWith(dark: v));
  void setLanguage(AppLanguage v) => _set(state.copyWith(language: v));
  void setSounds(bool v) => _set(state.copyWith(sounds: v));

  void setTheme(int? accent, int? backdrop) {
    writePref('accent', accent?.toString() ?? '');
    writePref('backdrop', backdrop?.toString() ?? '');
    final p = AppPrefs(
      dark: state.dark,
      language: state.language,
      sounds: state.sounds,
      accent: accent,
      backdrop: backdrop,
    );
    _apply(p);
    state = p;
    _rebuildAll();
  }

  void _set(AppPrefs p) {
    writePref('dark', p.dark ? '1' : '0');
    writePref('lang', p.language.code);
    writePref('sounds', p.sounds ? '1' : '0');
    final repaint = p.dark != state.dark || p.language != state.language;
    _apply(p);
    state = p;
    if (repaint) _rebuildAll();
  }

  static void _apply(AppPrefs p) {
    Confetti.dark = p.dark;
    Confetti.accent = p.accent == null ? null : Color(p.accent!);
    Confetti.backdrop = p.backdrop == null ? null : Color(p.backdrop!);
    L10n.lang = p.language.code;
  }

  /// Couleurs et textes sont lus à la construction : on marque tout l'arbre
  /// à reconstruire, sans perdre l'état des écrans (navigation, saisies).
  static void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }
}

final prefsProvider = NotifierProvider<PrefsNotifier, AppPrefs>(
  PrefsNotifier.new,
);

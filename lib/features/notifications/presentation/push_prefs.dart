import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../platform/mobile/prefs_store_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/prefs_store_web.dart';
import '../../../ui/theme/app_icons.dart';

/// Notifications push, par type d'alerte. Chaque type s'active ou se coupe
/// dans Compte › Notifications.
enum PushKind {
  newRequest(
    'Nouvelle demande',
    'Un organisateur vous demande un devis.',
    AppIcons.inbox,
    creator: true,
  ),
  quoteReceived(
    'Devis reçu',
    'Un prestataire a répondu à votre demande.',
    AppIcons.file,
    organizer: true,
  ),
  depositPaid(
    'Acompte payé',
    'Un acompte est réglé et la date est bloquée.',
    AppIcons.coins,
    creator: true,
    organizer: true,
  ),
  dayBefore(
    'Rappel J-1',
    'La veille d’un événement, d’une prestation ou d’une échéance.',
    AppIcons.reminder,
    creator: true,
    organizer: true,
  );

  const PushKind(
    this._label,
    this._caption,
    this.icon, {
    this.creator = false,
    this.organizer = false,
  });

  final String _label;
  final String _caption;
  final IconData icon;

  /// Types proposés à chaque profil.
  final bool creator;
  final bool organizer;

  String get label => _label.tr;
  String get caption => _caption.tr;

  static List<PushKind> forRole({required bool creator}) => [
    for (final k in values)
      if (creator ? k.creator : k.organizer) k,
  ];
}

/// Types de notifications push coupés par l'utilisateur (enregistrés sur
/// l'appareil). Par défaut, tout est activé.
class PushPrefsNotifier extends Notifier<Set<PushKind>> {
  @override
  Set<PushKind> build() {
    final off = (readPref('push_off') ?? '').split(',');
    return {
      for (final k in PushKind.values)
        if (!off.contains(k.name)) k,
    };
  }

  void toggle(PushKind k, bool on) {
    state = on ? {...state, k} : ({...state}..remove(k));
    writePref(
      'push_off',
      [
        for (final k in PushKind.values)
          if (!state.contains(k)) k.name,
      ].join(','),
    );
  }
}

final pushPrefsProvider = NotifierProvider<PushPrefsNotifier, Set<PushKind>>(
  PushPrefsNotifier.new,
);

/// Dernière notification push émise : l'application l'affiche en bandeau
/// (sur mobile, le système la présente aussi hors de l'app).
@immutable
class PushMessage {
  const PushMessage(this.kind, this.title, this.body, this.at, {this.link});
  final PushKind kind;
  final String title;
  final String body;
  final DateTime at;
  final String? link;
}

class PushBannerNotifier extends Notifier<PushMessage?> {
  @override
  PushMessage? build() => null;

  void show(PushMessage m) => state = m;
}

final pushBannerProvider = NotifierProvider<PushBannerNotifier, PushMessage?>(
  PushBannerNotifier.new,
);

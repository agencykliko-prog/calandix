import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/prefs_provider.dart';

/// Effets sonores de Calandix : une seule famille (même timbre de cloche
/// de verre, même tonalité de ré majeur, même réverbération), attaque
/// immédiate pour tomber pile avec l'animation qui les accompagne.
enum Sfx {
  // Moments forts
  booking(0.6),
  payment(0.6),
  premium(0.6),
  success(0.55),
  notification(0.5),
  // Gestes du quotidien, plus courts et plus discrets
  complete(0.5),
  message(0.45),
  toggle(0.4),
  trash(0.45),
  error(0.45);

  const Sfx(this.volume);

  /// Volumes équilibrés : les gestes répétés restent en retrait.
  final double volume;

  String get asset => 'sounds/$name.wav';
}

class SoundPlayer {
  SoundPlayer(this._enabled);

  final bool Function() _enabled;
  final _players = <Sfx, AudioPlayer>{};
  bool _warm = false;

  /// Faux dans les tests (pas de moteur audio) : aucun son n'est joué.
  static bool get _available {
    try {
      final b = WidgetsBinding.instance;
      return !b.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  AudioPlayer _player(Sfx sfx) => _players.putIfAbsent(
    sfx,
    () => AudioPlayer()
      ..setPlayerMode(PlayerMode.lowLatency)
      ..setReleaseMode(ReleaseMode.stop),
  );

  /// Charge tous les sons à l'avance : le premier déclenchement n'attend
  /// pas le téléchargement et reste synchrone avec l'écran.
  void warmUp() {
    if (_warm || !_available) return;
    _warm = true;
    for (final s in Sfx.values) {
      unawaited(
        _player(s).setSource(AssetSource(s.asset)).catchError((Object _) {}),
      );
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!_enabled() || !_available) return;
    warmUp();
    try {
      final p = _player(sfx);
      await p.stop();
      await p.play(AssetSource(sfx.asset), volume: sfx.volume);
    } catch (_) {
      // Son indisponible (navigateur muet, test) : jamais bloquant.
    }
  }
}

final soundProvider = Provider<SoundPlayer>(
  (ref) => SoundPlayer(() => ref.read(prefsProvider).sounds),
);

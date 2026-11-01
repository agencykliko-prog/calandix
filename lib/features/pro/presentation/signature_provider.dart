import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/backend/backend.dart';
import '../../../platform/mobile/prefs_store_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/prefs_store_web.dart';

/// Signature du prestataire (image PNG transparente), posée automatiquement
/// sur ses devis et factures. Compte réel : uniquement dans une table que seul
/// son propriétaire peut lire ; démo : sur l'appareil.
class SignatureNotifier extends Notifier<Uint8List?> {
  static const _key = 'creator.signature';

  @override
  Uint8List? build() {
    // Reconstruit à la connexion et à la déconnexion : jamais la signature
    // d'un autre compte sur un appareil partagé.
    ref.watch(liveSessionProvider);
    if (_live) {
      _load();
      return null;
    }
    final saved = readPref(_key);
    return saved == null || saved.isEmpty ? null : base64Decode(saved);
  }

  String? get _uid => _liveId;

  bool get _live => _liveId != null;

  String? get _liveId {
    if (!ref.read(liveSessionProvider) || !Backend.ready) return null;
    return Backend.client.auth.currentUser?.id;
  }

  Future<void> _load() async {
    try {
      final row = await Backend.client
          .from('creator_signatures')
          .select('image')
          .eq('creator_id', _uid!)
          .maybeSingle();
      final image = row?['image'] as String?;
      if (image != null) state = base64Decode(image);
    } catch (e) {
      debugPrint('Signature non chargée : $e');
    }
  }

  /// Enregistre la signature. Renvoie faux si la base n'a pas pu la garder.
  Future<bool> save(Uint8List png) async {
    final encoded = base64Encode(png);
    if (!_live) {
      writePref(_key, encoded);
      state = png;
      return true;
    }
    try {
      await Backend.client.from('creator_signatures').upsert({
        'creator_id': _uid,
        'image': encoded,
      });
      state = png;
      return true;
    } catch (e) {
      debugPrint('Signature non enregistrée : $e');
      return false;
    }
  }

  Future<void> clear() async {
    state = null;
    if (!_live) {
      writePref(_key, '');
      return;
    }
    try {
      await Backend.client
          .from('creator_signatures')
          .delete()
          .eq('creator_id', _uid!);
    } catch (e) {
      debugPrint('Signature non supprimée : $e');
    }
  }
}

final signatureProvider = NotifierProvider<SignatureNotifier, Uint8List?>(
  SignatureNotifier.new,
);

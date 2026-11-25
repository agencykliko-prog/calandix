import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sound/sounds.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../core/auth/session_provider.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../pro/presentation/creator_providers.dart';
import '../../../core/models/models.dart';

// ─── Messagerie ─────────────────────────────────────────────────────────
// Une conversation par dossier : réservation côté organisateur, demande de
// devis côté Creator. Les messages restent ceux du dossier ; la messagerie
// les rassemble et suit ce qui a été lu. L'organisateur peut aussi écrire à
// un prestataire depuis sa fiche, avant toute demande de devis.

/// Préfixe des conversations ouvertes depuis une fiche prestataire.
const _direct = 'v-';

String directConversationId(Vendor v) => '$_direct${v.id}';

/// Échange ouvert depuis la fiche d'un prestataire, hors réservation.
@immutable
class DirectThread {
  const DirectThread(this.vendor, this.messages, this.since);
  final Vendor vendor;
  final List<ChatMessage> messages;
  final DateTime since;
}

class DirectThreads extends Notifier<Map<String, DirectThread>> {
  @override
  Map<String, DirectThread> build() {
    ref.watch(profileProvider);
    return const {};
  }

  void _append(Vendor v, ChatMessage m) {
    final cur = state[v.id];
    state = {
      ...state,
      v.id: DirectThread(v, [...?cur?.messages, m], cur?.since ?? m.at),
    };
  }

  /// Envoie un message au prestataire ; sa réponse (simulée) suit.
  void send(Vendor v, String text) {
    _append(v, ChatMessage(fromMe: true, text: text, at: DateTime.now()));
    ref.read(audienceProvider.notifier).track(Metric.messageSent);
    Timer(const Duration(milliseconds: 1500), () {
      if (!ref.mounted) return;
      _append(
        v,
        ChatMessage(
          fromMe: false,
          text: 'Bonjour ! Merci pour votre message, je vous réponds au plus vite.'
              .tr,
          at: DateTime.now(),
        ),
      );
    });
  }
}

final directThreadsProvider =
    NotifierProvider<DirectThreads, Map<String, DirectThread>>(
      DirectThreads.new,
    );

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.messages,
    required this.since,
    required this.folder,
    this.avatar,
  });

  final String id;

  /// Prestataire (organisateur) ou client (Creator).
  final String title;

  /// Catégorie du prestataire ou nom de l'événement.
  final String subtitle;
  final String? avatar;
  final List<ChatMessage> messages;

  /// Ouverture du dossier, pour classer une conversation encore vide.
  final DateTime since;

  /// Dossier complet (réservation ou demande).
  final String folder;

  DateTime get lastAt => messages.isEmpty ? since : messages.last.at;
}

final conversationsProvider = Provider<List<Conversation>>((ref) {
  final creator = ref.watch(profileProvider).isCreator;
  final list = creator
      ? [
          for (final r in ref.watch(requestsProvider))
            if (r.status != RequestStatus.declined)
              Conversation(
                id: r.id,
                title: r.client,
                subtitle: r.eventName,
                avatar: r.avatar,
                since: r.receivedAt,
                folder: '/pro/devis/${r.id}',
                messages: [
                  for (final l in r.thread)
                    ChatMessage(fromMe: l.fromMe, text: l.text, at: l.at),
                ],
              ),
        ]
      : [
          for (final b in ref.watch(bookingsProvider))
            if (!b.archived)
              Conversation(
                id: b.id,
                title: b.vendor.name,
                subtitle: b.vendor.category.label,
                avatar: b.vendor.image,
                since: b.createdAt,
                folder: Routes.booking(b.id),
                messages: b.messages,
              ),
          for (final t in ref.watch(directThreadsProvider).values)
            Conversation(
              id: directConversationId(t.vendor),
              title: t.vendor.name,
              subtitle: t.vendor.category.label,
              avatar: t.vendor.image,
              since: t.since,
              folder: Routes.vendor(t.vendor.id),
              messages: t.messages,
            ),
        ];
  return list..sort((a, b) => b.lastAt.compareTo(a.lastAt));
});

final conversationProvider = Provider.family<Conversation?, String>(
  (ref, id) =>
      ref.watch(conversationsProvider).where((c) => c.id == id).firstOrNull,
);

/// Nombre de messages déjà vus, par conversation.
class ReadMarks extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    ref.watch(profileProvider);
    return const {};
  }

  void seen(Conversation c) {
    if (state[c.id] == c.messages.length) return;
    state = {...state, c.id: c.messages.length};
  }
}

final readMarksProvider = NotifierProvider<ReadMarks, Map<String, int>>(
  ReadMarks.new,
);

/// Messages reçus non lus d'une conversation.
final unreadInProvider = Provider.family<int, String>((ref, id) {
  final c = ref.watch(conversationProvider(id));
  if (c == null) return 0;
  final seen = ref.watch(readMarksProvider)[c.id] ?? 0;
  return c.messages.skip(seen).where((m) => !m.fromMe).length;
});

final unreadMessagesProvider = Provider<int>(
  (ref) => ref
      .watch(conversationsProvider)
      .fold(0, (s, c) => s + ref.watch(unreadInProvider(c.id))),
);

class Messenger {
  const Messenger(this._ref);
  final Ref _ref;

  /// Envoie un message dans la conversation ; l'interlocuteur (simulé)
  /// répond peu après.
  void send(String id, String text) {
    _ref.read(soundProvider).play(Sfx.message);
    if (_ref.read(profileProvider).isCreator) {
      _ref
          .read(requestsProvider.notifier)
          .ask(
            id,
            text,
            simulatedReply:
                'Merci pour votre message, je regarde et je reviens vers vous.'
                    .tr,
          );
    } else if (id.startsWith(_direct)) {
      final t = _ref.read(directThreadsProvider)[id.substring(_direct.length)];
      if (t != null) {
        _ref.read(directThreadsProvider.notifier).send(t.vendor, text);
      }
    } else {
      _ref.read(bookingsProvider.notifier).message(id, text);
    }
  }
}

final messengerProvider = Provider<Messenger>(Messenger.new);

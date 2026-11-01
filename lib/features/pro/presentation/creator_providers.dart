import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/models/models.dart';
import 'signature_provider.dart';

enum RequestStatus {
  received('Nouvelle'),
  quoted('Devis envoyé'),
  confirmed('Confirmée'),
  declined('Déclinée');

  const RequestStatus(this._label);
  final String _label;
  String get label => _label.tr;
}

/// Message d'un échange sur une demande (question, réponse).
@immutable
class ChatLine {
  const ChatLine(this.fromMe, this.text, this.at);
  final bool fromMe;
  final String text;
  final DateTime at;
}

/// Ligne d'un devis détaillé.
@immutable
class QuoteItem {
  const QuoteItem(this.label, this.amount, {this.option = false});
  final String label;
  final int amount;

  /// Option facultative que le client peut retirer.
  final bool option;
}

/// Demande de devis reçue par un Creator.
@immutable
class ClientRequest {
  const ClientRequest({
    required this.id,
    required this.client,
    required this.eventName,
    required this.category,
    required this.date,
    required this.guests,
    required this.message,
    required this.receivedAt,
    this.avatar,
    this.options = const [],
    this.budget,
    this.status = RequestStatus.received,
    this.quote,
    this.durationMin = 240,
    this.thread = const [],
    this.items = const [],
    this.validUntil,
    this.declineReason,
    this.depositPercent = 30,
    this.place,
    this.signature,
    this.signedAt,
  });

  final String id;
  final String client;
  final String? avatar;
  final String eventName;
  final EventCategory category;

  /// Début de la prestation (date et heure).
  final DateTime date;
  final int durationMin;
  final int guests;
  final String message;
  final List<String> options;
  final int? budget;
  final DateTime receivedAt;
  final RequestStatus status;
  final int? quote;

  /// Questions et réponses échangées avant le devis.
  final List<ChatLine> thread;

  /// Lignes du devis détaillé (vide si devis au montant global).
  final List<QuoteItem> items;
  final DateTime? validUntil;
  final String? declineReason;
  final int depositPercent;
  final String? place;

  /// Signature posée à l'envoi du devis : la pièce garde celle du moment.
  final Uint8List? signature;
  final DateTime? signedAt;

  bool get expired =>
      status == RequestStatus.quoted &&
      validUntil != null &&
      validUntil!.isBefore(DateTime.now());

  ClientRequest copyWith({
    RequestStatus? status,
    int? quote,
    List<ChatLine>? thread,
    List<QuoteItem>? items,
    DateTime? validUntil,
    String? declineReason,
    int? depositPercent,
    Uint8List? signature,
    DateTime? signedAt,
  }) => ClientRequest(
    id: id,
    client: client,
    avatar: avatar,
    eventName: eventName,
    category: category,
    date: date,
    durationMin: durationMin,
    guests: guests,
    message: message,
    options: options,
    budget: budget,
    receivedAt: receivedAt,
    status: status ?? this.status,
    quote: quote ?? this.quote,
    thread: thread ?? this.thread,
    items: items ?? this.items,
    validUntil: validUntil ?? this.validUntil,
    declineReason: declineReason ?? this.declineReason,
    depositPercent: depositPercent ?? this.depositPercent,
    place: place,
    signature: signature ?? this.signature,
    signedAt: signedAt ?? this.signedAt,
  );
}

class RequestsNotifier extends Notifier<List<ClientRequest>> {
  @override
  List<ClientRequest> build() {
    // Demandes fictives réservées à la démo.
    if (ref.watch(liveSessionProvider)) return const [];
    final n = DateTime.now();
    DateTime d(int days, int h, [int m = 0]) =>
        DateTime(n.year, n.month, n.day + days, h, m);
    return [
      ClientRequest(
        id: 'r1',
        client: 'Awa Traoré'.tr,
        avatar: 'assets/images/avatar_1.jpg',
        eventName: 'Mariage Awa & Kouassi'.tr,
        category: EventCategory.wedding,
        date: d(42, 14),
        durationMin: 360,
        guests: 250,
        budget: 1300000,
        options: ['Livraison & installation'.tr, 'Arche florale'.tr],
        message: 'Bonjour, nous cherchons une scénographie complète blanc et or pour la réception.'
            .tr,
        receivedAt: n.subtract(const Duration(minutes: 35)),
        place: 'Espace Latrille Events, Cocody',
      ),
      ClientRequest(
        id: 'r2',
        client: 'Yasmine Ouattara'.tr,
        avatar: 'assets/images/avatar_5.jpg',
        eventName: 'Les 30 ans de Yasmine'.tr,
        category: EventCategory.birthday,
        date: d(27, 18),
        durationMin: 180,
        guests: 60,
        budget: 250000,
        message: 'Déco rooftop thème Gold & Rose, c’est une surprise !'.tr,
        receivedAt: n.subtract(const Duration(hours: 5)),
        place: 'Rooftop Le Plateau',
        thread: [
          ChatLine(
            true,
            'Bonjour Yasmine ! Le rooftop est-il couvert en cas de pluie ?'.tr,
            n.subtract(const Duration(hours: 4)),
          ),
          ChatLine(
            false,
            'Oui, une partie est couverte. Accès possible dès 14 h.'.tr,
            n.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      ClientRequest(
        id: 'r3',
        client: 'Société Ivoire Digital'.tr,
        avatar: 'assets/images/avatar_4.jpg',
        eventName: 'Lancement produit'.tr,
        category: EventCategory.pro,
        date: d(9, 9, 30),
        durationMin: 300,
        guests: 120,
        message:
            'Habillage de salle et photocall aux couleurs de la marque.'.tr,
        receivedAt: n.subtract(const Duration(days: 2)),
        status: RequestStatus.quoted,
        quote: 780000,
        place: 'Pullman Abidjan, Plateau',
        validUntil: n.add(const Duration(days: 5)),
        items: [
          QuoteItem('Habillage de salle aux couleurs de la marque'.tr, 520000),
          QuoteItem('Photocall 3 × 2 m'.tr, 180000),
          QuoteItem('Livraison & installation'.tr, 80000, option: true),
        ],
      ),
      ClientRequest(
        id: 'r4',
        client: 'Mariam Traoré'.tr,
        avatar: 'assets/images/avatar_3.jpg',
        eventName: 'Baby shower de Mariam'.tr,
        category: EventCategory.baby,
        date: d(14, 13),
        durationMin: 150,
        guests: 35,
        message: 'Arche de ballons pastel et table sucrée.'.tr,
        receivedAt: n.subtract(const Duration(days: 6)),
        status: RequestStatus.confirmed,
        quote: 150000,
        place: 'Villa Les Palmiers, Riviera 3',
        options: [
          'Arche de ballons pastel'.tr,
          'Table sucrée'.tr,
          'Prénom en lettres géantes'.tr,
        ],
      ),
      ClientRequest(
        id: 'r5',
        client: 'Fondation Lumière'.tr,
        eventName: 'Gala de charité'.tr,
        category: EventCategory.charity,
        date: d(3, 17),
        durationMin: 240,
        guests: 300,
        message: 'Centres de table pour 30 tables rondes.'.tr,
        receivedAt: n.subtract(const Duration(days: 12)),
        status: RequestStatus.confirmed,
        quote: 1100000,
        place: 'Sofitel Hôtel Ivoire',
        options: [
          '30 centres de table'.tr,
          'Nappage blanc'.tr,
          'Montage la veille'.tr,
        ],
      ),
    ];
  }

  void _set(ClientRequest r) =>
      state = [for (final x in state) x.id == r.id ? r : x];

  void sendQuote(String id, int amount) {
    _set(
      state
          .firstWhere((r) => r.id == id)
          .copyWith(
            status: RequestStatus.quoted,
            quote: amount,
            signature: ref.read(signatureProvider),
            signedAt: ref.read(signatureProvider) == null
                ? null
                : DateTime.now(),
          ),
    );
    ref.read(audienceProvider.notifier).track(Metric.quoteSent);
  }

  void confirm(String id) => _set(
    state
        .firstWhere((r) => r.id == id)
        .copyWith(status: RequestStatus.confirmed),
  );

  void decline(String id, {String? reason}) => _set(
    state
        .firstWhere((r) => r.id == id)
        .copyWith(status: RequestStatus.declined, declineReason: reason),
  );

  /// Pose une question au client ; la réponse simulée arrive peu après.
  void ask(String id, String question, {String? simulatedReply}) {
    final r = state.firstWhere((x) => x.id == id);
    _set(
      r.copyWith(
        thread: [...r.thread, ChatLine(true, question, DateTime.now())],
      ),
    );
    ref.read(audienceProvider.notifier).track(Metric.messageSent);
    if (simulatedReply == null) return;
    Future<void>.delayed(const Duration(seconds: 2), () {
      final cur = state.where((x) => x.id == id).firstOrNull;
      if (cur == null) return;
      _set(
        cur.copyWith(
          thread: [
            ...cur.thread,
            ChatLine(false, simulatedReply, DateTime.now()),
          ],
        ),
      );
    });
  }

  /// Envoie un devis détaillé : lignes, options, validité et acompte.
  void sendDetailedQuote(
    String id, {
    required List<QuoteItem> items,
    required int validityDays,
    required int depositPercent,
  }) {
    _set(
      state
          .firstWhere((r) => r.id == id)
          .copyWith(
            status: RequestStatus.quoted,
            items: items,
            quote: items.fold<int>(0, (s, i) => s + i.amount),
            validUntil: DateTime.now().add(Duration(days: validityDays)),
            depositPercent: depositPercent,
            signature: ref.read(signatureProvider),
            signedAt: ref.read(signatureProvider) == null
                ? null
                : DateTime.now(),
          ),
    );
    ref.read(audienceProvider.notifier).track(Metric.quoteSent);
  }
}

final requestsProvider =
    NotifierProvider<RequestsNotifier, List<ClientRequest>>(
      RequestsNotifier.new,
    );

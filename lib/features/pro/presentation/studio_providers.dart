import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'creator_providers.dart';
import 'signature_provider.dart';

// ─── Studio Creator : outils des formules Creator et Business ────────────

/// Le Studio est ouvert tant qu'une formule Creator ou Business court, même
/// résiliée (jusqu'à la fin de la période payée).
final studioUnlockedProvider = Provider<bool>(
  (ref) => ref.watch(proPlanProvider).studio,
);

/// Facture émise à partir d'une prestation confirmée.
@immutable
class StudioInvoice {
  const StudioInvoice({
    required this.number,
    required this.requestId,
    required this.client,
    required this.label,
    required this.amount,
    required this.issued,
    this.paid = false,
    this.signature,
  });

  final String number;
  final String requestId;
  final String client;
  final String label;
  final int amount;
  final DateTime issued;
  final bool paid;

  /// Signature posée à l'émission.
  final Uint8List? signature;

  /// Échéance : 15 jours après l'émission.
  DateTime get due => issued.add(const Duration(days: 15));

  StudioInvoice markPaid() => StudioInvoice(
    number: number,
    requestId: requestId,
    client: client,
    label: label,
    amount: amount,
    issued: issued,
    paid: true,
    signature: signature,
  );
}

enum TeamRole {
  admin('Administrateur'),
  planner('Chef de projet'),
  staff('Équipe terrain');

  const TeamRole(this._label);
  final String _label;
  String get label => _label.tr;
}

@immutable
class TeamMember {
  const TeamMember(this.name, this.role, {this.pending = true});
  final String name;
  final TeamRole role;

  /// Invitation envoyée, pas encore acceptée.
  final bool pending;
}

enum Automation {
  autoReply(
    'Réponse automatique',
    'Accusé de réception envoyé à chaque nouvelle demande.',
  ),
  depositReminder(
    'Relance d’acompte',
    'Rappel au client 3 jours avant l’échéance d’une facture.',
  ),
  reviewRequest(
    'Demande d’avis',
    'Message de remerciement et lien d’avis le lendemain de la prestation.',
  ),
  weeklyReport(
    'Rapport hebdomadaire',
    'Synthèse du chiffre et des demandes chaque lundi.',
  );

  const Automation(this._title, this._caption);
  final String _title;
  final String _caption;
  String get title => _title.tr;
  String get caption => _caption.tr;
}

/// Couleurs proposées pour la marque blanche des devis et factures.
const studioBrandColors = <int>[
  0xFF6246EA,
  0xFF1A0637,
  0xFF0E9F8E,
  0xFFE5484D,
  0xFFE5A21A,
];

@immutable
class StudioState {
  const StudioState({
    this.invoices = const [],
    this.team = const [],
    this.automations = const {Automation.autoReply},
    this.brandName = '',
    this.brandColor = 0xFF6246EA,
    this.notes = const {},
    this.apiKey,
  });

  final List<StudioInvoice> invoices;
  final List<TeamMember> team;
  final Set<Automation> automations;
  final String brandName;
  final int brandColor;

  /// Notes privées par client (CRM).
  final Map<String, String> notes;
  final String? apiKey;

  StudioState copyWith({
    List<StudioInvoice>? invoices,
    List<TeamMember>? team,
    Set<Automation>? automations,
    String? brandName,
    int? brandColor,
    Map<String, String>? notes,
    String? apiKey,
  }) => StudioState(
    invoices: invoices ?? this.invoices,
    team: team ?? this.team,
    automations: automations ?? this.automations,
    brandName: brandName ?? this.brandName,
    brandColor: brandColor ?? this.brandColor,
    notes: notes ?? this.notes,
    apiKey: apiKey ?? this.apiKey,
  );
}

class StudioNotifier extends Notifier<StudioState> {
  @override
  StudioState build() => const StudioState();

  /// Facture une prestation confirmée (une seule facture par prestation).
  StudioInvoice? invoice(ClientRequest r) {
    if (r.status != RequestStatus.confirmed || r.quote == null) return null;
    final existing = state.invoices.where((i) => i.requestId == r.id);
    if (existing.isNotEmpty) return existing.first;
    final now = DateTime.now();
    final inv = StudioInvoice(
      number:
          'F-${now.year}-${(state.invoices.length + 1).toString().padLeft(3, '0')}',
      requestId: r.id,
      client: r.client,
      label: r.eventName,
      amount: r.quote!,
      issued: now,
      signature: ref.read(signatureProvider),
    );
    state = state.copyWith(invoices: [...state.invoices, inv]);
    return inv;
  }

  void markPaid(String number) => state = state.copyWith(
    invoices: [
      for (final i in state.invoices) i.number == number ? i.markPaid() : i,
    ],
  );

  /// Invite un membre ; refuse un nom vide ou déjà présent.
  bool invite(String name, TeamRole role) {
    final n = name.trim();
    if (n.isEmpty ||
        state.team.any((m) => m.name.toLowerCase() == n.toLowerCase())) {
      return false;
    }
    state = state.copyWith(team: [...state.team, TeamMember(n, role)]);
    return true;
  }

  void remove(String name) => state = state.copyWith(
    team: state.team.where((m) => m.name != name).toList(),
  );

  void toggle(Automation a) {
    final s = {...state.automations};
    s.contains(a) ? s.remove(a) : s.add(a);
    state = state.copyWith(automations: s);
  }

  void setBrand({String? name, int? color}) =>
      state = state.copyWith(brandName: name?.trim(), brandColor: color);

  void note(String client, String text) =>
      state = state.copyWith(notes: {...state.notes, client: text.trim()});

  /// Clé d'API de démonstration (régénérable).
  String generateApiKey() {
    final r = math.Random();
    const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
    final key =
        'evt_live_${List.generate(24, (_) => chars[r.nextInt(chars.length)]).join()}';
    state = state.copyWith(apiKey: key);
    return key;
  }
}

final studioProvider = NotifierProvider<StudioNotifier, StudioState>(
  StudioNotifier.new,
);

/// Fiche client du CRM, consolidée à partir des demandes reçues.
@immutable
class StudioClient {
  const StudioClient({
    required this.name,
    required this.requests,
    required this.confirmed,
    required this.revenue,
    required this.last,
  });

  final String name;
  final int requests;
  final int confirmed;
  final int revenue;
  final DateTime last;
}

final studioClientsProvider = Provider<List<StudioClient>>((ref) {
  final byClient = <String, List<ClientRequest>>{};
  for (final r in ref.watch(requestsProvider)) {
    byClient.putIfAbsent(r.client, () => []).add(r);
  }
  final list = [
    for (final e in byClient.entries)
      StudioClient(
        name: e.key,
        requests: e.value.length,
        confirmed: e.value
            .where((r) => r.status == RequestStatus.confirmed)
            .length,
        revenue: e.value
            .where((r) => r.status == RequestStatus.confirmed)
            .fold(0, (s, r) => s + (r.quote ?? 0)),
        last: e.value
            .map((r) => r.receivedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      ),
  ]..sort((a, b) => b.revenue.compareTo(a.revenue));
  return list;
});

/// Indicateurs avancés du tableau de bord financier.
@immutable
class StudioStats {
  const StudioStats({
    required this.conversion,
    required this.averageBasket,
    required this.invoiced,
    required this.collected,
  });

  /// Part des demandes traitées qui deviennent des prestations (0 à 1).
  final double conversion;
  final int averageBasket;
  final int invoiced;
  final int collected;
  int get outstanding => invoiced - collected;
}

final studioStatsProvider = Provider<StudioStats>((ref) {
  final requests = ref.watch(requestsProvider);
  final handled = requests.where((r) => r.status != RequestStatus.received);
  final won = requests
      .where((r) => r.status == RequestStatus.confirmed && r.quote != null)
      .toList();
  final invoices = ref.watch(studioProvider.select((s) => s.invoices));
  return StudioStats(
    conversion: handled.isEmpty ? 0 : won.length / handled.length,
    averageBasket: won.isEmpty
        ? 0
        : won.fold(0, (s, r) => s + r.quote!) ~/ won.length,
    invoiced: invoices.fold(0, (s, i) => s + i.amount),
    collected: invoices.where((i) => i.paid).fold(0, (s, i) => s + i.amount),
  );
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../commerce/presentation/commerce_providers.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/auth/session_provider.dart';
import 'creator_providers.dart';
import '../domain/pro_models.dart';

/// Commission de la formule Découverte, appliquée à l'historique de démo.
/// Les nouveaux encaissements suivent la formule (`proCommissionProvider`).
const proCommissionRate = 0.08;

@immutable
class ProState {
  const ProState({
    required this.catalog,
    required this.availability,
    required this.progress,
    required this.payouts,
    required this.reviews,
  });

  final ProCatalog catalog;
  final Availability availability;

  /// Suivi des commandes confirmées, par identifiant de demande.
  final Map<String, OrderProgress> progress;
  final List<Payout> payouts;
  final List<ProReview> reviews;

  ProState copyWith({
    ProCatalog? catalog,
    Availability? availability,
    Map<String, OrderProgress>? progress,
    List<Payout>? payouts,
    List<ProReview>? reviews,
  }) => ProState(
    catalog: catalog ?? this.catalog,
    availability: availability ?? this.availability,
    progress: progress ?? this.progress,
    payouts: payouts ?? this.payouts,
    reviews: reviews ?? this.reviews,
  );

  OrderProgress progressOf(String id) => progress[id] ?? const OrderProgress();

  double get rating => reviews.isEmpty
      ? 0
      : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
}

class ProController extends Notifier<ProState> {
  @override
  ProState build() {
    // Compte réel : catalogue vierge, sans avis ni reversements fictifs.
    if (ref.watch(liveSessionProvider)) {
      return ProState(
        catalog: ProCatalog(
          portfolio: const [],
          zones: [?ref.watch(profileProvider).creator?.zone],
          categories: const [],
          packages: const [],
          options: const [],
        ),
        availability: const Availability(),
        progress: const {},
        payouts: const [],
        reviews: const [],
      );
    }
    final n = DateTime.now();
    DateTime ago(int d) => n.subtract(Duration(days: d));
    return ProState(
      catalog: ProCatalog(
        portfolio: const [
          'assets/images/v/decor_1.jpg',
          'assets/images/v/decor_2.jpg',
          'assets/images/v/decor_3.jpg',
          'assets/images/vendor_deco.jpg',
          'assets/images/cover_wedding.jpg',
          'assets/images/cover_babyshower.jpg',
        ],
        zones: ['Abidjan'.tr, 'Grand-Bassam', 'Assinie', 'Bingerville'],
        categories: ['Fleurs'.tr, 'Ballons'.tr, 'Scénographie'.tr],
        packages: [
          ProPackage(
            id: 'p1',
            name: 'Essentiel'.tr,
            price: 450000,
            includes: [
              'Centres de table (10 tables)'.tr,
              'Arche fleurie standard'.tr,
              'Installation et démontage'.tr,
            ],
          ),
          ProPackage(
            id: 'p2',
            name: 'Signature'.tr,
            price: 1200000,
            includes: [
              'Scénographie complète'.tr,
              'Moodboard et visite technique'.tr,
              'Fleurs fraîches de saison'.tr,
              'Équipe de 4 décorateurs'.tr,
            ],
          ),
          ProPackage(
            id: 'p3',
            name: 'Table sucrée'.tr,
            price: 150000,
            unit: 'forfait',
            includes: ['Mobilier et nappage'.tr, 'Présentoirs dorés'.tr],
          ),
        ],
        options: [
          ProOption(id: 'o1', name: 'Arche de ballons'.tr, price: 85000),
          ProOption(
            id: 'o2',
            name: 'Prénom en lettres géantes'.tr,
            price: 60000,
          ),
          ProOption(id: 'o3', name: 'Photocall 3 × 2 m'.tr, price: 180000),
          ProOption(id: 'o4', name: 'Montage la veille'.tr, price: 50000),
          ProOption(
            id: 'o5',
            name: 'Bougies et photophores'.tr,
            price: 40000,
            active: false,
          ),
        ],
      ),
      availability: Availability(
        blocked: {
          dateOnly(n.add(const Duration(days: 10))),
          dateOnly(n.add(const Duration(days: 11))),
          dateOnly(n.add(const Duration(days: 20))),
        },
      ),
      progress: const {
        'r4': OrderProgress(stage: OrderStage.preparing, checked: {0}),
      },
      payouts: [
        Payout(
          ref: 'RV-2291',
          label: 'Mariage Bamba · Cocody'.tr,
          gross: 1450000,
          commission: (1450000 * proCommissionRate).round(),
          date: ago(18),
          status: PayoutStatus.sent,
        ),
        Payout(
          ref: 'RV-2264',
          label: 'Séminaire Orange CI'.tr,
          gross: 820000,
          commission: (820000 * proCommissionRate).round(),
          date: ago(33),
          status: PayoutStatus.sent,
        ),
        Payout(
          ref: 'RV-2231',
          label: 'Anniversaire 40 ans Kouamé'.tr,
          gross: 380000,
          commission: (380000 * proCommissionRate).round(),
          date: ago(47),
          status: PayoutStatus.sent,
          method: 'Orange Money',
        ),
      ],
      reviews: [
        ProReview(
          id: 'v1',
          author: 'Aminata K.',
          event: 'Mariage · Cocody'.tr,
          rating: 5,
          text: 'Une décoration à couper le souffle, tout était prêt une heure avant. Merci !'
              .tr,
          date: ago(12),
          avatar: 'assets/images/avatar_2.jpg',
          reply:
              'Merci Aminata, ce fut un bonheur de travailler avec vous !'.tr,
        ),
        ProReview(
          id: 'v2',
          author: 'Orange CI',
          event: 'Séminaire · Plateau'.tr,
          rating: 5,
          text: 'Équipe très professionnelle, respect total de la charte graphique.'
              .tr,
          date: ago(30),
        ),
        ProReview(
          id: 'v3',
          author: 'Serge K.',
          event: 'Anniversaire · Riviera'.tr,
          rating: 4,
          text: 'Très beau rendu. Petit retard à l’installation, mais rattrapé.'
              .tr,
          date: ago(45),
          avatar: 'assets/images/avatar_4.jpg',
        ),
        ProReview(
          id: 'v4',
          author: 'Nadège A.',
          event: 'Baby shower · Bingerville'.tr,
          rating: 5,
          text:
              'Les ballons pastel étaient parfaits, nos invités ont adoré.'.tr,
          date: ago(60),
        ),
      ],
    );
  }

  // ─── Catalogue ──────────────────────────────────────────────────────

  void setCatalog(ProCatalog c) => state = state.copyWith(catalog: c);

  void savePackage(ProPackage p) {
    final list = state.catalog.packages;
    final exists = list.any((x) => x.id == p.id);
    setCatalog(
      state.catalog.copyWith(
        packages: exists
            ? [for (final x in list) x.id == p.id ? p : x]
            : [...list, p],
      ),
    );
  }

  void saveOption(ProOption o) {
    final list = state.catalog.options;
    final exists = list.any((x) => x.id == o.id);
    setCatalog(
      state.catalog.copyWith(
        options: exists
            ? [for (final x in list) x.id == o.id ? o : x]
            : [...list, o],
      ),
    );
  }

  // ─── Disponibilités ─────────────────────────────────────────────────

  void toggleBlocked(DateTime day) {
    final d = dateOnly(day);
    final set = {...state.availability.blocked};
    set.contains(d) ? set.remove(d) : set.add(d);
    state = state.copyWith(
      availability: state.availability.copyWith(blocked: set),
    );
  }

  void setCapacity(int n) => state = state.copyWith(
    availability: state.availability.copyWith(capacityPerDay: n.clamp(1, 6)),
  );

  void setPreventDouble(bool v) => state = state.copyWith(
    availability: state.availability.copyWith(preventDouble: v),
  );

  // ─── Commandes ──────────────────────────────────────────────────────

  void toggleRequirement(String id, int index) {
    final p = state.progressOf(id);
    final set = {...p.checked};
    set.contains(index) ? set.remove(index) : set.add(index);
    state = state.copyWith(
      progress: {
        ...state.progress,
        id: p.copyWith(checked: set),
      },
    );
  }

  void setNote(String id, String note) {
    final p = state.progressOf(id);
    state = state.copyWith(
      progress: {
        ...state.progress,
        id: p.copyWith(note: note),
      },
    );
  }

  /// Passe la commande à l'étape suivante. À la clôture, le reversement
  /// (montant net de commission) est programmé.
  void advance(ClientRequest r) {
    final p = state.progressOf(r.id);
    if (p.stage == OrderStage.closed) return;
    final next = OrderStage.values[p.stage.index + 1];
    var s = state.copyWith(
      progress: {
        ...state.progress,
        r.id: p.copyWith(stage: next),
      },
    );
    if (next == OrderStage.closed) {
      final gross = r.quote ?? 0;
      s = s.copyWith(
        payouts: [
          Payout(
            ref: 'RV-${2300 + s.payouts.length}',
            label: r.eventName,
            gross: gross,
            commission: (gross * ref.read(proCommissionProvider)).round(),
            date: DateTime.now().add(const Duration(days: 2)),
            status: PayoutStatus.scheduled,
          ),
          ...s.payouts,
        ],
      );
    }
    state = s;
  }

  // ─── Avis ───────────────────────────────────────────────────────────

  void reply(String reviewId, String text) => state = state.copyWith(
    reviews: [
      for (final r in state.reviews) r.id == reviewId ? r.withReply(text) : r,
    ],
  );
}

final proProvider = NotifierProvider<ProController, ProState>(
  ProController.new,
);

/// Nombre de prestations confirmées un jour donné.
final dayLoadProvider = Provider.family<int, DateTime>((ref, day) {
  final d = dateOnly(day);
  return ref
      .watch(requestsProvider)
      .where(
        (r) => r.status == RequestStatus.confirmed && dateOnly(r.date) == d,
      )
      .length;
});

/// Le jour est-il fermé (bloqué ou capacité atteinte) ?
final dayFullProvider = Provider.family<bool, DateTime>((ref, day) {
  final a = ref.watch(proProvider.select((s) => s.availability));
  if (a.blocked.contains(dateOnly(day))) return true;
  return ref.watch(dayLoadProvider(day)) >= a.capacityPerDay;
});

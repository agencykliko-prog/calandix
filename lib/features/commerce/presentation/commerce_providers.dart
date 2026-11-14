import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../events/presentation/events_providers.dart';
import '../domain/commerce_models.dart';

// ─── Abonnement ─────────────────────────────────────────────────────────

/// Durée de l'essai gratuit : Privilège côté organisateur, Creator et
/// Business côté prestataire.
const trialDays = 7;

class PlanNotifier extends Notifier<Plan> {
  @override
  Plan build() => Plan.free;

  void subscribe(Plan p) {
    ref.read(trialEndsProvider.notifier).set(null);
    _activate(p);
  }

  /// Essai gratuit de [trialDays] jours : l'offre devient payante ensuite.
  /// Seul Privilège en propose un.
  void startTrial([Plan p = Plan.privilege]) {
    assert(p.hasTrial, 'Essai réservé à Privilège');
    if (!p.hasTrial) return;
    ref
        .read(trialEndsProvider.notifier)
        .set(DateTime.now().add(const Duration(days: trialDays)));
    _activate(p);
  }

  void _activate(Plan p) {
    state = p;
    Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => ref.read(soundProvider).play(Sfx.premium),
    );
  }
}

final planProvider = NotifierProvider<PlanNotifier, Plan>(PlanNotifier.new);

/// Fin de l'essai gratuit en cours (null : pas d'essai, ou offre payée).
class TrialEndsNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? d) => state = d;
}

final trialEndsProvider = NotifierProvider<TrialEndsNotifier, DateTime?>(
  TrialEndsNotifier.new,
);

/// Un essai a déjà été utilisé : il n'est proposé qu'une fois.
final trialUsedProvider = Provider<bool>(
  (ref) => ref.watch(trialEndsProvider) != null,
);

/// Dernière offre consentie par défaut selon le métier du prestataire, en
/// pourcentage du devis (le prestataire l'ajuste dans ses conditions).
int lastOfferPercent(VendorCategory c) => switch (c) {
  VendorCategory.venue || VendorCategory.catering || VendorCategory.staff => 5,
  VendorCategory.rental ||
  VendorCategory.paper ||
  VendorCategory.transport => 6,
  VendorCategory.beauty ||
  VendorCategory.planner ||
  VendorCategory.activity => 7,
  VendorCategory.decor || VendorCategory.photo => 8,
  VendorCategory.music => 10,
};

// ─── Pass Événement ─────────────────────────────────────────────────────

/// Pass Événement : toutes les fonctions Signature pendant 90 jours, pour un
/// seul événement, sans abonnement (paiement unique).
const eventPassPrice = 5000;
const eventPassDays = 90;

/// Formule dont le Pass ouvre les fonctions, et ses plafonds.
const eventPassPlan = Plan.signature;
final eventPassGuests = eventPassPlan.guests!;
final eventPassCollaborators = eventPassPlan.collaborators;

/// Fin du pass de chaque événement, par identifiant d'événement.
class EventPassNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => const {};

  void activate(String eventId) => state = {
    ...state,
    eventId: DateTime.now().add(const Duration(days: eventPassDays)),
  };

  bool active(String eventId) =>
      state[eventId]?.isAfter(DateTime.now()) ?? false;
}

final eventPassProvider =
    NotifierProvider<EventPassNotifier, Map<String, DateTime>>(
      EventPassNotifier.new,
    );

/// Plafonds d'un événement : invités (accompagnants compris, null : sans
/// plafond) et collaborateurs, selon la formule ou le Pass s'il fait mieux.
/// [plan] : formule qui fixe ces plafonds ; [pass] : ils viennent du Pass.
typedef EventCaps = ({int? guests, int collaborators, Plan plan, bool pass});

final eventCapsProvider = Provider.family<EventCaps, String>((ref, eventId) {
  final plan = ref.watch(planProvider);
  ref.watch(eventPassProvider);
  final pass =
      !plan.includes(eventPassPlan) &&
      ref.read(eventPassProvider.notifier).active(eventId);
  final p = pass ? eventPassPlan : plan;
  return (
    guests: p.guests,
    collaborators: p.collaborators,
    plan: p,
    pass: pass,
  );
});

/// Assistance prioritaire : Privilège ou, côté prestataire, Business.
final prioritySupportProvider = Provider<bool>((ref) {
  if (ref.watch(profileProvider).isCreator) {
    return ref.watch(proPlanProvider).includes(ProPlan.business);
  }
  return ref.watch(planProvider) == Plan.privilege;
});

// ─── Formule prestataire ────────────────────────────────────────────────

/// Abonnement prestataire payant en cours (null : formule Découverte).
class CreatorSubscription {
  const CreatorSubscription({
    required this.plan,
    required this.since,
    required this.renewsOn,
    required this.method,
    required this.receipt,
    this.cancelled = false,
    this.trial = false,
    this.yearly = false,
  });

  final ProPlan plan;
  final DateTime since;
  final DateTime renewsOn;
  final PayMethod method;
  final String receipt;

  /// Résilié : reste actif jusqu'à [renewsOn], sans renouvellement.
  final bool cancelled;

  /// Essai gratuit : l'offre devient payante à [renewsOn].
  final bool trial;

  /// Payé à l'année (dix mensualités pour douze mois).
  final bool yearly;

  bool get active => renewsOn.isAfter(DateTime.now());

  CreatorSubscription copyWith({bool? cancelled}) => CreatorSubscription(
    plan: plan,
    since: since,
    renewsOn: renewsOn,
    method: method,
    receipt: receipt,
    cancelled: cancelled ?? this.cancelled,
    trial: trial,
    yearly: yearly,
  );
}

class CreatorSubNotifier extends Notifier<CreatorSubscription?> {
  @override
  CreatorSubscription? build() => null;

  /// Active la formule après un paiement réussi (30 jours, ou un an).
  void activate(
    PayMethod method,
    String receipt, {
    ProPlan plan = ProPlan.creator,
    bool yearly = false,
  }) {
    final now = DateTime.now();
    state = CreatorSubscription(
      plan: plan,
      yearly: yearly,
      since: now,
      renewsOn: now.add(Duration(days: yearly ? 365 : 30)),
      method: method,
      receipt: receipt,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => ref.read(soundProvider).play(Sfx.premium),
    );
  }

  /// Essai gratuit de [trialDays] jours, sans paiement ni carte : Creator et
  /// Business seulement.
  void startTrial([ProPlan plan = ProPlan.creator]) {
    assert(plan.hasTrial, 'Essai réservé à Creator et Business');
    if (!plan.hasTrial) return;
    final now = DateTime.now();
    state = CreatorSubscription(
      plan: plan,
      since: now,
      renewsOn: now.add(const Duration(days: trialDays)),
      method: PayMethod.values.first,
      receipt: '',
      trial: true,
    );
  }

  void cancel() => state = state?.copyWith(cancelled: true);
  void resume() => state = state?.copyWith(cancelled: false);
}

final creatorSubProvider =
    NotifierProvider<CreatorSubNotifier, CreatorSubscription?>(
      CreatorSubNotifier.new,
    );

/// Formule du prestataire : celle de l'abonnement en cours, sinon
/// Découverte.
final proPlanProvider = Provider<ProPlan>((ref) {
  final sub = ref.watch(creatorSubProvider);
  return sub != null && sub.active ? sub.plan : ProPlan.decouverte;
});

/// Commission appliquée aux prochains encaissements, selon la formule.
final proCommissionProvider = Provider<double>(
  (ref) => ref.watch(proPlanProvider).commission,
);

/// Options de visibilité en cours, avec leur date de fin.
class ProBoostNotifier extends Notifier<Map<ProBoost, DateTime>> {
  @override
  Map<ProBoost, DateTime> build() => const {};

  void activate(ProBoost b) =>
      state = {...state, b: DateTime.now().add(Duration(days: b.days ?? 14))};

  bool active(ProBoost b) => state[b]?.isAfter(DateTime.now()) ?? false;
}

final proBoostsProvider =
    NotifierProvider<ProBoostNotifier, Map<ProBoost, DateTime>>(
      ProBoostNotifier.new,
    );

/// Une fonctionnalité est débloquée par l'abonnement.
/// Le Pass Événement débloque les fonctions Signature de son événement.
final featureUnlockedProvider =
    Provider.family<bool, (PremiumFeature, String?)>((ref, arg) {
      if (ref.watch(planProvider).includes(arg.$1.minPlan)) return true;
      final id = arg.$2;
      if (id == null || !eventPassPlan.includes(arg.$1.minPlan)) return false;
      ref.watch(eventPassProvider);
      return ref.read(eventPassProvider.notifier).active(id);
    });

// ─── Coffre-fort ────────────────────────────────────────────────────────

class VaultNotifier extends Notifier<List<VaultDoc>> {
  @override
  List<VaultDoc> build() {
    // Documents fictifs réservés à la démo.
    if (ref.watch(liveSessionProvider)) return const [];
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));
    const w = 'mariage-awa-kouassi';
    return [
      VaultDoc(
        name: 'Contrat Espace Latrille Events.pdf'.tr,
        folder: VaultFolder.contracts,
        sizeKb: 412,
        date: ago(40),
        eventId: w,
      ),
      VaultDoc(
        name: 'Contrat Saveurs d’Ivoire.pdf'.tr,
        folder: VaultFolder.contracts,
        sizeKb: 386,
        date: ago(21),
        eventId: w,
      ),
      VaultDoc(
        name: 'Devis Studio Lumière.pdf'.tr,
        folder: VaultFolder.quotes,
        sizeKb: 198,
        date: ago(6),
        eventId: w,
      ),
      VaultDoc(
        name: 'Devis Maison Inès Déco.pdf'.tr,
        folder: VaultFolder.quotes,
        sizeKb: 233,
        date: ago(15),
        eventId: w,
      ),
      VaultDoc(
        name: 'Reçu acompte salle EVT-0412.pdf'.tr,
        folder: VaultFolder.invoices,
        sizeKb: 96,
        date: ago(40),
        eventId: w,
      ),
      VaultDoc(
        name: 'Reçu acompte traiteur EVT-0498.pdf'.tr,
        folder: VaultFolder.invoices,
        sizeKb: 94,
        date: ago(21),
        eventId: w,
      ),
      VaultDoc(
        name: 'Essayage robe — 12 photos'.tr,
        folder: VaultFolder.photos,
        sizeKb: 18400,
        date: ago(3),
        eventId: w,
      ),
      VaultDoc(
        name: 'Moodboard déco blanc et or — 18 images'.tr,
        folder: VaultFolder.inspirations,
        sizeKb: 9600,
        date: ago(9),
        eventId: w,
      ),
      VaultDoc(
        name: 'Idées de gâteau et table sucrée.pdf'.tr,
        folder: VaultFolder.inspirations,
        sizeKb: 2300,
        date: ago(5),
        eventId: w,
      ),
      VaultDoc(
        name: 'Certificat de publication des bans.pdf'.tr,
        folder: VaultFolder.certificates,
        sizeKb: 120,
        date: ago(2),
        eventId: w,
      ),
      VaultDoc(
        name: 'Pièces d’identité des témoins.pdf'.tr,
        folder: VaultFolder.documents,
        sizeKb: 840,
        date: ago(9),
        eventId: w,
      ),
    ];
  }

  void add(VaultDoc d) => state = [d, ...state];

  void remove(VaultDoc d) => state = state.where((x) => x != d).toList();
}

final vaultProvider = NotifierProvider<VaultNotifier, List<VaultDoc>>(
  VaultNotifier.new,
);

// ─── Réservations ───────────────────────────────────────────────────────

String receiptRef() => 'EVT-{0}-{1}'.trf([
  DateTime.now().year,
  (math.Random().nextInt(9000) + 1000),
]);

class BookingsNotifier extends Notifier<List<Booking>> {
  var _seq = 0;

  @override
  List<Booking> build() => const [];

  Booking byId(String id) => state.firstWhere((b) => b.id == id);

  void _set(Booking b) => state = [for (final x in state) x.id == b.id ? b : x];

  /// Étapes 1 → 2 : demande de devis. Le prestataire (simulé) répond.
  String request(Vendor v, String eventId, QuoteRequest r) {
    // Compteur en plus de l'horodatage : deux demandes envoyées dans la même
    // microseconde (horloge peu précise) ne doivent pas partager d'identifiant.
    final id = 'bk-${DateTime.now().microsecondsSinceEpoch}-${++_seq}';
    final b = Booking(
      id: id,
      vendor: v,
      eventId: eventId,
      step: BookingStep.requested,
      request: r,
      createdAt: DateTime.now(),
      messages: [
        ChatMessage(fromMe: true, text: r.message, at: DateTime.now()),
      ],
    );
    state = [b, ...state];
    ref.read(audienceProvider.notifier).track(Metric.quoteRequest);
    ref
        .read(eventsProvider.notifier)
        .upsertVendor(
          eventId,
          EventVendor(vendor: v, status: VendorStatus.contacted, amount: 0),
        );
    Timer(const Duration(milliseconds: 2600), () => _receiveQuote(id));
    return id;
  }

  /// Étape 3 : réception du devis (simulée).
  void _receiveQuote(String id) {
    if (!state.any((b) => b.id == id)) return;
    final b = byId(id);
    final v = b.vendor;
    final perHead = v.unit == 'pers.';
    final base = perHead ? v.priceFrom * b.request.guests : v.priceFrom;
    final lines = <QuoteLine>[
      QuoteLine(
        perHead
            ? '{0} × {1} invités'.trf([
                v.packages.isEmpty ? 'Prestation'.tr : v.packages.first.name,
                b.request.guests,
              ])
            : (v.packages.isEmpty
                  ? 'Prestation {0}'.trf([v.category.label.toLowerCase()])
                  : v.packages.first.name),
        base,
      ),
      for (final o in b.request.options)
        QuoteLine(o, (base * 0.08 / 1000).round() * 1000, optional: true),
      if (v.zone != 'Cocody'.tr && v.zone != 'Plateau'.tr)
        QuoteLine('Déplacement & installation'.tr, 35000),
    ];
    final subtotal = lines.fold<int>(0, (s, l) => s + l.amount);
    final quote = Quote(
      lines: lines,
      fees: (subtotal * 0.02 / 100).round() * 100,
      validUntil: DateTime.now().add(const Duration(days: 7)),
      conditions: [
        'Acompte de 30 % à la réservation, solde à J-7.'.tr,
        'Annulation gratuite jusqu’à J-30 ; ensuite l’acompte est conservé.'.tr,
        'Date bloquée dès le paiement de l’acompte.'.tr,
        'Fonds reversés au prestataire après validation de la prestation.'.tr,
      ],
    );
    _set(
      b.copyWith(
        step: BookingStep.quoted,
        quote: quote,
        messages: [
          ...b.messages,
          ChatMessage(
            fromMe: false,
            text: 'Merci pour votre demande ! Voici notre devis détaillé, valable 7 jours. N’hésitez pas si vous avez des questions.'
                .tr,
            at: DateTime.now(),
          ),
        ],
      ),
    );
    ref
        .read(eventsProvider.notifier)
        .upsertVendor(
          b.eventId,
          EventVendor(
            vendor: v,
            status: VendorStatus.quoted,
            amount: quote.total,
          ),
        );
  }

  /// Dernière offre du prestataire : son meilleur prix, une seule fois par
  /// devis. Renvoie la remise obtenue.
  int lastOffer(String id) {
    final b = byId(id);
    final q = b.quote!;
    if (q.lastOffer) return 0;
    final rate = lastOfferPercent(b.vendor.category) / 100;
    final lines = [
      for (final l in q.lines)
        QuoteLine(
          l.label,
          (l.amount * (1 - rate) / 500).round() * 500,
          optional: l.optional,
        ),
    ];
    final next = Quote(
      lines: lines,
      conditions: q.conditions,
      fees: q.fees,
      validUntil: q.validUntil,
      depositRate: q.depositRate,
      lastOffer: true,
    );
    _set(
      b.copyWith(
        quote: next,
        messages: [
          ...b.messages,
          ChatMessage(
            fromMe: true,
            text: 'Pouvez-vous me faire votre dernière offre ?'.tr,
            at: DateTime.now(),
          ),
          ChatMessage(
            fromMe: false,
            text: 'Voici notre dernière offre : {0} au lieu de {1}. Devis mis à jour.'
                .trf([fcfa(next.total), fcfa(q.total)]),
            at: DateTime.now(),
          ),
        ],
      ),
    );
    return q.total - next.total;
  }

  /// Étape 4 : acceptation, la date est bloquée, l'engagé est mis à jour.
  /// [note] : trace de l'accord (signature électronique) ajoutée au fil.
  void accept(String id, {String? note}) {
    final b = byId(id);
    _set(
      b.copyWith(
        step: BookingStep.reserved,
        messages: [
          ...b.messages,
          if (note != null)
            ChatMessage(fromMe: true, text: note, at: DateTime.now()),
        ],
      ),
    );
    ref.read(audienceProvider.notifier).track(Metric.booking);
    ref.read(soundProvider).play(Sfx.booking);
    final events = ref.read(eventsProvider.notifier);
    events.commit(b.eventId, b.vendor.category.budget, b.quote!.subtotal);
    events.upsertVendor(
      b.eventId,
      EventVendor(
        vendor: b.vendor,
        status: VendorStatus.booked,
        amount: b.quote!.total,
      ),
    );
  }

  /// Étape 5 (acompte) ou 7 (solde) : paiement confirmé, reçu généré.
  Receipt pay(String id, int amount, PayMethod method) {
    final b = byId(id);
    final r = Receipt(
      ref: receiptRef(),
      label: b.paidAmount == 0 && amount < b.balance
          ? 'Acompte {0}'.trf([b.vendor.name])
          : (b.paidAmount == 0
                ? 'Paiement {0}'.trf([b.vendor.name])
                : 'Solde {0}'.trf([b.vendor.name])),
      amount: amount,
      method: method,
      date: DateTime.now(),
      payee: b.vendor.name,
    );
    final paid = b.paidAmount + amount;
    final next = b.step.index < BookingStep.executing.index
        ? BookingStep.executing
        : b.step;
    _set(
      b.copyWith(step: next, paidAmount: paid, receipts: [...b.receipts, r]),
    );
    ref.read(audienceProvider.notifier).track(Metric.payment);

    final events = ref.read(eventsProvider.notifier);
    events.addExpense(
      b.eventId,
      Expense(
        id: r.ref,
        category: b.vendor.category.budget,
        label: r.label,
        amount: amount,
        date: r.date,
        method: method.label,
      ),
    );
    events.upsertVendor(
      b.eventId,
      EventVendor(
        vendor: b.vendor,
        status: paid >= b.quote!.total
            ? VendorStatus.paid
            : VendorStatus.booked,
        amount: b.quote!.total,
      ),
    );
    ref
        .read(vaultProvider.notifier)
        .add(
          VaultDoc(
            name: 'Reçu {0} {1}.pdf'.trf([r.label, r.ref]),
            folder: VaultFolder.invoices,
            sizeKb: 92,
            date: r.date,
            eventId: b.eventId,
          ),
        );
    return r;
  }

  void message(String id, String text) {
    final b = byId(id);
    _set(
      b.copyWith(
        messages: [
          ...b.messages,
          ChatMessage(fromMe: true, text: text, at: DateTime.now()),
        ],
      ),
    );
    ref.read(audienceProvider.notifier).track(Metric.messageSent);
    Timer(const Duration(milliseconds: 1500), () {
      if (!state.any((x) => x.id == id)) return;
      final cur = byId(id);
      _set(
        cur.copyWith(
          messages: [
            ...cur.messages,
            ChatMessage(
              fromMe: false,
              text: 'Bien noté, je reviens vers vous très vite.'.tr,
              at: DateTime.now(),
            ),
          ],
        ),
      );
    });
  }

  /// Étape 7 : clôture — reversement au prestataire après validation.
  void close(String id) {
    final b = byId(id);
    _set(b.copyWith(step: BookingStep.closed, payoutDone: true));
  }

  void review(String id, int rating) => _set(byId(id).copyWith(rating: rating));

  void archive(String id) => _set(byId(id).copyWith(archived: true));
}

final bookingsProvider = NotifierProvider<BookingsNotifier, List<Booking>>(
  BookingsNotifier.new,
);

final bookingProvider = Provider.family<Booking?, String>((ref, id) {
  for (final b in ref.watch(bookingsProvider)) {
    if (b.id == id) return b;
  }
  return null;
});

/// Raccourci : catégorie budgétaire d'une réservation.
extension BookingBudgetX on Booking {
  BudgetCategory get budgetCategory => vendor.category.budget;
}

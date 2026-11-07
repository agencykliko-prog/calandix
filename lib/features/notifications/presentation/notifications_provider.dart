import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/auth/session_provider.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../pro/presentation/creator_providers.dart';
import '../../inbox/presentation/inbox_providers.dart';
import '../../pro/presentation/verification_providers.dart';
import '../../pro/domain/pro_models.dart';
import '../../pro/presentation/pro_providers.dart';
import '../../events/presentation/events_providers.dart';
import '../../../core/models/models.dart';
import 'push_prefs.dart';

/// Notification affichée dans la cloche de l'accueil.
@immutable
class Notice {
  const Notice({
    required this.id,
    required this.icon,
    required this.hue,
    required this.title,
    required this.caption,
    required this.at,
    this.link,
    this.read = false,
  });

  final String id;
  final IconData icon;
  final Hue hue;
  final String title;
  final String caption;
  final DateTime at;

  /// Écran à ouvrir au toucher.
  final String? link;
  final bool read;

  Notice asRead() => Notice(
    id: id,
    icon: icon,
    hue: hue,
    title: title,
    caption: caption,
    at: at,
    link: link,
    read: true,
  );
}

/// Notifications du profil connecté : quelques notifications de démo, puis
/// celles produites par les actions (devis reçu, message, paiement, demande
/// confirmée, décision de vérification…).
class NoticesNotifier extends Notifier<List<Notice>> {
  var _seq = 0;

  /// Rappels J-1 déjà émis (une seule fois par élément).
  final _dayBefore = <String>{};

  @override
  List<Notice> build() {
    final creator = ref.watch(profileProvider).isCreator;
    if (creator) {
      ref.listen(requestsProvider, _onRequests, fireImmediately: true);
      ref.listen(verificationProvider, _onVerification);
      ref.listen(proProvider, _onOrders);
    } else {
      ref.listen(bookingsProvider, _onBookings);
      ref.listen(directThreadsProvider, _onDirect);
      ref.listen(eventsProvider, (_, next) {
        final list = next.value;
        if (list != null) _checkEvents(list);
      }, fireImmediately: true);
    }
    // Avec un compte réel, pas de notifications fictives.
    if (ref.watch(liveSessionProvider)) return const [];
    return creator ? _creatorDemo() : _organizerDemo();
  }

  void _push(
    IconData icon,
    Hue hue,
    String title,
    String caption, {
    String? link,
    PushKind? kind,
  }) {
    state = [
      Notice(
        id: 'n${++_seq}',
        icon: icon,
        hue: hue,
        title: title,
        caption: caption,
        at: DateTime.now(),
        link: link,
      ),
      ...state,
    ];
    // Notification push, si ce type n'a pas été coupé dans les réglages.
    if (kind != null && ref.read(pushPrefsProvider).contains(kind)) {
      ref
          .read(pushBannerProvider.notifier)
          .show(PushMessage(kind, title, caption, DateTime.now(), link: link));
    }
  }

  bool _tomorrow(DateTime d) {
    final t = DateTime.now().add(const Duration(days: 1));
    return d.year == t.year && d.month == t.month && d.day == t.day;
  }

  // ─── Rappels J-1 ────────────────────────────────────────────────────

  void _checkEvents(List<Event> events) {
    for (final e in events) {
      if (_tomorrow(e.date) && _dayBefore.add('e-${e.id}')) {
        Future.microtask(
          () => _push(
            AppIcons.reminder,
            Hue.coral,
            'Rappel J-1'.tr,
            '{0} a lieu demain à {1}.'.trf([e.name, timeOf(e.date)]),
            link: Routes.event(e.id),
            kind: PushKind.dayBefore,
          ),
        );
      }
      for (final t in e.tasks) {
        if (!t.done && _tomorrow(t.due) && _dayBefore.add('t-${t.id}')) {
          Future.microtask(
            () => _push(
              AppIcons.reminder,
              Hue.violet,
              'Rappel J-1'.tr,
              'Demain : {0} ({1}).'.trf([t.title, e.name]),
              link: Routes.event(e.id),
              kind: PushKind.dayBefore,
            ),
          );
        }
      }
    }
  }

  // ─── Organisateur : réservations ────────────────────────────────────

  void _onBookings(List<Booking>? prev, List<Booking> next) {
    for (final b in next) {
      final before = prev?.where((x) => x.id == b.id).firstOrNull;
      if (before == null) continue;
      final link = Routes.booking(b.id);
      if (before.step != BookingStep.quoted && b.step == BookingStep.quoted) {
        _push(
          AppIcons.file,
          Hue.mango,
          'Devis reçu'.tr,
          '{0} · valable 7 jours'.trf([b.vendor.name]),
          link: link,
          kind: PushKind.quoteReceived,
        );
      } else if (b.messages.length > before.messages.length &&
          !b.messages.last.fromMe) {
        _push(
          AppIcons.message,
          Hue.violet,
          'Nouveau message'.tr,
          '{0} : {1}'.trf([b.vendor.name, b.messages.last.text]),
          link: Routes.conversation(b.id),
        );
      }
      if (b.receipts.length > before.receipts.length) {
        final r = b.receipts.last;
        _push(
          AppIcons.checkCircle,
          Hue.lagoon,
          'Paiement confirmé'.tr,
          '{0} · {1}'.trf([r.label, fcfa(r.amount)]),
          link: link,
          kind: PushKind.depositPaid,
        );
      }
    }
  }

  void _onDirect(
    Map<String, DirectThread>? prev,
    Map<String, DirectThread> next,
  ) {
    for (final t in next.values) {
      final before = prev?[t.vendor.id]?.messages.length ?? 0;
      if (t.messages.length > before && !t.messages.last.fromMe) {
        _push(
          AppIcons.message,
          Hue.violet,
          'Nouveau message'.tr,
          '{0} : {1}'.trf([t.vendor.name, t.messages.last.text]),
          link: Routes.conversation(directConversationId(t.vendor)),
        );
      }
    }
  }

  // ─── Creator : demandes et vérification ─────────────────────────────

  void _onRequests(List<ClientRequest>? prev, List<ClientRequest> next) {
    for (final r in next) {
      if (r.status == RequestStatus.confirmed &&
          _tomorrow(r.date) &&
          _dayBefore.add('r-${r.id}')) {
        Future.microtask(
          () => _push(
            AppIcons.reminder,
            Hue.coral,
            'Rappel J-1'.tr,
            'Prestation demain : {0} à {1}.'.trf([r.eventName, timeOf(r.date)]),
            link: '/pro/commandes',
            kind: PushKind.dayBefore,
          ),
        );
      }
      final before = prev?.where((x) => x.id == r.id).firstOrNull;
      if (before == null) {
        if (prev != null && r.status == RequestStatus.received) {
          _push(
            AppIcons.inbox,
            Hue.mango,
            'Nouvelle demande de devis'.tr,
            '{0} · {1}'.trf([r.client, r.eventName]),
            link: '/pro/devis/${r.id}',
            kind: PushKind.newRequest,
          );
        }
        continue;
      }
      if (r.thread.length > before.thread.length && !r.thread.last.fromMe) {
        _push(
          AppIcons.message,
          Hue.violet,
          'Nouveau message'.tr,
          '{0} : {1}'.trf([r.client, r.thread.last.text]),
          link: Routes.conversation(r.id),
        );
      }
      if (before.status != RequestStatus.confirmed &&
          r.status == RequestStatus.confirmed) {
        _push(
          AppIcons.calendarCheck,
          Hue.lagoon,
          'Prestation confirmée'.tr,
          r.eventName,
          link: '/pro/devis/${r.id}',
        );
      }
    }
  }

  /// Acompte enregistré sur une commande.
  void _onOrders(ProState? prev, ProState next) {
    if (prev == null) return;
    for (final MapEntry(:key, :value) in next.progress.entries) {
      final before = prev.progressOf(key).stage;
      if (before == OrderStage.accepted &&
          value.stage == OrderStage.confirmed) {
        final r = ref
            .read(requestsProvider)
            .where((x) => x.id == key)
            .firstOrNull;
        _push(
          AppIcons.coins,
          Hue.lagoon,
          'Acompte reçu'.tr,
          r == null
              ? 'La date est bloquée.'.tr
              : '{0} · {1}'.trf([r.client, r.eventName]),
          link: '/pro/commandes',
          kind: PushKind.depositPaid,
        );
      }
    }
  }

  void _onVerification(Verification? prev, Verification next) {
    if (prev?.step == next.step) return;
    const link = '/pro/verification';
    switch (next.step) {
      case VerificationStep.verified:
        _push(
          AppIcons.verified,
          Hue.lagoon,
          'Profil vérifié'.tr,
          'Le badge « Vérifié » apparaît sur votre fiche.'.tr,
          link: link,
        );
      case VerificationStep.info:
        _push(
          AppIcons.info,
          Hue.mango,
          'Informations demandées'.tr,
          next.comment ?? 'Complétez votre dossier de vérification.'.tr,
          link: link,
        );
      case VerificationStep.rejected:
        _push(
          AppIcons.warning,
          Hue.coral,
          'Vérification refusée'.tr,
          next.comment ?? 'Contactez l’équipe pour en savoir plus.'.tr,
          link: link,
        );
      case VerificationStep.draft || VerificationStep.pending:
        break;
    }
  }

  // ─── Lecture ────────────────────────────────────────────────────────

  void markAllRead() {
    if (state.every((n) => n.read)) return;
    state = [for (final n in state) n.read ? n : n.asRead()];
  }

  // ─── Données de démo ────────────────────────────────────────────────

  List<Notice> _organizerDemo() {
    final n = DateTime.now();
    return [
      Notice(
        id: 'd1',
        icon: AppIcons.file,
        hue: Hue.mango,
        title: 'Devis reçu'.tr,
        caption: 'Studio Lumière · valable 7 jours'.tr,
        at: n.subtract(const Duration(hours: 1)),
        link: Routes.vendor('studio-lumiere'),
      ),
      Notice(
        id: 'd2',
        icon: AppIcons.coins,
        hue: Hue.lagoon,
        title: 'Paiement à venir'.tr,
        caption: 'Solde Lagune Sound demain'.tr,
        at: n.subtract(const Duration(hours: 3)),
      ),
      Notice(
        id: 'd3',
        icon: AppIcons.guests,
        hue: Hue.coral,
        title: '+8 réponses RSVP'.tr,
        caption: 'Mariage Awa & Kouassi'.tr,
        at: n.subtract(const Duration(hours: 5)),
      ),
      Notice(
        id: 'd4',
        icon: AppIcons.reminder,
        hue: Hue.violet,
        title: 'Rappel'.tr,
        caption: 'Valider le menu de dégustation à 11:00'.tr,
        at: n.subtract(const Duration(hours: 8)),
        read: true,
      ),
    ];
  }

  List<Notice> _creatorDemo() {
    final n = DateTime.now();
    return [
      Notice(
        id: 'd1',
        icon: AppIcons.inbox,
        hue: Hue.mango,
        title: 'Nouvelle demande de devis'.tr,
        caption: 'Awa Traoré · Mariage du 7 déc.'.tr,
        at: n.subtract(const Duration(minutes: 35)),
        link: '/pro/devis/r1',
      ),
      Notice(
        id: 'd2',
        icon: AppIcons.message,
        hue: Hue.violet,
        title: 'Nouveau message'.tr,
        caption: 'Yasmine Ouattara : {0}'.trf([
          'Oui, une partie est couverte. Accès possible dès 14 h.'.tr,
        ]),
        at: n.subtract(const Duration(hours: 3)),
        link: Routes.conversation('r2'),
      ),
      Notice(
        id: 'd3',
        icon: AppIcons.checkCircle,
        hue: Hue.lagoon,
        title: 'Prestation confirmée'.tr,
        caption: 'Baby shower de Mariam · acompte reçu'.tr,
        at: n.subtract(const Duration(days: 1)),
        link: '/pro/devis/r4',
      ),
      Notice(
        id: 'd4',
        icon: AppIcons.star,
        hue: Hue.violet,
        title: 'Nouvel avis 5 étoiles'.tr,
        caption: 'Fondation Lumière'.tr,
        at: n.subtract(const Duration(days: 3)),
        link: '/pro/reputation',
        read: true,
      ),
    ];
  }
}

final noticesProvider = NotifierProvider<NoticesNotifier, List<Notice>>(
  NoticesNotifier.new,
);

final unreadNoticesProvider = Provider<int>(
  (ref) => ref.watch(noticesProvider).where((n) => !n.read).length,
);

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend.dart';
import '../../../core/auth/session_provider.dart';
import '../data/events_remote.dart';
import '../data/events_repository.dart';
import '../../../core/models/models.dart';

/// Source des événements : la base pour un compte réel, les données de
/// démonstration sinon.
final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  if (ref.watch(liveSessionProvider) && Backend.ready) {
    final id = Backend.client.auth.currentUser?.id;
    if (id != null) {
      return SupabaseEventsRepository(
        userId: id,
        userName: ref.watch(profileProvider.select((p) => p.name)),
      );
    }
  }
  return const DemoEventsRepository();
});

class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() =>
      ref.watch(eventsRepositoryProvider).fetchEvents();

  EventsRepository get _repo => ref.read(eventsRepositoryProvider);

  /// Enregistre une modification déjà affichée. En cas d'échec, on recharge
  /// depuis la base pour ne pas laisser l'écran mentir.
  void _persist(Future<void> Function(EventsRepository r) write) {
    unawaited(
      write(_repo).catchError((Object e) {
        debugPrint('Enregistrement impossible : $e');
        ref.invalidateSelf();
      }),
    );
  }

  /// Ligne de budget après modification, pour l'enregistrer.
  void _persistLine(String eventId, BudgetCategory c) {
    final line = state.value
        ?.where((e) => e.id == eventId)
        .firstOrNull
        ?.line(c);
    if (line != null) _persist((r) => r.saveLine(eventId, line));
  }

  EventTask? _taskOf(String eventId, String taskId) => state.value
      ?.where((e) => e.id == eventId)
      .firstOrNull
      ?.tasks
      .where((t) => t.id == taskId)
      .firstOrNull;

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  void _update(String eventId, Event Function(Event) f) {
    final events = state.value;
    if (events == null) return;
    state = AsyncData([for (final e in events) e.id == eventId ? f(e) : e]);
  }

  void toggleTask(String eventId, String taskId) {
    _update(
      eventId,
      (e) => e.copyWith(
        tasks: [
          for (final t in e.tasks)
            if (t.id == taskId) t.copyWith(done: !t.done) else t,
        ],
      ),
    );
    final t = _taskOf(eventId, taskId);
    if (t != null) _persist((r) => r.saveTask(eventId, t));
  }

  void addTask(String eventId, EventTask t) {
    // La base attend un identifiant UUID.
    final task = ref.read(liveSessionProvider) && !isServerId(t.id)
        ? EventTask(
            id: newUuid(),
            title: t.title,
            due: t.due,
            module: t.module,
            assigneeId: t.assigneeId,
            done: t.done,
            urgent: t.urgent,
            durationMin: t.durationMin,
            icon: t.icon,
          )
        : t;
    _update(eventId, (e) => e.copyWith(tasks: [...e.tasks, task]));
    _persist((r) => r.saveTask(eventId, task));
  }

  void updateTask(String eventId, EventTask t) {
    _update(
      eventId,
      (e) => e.copyWith(tasks: [for (final x in e.tasks) x.id == t.id ? t : x]),
    );
    _persist((r) => r.saveTask(eventId, t));
  }

  void removeTask(String eventId, String taskId) {
    _update(
      eventId,
      (e) => e.copyWith(tasks: e.tasks.where((x) => x.id != taskId).toList()),
    );
    _persist((r) => r.deleteTask(taskId));
  }

  /// Ajoute un événement et renvoie son identifiant définitif (celui de la
  /// base pour un compte réel).
  Future<String> add(Event event) async {
    final saved = await _repo.createEvent(event);
    final events = state.value ?? const [];
    state = AsyncData([saved, ...events]);
    return saved.id;
  }

  /// Retire l'événement de la liste (mise à la corbeille). Renvoie
  /// l'événement retiré.
  Event? detach(String eventId) {
    final events = state.value;
    final e = events?.where((x) => x.id == eventId).firstOrNull;
    if (events == null || e == null) return null;
    state = AsyncData([
      for (final x in events)
        if (x.id != eventId) x,
    ]);
    return e;
  }

  /// Remet un événement restauré dans la liste, à sa place chronologique.
  void reattach(Event e) {
    final events = [
      for (final x in state.value ?? const <Event>[])
        if (x.id != e.id) x,
      e,
    ]..sort((a, b) => a.date.compareTo(b.date));
    state = AsyncData(events);
  }

  // ─── Budget ──────────────────────────────────────────────────────────

  void setTarget(String eventId, int target) {
    _update(eventId, (e) => e.copyWith(targetBudget: target));
    _persist((r) => r.setTarget(eventId, target));
  }

  void upsertLine(String eventId, BudgetLine line) {
    _update(eventId, (e) {
      final exists = e.budget.any((l) => l.category == line.category);
      return e.copyWith(
        budget: exists
            ? [for (final l in e.budget) l.category == line.category ? line : l]
            : [...e.budget, line],
      );
    });
    _persist((r) => r.saveLine(eventId, line));
  }

  void removeLine(String eventId, BudgetCategory c) {
    _update(
      eventId,
      (e) =>
          e.copyWith(budget: e.budget.where((l) => l.category != c).toList()),
    );
    _persist((r) => r.deleteLine(eventId, c));
  }

  void replaceBudget(String eventId, List<BudgetLine> lines) {
    final before =
        state.value?.where((e) => e.id == eventId).firstOrNull?.budget ??
        const <BudgetLine>[];
    _update(eventId, (e) => e.copyWith(budget: lines));
    _persist((r) async {
      for (final old in before) {
        if (!lines.any((l) => l.category == old.category)) {
          await r.deleteLine(eventId, old.category);
        }
      }
      for (final l in lines) {
        await r.saveLine(eventId, l);
      }
    });
  }

  /// Une dépense réglée augmente le payé du poste (et l'engagé s'il le faut).
  void addExpense(String eventId, Expense x) {
    _addExpense(eventId, x);
    _persist((r) => r.addExpense(eventId, x));
    _persistLine(eventId, x.category);
  }

  void _addExpense(String eventId, Expense x) => _update(eventId, (e) {
    final line =
        e.line(x.category) ?? BudgetLine(category: x.category, estimated: 0);
    final paid = line.paid + x.amount;
    final updated = line.copyWith(
      paid: paid,
      committed: paid > line.committed ? paid : line.committed,
    );
    final exists = e.budget.any((l) => l.category == x.category);
    return e.copyWith(
      expenses: [x, ...e.expenses],
      budget: exists
          ? [for (final l in e.budget) l.category == x.category ? updated : l]
          : [...e.budget, updated],
    );
  });

  /// Une réservation acceptée crée ou met à jour l'engagé du poste.
  void commit(String eventId, BudgetCategory c, int amount) {
    _commit(eventId, c, amount);
    _persistLine(eventId, c);
  }

  void _commit(String eventId, BudgetCategory c, int amount) =>
      _update(eventId, (e) {
        final line = e.line(c) ?? BudgetLine(category: c, estimated: amount);
        final updated = line.copyWith(committed: line.committed + amount);
        final exists = e.budget.any((l) => l.category == c);
        return e.copyWith(
          budget: exists
              ? [for (final l in e.budget) l.category == c ? updated : l]
              : [...e.budget, updated],
        );
      });

  // ─── Invités ─────────────────────────────────────────────────────────

  void _setGuests(String eventId, List<Guest> Function(List<Guest>) f) =>
      _update(
        eventId,
        (e) => e.copyWith(
          guests: Guests.fromList(
            f(e.guests.list),
            expected: e.guests.expected,
          ),
        ),
      );

  /// Ajoute un invité et renvoie son identifiant définitif.
  String addGuest(String eventId, Guest g) {
    // La base attend un identifiant UUID.
    final guest = ref.read(liveSessionProvider) && !isServerId(g.id)
        ? Guest(
            id: newUuid(),
            name: g.name,
            phone: g.phone,
            group: g.group,
            rsvp: g.rsvp,
            companions: g.companions,
            diet: g.diet,
            addedAt: g.addedAt ?? DateTime.now(),
          )
        : g;
    _setGuests(
      eventId,
      (l) => [...l, guest]..sort((a, b) => a.name.compareTo(b.name)),
    );
    _persist((r) => r.saveGuest(eventId, guest));
    return guest.id;
  }

  void updateGuest(String eventId, Guest g) {
    _setGuests(eventId, (l) => [for (final x in l) x.id == g.id ? g : x]);
    _persist((r) => r.saveGuest(eventId, g));
  }

  void setRsvp(String eventId, String guestId, Rsvp rsvp) {
    final g = state.value
        ?.where((e) => e.id == eventId)
        .firstOrNull
        ?.guests
        .list
        .where((x) => x.id == guestId)
        .firstOrNull;
    if (g != null) updateGuest(eventId, g.copyWith(rsvp: rsvp));
  }

  void removeGuest(String eventId, String guestId) {
    _setGuests(eventId, (l) => l.where((x) => x.id != guestId).toList());
    _persist((r) => r.deleteGuest(guestId));
  }

  // ─── Équipe ──────────────────────────────────────────────────────────

  void addMember(String eventId, TeamMember m) =>
      _update(eventId, (e) => e.copyWith(team: [...e.team, m]));

  void updateMember(String eventId, TeamMember m) => _update(
    eventId,
    (e) => e.copyWith(team: [for (final x in e.team) x.id == m.id ? m : x]),
  );

  void removeMember(String eventId, String memberId) => _update(
    eventId,
    (e) => e.copyWith(team: e.team.where((x) => x.id != memberId).toList()),
  );

  // ─── Prestataires ────────────────────────────────────────────────────

  void upsertVendor(String eventId, EventVendor v) => _update(eventId, (e) {
    final exists = e.vendors.any((x) => x.vendor.id == v.vendor.id);
    return e.copyWith(
      vendors: exists
          ? [for (final x in e.vendors) x.vendor.id == v.vendor.id ? v : x]
          : [...e.vendors, v],
    );
  });
}

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<Event>>(
  EventsNotifier.new,
);

/// Un événement précis, à partir de la liste.
final eventProvider = Provider.family<AsyncValue<Event?>, String>((ref, id) {
  return ref.watch(eventsProvider).whenData((events) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  });
});

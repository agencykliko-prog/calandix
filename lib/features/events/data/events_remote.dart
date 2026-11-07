import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show IconData;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../core/models/models.dart';
import 'event_templates.dart';
import 'events_repository.dart';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// L'identifiant vient-il de la base (UUID) ?
bool isServerId(String id) => _uuid.hasMatch(id);

/// Événements du compte connecté, lus et enregistrés dans Supabase. Les
/// règles d'accès de la base limitent chaque compte à ses événements et à
/// ceux où il est invité.
class SupabaseEventsRepository extends EventsRepository {
  const SupabaseEventsRepository({
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  SupabaseClient get _db => Backend.client;

  TeamMember get _me => TeamMember(
    id: userId,
    name: userName,
    role: TeamRole.owner,
    online: true,
    permissions: Permissions.all,
  );

  // ─── Lecture ─────────────────────────────────────────────────────────

  @override
  Future<List<Event>> fetchEvents() async {
    const cols = '*, budget_lines(*), expenses(*), tasks(*), guests(*)';
    try {
      final rows = await _db
          .from('events')
          .select(cols)
          .eq('archived', false)
          .isFilter('deleted_at', null)
          .order('starts_at');
      return [for (final r in rows) eventFromRow(r)];
    } on PostgrestException {
      // Base sans la colonne de corbeille (migration pas encore appliquée).
      final rows = await _db
          .from('events')
          .select(cols)
          .eq('archived', false)
          .order('starts_at');
      return [for (final r in rows) eventFromRow(r)];
    }
  }

  @override
  Future<List<(Event, DateTime)>> fetchTrash() async {
    try {
      final rows = await _db
          .from('events')
          .select('*, budget_lines(*), expenses(*), tasks(*), guests(*)')
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);
      return [
        for (final r in rows)
          (
            eventFromRow(r),
            DateTime.parse(r['deleted_at'] as String).toLocal(),
          ),
      ];
    } on PostgrestException {
      return const [];
    }
  }

  @override
  Future<void> trashEvent(String eventId, DateTime at) => _db
      .from('events')
      .update({'deleted_at': at.toUtc().toIso8601String()})
      .eq('id', eventId);

  @override
  Future<void> restoreEvent(String eventId) =>
      _db.from('events').update({'deleted_at': null}).eq('id', eventId);

  @override
  Future<void> deleteEvent(String eventId) =>
      _db.from('events').delete().eq('id', eventId);

  /// Événement à partir d'une ligne de la base (avec ses postes, dépenses,
  /// tâches et réponses des invités).
  @visibleForTesting
  Event eventFromRow(Map<String, dynamic> r) {
    final category = _enum(EventCategory.values, r['category'])!;
    final guests = (r['guests'] as List).cast<Map<String, dynamic>>();
    final expected = (r['guests_expected'] as num?)?.toInt() ?? 0;
    return Event(
      id: r['id'] as String,
      name: r['name'] as String,
      subtitle: r['subtitle'] as String?,
      category: category,
      subcategories: [...?(r['subcategories'] as List?)?.cast<String>()],
      date: DateTime.parse(r['starts_at'] as String).toLocal(),
      venue: (r['place'] as String?) ?? '',
      city: (r['city'] as String?) ?? '',
      cover: (r['cover_url'] as String?) ?? EventTemplates.cover(category),
      targetBudget: (r['budget_target'] as num?)?.toInt() ?? 0,
      budget: [
        for (final l
            in (r['budget_lines'] as List).cast<Map<String, dynamic>>())
          if (_enum(BudgetCategory.values, l['category']) case final c?)
            BudgetLine(
              category: c,
              estimated: (l['planned'] as num).toInt(),
              committed: (l['committed'] as num).toInt(),
              paid: (l['paid'] as num?)?.toInt() ?? 0,
              note: l['note'] as String?,
            ),
      ],
      expenses: [
        for (final x in (r['expenses'] as List).cast<Map<String, dynamic>>())
          if (_enum(BudgetCategory.values, x['category']) case final c?)
            Expense(
              id: (x['receipt_ref'] as String?) ?? x['id'] as String,
              category: c,
              label: x['label'] as String,
              amount: (x['amount'] as num).toInt(),
              date: DateTime.parse(x['paid_at'] as String).toLocal(),
              method: (x['method'] as String?) ?? 'Mobile money',
            ),
      ]..sort((a, b) => b.date.compareTo(a.date)),
      tasks: [
        for (final t in (r['tasks'] as List).cast<Map<String, dynamic>>())
          _task(t),
      ]..sort((a, b) => a.due.compareTo(b.due)),
      vendors: const [],
      team: [_me],
      activity: const [],
      guests: Guests.fromList(
        [for (final g in guests) _guest(g)]
          ..sort((a, b) => a.name.compareTo(b.name)),
        expected: expected,
      ),
    );
  }

  Guest _guest(Map<String, dynamic> g) {
    final added = g['created_at'] as String?;
    return Guest(
      id: g['id'] as String,
      name: g['name'] as String,
      phone: g['phone'] as String?,
      group: g['group_name'] as String?,
      rsvp: _enum(Rsvp.values, g['rsvp']) ?? Rsvp.pending,
      companions: (g['companions'] as num?)?.toInt() ?? 0,
      diet: g['diet'] as String?,
      addedAt: added == null ? null : DateTime.parse(added).toLocal(),
    );
  }

  EventTask _task(Map<String, dynamic> t) {
    final module = _enum(Module.values, t['module']) ?? Module.tasks;
    final due = t['due_at'] as String?;
    return EventTask(
      id: t['id'] as String,
      title: t['title'] as String,
      due: due == null ? DateTime.now() : DateTime.parse(due).toLocal(),
      module: module,
      assigneeId: t['assignee_id'] as String?,
      done: t['done'] as bool,
      urgent: (t['urgent'] as bool?) ?? false,
      durationMin: (t['duration_min'] as num?)?.toInt() ?? 30,
      icon: _moduleIcon(module),
    );
  }

  // ─── Écriture ────────────────────────────────────────────────────────

  @override
  Future<Event> createEvent(Event e) async {
    final id = isServerId(e.id) ? e.id : newUuid();
    final tasks = [
      for (final t in e.tasks)
        EventTask(
          id: isServerId(t.id) ? t.id : newUuid(),
          title: t.title,
          due: t.due,
          module: t.module,
          assigneeId: userId,
          done: t.done,
          urgent: t.urgent,
          durationMin: t.durationMin,
          icon: t.icon,
        ),
    ];
    await _db.from('events').insert({
      'id': id,
      'owner_id': userId,
      'name': e.name,
      'category': e.category.name,
      'subtitle': e.subtitle,
      'subcategories': e.subcategories,
      'starts_at': e.date.toUtc().toIso8601String(),
      'place': e.venue,
      'city': e.city,
      'guests_expected': e.guests.invited,
      'budget_target': e.targetBudget,
      'cover_url': e.cover,
    });
    if (e.budget.isNotEmpty) {
      await _db.from('budget_lines').insert([
        for (final l in e.budget) _line(id, l),
      ]);
    }
    if (tasks.isNotEmpty) {
      await _db.from('tasks').insert([for (final t in tasks) _taskRow(id, t)]);
    }
    return Event(
      id: id,
      name: e.name,
      subtitle: e.subtitle,
      category: e.category,
      subcategories: e.subcategories,
      date: e.date,
      venue: e.venue,
      city: e.city,
      cover: e.cover,
      targetBudget: e.targetBudget,
      budget: e.budget,
      expenses: e.expenses,
      tasks: tasks,
      vendors: e.vendors,
      team: [_me],
      activity: [
        for (final a in e.activity)
          Activity(memberId: userId, text: a.text, at: a.at, module: a.module),
      ],
      guests: e.guests,
      nextPayment: e.nextPayment,
    );
  }

  @override
  Future<void> setTarget(String eventId, int target) =>
      _db.from('events').update({'budget_target': target}).eq('id', eventId);

  @override
  Future<void> saveTask(String eventId, EventTask t) =>
      _db.from('tasks').upsert(_taskRow(eventId, t));

  @override
  Future<void> deleteTask(String taskId) =>
      _db.from('tasks').delete().eq('id', taskId);

  @override
  Future<void> saveLine(String eventId, BudgetLine line) => _db
      .from('budget_lines')
      .upsert(_line(eventId, line), onConflict: 'event_id,category');

  @override
  Future<void> deleteLine(String eventId, BudgetCategory c) => _db
      .from('budget_lines')
      .delete()
      .eq('event_id', eventId)
      .eq('category', c.name);

  @override
  Future<void> addExpense(String eventId, Expense x) =>
      _db.from('expenses').insert({
        'event_id': eventId,
        'category': x.category.name,
        'label': x.label,
        'amount': x.amount,
        'paid_at': x.date.toUtc().toIso8601String(),
        'method': x.method,
        'receipt_ref': x.id,
        'created_by': userId,
      });

  @override
  Future<void> saveGuest(String eventId, Guest g) => _db.from('guests').upsert({
    'id': g.id,
    'event_id': eventId,
    'name': g.name,
    'phone': g.phone,
    'group_name': g.group,
    'rsvp': g.rsvp.name,
    'companions': g.companions,
    'diet': g.diet,
  });

  @override
  Future<void> deleteGuest(String guestId) =>
      _db.from('guests').delete().eq('id', guestId);

  Map<String, dynamic> _line(String eventId, BudgetLine l) => {
    'event_id': eventId,
    'category': l.category.name,
    'label': l.category.name,
    'planned': l.estimated,
    'committed': l.committed,
    'paid': l.paid,
    'note': l.note,
  };

  Map<String, dynamic> _taskRow(String eventId, EventTask t) => {
    'id': t.id,
    'event_id': eventId,
    'title': t.title,
    'due_at': t.due.toUtc().toIso8601String(),
    'done': t.done,
    'module': t.module.name,
    'urgent': t.urgent,
    'duration_min': t.durationMin,
    'assignee_id': t.assigneeId != null && isServerId(t.assigneeId!)
        ? t.assigneeId
        : null,
  };

  static T? _enum<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static IconData _moduleIcon(Module m) => switch (m) {
    Module.budget => AppIcons.wallet,
    Module.tasks => AppIcons.check,
    Module.vendors => AppIcons.vendors,
    Module.team => AppIcons.team,
    Module.guests => AppIcons.guests,
  };
}

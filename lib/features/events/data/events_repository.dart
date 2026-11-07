import '../../../core/models/models.dart';
import 'demo_data.dart';

/// Contrat d'accès aux événements. En démo, les données sont locales et les
/// écritures ne vont nulle part ; avec un compte réel, [SupabaseEventsRepository]
/// lit et enregistre dans la base, sans que les écrans changent.
abstract class EventsRepository {
  const EventsRepository();

  Future<List<Event>> fetchEvents();

  /// Crée l'événement et renvoie sa version enregistrée (identifiants de la
  /// base).
  Future<Event> createEvent(Event e) async => e;

  Future<void> setTarget(String eventId, int target) async {}

  Future<void> saveTask(String eventId, EventTask t) async {}

  Future<void> deleteTask(String taskId) async {}

  Future<void> saveLine(String eventId, BudgetLine line) async {}

  Future<void> deleteLine(String eventId, BudgetCategory c) async {}

  Future<void> addExpense(String eventId, Expense x) async {}

  Future<void> saveGuest(String eventId, Guest g) async {}

  Future<void> deleteGuest(String guestId) async {}

  // ─── Corbeille ───────────────────────────────────────────────────────

  /// Événements mis à la corbeille, avec leur date de suppression.
  Future<List<(Event, DateTime)>> fetchTrash() async => const [];

  Future<void> trashEvent(String eventId, DateTime at) async {}

  Future<void> restoreEvent(String eventId) async {}

  /// Suppression définitive (depuis la corbeille uniquement).
  Future<void> deleteEvent(String eventId) async {}
}

class DemoEventsRepository extends EventsRepository {
  const DemoEventsRepository({this.latency = Duration.zero});

  final Duration latency;

  @override
  Future<List<Event>> fetchEvents() async {
    await Future<void>.delayed(latency);
    return DemoData.events();
  }
}

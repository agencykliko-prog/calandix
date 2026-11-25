import 'dart:typed_data';

import 'package:eventa/core/models/models.dart';
import 'package:eventa/features/events/data/demo_data.dart';
import 'package:eventa/features/events/data/events_remote.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/features/events/presentation/widgets/event_cover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = '11111111-2222-4333-8444-555555555555';
const _other = '99999999-2222-4333-8444-555555555555';

Map<String, dynamic> _row({String? owner, List<Object>? members}) => {
  'id': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
  'owner_id': owner,
  'name': 'Test',
  'category': 'wedding',
  'starts_at': '2027-02-14T15:00:00Z',
  'cover_url': 'https://exemple.test/couverture.jpg',
  'budget_lines': const [],
  'expenses': const [],
  'tasks': const [],
  'guests': const [],
  'event_members': ?members,
};

void main() {
  test('la couverture choisie remplace l’ancienne (démo)', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final events = await c.read(eventsProvider.future);
    final id = events.first.id;
    const asset = 'assets/images/v/venue_1.jpg';

    await c.read(eventsProvider.notifier).setCover(id, asset: asset);
    expect(c.read(eventProvider(id)).value!.cover, asset);

    // Photo importée : gardée sur l'appareil en démo.
    final bytes = Uint8List.fromList([1, 2, 3]);
    await c.read(eventsProvider.notifier).setCover(id, bytes: bytes);
    final cover = c.read(eventProvider(id)).value!.cover;
    expect(cover, startsWith('data:image/jpeg'));
    expect(UriData.parse(cover).contentAsBytes(), bytes);
  });

  test('la démo laisse l’organisateur changer la couverture', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final events = await c.read(eventsProvider.future);
    expect(c.read(canEditEventProvider(events.first.id)), isTrue);
  });

  test('les lecteurs ne peuvent pas modifier, les éditeurs si', () {
    final e = DemoData.wedding();
    expect(e.canEdit('awa'), isTrue); // propriétaire
    expect(e.canEdit('kouassi'), isTrue); // admin
    expect(e.canEdit('fatou'), isTrue); // éditeur
    expect(e.canEdit('mariam'), isFalse); // lecteur
    expect(e.canEdit('inconnu'), isFalse);
  });

  test('le rôle du compte vient de l’équipe de l’événement', () {
    const repo = SupabaseEventsRepository(userId: _me, userName: 'Awa');
    TeamRole role(Map<String, dynamic> r) =>
        repo.eventFromRow(r).team.single.role;

    expect(role(_row(owner: _me)), TeamRole.owner);
    expect(
      role(
        _row(
          owner: _other,
          members: [
            {'user_id': _me, 'role': 'editor'},
          ],
        ),
      ),
      TeamRole.editor,
    );
    expect(
      role(
        _row(
          owner: _other,
          members: [
            {'user_id': _me, 'role': 'viewer'},
          ],
        ),
      ),
      TeamRole.viewer,
    );
    expect(role(_row(owner: _other, members: [])), TeamRole.viewer);
    expect(
      repo.eventFromRow(_row(owner: _me)).cover,
      'https://exemple.test/couverture.jpg',
    );
  });

  test('la couverture de la famille est proposée en premier', () {
    final covers = suggestedCovers(EventCategory.birthday);
    expect(covers.first, 'assets/images/cover_birthday.jpg');
    expect(covers.toSet().length, covers.length);
  });
}

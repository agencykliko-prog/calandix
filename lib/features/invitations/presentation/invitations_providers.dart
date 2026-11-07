import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';

// ─── Invitation numérique ───────────────────────────────────────────────

/// Les trois mises en page proposées pour l'invitation.
enum InvitationStyle {
  elegant('Élégante'),
  festive('Festive'),
  minimal('Épurée');

  const InvitationStyle(this._label);
  final String _label;
  String get label => _label.tr;
}

/// Contenu de l'invitation d'un événement.
@immutable
class InvitationDesign {
  const InvitationDesign({
    this.style = InvitationStyle.elegant,
    this.title,
    this.message,
    this.dressCode = '',
    this.rsvpBefore,
    this.withQr = true,
    this.maxCompanions = 2,
  });

  /// Accompagnants qu'un invité peut déclarer lui-même en répondant.
  final int maxCompanions;

  final InvitationStyle style;

  /// Titre affiché ; null : le nom de l'événement.
  final String? title;

  /// Mot d'accueil ; null : texte proposé par défaut.
  final String? message;
  final String dressCode;

  /// Date limite de réponse ; null : 14 jours avant l'événement.
  final DateTime? rsvpBefore;

  /// Chaque invité reçoit un QR code d'entrée personnel.
  final bool withQr;

  String titleFor(Event e) =>
      (title == null || title!.trim().isEmpty) ? e.name : title!.trim();

  String messageFor(Event e) => (message == null || message!.trim().isEmpty)
      ? 'Nous serions heureux de vous compter parmi nous pour célébrer ce moment.'
            .tr
      : message!.trim();

  DateTime deadlineFor(Event e) =>
      rsvpBefore ?? e.date.subtract(const Duration(days: 14));

  InvitationDesign copyWith({
    InvitationStyle? style,
    String? title,
    String? message,
    String? dressCode,
    DateTime? rsvpBefore,
    bool? withQr,
    int? maxCompanions,
  }) => InvitationDesign(
    maxCompanions: maxCompanions ?? this.maxCompanions,
    style: style ?? this.style,
    title: title ?? this.title,
    message: message ?? this.message,
    dressCode: dressCode ?? this.dressCode,
    rsvpBefore: rsvpBefore ?? this.rsvpBefore,
    withQr: withQr ?? this.withQr,
  );
}

class InvitationNotifier extends Notifier<Map<String, InvitationDesign>> {
  @override
  Map<String, InvitationDesign> build() => const {};

  InvitationDesign of(String eventId) =>
      state[eventId] ?? const InvitationDesign();

  void save(String eventId, InvitationDesign d) =>
      state = {...state, eventId: d};
}

final invitationProvider =
    NotifierProvider<InvitationNotifier, Map<String, InvitationDesign>>(
      InvitationNotifier.new,
    );

/// Code d'entrée personnel d'un invité : stable, court, lisible à voix
/// haute (sans 0/O ni 1/I). Il figure dans le QR code de son invitation.
String guestCode(String eventId, String guestId) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  var h = 0x811C9DC5;
  for (final c in '$eventId/$guestId'.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  final b = StringBuffer('CX-');
  for (var i = 0; i < 6; i++) {
    if (i == 3) b.write('-');
    b.write(alphabet[h % alphabet.length]);
    h = (h ~/ alphabet.length) ^ (i * 0x9E3779B1 & 0xFFFF);
  }
  return b.toString();
}

/// Contenu du QR code d'entrée.
String guestQrData(String eventId, String guestId) =>
    'calandix:entree:$eventId:${guestCode(eventId, guestId)}';

// ─── Contrôle des entrées ───────────────────────────────────────────────

/// Résultat d'un contrôle à l'entrée.
enum CheckResult { admitted, already, notConfirmed, unknown }

@immutable
class CheckIn {
  const CheckIn(this.guestId, this.at, this.people);
  final String guestId;
  final DateTime at;

  /// L'invité et ses accompagnants entrés avec lui.
  final int people;
}

/// Entrées enregistrées, par événement puis par invité.
class CheckInNotifier extends Notifier<Map<String, Map<String, CheckIn>>> {
  @override
  Map<String, Map<String, CheckIn>> build() => const {};

  Map<String, CheckIn> of(String eventId) => state[eventId] ?? const {};

  /// Contrôle un invité : seul un invité confirmé entre, et une seule fois.
  (CheckResult, Guest?) check(Event e, String raw) {
    final code = raw.trim().toUpperCase().split(':').last;
    Guest? g;
    for (final x in e.guests.list) {
      if (guestCode(e.id, x.id) == code || x.id == raw.trim()) {
        g = x;
        break;
      }
    }
    if (g == null) return (CheckResult.unknown, null);
    if (of(e.id).containsKey(g.id)) return (CheckResult.already, g);
    if (g.rsvp != Rsvp.yes) return (CheckResult.notConfirmed, g);
    state = {
      ...state,
      e.id: {
        ...of(e.id),
        g.id: CheckIn(g.id, DateTime.now(), 1 + g.companions),
      },
    };
    return (CheckResult.admitted, g);
  }

  void undo(String eventId, String guestId) {
    final m = {...of(eventId)}..remove(guestId);
    state = {...state, eventId: m};
  }
}

final checkInProvider =
    NotifierProvider<CheckInNotifier, Map<String, Map<String, CheckIn>>>(
      CheckInNotifier.new,
    );

// ─── Album privé ────────────────────────────────────────────────────────

/// Qui peut voir l'album.
enum AlbumAudience {
  team('Équipe d’organisation'),
  confirmed('Invités confirmés'),
  link('Toute personne ayant le lien privé');

  const AlbumAudience(this._label);
  final String _label;
  String get label => _label.tr;
}

@immutable
class AlbumPhoto {
  const AlbumPhoto({
    required this.id,
    required this.author,
    required this.at,
    this.asset,
    this.bytes,
    this.video = false,
    this.name,
  });

  final String id;
  final String author;
  final DateTime at;

  /// Vidéo (octets du fichier) plutôt que photo.
  final bool video;

  /// Nom du fichier d'origine (vidéos).
  final String? name;

  /// Image de démonstration (asset) ou photo ajoutée (octets).
  final String? asset;
  final Uint8List? bytes;
}

@immutable
class Album {
  const Album({
    this.photos = const [],
    this.audience = AlbumAudience.confirmed,
    this.guestsCanAdd = true,
    this.guestsCanDownload = false,
  });

  final List<AlbumPhoto> photos;
  final AlbumAudience audience;
  final bool guestsCanAdd;
  final bool guestsCanDownload;

  Album copyWith({
    List<AlbumPhoto>? photos,
    AlbumAudience? audience,
    bool? guestsCanAdd,
    bool? guestsCanDownload,
  }) => Album(
    photos: photos ?? this.photos,
    audience: audience ?? this.audience,
    guestsCanAdd: guestsCanAdd ?? this.guestsCanAdd,
    guestsCanDownload: guestsCanDownload ?? this.guestsCanDownload,
  );
}

class AlbumNotifier extends Notifier<Map<String, Album>> {
  @override
  Map<String, Album> build() => const {};

  /// Album de l'événement ; un événement passé de la démo montre des
  /// photos d'exemple.
  Album of(Event e, {required bool demo}) {
    final a = state[e.id];
    if (a != null) return a;
    if (!demo) return const Album();
    return Album(
      photos: [
        for (final (i, p) in _demoPhotos.indexed)
          AlbumPhoto(
            id: 'demo-$i',
            author: _demoAuthors[i % _demoAuthors.length],
            at: e.date.add(Duration(minutes: 40 * i)),
            asset: p,
          ),
      ],
    );
  }

  void _set(String id, Album a) => state = {...state, id: a};

  void add(
    Event e,
    Uint8List bytes,
    String author, {
    required bool demo,
    bool video = false,
    String? name,
  }) {
    final a = of(e, demo: demo);
    _set(
      e.id,
      a.copyWith(
        photos: [
          AlbumPhoto(
            id: 'p${DateTime.now().microsecondsSinceEpoch}',
            author: author,
            at: DateTime.now(),
            bytes: bytes,
            video: video,
            name: name,
          ),
          ...a.photos,
        ],
      ),
    );
  }

  void remove(Event e, String photoId, {required bool demo}) {
    final a = of(e, demo: demo);
    _set(
      e.id,
      a.copyWith(
        photos: [
          for (final p in a.photos)
            if (p.id != photoId) p,
        ],
      ),
    );
  }

  void settings(
    Event e, {
    required bool demo,
    AlbumAudience? audience,
    bool? guestsCanAdd,
    bool? guestsCanDownload,
  }) => _set(
    e.id,
    of(e, demo: demo).copyWith(
      audience: audience,
      guestsCanAdd: guestsCanAdd,
      guestsCanDownload: guestsCanDownload,
    ),
  );
}

const _demoPhotos = [
  'assets/images/cover_wedding.jpg',
  'assets/images/vendor_deco.jpg',
  'assets/images/onboarding_wedding.jpg',
  'assets/images/vendor_traiteur.jpg',
  'assets/images/onboarding_confetti.jpg',
  'assets/images/vendor_dj.jpg',
  'assets/images/cover_birthday.jpg',
  'assets/images/onboarding_balloons.jpg',
];
const _demoAuthors = ['Awa', 'Kouassi', 'Mariam', 'Yao'];

final albumProvider = NotifierProvider<AlbumNotifier, Map<String, Album>>(
  AlbumNotifier.new,
);

// ─── Rappels automatiques ───────────────────────────────────────────────

/// Les rappels que Calandix peut envoyer à la place de l'organisateur.
enum AutoReminder {
  pendingGuests(
    'Invités sans réponse',
    'Relance des invités qui n’ont pas encore répondu, 7 jours après l’invitation.',
  ),
  deadline(
    'Date limite de réponse',
    'Rappel aux invités 3 jours avant la date limite de réponse.',
  ),
  organizer(
    'Vos échéances',
    'Rappel la veille de chaque tâche et de chaque paiement à venir.',
  ),
  collaborators(
    'Tâches des collaborateurs',
    'Rappel à chaque collaborateur pour les tâches qui lui sont attribuées.',
  );

  const AutoReminder(this._title, this._caption);
  final String _title;
  final String _caption;
  String get title => _title.tr;
  String get caption => _caption.tr;
}

/// Canal d'envoi des rappels automatiques.
enum ReminderChannel {
  whatsapp('WhatsApp'),
  sms('SMS');

  const ReminderChannel(this.label);
  final String label;
}

@immutable
class ReminderSettings {
  const ReminderSettings({
    this.enabled = const {},
    this.channel = ReminderChannel.whatsapp,
    this.used = 0,
  });

  final Set<AutoReminder> enabled;
  final ReminderChannel channel;

  /// Messages déjà envoyés ce mois-ci.
  final int used;

  ReminderSettings copyWith({
    Set<AutoReminder>? enabled,
    ReminderChannel? channel,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    channel: channel ?? this.channel,
    used: used,
  );
}

class ReminderNotifier extends Notifier<Map<String, ReminderSettings>> {
  @override
  Map<String, ReminderSettings> build() => const {};

  ReminderSettings of(String eventId) =>
      state[eventId] ?? const ReminderSettings();

  void toggle(String eventId, AutoReminder r) {
    final s = of(eventId);
    final on = {...s.enabled};
    on.contains(r) ? on.remove(r) : on.add(r);
    state = {...state, eventId: s.copyWith(enabled: on)};
  }

  void channel(String eventId, ReminderChannel c) =>
      state = {...state, eventId: of(eventId).copyWith(channel: c)};
}

final reminderProvider =
    NotifierProvider<ReminderNotifier, Map<String, ReminderSettings>>(
      ReminderNotifier.new,
    );

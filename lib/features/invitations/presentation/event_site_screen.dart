import 'package:flutter/material.dart';

import '../../events/presentation/event_trash.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/mobile/open_link_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/open_link_web.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/presentation/events_providers.dart';
import 'invitations_providers.dart';

// ─── Modèle ─────────────────────────────────────────────────────────────

@immutable
class SiteStep {
  const SiteStep(this.time, this.title);
  final String time;
  final String title;
}

@immutable
class SiteStay {
  const SiteStay(this.name, this.note, {this.phone});
  final String name;
  final String note;
  final String? phone;
}

@immutable
class SiteFaq {
  const SiteFaq(this.question, this.answer);
  final String question;
  final String answer;
}

/// Page publique de l'événement : programme, lieu et itinéraire,
/// hébergements, questions des invités.
@immutable
class EventSite {
  const EventSite({
    this.published = false,
    this.intro = '',
    this.address = '',
    this.access = '',
    this.program = const [],
    this.stays = const [],
    this.faq = const [],
  });

  final bool published;
  final String intro;

  /// Adresse précise du lieu (vide : lieu et ville de l'événement).
  final String address;

  /// Accès : parking, entrée, repères.
  final String access;
  final List<SiteStep> program;
  final List<SiteStay> stays;
  final List<SiteFaq> faq;

  EventSite copyWith({
    bool? published,
    String? intro,
    String? address,
    String? access,
    List<SiteStep>? program,
    List<SiteStay>? stays,
    List<SiteFaq>? faq,
  }) => EventSite(
    published: published ?? this.published,
    intro: intro ?? this.intro,
    address: address ?? this.address,
    access: access ?? this.access,
    program: program ?? this.program,
    stays: stays ?? this.stays,
    faq: faq ?? this.faq,
  );

  String addressFor(Event e) => address.trim().isNotEmpty
      ? address.trim()
      : [e.venue.trim(), e.city.trim()].where((s) => s.isNotEmpty).join(', ');
}

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Proposition de départ, construite à partir de l'événement : un
/// déroulé type à adapter, et les réponses déjà connues (tenue, date limite,
/// accompagnants).
EventSite defaultSite(Event e, InvitationDesign d) {
  final start = e.date;
  return EventSite(
    intro: d.messageFor(e),
    program: [
      SiteStep(
        _hm(start.subtract(const Duration(minutes: 30))),
        'Accueil des invités'.tr,
      ),
      SiteStep(_hm(start), 'Cérémonie'.tr),
      SiteStep(_hm(start.add(const Duration(hours: 2))), 'Cocktail'.tr),
      SiteStep(_hm(start.add(const Duration(hours: 3))), 'Dîner'.tr),
      SiteStep(_hm(start.add(const Duration(hours: 5))), 'Soirée dansante'.tr),
    ],
    faq: [
      if (d.dressCode.trim().isNotEmpty)
        SiteFaq('Quel est le code vestimentaire ?'.tr, d.dressCode.trim()),
      SiteFaq(
        'Jusqu’à quand puis-je répondre ?'.tr,
        'Avant le {0}, depuis votre lien d’invitation.'.trf([
          mediumDate(d.deadlineFor(e)),
        ]),
      ),
      SiteFaq(
        'Puis-je venir accompagné ?'.tr,
        d.maxCompanions == 0
            ? 'L’invitation est personnelle.'.tr
            : 'Oui, jusqu’à {0} personnes : indiquez-les en répondant.'.trf([
                d.maxCompanions,
              ]),
      ),
    ],
  );
}

class EventSiteNotifier extends Notifier<Map<String, EventSite>> {
  @override
  Map<String, EventSite> build() => const {};

  EventSite of(Event e) =>
      state[e.id] ??
      defaultSite(
        e,
        ref.read(invitationProvider)[e.id] ?? const InvitationDesign(),
      );

  void save(String eventId, EventSite s) => state = {...state, eventId: s};
}

final eventSiteProvider =
    NotifierProvider<EventSiteNotifier, Map<String, EventSite>>(
      EventSiteNotifier.new,
    );

String sitePath(String eventId) => '/e/$eventId';
String siteLink(String eventId) => 'https://calandix.ci${sitePath(eventId)}';

String directionsUrl(String address) =>
    'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}';

// ─── Édition (organisateur) ─────────────────────────────────────────────

class EventSiteEditor extends ConsumerWidget {
  const EventSiteEditor({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventProvider(id));
    ref.watch(eventSiteProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Page de l’événement'.tr)),
      body: async.when(
        loading: () => const Center(child: MascotLoader.party()),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
        data: (e) => e == null ? MissingEvent(id: id) : _Editor(event: e),
      ),
    );
  }
}

class _Editor extends ConsumerWidget {
  const _Editor({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final n = ref.read(eventSiteProvider.notifier);
    final s = n.of(e);
    void save(EventSite x) => n.save(e.id, x);

    Future<void> text(
      String title,
      String value,
      void Function(String) done, {
      int lines = 1,
    }) async {
      final c = TextEditingController(text: value);
      final r = await showEventaSheet<String>(
        context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: ctx.text.headlineSmall),
              const SizedBox(height: 12),
              AppField(
                label: title,
                controller: c,
                maxLines: lines,
                autofocus: true,
              ),
              const SizedBox(height: 14),
              PillButton(
                label: 'Enregistrer'.tr,
                tone: ButtonTone.dark,
                onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
              ),
            ],
          ),
        ),
      );
      if (r != null) done(r);
    }

    Future<(String, String)?> pair(String title, String a, String b) async {
      final x = TextEditingController();
      final y = TextEditingController();
      return showEventaSheet<(String, String)>(
        context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: ctx.text.headlineSmall),
              const SizedBox(height: 12),
              AppField(label: a, controller: x, autofocus: true),
              const SizedBox(height: 10),
              AppField(label: b, controller: y, maxLines: 3),
              const SizedBox(height: 14),
              PillButton(
                label: 'Ajouter'.tr,
                tone: ButtonTone.dark,
                onPressed: () {
                  if (x.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop((x.text.trim(), y.text.trim()));
                },
              ),
            ],
          ),
        ),
      );
    }

    Widget removable(String title, String caption, VoidCallback onRemove) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    if (caption.isNotEmpty)
                      Text(caption, style: context.text.bodySmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Retirer'.tr,
                icon: const Icon(AppIcons.trash, size: 18),
                onPressed: onRemove,
              ),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: s.published,
                  onChanged: (v) => save(s.copyWith(published: v)),
                  title: Text(
                    s.published ? 'Page publiée'.tr : 'Page non publiée'.tr,
                    style: context.text.titleSmall,
                  ),
                  subtitle: Text(
                    'Les invités l’ouvrent depuis leur invitation.'.tr,
                    style: context.text.bodySmall,
                  ),
                ),
              ),
              SelectableText(siteLink(e.id), style: context.text.bodySmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Copier le lien'.tr,
                      icon: AppIcons.link,
                      tone: ButtonTone.ghost,
                      height: 44,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: siteLink(e.id)),
                        );
                        if (context.mounted) toast(context, 'Lien copié'.tr);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PillButton(
                      label: 'Aperçu'.tr,
                      icon: AppIcons.eye,
                      height: 44,
                      onPressed: () => context.push(sitePath(e.id)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionTitle(
          'Mot d’accueil'.tr,
          action: 'Modifier'.tr,
          onAction: () => text(
            'Mot d’accueil'.tr,
            s.intro,
            (v) => save(s.copyWith(intro: v)),
            lines: 4,
          ),
        ),
        Text(s.intro, style: context.text.bodyMedium),
        SectionTitle(
          'Programme'.tr,
          action: 'Ajouter'.tr,
          onAction: () async {
            final r = await pair('Nouvelle étape'.tr, 'Heure'.tr, 'Moment'.tr);
            if (r == null) return;
            final list = [...s.program, SiteStep(r.$1, r.$2)]
              ..sort((a, b) => a.time.compareTo(b.time));
            save(s.copyWith(program: list));
          },
        ),
        for (final p in s.program)
          removable(
            '${p.time} · ${p.title}',
            '',
            () => save(s.copyWith(program: [...s.program]..remove(p))),
          ),
        SectionTitle(
          'Lieu et itinéraire'.tr,
          action: 'Modifier'.tr,
          onAction: () => text(
            'Adresse précise'.tr,
            s.addressFor(e),
            (v) => save(s.copyWith(address: v)),
          ),
        ),
        Text(s.addressFor(e), style: context.text.titleSmall),
        const SizedBox(height: 6),
        Pressable(
          onTap: () => text(
            'Accès et stationnement'.tr,
            s.access,
            (v) => save(s.copyWith(access: v)),
            lines: 3,
          ),
          child: Text(
            s.access.isEmpty
                ? 'Ajouter les indications d’accès (parking, entrée, repères)'
                      .tr
                : s.access,
            style: context.text.bodySmall?.copyWith(
              color: s.access.isEmpty ? Confetti.coralDeep : null,
            ),
          ),
        ),
        SectionTitle(
          'Hébergements'.tr,
          action: 'Ajouter'.tr,
          onAction: () async {
            final r = await pair(
              'Hébergement conseillé'.tr,
              'Nom'.tr,
              'Distance, tarif négocié, contact'.tr,
            );
            if (r == null) return;
            save(s.copyWith(stays: [...s.stays, SiteStay(r.$1, r.$2)]));
          },
        ),
        if (s.stays.isEmpty)
          Text(
            'Conseillez des hôtels proches à vos invités qui viennent de loin.'
                .tr,
            style: context.text.bodySmall,
          ),
        for (final x in s.stays)
          removable(
            x.name,
            x.note,
            () => save(s.copyWith(stays: [...s.stays]..remove(x))),
          ),
        SectionTitle(
          'Questions des invités'.tr,
          action: 'Ajouter'.tr,
          onAction: () async {
            final r = await pair(
              'Nouvelle question'.tr,
              'Question'.tr,
              'Réponse'.tr,
            );
            if (r == null) return;
            save(s.copyWith(faq: [...s.faq, SiteFaq(r.$1, r.$2)]));
          },
        ),
        for (final f in s.faq)
          removable(
            f.question,
            f.answer,
            () => save(s.copyWith(faq: [...s.faq]..remove(f))),
          ),
      ],
    );
  }
}

// ─── Page publique (invités) ────────────────────────────────────────────

class EventSitePage extends ConsumerWidget {
  const EventSitePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).value ?? const <Event>[];
    final e = events.where((x) => x.id == id).firstOrNull;
    ref.watch(eventSiteProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(e?.name ?? 'Événement'.tr),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Retour'.tr,
                icon: const Icon(AppIcons.back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: e == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Cette page n’existe pas ou n’est plus en ligne.'.tr,
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge,
                ),
              ),
            )
          : _Public(event: e),
    );
  }
}

class _Public extends ConsumerWidget {
  const _Public({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = event;
    final s = ref.read(eventSiteProvider.notifier).of(e);
    final address = s.addressFor(e);
    final hue = e.category.hue;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (!s.published)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  color: Confetti.mangoTint,
                  border: false,
                  child: Text(
                    'Aperçu : la page n’est pas encore publiée.'.tr,
                    style: context.text.bodySmall,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: hue.tint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: context.text.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    longDate(e.date),
                    style: context.text.titleSmall?.copyWith(color: hue.text),
                  ),
                  if (s.intro.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(s.intro, style: context.text.bodyMedium),
                  ],
                ],
              ),
            ),
            if (s.program.isNotEmpty) ...[
              SectionTitle('Programme'.tr),
              Panel(
                child: Column(
                  children: [
                    for (final p in s.program)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                p.time,
                                style: context.text.titleSmall?.copyWith(
                                  color: hue.text,
                                ),
                              ),
                            ),
                            Expanded(child: Text(p.title)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (address.isNotEmpty) ...[
              SectionTitle('Lieu'.tr),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(AppIcons.place, size: 18, color: hue.text),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(address, style: context.text.titleSmall),
                        ),
                      ],
                    ),
                    if (s.access.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(s.access, style: context.text.bodySmall),
                    ],
                    const SizedBox(height: 12),
                    PillButton(
                      label: 'Itinéraire'.tr,
                      icon: AppIcons.place,
                      height: 44,
                      onPressed: () => openLink(directionsUrl(address)),
                    ),
                  ],
                ),
              ),
            ],
            if (s.stays.isNotEmpty) ...[
              SectionTitle('Où dormir'.tr),
              for (final x in s.stays)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(x.name, style: context.text.titleSmall),
                        if (x.note.isNotEmpty)
                          Text(x.note, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ),
            ],
            if (s.faq.isNotEmpty) ...[
              SectionTitle('Questions fréquentes'.tr),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final f in s.faq)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        shape: const Border(),
                        title: Text(f.question, style: context.text.titleSmall),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                f.answer,
                                style: context.text.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => context.go(Routes.onboarding),
                child: Text('Organisé avec Calandix'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

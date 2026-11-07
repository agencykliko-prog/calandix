import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/app_router.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../events/presentation/events_providers.dart';
import '../../../platform/mobile/download_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/download_web.dart';
import 'invitations_providers.dart';

/// Fichiers reconnus comme vidéos.
bool isVideoName(String name) => RegExp(
  r'\.(mp4|mov|m4v|webm|3gp|avi)$',
  caseSensitive: false,
).hasMatch(name);

/// Album privé de l'événement : photos et souvenirs réunis, visibles selon
/// les permissions choisies par l'organisateur.
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key, required this.id, this.guest = false});

  final String id;

  /// Vue de l'album telle qu'un invité la voit, selon les réglages.
  final bool guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventProvider(id));
    ref.watch(albumProvider);
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: RoundIconButton(
              icon: AppIcons.back,
              tooltip: 'Retour',
              onTap: () => context.pop(),
            ),
          ),
        ),
        leadingWidth: 64,
        title: Text(guest ? 'Album · vue invité'.tr : 'Album privé'.tr),
      ),
      body: async.when(
        loading: () => const Center(child: MascotLoader.party()),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(eventsProvider)),
        data: (e) =>
            e == null ? const SizedBox() : _AlbumBody(event: e, guest: guest),
      ),
    );
  }
}

class _AlbumBody extends ConsumerWidget {
  const _AlbumBody({required this.event, required this.guest});

  final Event event;
  final bool guest;

  Future<void> _add(BuildContext context, WidgetRef ref, bool demo) async {
    final files = await ImagePicker().pickMultipleMedia(
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (files.isEmpty) return;
    final author = guest
        ? 'Un invité'.tr
        : ref.read(sessionProvider)?.name.split(' ').first ?? 'Moi';
    var videos = 0;
    for (final f in files) {
      final bytes = await f.readAsBytes();
      final video =
          (f.mimeType?.startsWith('video/') ?? false) || isVideoName(f.name);
      if (video) videos++;
      ref
          .read(albumProvider.notifier)
          .add(event, bytes, author, demo: demo, video: video, name: f.name);
    }
    if (context.mounted) {
      toast(
        context,
        '{0} photo(s) et {1} vidéo(s) ajoutée(s) à l’album'.trf([
          files.length - videos,
          videos,
        ]),
        icon: AppIcons.checkCircle,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = !ref.watch(liveSessionProvider);
    final n = ref.read(albumProvider.notifier);
    final a = n.of(event, demo: demo);
    if (guest) return _guestView(context, ref, a, demo);
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 640 ? 4 : 3;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverList.list(
                children: [
                  Text(event.name, style: context.text.bodySmall),
                  const SizedBox(height: 12),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconTile(
                              icon: AppIcons.lock,
                              hue: Hue.violet,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Qui peut voir l’album'.tr,
                                style: context.text.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final x in AlbumAudience.values)
                              ChoiceChip(
                                label: Text(x.label),
                                selected: a.audience == x,
                                onSelected: (_) =>
                                    n.settings(event, demo: demo, audience: x),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: a.guestsCanAdd,
                          onChanged: (v) =>
                              n.settings(event, demo: demo, guestsCanAdd: v),
                          title: Text(
                            'Les invités peuvent ajouter leurs photos'.tr,
                            style: context.text.bodyMedium,
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: a.guestsCanDownload,
                          onChanged: (v) => n.settings(
                            event,
                            demo: demo,
                            guestsCanDownload: v,
                          ),
                          title: Text(
                            'Les invités peuvent télécharger et partager'.tr,
                            style: context.text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: 'Photos et vidéos'.tr,
                          icon: AppIcons.upload,
                          height: 48,
                          onPressed: () => _add(context, ref, demo),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: AppIcons.eye,
                        tooltip: 'Voir comme un invité'.tr,
                        size: 48,
                        onTap: () => context.push(
                          '${Routes.album(event.id)}?vue=invite',
                        ),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: AppIcons.share,
                        tooltip: 'Inviter à l’album'.tr,
                        size: 48,
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: 'Retrouvez les photos de « {0} » dans l’album privé Calandix. Demandez l’accès à l’organisateur.'
                                  .trf([event.name]),
                            ),
                          );
                          if (context.mounted) {
                            toast(context, 'Message d’invitation copié'.tr);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SectionTitle(_count(a)),
                  const SizedBox(height: 8),
                  if (a.photos.isEmpty)
                    Panel(
                      child: Column(
                        children: [
                          const Mascot(size: 72, mood: MascotMood.happy),
                          const SizedBox(height: 10),
                          Text(
                            'L’album est vide. Ajoutez les premières photos, puis invitez vos proches à partager les leurs.'
                                .tr,
                            textAlign: TextAlign.center,
                            style: context.text.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverGrid.count(
                crossAxisCount: cols,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final p in a.photos)
                    GestureDetector(
                      onTap: () => _open(context, ref, p, demo),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _image(p),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _count(Album a) {
    final v = a.photos.where((p) => p.video).length;
    final p = a.photos.length - v;
    return v == 0
        ? '{0} photos'.trf([p])
        : '{0} photos · {1} vidéos'.trf([p, v]);
  }

  /// Ce que voit un invité : les photos, et seulement les actions que
  /// l'organisateur a autorisées.
  Widget _guestView(BuildContext context, WidgetRef ref, Album a, bool demo) {
    final allowed = a.audience != AlbumAudience.team;
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 640 ? 4 : 3;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverList.list(
                children: [
                  Panel(
                    color: Confetti.violetTint,
                    border: false,
                    child: Text(
                      allowed
                          ? 'Aperçu pour : {0}.'.trf([a.audience.label])
                          : 'L’album est réservé à l’équipe d’organisation : les invités ne le voient pas.'
                                .tr,
                      style: context.text.bodySmall,
                    ),
                  ),
                  if (allowed) ...[
                    const SizedBox(height: 12),
                    Text(event.name, style: context.text.headlineSmall),
                    Text(_count(a), style: context.text.bodySmall),
                    if (a.guestsCanAdd) ...[
                      const SizedBox(height: 12),
                      PillButton(
                        label: 'Partager mes photos et vidéos'.tr,
                        icon: AppIcons.upload,
                        height: 48,
                        onPressed: () => _add(context, ref, demo),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (allowed)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverGrid.count(
                  crossAxisCount: cols,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final p in a.photos)
                      GestureDetector(
                        onTap: () => _open(
                          context,
                          ref,
                          p,
                          demo,
                          asGuest: true,
                          canDownload: a.guestsCanDownload,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _image(p),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _image(AlbumPhoto p, {BoxFit fit = BoxFit.cover}) {
    if (p.video) {
      return Container(
        color: Confetti.night,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                p.name ?? 'Vidéo'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
    return p.bytes != null
        ? Image.memory(p.bytes!, fit: fit)
        : Image.asset(p.asset!, fit: fit, cacheWidth: 600);
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    AlbumPhoto p,
    bool demo, {
    bool asGuest = false,
    bool canDownload = true,
  }) {
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _image(p, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajoutée par {0} · {1}'.trf([p.author, mediumDate(p.at)]),
              style: ctx.text.bodySmall,
            ),
            if (p.video && p.bytes != null) ...[
              const SizedBox(height: 4),
              Text(
                '{0} · {1} Mo'.trf([
                  p.name ?? 'Vidéo'.tr,
                  (p.bytes!.length / 1048576)
                      .toStringAsFixed(1)
                      .replaceAll('.', ','),
                ]),
                style: ctx.text.bodySmall,
              ),
            ],
            if (p.bytes != null && canDownload) ...[
              const SizedBox(height: 10),
              PillButton(
                label: p.video
                    ? 'Télécharger la vidéo'.tr
                    : 'Télécharger la photo'.tr,
                icon: AppIcons.download,
                height: 46,
                onPressed: () async {
                  final ok = await saveBytesFile(
                    p.name ?? (p.video ? 'video.mp4' : 'photo.jpg'),
                    p.bytes!,
                    type: p.video ? 'video/mp4' : 'image/jpeg',
                  );
                  if (!ok && ctx.mounted) {
                    toast(ctx, 'Téléchargement disponible sur le web'.tr);
                  }
                },
              ),
            ],
            if (!asGuest) ...[
              const SizedBox(height: 10),
              PillButton(
                label: 'Retirer de l’album'.tr,
                icon: AppIcons.trash,
                tone: ButtonTone.ghost,
                height: 46,
                onPressed: () {
                  ref
                      .read(albumProvider.notifier)
                      .remove(event, p.id, demo: demo);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

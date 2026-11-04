import 'dart:async';

import 'package:flutter/material.dart';

import 'theme_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/prefs/prefs_provider.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/sound/sounds.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/avatars.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/forms.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/auth/session_provider.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../../core/models/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../export/presentation/export_sheet.dart';
import '../../../ui/widgets/contact_team.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final plan = ref.watch(planProvider);
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            // La mascotte salue depuis le bord de la carte de profil.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 18),
                    child: Text(
                      'Compte'.tr,
                      style: context.text.headlineMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _AccountMascot(creator: p.isCreator),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: RoundIconButton(
                    icon: AppIcons.close,
                    tooltip: 'Fermer'.tr,
                    onTap: () => context.go(Routes.home),
                  ),
                ),
              ],
            ),
            Panel(
              onTap: () => context.push(Routes.editProfile),
              child: Row(
                children: [
                  Avatar(
                    image: p.photoAsset,
                    bytes: p.photoBytes,
                    initials: p.initials,
                    size: 60,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleLarge,
                              ),
                            ),
                            if (!p.isCreator && plan != Plan.free) ...[
                              const SizedBox(width: 8),
                              PremiumBadge(label: plan.label),
                            ],
                          ],
                        ),
                        Text(
                          p.email,
                          style: context.text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${p.phone} · ${p.city}',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(AppIcons.edit, size: 18, color: Confetti.inkMuted),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (p.isCreator)
              NightPanel(
                onTap: () => context.push(Routes.business),
                child: Row(
                  children: [
                    IconTile(icon: AppIcons.briefcase, hue: Hue.gold, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes formules pro'.tr,
                            style: context.text.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Formule {0} · commission {1} %'.trf([
                              ref.watch(proPlanProvider).label,
                              ref.watch(proPlanProvider).commissionPercent,
                            ]),
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevron,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ],
                ),
              )
            else
              NightPanel(
                onTap: () => context.push(Routes.premium),
                child: Row(
                  children: [
                    IconTile(icon: AppIcons.crown, hue: Hue.gold, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan == Plan.free
                                ? 'Passer à Premium'.tr
                                : 'Abonnement {0}'.trf([plan.label]),
                            style: context.text.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            plan == Plan.free
                                ? 'IA, coffre-fort, collaboration · dès 2 900 FCFA/mois'
                                      .tr
                                : '{0} / mois · gérer'.trf([fcfa(plan.price)]),
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevron,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            if (p.isCreator) ...[
              SectionTitle('Visibilité'.tr),
              _Group(
                rows: [
                  _Row(
                    AppIcons.megaphone,
                    'Publicité Premium'.tr,
                    'Sponsor du mois, mise en avant, résultat sponsorisé'.tr,
                    () => context.push(Routes.business),
                  ),
                  _Row(
                    AppIcons.vendors,
                    'Voir ma fiche'.tr,
                    'Telle qu’elle apparaît dans Explorer'.tr,
                    () => context.push(Routes.editProfile),
                  ),
                ],
              ),
            ] else ...[
              SectionTitle('Mon activité'.tr),
              _Group(
                rows: [
                  _Row(
                    AppIcons.calendarCheck,
                    'Mes réservations'.tr,
                    bookings.isEmpty
                        ? 'Aucune réservation en cours'.tr
                        : '{0} en cours'.trf([bookings.length]),
                    () {
                      bookings.isEmpty
                          ? context.go(Routes.explore)
                          : context.push(Routes.booking(bookings.first.id));
                    },
                  ),
                  _Row(
                    AppIcons.lock,
                    'Coffre-fort'.tr,
                    'Contrats, devis, factures, photos'.tr,
                    () => context.push(Routes.vault),
                  ),
                  _Row(
                    AppIcons.download,
                    'Exporter mes données'.tr,
                    'Dépenses, prestataires, paiements (CSV)'.tr,
                    () => _pickEventToExport(context, ref),
                  ),
                ],
              ),
            ],
            SectionTitle('Préférences'.tr),
            const _PrefsGroup(),
            SectionTitle('Couleur du thème'.tr),
            const ThemePicker(),
            SectionTitle('Réglages'.tr),
            _Group(
              rows: [
                _Row(
                  AppIcons.bell,
                  'Notifications'.tr,
                  'Push, e-mail, WhatsApp'.tr,
                  () => _notificationsSheet(context),
                ),
                if (!p.isCreator)
                  _Row(
                    AppIcons.card,
                    'Moyen de paiement par défaut'.tr,
                    'Mobile Money, carte, Apple Pay'.tr,
                    () => _paymentSheet(context),
                  ),
                _Row(
                  AppIcons.shield,
                  'Confidentialité'.tr,
                  'Visibilité du profil et des données'.tr,
                  () => _privacySheet(context, ref),
                ),
                _Row(
                  AppIcons.help,
                  'Aide & support'.tr,
                  'Questions fréquentes, nous contacter'.tr,
                  () => _helpSheet(context),
                ),
              ],
            ),
            const SectionTitle('Calandix'),
            _Group(
              rows: [
                _Row(
                  AppIcons.heart,
                  'À propos de Calandix'.tr,
                  'Vision, mission, valeurs, contact'.tr,
                  () => context.push(Routes.about),
                ),
                _Row(
                  AppIcons.file,
                  'Conditions générales'.tr,
                  'Utilisation, paiements, annulations'.tr,
                  () => context.push(Routes.terms),
                ),
                _Row(
                  AppIcons.scroll,
                  'Politique de confidentialité'.tr,
                  'Vos données et vos droits'.tr,
                  () => context.push(Routes.privacy),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PillButton(
              label: 'Se déconnecter'.tr,
              tone: ButtonTone.ghost,
              icon: AppIcons.signOut,
              onPressed: () {
                ref.read(sessionProvider.notifier).signOut();
                context.go(Routes.onboarding);
              },
            ),
            const SizedBox(height: 28),
            const Center(child: CalandixWordmark(size: 15)),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Le budget parfait pour célébrer · démo'.tr,
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickEventToExport(BuildContext context, WidgetRef ref) async {
    final events = ref.read(eventsProvider).value ?? const <Event>[];
    if (events.isEmpty) return;
    final picked = await showEventaSheet<Event>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text('Quel événement ?'.tr, style: ctx.text.headlineSmall),
          const SizedBox(height: 10),
          for (final e in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  e.cover,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(e.name, style: ctx.text.titleSmall),
              subtitle: Text(mediumDate(e.date), style: ctx.text.bodySmall),
              trailing: const Icon(AppIcons.chevron, size: 15),
              onTap: () => Navigator.of(ctx).pop(e),
            ),
        ],
      ),
    );
    if (picked != null && context.mounted) showExportSheet(context, picked.id);
  }

  void _notificationsSheet(BuildContext context) => showEventaSheet<void>(
    context,
    builder: (_) => _ToggleSheet(
      title: 'Notifications'.tr,
      items: [
        ('Notifications push'.tr, 'Rappels, devis, paiements'.tr, true),
        ('E-mail'.tr, 'Récapitulatif hebdomadaire'.tr, true),
        ('WhatsApp'.tr, 'Rappels importants uniquement'.tr, false),
        ('SMS'.tr, 'Codes et confirmations'.tr, true),
      ],
    ),
  );

  void _privacySheet(BuildContext context, WidgetRef ref) =>
      showEventaSheet<void>(
        context,
        builder: (_) => _ToggleSheet(
          title: 'Confidentialité'.tr,
          // La mesure d'audience suit réellement ce réglage.
          onChanged: (i, v) {
            if (i == 1) ref.read(audienceConsentProvider.notifier).set(v);
          },
          items: [
            ('Profil visible des collaborateurs'.tr, 'Nom et photo'.tr, true),
            (
              'Mesure d’audience anonyme'.tr,
              'Écrans vus, sans identifiant, pour améliorer Calandix'.tr,
              ref.read(audienceConsentProvider),
            ),
            (
              'Afficher mon numéro aux prestataires'.tr,
              'Après une demande de devis'.tr,
              true,
            ),
          ],
        ),
      );

  void _paymentSheet(BuildContext context) {
    var method = PayMethod.wave;
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moyen de paiement par défaut'.tr,
                style: ctx.text.headlineSmall,
              ),
              const SizedBox(height: 14),
              MethodPicker(
                value: method,
                onChanged: (m) => set(() => method = m),
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'Enregistrer'.tr,
                tone: ButtonTone.dark,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  toast(context, '{0} défini par défaut'.trf([method.label]));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _helpSheet(BuildContext context) => showEventaSheet<void>(
    context,
    builder: (ctx) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Aide & support'.tr, style: ctx.text.headlineSmall),
        const SizedBox(height: 8),
        for (final (q, a) in [
          (
            'Mes paiements sont-ils sécurisés ?'.tr,
            'Les fonds sont conservés jusqu’à la validation de la prestation, puis reversés au prestataire.'
                .tr,
          ),
          (
            'Puis-je annuler une réservation ?'.tr,
            'Oui, selon les conditions du devis. L’annulation est gratuite jusqu’à J-30 en général.'
                .tr,
          ),
          (
            'Comment inviter un co-organisateur ?'.tr,
            'Depuis l’événement, touchez l’icône Partager. Deux collaborateurs sont offerts.'
                .tr,
          ),
        ])
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            title: Text(q, style: ctx.text.titleSmall),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(a, style: ctx.text.bodyMedium),
              ),
            ],
          ),
        const SizedBox(height: 10),
        PillButton(
          label: 'Contacter l’équipe'.tr,
          icon: AppIcons.whatsapp,
          tone: ButtonTone.dark,
          onPressed: () {
            Navigator.of(ctx).pop();
            showContactTeam(context);
          },
        ),
      ],
    ),
  );
}

class _Row {
  const _Row(this.icon, this.title, this.caption, this.onTap);
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
}

class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Pressable(
              scale: 0.99,
              onTap: rows[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Icon(rows[i].icon, size: 21, color: Confetti.ink),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].title, style: context.text.titleSmall),
                          Text(rows[i].caption, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevron, size: 15, color: Confetti.inkFaint),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleSheet extends StatefulWidget {
  const _ToggleSheet({
    required this.title,
    required this.items,
    this.onChanged,
  });

  final String title;
  final List<(String, String, bool)> items;

  /// Appelé à chaque bascule (index de la ligne, nouvelle valeur).
  final void Function(int index, bool value)? onChanged;

  @override
  State<_ToggleSheet> createState() => _ToggleSheetState();
}

class _ToggleSheetState extends State<_ToggleSheet> {
  late final _values = [for (final i in widget.items) i.$3];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: context.text.headlineSmall),
          const SizedBox(height: 8),
          for (var i = 0; i < widget.items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.items[i].$1,
                          style: context.text.titleSmall,
                        ),
                        Text(widget.items[i].$2, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: _values[i],
                    onChanged: (v) {
                      setState(() => _values[i] = v);
                      widget.onChanged?.call(i, v);
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FieldLabel('Les préférences sont enregistrées automatiquement.'.tr),
        ],
      ),
    );
  }
}

/// Mascotte du compte : salue à l'arrivée, saute de joie au toucher.
class _AccountMascot extends ConsumerStatefulWidget {
  const _AccountMascot({required this.creator});

  final bool creator;

  @override
  ConsumerState<_AccountMascot> createState() => _AccountMascotState();
}

class _AccountMascotState extends ConsumerState<_AccountMascot> {
  bool _waving = true;

  @override
  void initState() {
    super.initState();
    _stopWaving(1800);
  }

  Timer? _timer;

  void _stopWaving(int ms) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _waving = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 14),
      child: Mascot(
        size: 78,
        color: widget.creator ? MascotColor.creator : MascotColor.organizer,
        waving: _waving,
        legs: false,
        onTap: () {
          ref.read(soundProvider).play(Sfx.success);
          setState(() => _waving = true);
          _stopWaving(1400);
        },
      ),
    );
  }
}

/// Préférences d'affichage : mode sombre, langue, sons.
class _PrefsGroup extends ConsumerWidget {
  const _PrefsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final n = ref.read(prefsProvider.notifier);

    Widget row(IconData icon, String title, String caption, Widget trailing) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 21, color: Confetti.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    Text(caption, style: context.text.bodySmall),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        );

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          row(
            AppIcons.moon,
            'Mode sombre'.tr,
            'Plus doux pour les yeux le soir'.tr,
            Switch(value: prefs.dark, onChanged: n.setDark),
          ),
          const Divider(height: 1),
          row(
            AppIcons.translate,
            'Langue'.tr,
            prefs.language.label,
            _LanguageToggle(value: prefs.language, onChanged: n.setLanguage),
          ),
          const Divider(height: 1),
          row(
            prefs.sounds ? AppIcons.speaker : AppIcons.speakerOff,
            'Sons'.tr,
            'Réservation, paiement, notifications'.tr,
            Switch(
              value: prefs.sounds,
              onChanged: (v) {
                n.setSounds(v);
                if (v) ref.read(soundProvider).play(Sfx.notification);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.value, required this.onChanged});

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Confetti.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in AppLanguage.values)
            Pressable(
              onTap: () => onChanged(l),
              semanticLabel: l.label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: l == value ? Confetti.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  l.code.toUpperCase(),
                  style: context.text.labelMedium?.copyWith(
                    color: l == value ? Confetti.ink : Confetti.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

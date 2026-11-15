import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/brand.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../../ui/widgets/contact_team.dart';

/// Texte bilingue des pages éditoriales (prose longue, hors dictionnaire).
String bi(String fr, String en) => L10n.isEn ? en : fr;

/// À propos de Calandix : vision, mission, valeurs, avantages, histoire, contact.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        AppIcons.eye,
        Hue.lagoon,
        bi('Transparence', 'Transparency'),
        bi(
          'Chaque franc est visible : prévu, engagé, payé, reste. Jamais de frais cachés.',
          'Every franc is visible: planned, committed, paid, remaining. No hidden fees.',
        ),
      ),
      (
        AppIcons.confetti,
        Hue.coral,
        bi('Convivialité', 'Conviviality'),
        bi(
          'Préparer une fête doit rester un plaisir partagé, pas une corvée.',
          'Planning a party should stay a shared pleasure, not a chore.',
        ),
      ),
      (
        AppIcons.shield,
        Hue.violet,
        bi('Fiabilité', 'Reliability'),
        bi(
          'Paiements sécurisés, prestataires vérifiés, rappels au bon moment.',
          'Secure payments, verified vendors, reminders at the right time.',
        ),
      ),
      (
        AppIcons.handHeart,
        Hue.candy,
        bi('Proximité', 'Closeness'),
        bi(
          'Pensé pour la Côte d’Ivoire : FCFA, Mobile Money, WhatsApp et traditions locales.',
          'Designed for Côte d’Ivoire: FCFA, Mobile Money, WhatsApp and local traditions.',
        ),
      ),
      (
        AppIcons.lock,
        Hue.mango,
        bi('Respect des données', 'Respect for data'),
        bi(
          'Vos informations vous appartiennent. Nous n’en vendons aucune.',
          'Your information belongs to you. We never sell any of it.',
        ),
      ),
    ];

    final benefits = [
      (
        bi('Pour les organisateurs', 'For organizers'),
        Hue.coral,
        MascotColor.organizer,
        [
          bi(
            'Un budget lisible en un coup d’œil, mis à jour à chaque paiement',
            'A budget you can read at a glance, updated with every payment',
          ),
          bi(
            'Un rétroplanning prêt selon le type d’événement',
            'A countdown plan ready for your type of event',
          ),
          bi(
            'Des prestataires vérifiés, des devis comparables',
            'Verified vendors and comparable quotes',
          ),
          bi(
            'Un paiement conservé jusqu’à la validation de la prestation',
            'Payment held until you approve the service',
          ),
        ],
      ),
      (
        bi('Pour les invités et participants', 'For guests and attendees'),
        Hue.lagoon,
        MascotColor.creator,
        [
          bi(
            'Une invitation claire, avec réponse en un geste',
            'A clear invitation, with a one-tap reply',
          ),
          bi(
            'Lieu, horaires et plan d’accès toujours à jour',
            'Venue, times and directions always up to date',
          ),
        ],
      ),
      (
        bi('Pour les prestataires et agences', 'For vendors and agencies'),
        Hue.violet,
        MascotColor.creator,
        [
          bi(
            'Des demandes de devis qualifiées, avec budget et date',
            'Qualified quote requests, with budget and date',
          ),
          bi(
            'Un agenda et des paiements centralisés',
            'A centralised calendar and payments',
          ),
          bi(
            'Une vitrine visible des organisateurs qui préparent leur fête',
            'A storefront seen by organizers planning their party',
          ),
        ],
      ),
    ];

    final story = [
      (
        bi('Le constat', 'The starting point'),
        bi(
          'Organiser un mariage, un anniversaire ou un séminaire, c’est jongler entre carnets, messages WhatsApp et avances en espèces. Le budget finit souvent par déraper.',
          'Planning a wedding, a birthday or a seminar means juggling notebooks, WhatsApp messages and cash advances. The budget often ends up slipping.',
        ),
      ),
      (
        bi('L’idée', 'The idea'),
        bi(
          'Mettre le budget au centre : chaque réservation met à jour l’engagé, chaque paiement le payé, en FCFA et en Mobile Money.',
          'Put the budget at the centre: every booking updates what’s committed, every payment what’s paid, in FCFA and Mobile Money.',
        ),
      ),
      (
        bi('Aujourd’hui', 'Today'),
        bi(
          'Une version de démonstration complète, pour les organisateurs comme pour les Creators.',
          'A complete demo version, for organizers and Creators alike.',
        ),
      ),
      (
        bi('Demain', 'Tomorrow'),
        bi(
          'Le lancement officiel en Côte d’Ivoire, avec paiements réels et comptes synchronisés, puis l’Afrique francophone.',
          'The official launch in Côte d’Ivoire, with real payments and synced accounts, then French-speaking Africa.',
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.account),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Entrance(
              child: Column(
                children: [
                  const Mascot(size: 150, waving: true),
                  const SizedBox(height: 14),
                  const CalandixWordmark(size: 26),
                  const SizedBox(height: 6),
                  Text(
                    bi(
                      'Le budget parfait pour célébrer.',
                      'The perfect budget to celebrate.',
                    ),
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Entrance(
              index: 1,
              child: NightPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Kicker(bi('Notre vision', 'Our vision'), dark: true),
                    const SizedBox(height: 8),
                    Text(
                      bi(
                        'Que chaque fête, en Côte d’Ivoire et dans toute l’Afrique francophone, se prépare sereinement, avec un budget maîtrisé du premier devis au dernier pas de danse.',
                        'That every celebration, in Côte d’Ivoire and across French-speaking Africa, is planned with peace of mind and a budget under control, from the first quote to the last dance.',
                      ),
                      style: context.text.titleLarge?.copyWith(
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Entrance(
              index: 2,
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Kicker(bi('Notre mission', 'Our mission')),
                    const SizedBox(height: 8),
                    Text(
                      bi(
                        'Réunir au même endroit le budget, les tâches, les prestataires, les invités et l’équipe d’un événement, avec le FCFA, le Mobile Money et WhatsApp comme réflexes.',
                        'Bring an event’s budget, tasks, vendors, guests and team together in one place, with FCFA, Mobile Money and WhatsApp built in.',
                      ),
                      style: context.text.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            SectionTitle(bi('Nos valeurs', 'Our values')),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (final (i, (icon, hue, title, text))
                      in values.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconTile(icon: icon, hue: hue, size: 40),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: context.text.titleSmall),
                                const SizedBox(height: 2),
                                Text(text, style: context.text.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SectionTitle(
              bi('Ce que Calandix vous apporte', 'What Calandix gives you'),
            ),
            for (final (title, hue, mascot, items) in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: context.text.titleMedium?.copyWith(
                                color: hue.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final it in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        AppIcons.checkCircle,
                                        size: 16,
                                        color: hue.base,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        it,
                                        style: context.text.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Mascot(size: 58, color: mascot, arms: false, legs: false),
                    ],
                  ),
                ),
              ),
            SectionTitle(bi('Notre histoire', 'Our story')),
            Panel(
              child: Column(
                children: [
                  for (final (i, (title, text)) in story.indexed)
                    _StoryStep(
                      title: title,
                      text: text,
                      last: i == story.length - 1,
                      hue: [Hue.coral, Hue.violet, Hue.lagoon, Hue.mango][i],
                    ),
                ],
              ),
            ),
            SectionTitle(bi('Contact et assistance', 'Contact and support')),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _ContactRow(
                    icon: AppIcons.mail,
                    title: EventaContact.email,
                    caption: bi(
                      'Réponse sous 24 h ouvrées',
                      'Reply within 24 business hours',
                    ),
                    onTap: EventaContact.openEmail,
                  ),
                  const Divider(height: 1),
                  _ContactRow(
                    icon: AppIcons.whatsapp,
                    title: bi(
                      'WhatsApp · ${EventaContact.whatsapp}',
                      'WhatsApp · ${EventaContact.whatsapp}',
                    ),
                    caption: bi(
                      'Du lundi au samedi, 8 h – 20 h · 7 j/7 pour Privilège',
                      'Monday to Saturday, 8 am – 8 pm · 7 days for Privilège',
                    ),
                    onTap: EventaContact.openWhatsApp,
                  ),
                  const Divider(height: 1),
                  _ContactRow(
                    icon: AppIcons.phone,
                    title: bi(
                      'Appeler · ${EventaContact.whatsapp}',
                      'Call · ${EventaContact.whatsapp}',
                    ),
                    caption: bi(
                      'Du lundi au samedi, 8 h – 20 h',
                      'Monday to Saturday, 8 am – 8 pm',
                    ),
                    onTap: EventaContact.call,
                  ),
                  const Divider(height: 1),
                  _ContactRow(
                    icon: AppIcons.file,
                    title: bi('Conditions générales', 'Terms and conditions'),
                    caption: bi(
                      'Utilisation, paiements, annulations',
                      'Use, payments, cancellations',
                    ),
                    onTap: () => context.push(Routes.terms),
                  ),
                  const Divider(height: 1),
                  _ContactRow(
                    icon: AppIcons.shield,
                    title: bi('Politique de confidentialité', 'Privacy policy'),
                    caption: bi(
                      'Vos données et vos droits',
                      'Your data and your rights',
                    ),
                    onTap: () => context.push(Routes.privacy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              bi(
                'L’équipe répond sur WhatsApp, par téléphone et par e-mail.',
                'The team answers on WhatsApp, by phone and by email.',
              ),
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text, {this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.labelSmall?.copyWith(
      letterSpacing: 1.1,
      color: dark ? Confetti.gold : Confetti.coralDeep,
    ),
  );
}

class _StoryStep extends StatelessWidget {
  const _StoryStep({
    required this.title,
    required this.text,
    required this.last,
    required this.hue,
  });

  final String title;
  final String text;
  final bool last;
  final Hue hue;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: hue.base,
                  shape: BoxShape.circle,
                  border: Border.all(color: hue.tint, width: 3),
                ),
              ),
              if (!last)
                Expanded(child: Container(width: 2, color: Confetti.line)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  const SizedBox(height: 3),
                  Text(text, style: context.text.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
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
            Icon(AppIcons.chevron, size: 15, color: Confetti.inkFaint),
          ],
        ),
      ),
    );
  }
}

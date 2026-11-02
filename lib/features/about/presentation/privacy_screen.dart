import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import '../../../core/auth/session_provider.dart';
import 'about_screen.dart';

/// Une section de la politique : titre, paragraphes et listes.
typedef _Section = (IconData, String, List<_Block>);

/// Paragraphe (texte) ou liste à puces (texte multiligne, une ligne = une puce).
typedef _Block = (bool, String);

(bool, String) _p(String fr, String en) => (false, bi(fr, en));
(bool, String) _ul(String fr, String en) => (true, bi(fr, en));

/// Politique de confidentialité de Calandix.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  final _keys = <GlobalKey>[];

  List<_Section> get _sections => [
    (
      AppIcons.buildings,
      bi('1. Qui sommes-nous ?', '1. Who are we?'),
      [
        _p(
          'Calandix est une application d’organisation d’événements destinée aux organisateurs (particuliers et professionnels) et aux prestataires événementiels (« Creators »). Le responsable du traitement de vos données est l’éditeur de l’application Calandix [raison sociale, siège social et numéro RCCM à compléter avant le lancement].',
          'Calandix is an event planning app for organizers (individuals and professionals) and event vendors (“Creators”). The controller of your data is the publisher of the Calandix app [company name, registered office and RCCM number to be completed before launch].',
        ),
      ],
    ),
    (
      AppIcons.database,
      bi('2. Les données que nous collectons', '2. The data we collect'),
      [
        _p(
          'Nous ne collectons que ce qui est utile au service :',
          'We only collect what the service needs:',
        ),
        _ul(
          'Identité et contact : nom, prénom, e-mail, téléphone, ville, photo de profil (facultative).\n'
              'Événements : type, date, lieu, budget, tâches, liste d’invités et réponses (RSVP), documents ajoutés au coffre-fort.\n'
              'Profil professionnel (Creators) : nom commercial, catégorie, zone, description, RCCM, tarifs, portfolio.\n'
              'Transactions : montants, moyen de paiement choisi, références et reçus. Nous ne stockons jamais vos codes Mobile Money ni les numéros complets de carte bancaire.\n'
              'Données techniques : type d’appareil, langue, journaux de connexion et d’erreurs, préférences (mode sombre, sons).',
          'Identity and contact: first and last name, email, phone, city, profile photo (optional).\n'
              'Events: type, date, venue, budget, tasks, guest list and replies (RSVP), documents added to the vault.\n'
              'Business profile (Creators): trade name, category, area, description, RCCM, prices, portfolio.\n'
              'Transactions: amounts, chosen payment method, references and receipts. We never store your Mobile Money PINs or full card numbers.\n'
              'Technical data: device type, language, sign-in and error logs, preferences (dark mode, sounds).',
        ),
        _p(
          'Les informations sur vos invités (nom, numéro WhatsApp) sont saisies par vous : vous vous engagez à les utiliser uniquement pour votre événement.',
          'Information about your guests (name, WhatsApp number) is entered by you: you agree to use it only for your event.',
        ),
      ],
    ),
    (
      AppIcons.target,
      bi('3. Pourquoi nous les utilisons', '3. Why we use it'),
      [
        _ul(
          'Fournir le service : créer votre compte, gérer vos événements, votre budget et vos réservations (exécution du contrat).\n'
              'Traiter les paiements et conserver les fonds jusqu’à la validation de la prestation (exécution du contrat, obligations légales).\n'
              'Vous envoyer des rappels et notifications que vous avez activés (consentement, modifiable à tout moment).\n'
              'Sécuriser la plateforme et prévenir la fraude (intérêt légitime).\n'
              'Améliorer Calandix à partir de statistiques anonymes, seulement si vous l’acceptez (consentement).\n'
              'Respecter nos obligations comptables et fiscales (obligation légale).',
          'Providing the service: creating your account, managing your events, budget and bookings (performance of contract).\n'
              'Processing payments and holding funds until the service is approved (performance of contract, legal obligations).\n'
              'Sending reminders and notifications you have turned on (consent, changeable at any time).\n'
              'Securing the platform and preventing fraud (legitimate interest).\n'
              'Improving Calandix with anonymous statistics, only if you agree (consent).\n'
              'Meeting our accounting and tax obligations (legal obligation).',
        ),
        _p(
          'Nous ne vendons jamais vos données et ne faisons pas de publicité ciblée à partir de vos événements.',
          'We never sell your data and we do not run targeted advertising based on your events.',
        ),
      ],
    ),
    (
      AppIcons.lock,
      bi('4. Conservation et sécurité', '4. Retention and security'),
      [
        _ul(
          'Compte et événements : pendant toute la durée d’utilisation, puis 3 ans après votre dernière activité.\n'
              'Pièces comptables et reçus : 10 ans, comme l’exige la loi.\n'
              'Journaux techniques : 12 mois maximum.\n'
              'Documents du coffre-fort : jusqu’à leur suppression par vous ou la fermeture du compte.',
          'Account and events: for as long as you use Calandix, then 3 years after your last activity.\n'
              'Accounting records and receipts: 10 years, as required by law.\n'
              'Technical logs: 12 months maximum.\n'
              'Vault documents: until you delete them or close your account.',
        ),
        _p(
          'Vos données sont chiffrées en transit (HTTPS) et au repos ; les documents du coffre-fort sont chiffrés de bout en bout. L’accès est limité aux personnes qui en ont besoin, et chaque collaborateur d’un événement n’a que les droits que vous lui donnez.',
          'Your data is encrypted in transit (HTTPS) and at rest; vault documents are end-to-end encrypted. Access is limited to those who need it, and each event collaborator only has the rights you give them.',
        ),
      ],
    ),
    (
      AppIcons.share,
      bi('5. Partage avec des tiers', '5. Sharing with third parties'),
      [
        _p(
          'Vos données ne sont partagées qu’avec :',
          'Your data is only shared with:',
        ),
        _ul(
          'Les prestataires que vous contactez : le nécessaire pour établir un devis (date, lieu, nombre d’invités, budget indicatif) et, après une demande de devis, votre numéro si vous l’autorisez.\n'
              'Les collaborateurs que vous invitez sur un événement, selon leurs droits.\n'
              'Nos sous-traitants techniques : hébergement et base de données, opérateurs de paiement (Orange Money, MTN MoMo, Wave, Moov Money, cartes), envoi d’e-mails, de SMS et de messages WhatsApp. Ils agissent sur nos instructions et sont tenus à la confidentialité.\n'
              'Les autorités, uniquement sur demande légale.',
          'The vendors you contact: what’s needed for a quote (date, venue, number of guests, indicative budget) and, after a quote request, your number if you allow it.\n'
              'The collaborators you invite to an event, according to their rights.\n'
              'Our technical processors: hosting and database, payment operators (Orange Money, MTN MoMo, Wave, Moov Money, cards), email, SMS and WhatsApp delivery. They act on our instructions and are bound by confidentiality.\n'
              'Authorities, only when legally required.',
        ),
        _p(
          'Lorsque certaines données sont hébergées hors de Côte d’Ivoire, ce transfert est encadré par des garanties appropriées et, lorsque la loi l’exige, autorisé par l’ARTCI.',
          'When some data is hosted outside Côte d’Ivoire, the transfer is covered by appropriate safeguards and, where the law requires it, authorised by ARTCI.',
        ),
      ],
    ),
    (
      AppIcons.cookie,
      bi('6. Cookies et traceurs', '6. Cookies and trackers'),
      [
        _p(
          'L’application et sa version web utilisent uniquement des traceurs nécessaires : maintien de la session, langue, mode sombre, sons. Les mesures d’audience anonymes ne sont activées qu’avec votre accord (Compte › Confidentialité). Aucun traceur publicitaire n’est utilisé.',
          'The app and its web version only use necessary trackers: keeping you signed in, language, dark mode, sounds. Anonymous analytics are turned on only with your consent (Account › Privacy). No advertising trackers are used.',
        ),
      ],
    ),
    (
      AppIcons.user,
      bi('7. Vos droits', '7. Your rights'),
      [
        _ul(
          'Accès : obtenir une copie de vos données (Compte › Exporter mes données).\n'
              'Rectification : corriger vos informations à tout moment (Compte › Modifier le profil).\n'
              'Effacement : supprimer votre compte et vos données.\n'
              'Opposition et retrait du consentement : notifications, statistiques anonymes.\n'
              'Portabilité : recevoir vos données dans un format lisible (CSV).\n'
              'Réclamation : saisir l’ARTCI (Autorité de Régulation des Télécommunications/TIC de Côte d’Ivoire) si vous estimez que vos droits ne sont pas respectés.',
          'Access: get a copy of your data (Account › Export my data).\n'
              'Rectification: correct your information at any time (Account › Edit profile).\n'
              'Erasure: delete your account and your data.\n'
              'Objection and withdrawal of consent: notifications, anonymous statistics.\n'
              'Portability: receive your data in a readable format (CSV).\n'
              'Complaint: contact ARTCI (Côte d’Ivoire’s telecom/ICT regulator) if you believe your rights are not respected.',
        ),
        _p(
          'Nous répondons à toute demande dans un délai d’un mois.',
          'We answer every request within one month.',
        ),
      ],
    ),
    (
      AppIcons.trash,
      bi('8. Suppression du compte', '8. Deleting your account'),
      [
        _p(
          'Vous pouvez supprimer votre compte depuis cette page ou en écrivant au support. La suppression est effective sous 30 jours : vos événements, invités, documents et préférences sont effacés définitivement. Seules les pièces comptables (reçus, factures) sont conservées pendant la durée légale, puis supprimées. Les réservations en cours doivent être clôturées ou annulées avant la suppression.',
          'You can delete your account from this page or by writing to support. Deletion takes effect within 30 days: your events, guests, documents and preferences are permanently erased. Only accounting records (receipts, invoices) are kept for the legal period, then deleted. Bookings in progress must be closed or cancelled before deletion.',
        ),
      ],
    ),
    (
      AppIcons.certificate,
      bi('9. Conformité', '9. Compliance'),
      [
        _p(
          'Cette politique s’appuie sur la loi ivoirienne n° 2013-450 du 19 juin 2013 relative à la protection des données à caractère personnel, sur l’Acte additionnel A/SA.1/01/10 de la CEDEAO et, pour les personnes situées dans l’Union européenne, sur le Règlement général sur la protection des données (RGPD). Les formalités auprès de l’ARTCI seront accomplies avant le lancement officiel.',
          'This policy is based on Ivorian Law No. 2013-450 of 19 June 2013 on the protection of personal data, the ECOWAS Supplementary Act A/SA.1/01/10 and, for people located in the European Union, the General Data Protection Regulation (GDPR). Filings with ARTCI will be completed before the official launch.',
        ),
        _p(
          'Calandix ne s’adresse pas aux enfants de moins de 16 ans. Les informations sur des enfants (par exemple pour un anniversaire) sont saisies sous la responsabilité de l’organisateur.',
          'Calandix is not intended for children under 16. Information about children (for example for a birthday) is entered under the organizer’s responsibility.',
        ),
      ],
    ),
    (
      AppIcons.mail,
      bi('10. Nous contacter', '10. Contact us'),
      [
        _p(
          'Pour toute question ou pour exercer vos droits : Compte › Aide & support, ou par écrit au délégué à la protection des données [adresse e-mail et postale à compléter]. Nous vous informerons de toute modification importante de cette politique dans l’application.',
          'For any question or to exercise your rights: Account › Help & support, or in writing to our data protection officer [email and postal address to be completed]. We will notify you in the app of any significant change to this policy.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    while (_keys.length < sections.length) {
      _keys.add(GlobalKey());
    }
    final signedIn = ref.watch(sessionProvider) != null;

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
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bi('Politique de confidentialité', 'Privacy policy'),
                        style: context.text.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bi(
                          'Dernière mise à jour : 26 octobre 2026',
                          'Last updated: 26 October 2026',
                        ),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Mascot(size: 84, color: MascotColor.creator, cover: true),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 14),
            NightPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bi(
                      'L’essentiel en 30 secondes',
                      'The essentials in 30 seconds',
                    ),
                    style: context.text.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final t in [
                    bi(
                      'Nous collectons seulement ce qui sert à organiser vos événements.',
                      'We only collect what helps organize your events.',
                    ),
                    bi(
                      'Nous ne vendons jamais vos données.',
                      'We never sell your data.',
                    ),
                    bi(
                      'Vos paiements et documents sont chiffrés.',
                      'Your payments and documents are encrypted.',
                    ),
                    bi(
                      'Vous pouvez tout consulter, exporter ou supprimer.',
                      'You can view, export or delete everything.',
                    ),
                  ])
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
                              color: Confetti.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t,
                              style: context.text.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Sommaire : chaque pastille fait défiler jusqu'à sa section.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (i, s) in sections.indexed)
                  ActionChip(
                    label: Text(
                      s.$2.replaceFirst(RegExp(r'^\d+\. '), ''),
                      style: context.text.labelMedium,
                    ),
                    backgroundColor: Confetti.surface,
                    side: BorderSide(color: Confetti.line),
                    shape: const StadiumBorder(),
                    onPressed: () => Scrollable.ensureVisible(
                      _keys[i].currentContext!,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              ],
            ),
            for (final (i, (icon, title, blocks)) in sections.indexed)
              Padding(
                key: _keys[i],
                padding: const EdgeInsets.only(top: 12),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconTile(icon: icon, hue: Hue.violet, size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(title, style: context.text.titleMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final (list, text) in blocks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: list
                              ? Column(
                                  children: [
                                    for (final line in text.split('\n'))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              margin: const EdgeInsets.only(
                                                top: 8,
                                                right: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Confetti.violet,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                line,
                                                style: context.text.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                )
                              : Text(text, style: context.text.bodyMedium),
                        ),
                    ],
                  ),
                ),
              ),
            if (signedIn) ...[
              const SizedBox(height: 20),
              PillButton(
                label: bi('Supprimer mon compte', 'Delete my account'),
                icon: AppIcons.trash,
                tone: ButtonTone.ghost,
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showEventaSheet<bool>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 96, mood: MascotMood.sleepy, idle: false),
            const SizedBox(height: 12),
            Text(
              bi('Supprimer votre compte ?', 'Delete your account?'),
              style: ctx.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              bi(
                'Vos événements, invités et documents seront effacés sous 30 jours. Cette action est irréversible.',
                'Your events, guests and documents will be erased within 30 days. This cannot be undone.',
              ),
              style: ctx.text.bodyMedium?.copyWith(color: Confetti.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            PillButton(
              label: bi('Supprimer définitivement', 'Delete permanently'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            PillButton(
              label: bi('Garder mon compte', 'Keep my account'),
              tone: ButtonTone.ghost,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(sessionProvider.notifier).signOut();
    context.go(Routes.onboarding);
    toast(
      context,
      bi(
        'Demande de suppression enregistrée (démo)',
        'Deletion request recorded (demo)',
      ),
    );
  }
}

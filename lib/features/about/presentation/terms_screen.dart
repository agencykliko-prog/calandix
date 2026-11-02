import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/ui.dart';
import 'about_screen.dart';

/// Conditions générales d'utilisation et de vente de Calandix.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final _keys = <GlobalKey>[];

  /// (icône, titre, paragraphes) ; une ligne commençant par « • » est une puce.
  List<(IconData, String, List<String>)> get _sections => [
    (
      AppIcons.info,
      bi('1. Objet', '1. Purpose'),
      [
        bi(
          'Les présentes conditions encadrent l’utilisation de l’application Calandix, éditée par [raison sociale, siège et RCCM à compléter], par les organisateurs d’événements et par les prestataires événementiels (« Creators »). Créer un compte vaut acceptation de ces conditions.',
          'These terms govern the use of the Calandix app, published by [company name, registered office and RCCM to be completed], by event organizers and event vendors (“Creators”). Creating an account means accepting these terms.',
        ),
      ],
    ),
    (
      AppIcons.file,
      bi('2. Définitions', '2. Definitions'),
      [
        bi(
          '• Organisateur : personne qui prépare un événement et réserve des prestations.\n• Creator : prestataire indépendant ou agence qui propose ses services.\n• Devis : proposition chiffrée d’un Creator, valable pour une durée indiquée.\n• Réservation : devis accepté par l’organisateur et confirmé par le paiement de l’acompte.',
          '• Organizer: a person planning an event and booking services.\n• Creator: an independent vendor or agency offering services.\n• Quote: a priced offer from a Creator, valid for a stated period.\n• Booking: a quote accepted by the organizer and confirmed by paying the deposit.',
        ),
      ],
    ),
    (
      AppIcons.user,
      bi('3. Compte', '3. Account'),
      [
        bi(
          '• L’inscription est réservée aux personnes majeures.\n• Les informations fournies doivent être exactes et tenues à jour.\n• Vous êtes responsable de la confidentialité de vos accès.\n• Les Creators fournissent les justificatifs demandés (RCCM, pièce d’identité, adresse) ; leur fiche n’est publiée qu’après vérification.',
          '• Registration is reserved for adults.\n• Information provided must be accurate and kept up to date.\n• You are responsible for keeping your access details confidential.\n• Creators provide the requested documents (RCCM, ID, address); their listing is published only after verification.',
        ),
      ],
    ),
    (
      AppIcons.handshake,
      bi('4. Rôle de Calandix', '4. Calandix’s role'),
      [
        bi(
          'Calandix met en relation organisateurs et Creators, fournit les outils d’organisation et sécurise les paiements. Le contrat de prestation est conclu directement entre l’organisateur et le Creator, qui reste seul responsable de l’exécution de sa prestation.',
          'Calandix connects organizers and Creators, provides planning tools and secures payments. The service contract is concluded directly between the organizer and the Creator, who remains solely responsible for delivering the service.',
        ),
      ],
    ),
    (
      AppIcons.calendarCheck,
      bi(
        '5. Devis, réservation, annulation',
        '5. Quotes, bookings, cancellation',
      ),
      [
        bi(
          '• Un devis engage le Creator pendant sa durée de validité.\n• La réservation est confirmée au paiement de l’acompte ; la date est alors bloquée.\n• Les conditions d’annulation sont celles indiquées sur le devis. À défaut : annulation gratuite jusqu’à 30 jours avant la prestation, acompte conservé ensuite.\n• Une annulation par le Creator entraîne le remboursement intégral de l’organisateur.',
          '• A quote binds the Creator for its validity period.\n• The booking is confirmed when the deposit is paid; the date is then held.\n• Cancellation terms are those stated on the quote. Failing that: free cancellation until 30 days before the service, deposit kept afterwards.\n• Cancellation by the Creator gives the organizer a full refund.',
        ),
      ],
    ),
    (
      AppIcons.wallet,
      bi('6. Paiements et reversements', '6. Payments and payouts'),
      [
        bi(
          '• Les paiements passent par des opérateurs agréés (Mobile Money, carte bancaire).\n• Les fonds sont conservés jusqu’à la validation de la prestation par l’organisateur, puis reversés au Creator, déduction faite de la commission Calandix (actuellement 8 %), sous 2 jours ouvrés.\n• Des frais de service (actuellement 2 %) peuvent s’ajouter au montant payé par l’organisateur ; ils sont affichés avant paiement.\n• Le paiement en dehors de l’application d’une prestation trouvée sur Calandix est interdit.',
          '• Payments go through licensed operators (Mobile Money, bank card).\n• Funds are held until the organizer approves the service, then paid to the Creator, minus Calandix’s commission (currently 8%), within 2 business days.\n• A service fee (currently 2%) may be added to the organizer’s payment; it is shown before payment.\n• Paying outside the app for a service found on Calandix is prohibited.',
        ),
      ],
    ),
    (
      AppIcons.crown,
      bi('7. Abonnements', '7. Subscriptions'),
      [
        bi(
          'Les offres Azur, Signature et Privilège (organisateurs) et Business / Creator (professionnels) sont mensuelles, sans engagement et résiliables à tout moment depuis l’application. Le mois entamé reste dû ; l’accès aux fonctionnalités se poursuit jusqu’à la fin de la période payée.',
          'The Azur, Signature and Privilege plans (organizers) and Business / Creator (professionals) are monthly, with no commitment, and can be cancelled anytime from the app. The current month remains due; access continues until the end of the paid period.',
        ),
      ],
    ),
    (
      AppIcons.warning,
      bi('8. Litiges', '8. Disputes'),
      [
        bi(
          'En cas de désaccord sur une prestation, l’organisateur le signale dans l’application au plus tard 48 h après la date prévue. Les fonds restent bloqués pendant l’examen. L’équipe Calandix recueille les éléments des deux parties et peut décider d’un remboursement total ou partiel, sans préjudice des recours de chacun.',
          'If there is a disagreement about a service, the organizer reports it in the app no later than 48 h after the scheduled date. Funds stay frozen during the review. The Calandix team gathers both parties’ evidence and may decide on a full or partial refund, without prejudice to either party’s remedies.',
        ),
      ],
    ),
    (
      AppIcons.vendors,
      bi('9. Engagements des Creators', '9. Creator commitments'),
      [
        bi(
          '• Décrire fidèlement leurs prestations, tarifs, options et conditions.\n• Tenir leurs disponibilités à jour pour éviter les doubles réservations.\n• Respecter les devis acceptés et les exigences convenues avec le client.\n• Disposer des autorisations, assurances et déclarations fiscales nécessaires à leur activité.',
          '• Describe their services, prices, options and terms accurately.\n• Keep their availability up to date to avoid double bookings.\n• Honour accepted quotes and the requirements agreed with the client.\n• Hold the permits, insurance and tax registrations their business requires.',
        ),
      ],
    ),
    (
      AppIcons.star,
      bi('10. Avis et contenus', '10. Reviews and content'),
      [
        bi(
          'Seuls les organisateurs ayant réservé peuvent laisser un avis. Les avis doivent être sincères et respectueux ; Calandix peut retirer un contenu illicite ou trompeur. Chaque utilisateur reste propriétaire de ses photos et accorde à Calandix le droit de les afficher dans l’application pour le service.',
          'Only organizers who booked can leave a review. Reviews must be honest and respectful; Calandix may remove unlawful or misleading content. Each user keeps ownership of their photos and grants Calandix the right to display them in the app for the service.',
        ),
      ],
    ),
    (
      AppIcons.lock,
      bi('11. Suspension et résiliation', '11. Suspension and termination'),
      [
        bi(
          'Calandix peut suspendre un compte en cas de fraude, de contournement des paiements, d’annulations répétées ou de non-respect de ces conditions, après information de l’utilisateur sauf urgence. Chacun peut supprimer son compte à tout moment (voir la politique de confidentialité).',
          'Calandix may suspend an account for fraud, payment circumvention, repeated cancellations or breach of these terms, after informing the user except in emergencies. Anyone can delete their account at any time (see the privacy policy).',
        ),
      ],
    ),
    (
      AppIcons.scroll,
      bi('12. Droit applicable', '12. Governing law'),
      [
        bi(
          'Ces conditions sont régies par le droit ivoirien. En cas de litige, une solution amiable est recherchée en priorité ; à défaut, les tribunaux d’Abidjan sont compétents. Calandix informe les utilisateurs dans l’application de toute modification importante de ces conditions.',
          'These terms are governed by Ivorian law. In case of dispute, an amicable solution is sought first; failing that, the courts of Abidjan have jurisdiction. Calandix notifies users in the app of any significant change to these terms.',
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
                      : context.go(Routes.onboarding),
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
                        bi('Conditions générales', 'Terms and conditions'),
                        style: context.text.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bi(
                          'Utilisation et vente · mise à jour le 27 octobre 2026',
                          'Use and sale · updated 27 October 2026',
                        ),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Mascot(size: 84, color: MascotColor.creator),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 14),
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
            for (final (i, (icon, title, paragraphs)) in sections.indexed)
              Padding(
                key: _keys[i],
                padding: const EdgeInsets.only(top: 12),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconTile(icon: icon, hue: Hue.lagoon, size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(title, style: context.text.titleMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final p in paragraphs)
                        for (final line in p.split('\n'))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: line.startsWith('• ')
                                ? Row(
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
                                          color: Confetti.lagoon,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          line.substring(2),
                                          style: context.text.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(line, style: context.text.bodyMedium),
                          ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push(Routes.privacy),
                child: Text(
                  bi(
                    'Lire aussi la politique de confidentialité',
                    'Also read the privacy policy',
                  ),
                  style: context.text.labelMedium?.copyWith(
                    color: Confetti.coralDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

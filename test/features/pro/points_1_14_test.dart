import 'package:eventa/core/auth/profile.dart';
import 'package:eventa/core/auth/session_provider.dart';
import 'package:eventa/core/models/models.dart' hide TeamRole;
import 'package:eventa/features/booking/presentation/quote_compare_screen.dart';
import 'package:eventa/features/commerce/data/catalog.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/events/data/demo_data.dart';
import 'package:eventa/features/invitations/presentation/album_screen.dart';
import 'package:eventa/features/invitations/presentation/invitation_screen.dart';
import 'package:eventa/features/invitations/presentation/invitations_providers.dart';
import 'package:eventa/features/invitations/presentation/rsvp_screen.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/features/pro/domain/pro_models.dart';
import 'package:eventa/features/pro/presentation/creator_providers.dart';
import 'package:eventa/features/pro/presentation/orders_screen.dart';
import 'package:eventa/features/pro/presentation/pro_providers.dart';
import 'package:eventa/features/pro/presentation/studio_providers.dart';
import 'package:eventa/features/pro/presentation/team_rights.dart';
import 'package:eventa/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  ProviderContainer creator() {
    final c = ProviderContainer();
    c.read(sessionProvider.notifier).signIn(UserRole.creator);
    return c;
  }

  test('une commande commence à « Devis accepté », puis l’acompte', () {
    expect(OrderStage.values.first, OrderStage.accepted);
    expect(const OrderProgress().stage, OrderStage.accepted);
    expect(OrderStage.values[1], OrderStage.confirmed);
  });

  test('chaque offre garde ses conditions et son activité', () {
    const p = ProPackage(id: 'x', name: 'Test', price: 1, includes: []);
    final q = p.copyWith(
      conditions: '50 invités min.',
      activity: VendorCategory.rental,
    );
    expect(q.conditions, '50 invités min.');
    expect(q.activity, VendorCategory.rental);
    expect(q.copyWith(clearActivity: true).activity, isNull);
  });

  test('droits par rôle : appliqués seulement avec la formule Business', () {
    final c = creator();
    addTearDown(c.dispose);
    c.read(actingRoleProvider.notifier).set(TeamRole.accountant);
    // Sans équipe, le titulaire garde tous les droits.
    expect(c.read(canProvider(TeamRight.sendQuotes)), isTrue);
    c.read(creatorSubProvider.notifier).startTrial(ProPlan.business);
    expect(c.read(canProvider(TeamRight.sendQuotes)), isFalse);
    expect(c.read(canProvider(TeamRight.billing)), isTrue);
    c.read(actingRoleProvider.notifier).set(TeamRole.sales);
    expect(c.read(canProvider(TeamRight.quotes)), isTrue);
    expect(c.read(canProvider(TeamRight.sendQuotes)), isFalse);
    c.read(actingRoleProvider.notifier).set(TeamRole.manager);
    expect(c.read(canProvider(TeamRight.sendQuotes)), isTrue);
    expect(c.read(canProvider(TeamRight.admin)), isFalse);
  });

  test('plafonds du Pass : 2 000 invités et 30 collaborateurs', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(passCapsProvider('e1')), isNull);
    c.read(eventPassProvider.notifier).activate('e1');
    final caps = c.read(passCapsProvider('e1'))!;
    expect(caps.guests, 2000);
    expect(caps.collaborators, 30);
    // Un abonnement Privilège lève le plafond du Pass.
    final p = ProviderContainer(
      overrides: [planProvider.overrideWith(_Privilege.new)],
    );
    addTearDown(p.dispose);
    p.read(eventPassProvider.notifier).activate('e1');
    expect(p.read(passCapsProvider('e1')), isNull);
  });

  test('assistance prioritaire : Privilège ou Pass en cours', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.organizer);
    expect(c.read(prioritySupportProvider), isFalse);
    c.read(eventPassProvider.notifier).activate('e1');
    expect(c.read(prioritySupportProvider), isTrue);
  });

  test('badges publics : qualité et formule de la fiche', () {
    final v = Catalog.vendor('ines-deco');
    expect(Catalog.planOf(v), ProPlan.business);
    expect(
      Catalog.qualityOf(v),
      v.verified && v.rating >= 4.5 && v.reviews >= 10,
    );
  });

  test('le coffre-fort a un dossier Inspirations', () {
    expect(VaultFolder.values, contains(VaultFolder.inspirations));
  });

  test('l’invitation contient le lien de réponse personnel', () {
    final e = DemoData.wedding();
    final g = e.guests.list.first;
    final text = invitationText(e, const InvitationDesign(), g);
    expect(text, contains(rsvpLink(e.id, g.id)));
    expect(rsvpPath(e.id, g.id), '/r/${e.id}/${guestCode(e.id, g.id)}');
  });

  test('les vidéos sont reconnues à leur extension', () {
    expect(isVideoName('fete.MP4'), isTrue);
    expect(isVideoName('photo.jpg'), isFalse);
  });

  testWidgets('l’invité répond lui-même depuis son lien', (tester) async {
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.organizer);
    final events = (await tester.runAsync(
      () => c.read(eventsProvider.future),
    ))!;
    final e = events.first;
    final g = e.guests.list.firstWhere((x) => x.rsvp != Rsvp.yes);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.current(),
          home: GuestRsvpScreen(eventId: e.id, code: guestCode(e.id, g.id)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text('Je serai là'));
    await tester.tap(find.text('Je serai là'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Envoyer ma réponse'));
    await tester.pump();
    await tester.tap(find.text('Envoyer ma réponse'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    final after = c
        .read(eventsProvider)
        .value!
        .firstWhere((x) => x.id == e.id)
        .guests
        .list
        .firstWhere((x) => x.id == g.id);
    expect(after.rsvp, Rsvp.yes);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('analyse des devis : rien à comparer sous deux offres', () {
    expect(analyzeQuotes(const QuoteGroup(VendorCategory.decor, [])), isNull);
  });

  for (final size in const [Size(375, 812), Size(1280, 800)]) {
    testWidgets(
      'suivi des 7 statuts sans débordement (${size.width.toInt()} px)',
      (tester) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final c = creator();
        addTearDown(c.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: AppTheme.current(),
              home: const Scaffold(
                body: SingleChildScrollView(child: OrderPipeline()),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Commande clôturée'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Aucune commande n'est comptée deux fois.
        final requests = c.read(requestsProvider);
        expect(
          c.read(proProvider).progress.length,
          lessThanOrEqualTo(requests.length),
        );
      },
    );
  }
}

class _Privilege extends PlanNotifier {
  @override
  Plan build() => Plan.privilege;
}

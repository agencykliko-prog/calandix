import 'package:eventa/core/models/models.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/concierge/presentation/concierge_screen.dart';
import 'package:eventa/features/events/data/demo_data.dart';
import 'package:eventa/features/invitations/presentation/entries_screen.dart';
import 'package:eventa/features/invitations/presentation/invitation_screen.dart';
import 'package:eventa/features/invitations/presentation/invitations_providers.dart';
import 'package:eventa/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  final e = DemoData.wedding();

  test('grille du 14 novembre 2026 : prix, annuel, commissions et Pass', () {
    expect([for (final p in Plan.values) p.price], [0, 2000, 3000, 5000]);
    expect(
      [for (final p in Plan.values) p.yearlyPrice],
      [0, 22000, 33000, 55000],
    );
    expect([for (final p in ProPlan.values) p.price], [0, 5000, 10000, 15000]);
    expect([for (final p in ProPlan.values) p.commissionPercent], [6, 5, 4, 2]);
    expect(eventPassPrice, 5000);
    expect(eventPassDays, 90);
    expect(eventPassGuests, 750);
    expect(eventPassCollaborators, 15);
  });

  test('le Pass Événement débloque les fonctions Signature', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(
      c.read(featureUnlockedProvider((PremiumFeature.agent, e.id))),
      isFalse,
    );
    c.read(eventPassProvider.notifier).activate(e.id);
    expect(
      c.read(featureUnlockedProvider((PremiumFeature.agent, e.id))),
      isTrue,
    );
    // Les fonctions Privilège restent fermées.
    expect(
      c.read(featureUnlockedProvider((PremiumFeature.album, e.id))),
      isFalse,
    );
    expect(
      c.read(featureUnlockedProvider((PremiumFeature.entries, e.id))),
      isTrue,
    );
    // Un autre événement reste sans pass.
    expect(
      c.read(featureUnlockedProvider((PremiumFeature.agent, 'autre'))),
      isFalse,
    );
  });

  test('chaque invité a un code d’entrée unique et stable', () {
    final codes = {for (final g in e.guests.list) guestCode(e.id, g.id)};
    expect(codes.length, e.guests.list.length);
    final g = e.guests.list.first;
    expect(guestCode(e.id, g.id), guestCode(e.id, g.id));
    expect(
      guestCode(e.id, g.id),
      matches(RegExp(r'^CX-[A-Z2-9]{3}-[A-Z2-9]{3}$')),
    );
    expect(guestQrData(e.id, g.id), endsWith(guestCode(e.id, g.id)));
  });

  test('contrôle des entrées : confirmé une seule fois, sinon refusé', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(checkInProvider.notifier);
    final yes = e.guests.list.firstWhere((g) => g.rsvp == Rsvp.yes);
    final pending = e.guests.list.firstWhere((g) => g.rsvp != Rsvp.yes);

    final first = n.check(e, guestCode(e.id, yes.id).toLowerCase());
    expect(first.$1, CheckResult.admitted);
    expect(n.of(e.id)[yes.id]!.people, 1 + yes.companions);
    expect(n.check(e, guestQrData(e.id, yes.id)).$1, CheckResult.already);
    expect(
      n.check(e, guestCode(e.id, pending.id)).$1,
      CheckResult.notConfirmed,
    );
    expect(n.check(e, 'CX-AAA-AAA').$1, CheckResult.unknown);

    n.undo(e.id, yes.id);
    expect(n.check(e, guestCode(e.id, yes.id)).$1, CheckResult.admitted);
  });

  test('le concierge comprend invités, budget et besoins', () {
    final b = readBrief(
      'Je dois organiser un mariage de 300 personnes à Abidjan. J’ai besoin '
      'd’un traiteur, d’un décorateur et d’un photographe. Mon budget est de '
      '6 millions FCFA.',
      e,
    );
    expect(b.guests, 300);
    expect(b.budget, 6000000);
    expect(
      b.needs,
      containsAll([
        VendorCategory.catering,
        VendorCategory.decor,
        VendorCategory.photo,
      ]),
    );
  });

  test('le message d’invitation porte la date limite et le code', () {
    final g = e.guests.list.first;
    const d = InvitationDesign(dressCode: 'Blanc et or');
    final text = invitationText(e, d, g);
    expect(text, contains(e.name));
    expect(text, contains('Blanc et or'));
    expect(text, contains(guestCode(e.id, g.id)));
  });

  for (final size in const [Size(375, 812), Size(1280, 800)]) {
    testWidgets(
      'invitation et entrées s’affichent sans débordement (${size.width.toInt()} px)',
      (tester) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        for (final screen in [
          InvitationScreen(id: e.id),
          EntriesScreen(id: e.id),
          ConciergeScreen(eventId: e.id),
        ]) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(theme: AppTheme.current(), home: screen),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

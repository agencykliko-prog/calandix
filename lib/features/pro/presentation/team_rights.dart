import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import 'studio_providers.dart';

/// Ce qu'un membre de l'équipe peut faire dans l'espace pro.
enum TeamRight {
  quotes('traiter les demandes et préparer les devis'),
  sendQuotes('envoyer un devis au client'),
  billing('facturer et encaisser'),
  catalog('modifier le catalogue et les conditions'),
  admin('gérer l’équipe, la marque et les automatisations');

  const TeamRight(this._label);
  final String _label;
  String get label => _label.tr;
}

extension TeamRoleRights on TeamRole {
  /// Droits accordés par le rôle : le commercial prépare, le responsable
  /// valide et envoie, le comptable facture, l'administrateur fait tout.
  Set<TeamRight> get grants => switch (this) {
    TeamRole.sales => const {TeamRight.quotes},
    TeamRole.manager => const {
      TeamRight.quotes,
      TeamRight.sendQuotes,
      TeamRight.catalog,
    },
    TeamRole.accountant => const {TeamRight.billing},
    TeamRole.admin => TeamRight.values.toSet(),
  };
}

/// Rôle avec lequel l'espace est utilisé. Le titulaire du compte est
/// administrateur ; en démo, on peut se mettre à la place d'un membre pour
/// vérifier ce qu'il voit.
class ActingRoleNotifier extends Notifier<TeamRole> {
  @override
  TeamRole build() => TeamRole.admin;

  void set(TeamRole r) => state = r;
}

final actingRoleProvider = NotifierProvider<ActingRoleNotifier, TeamRole>(
  ActingRoleNotifier.new,
);

/// Le rôle courant donne-t-il ce droit ? Sans formule Business, il n'y a
/// pas d'équipe : le titulaire a tous les droits.
final canProvider = Provider.family<bool, TeamRight>((ref, right) {
  if (!ref.watch(proPlanProvider).includes(ProPlan.business)) return true;
  return ref.watch(actingRoleProvider).grants.contains(right);
});

/// Vérifie un droit avant une action ; sinon, explique pourquoi elle est
/// refusée.
bool checkRight(BuildContext context, WidgetRef ref, TeamRight right) {
  if (ref.read(canProvider(right))) return true;
  toast(
    context,
    'Votre rôle {0} ne permet pas de {1}.'.trf([
      ref.read(actingRoleProvider).label,
      right.label,
    ]),
    icon: AppIcons.lock,
  );
  return false;
}

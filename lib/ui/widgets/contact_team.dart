import 'package:flutter/material.dart';

import '../../core/i18n/tr.dart';
import '../theme/app_icons.dart';
import '../theme/eventa_colors.dart';
import '../../platform/mobile/open_link_mobile.dart'
    if (dart.library.js_interop) '../../platform/web/open_link_web.dart';
import 'ui.dart';

/// Coordonnées de l'équipe Calandix : WhatsApp, appel et e-mail, sans formulaire.
abstract final class EventaContact {
  static const email = 'contact@calandix.com';
  static const whatsapp = '+225 07 04 25 22 25';
  static const whatsappLink = 'https://wa.me/2250704252225';

  static Future<void> openWhatsApp([String? message]) => openLink(
    message == null
        ? whatsappLink
        : '$whatsappLink?text=${Uri.encodeComponent(message)}',
  );

  static Future<void> openEmail() => openLink('mailto:$email');

  /// Appel du même numéro que WhatsApp.
  static const phoneLink = 'tel:+2250704252225';
  static Future<void> call() => openLink(phoneLink);
}

/// Feuille « Contacter l'équipe » : WhatsApp en premier (le canal le plus
/// rassurant en Côte d'Ivoire), puis l'appel et l'e-mail.
Future<void> showContactTeam(BuildContext context, {bool privilege = false}) {
  return showEventaSheet<void>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Contacter l’équipe'.tr, style: ctx.text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            privilege
                ? 'Assistance prioritaire 7 j/7 : écrivez-nous sur WhatsApp, un conseiller traite votre demande en priorité.'
                      .tr
                : 'Une question, un souci ? Écrivez-nous, on vous répond vite.'
                      .tr,
            style: ctx.text.bodyMedium?.copyWith(color: Confetti.inkMuted),
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'WhatsApp · {0}'.trf([EventaContact.whatsapp]),
            icon: AppIcons.whatsapp,
            onPressed: () {
              Navigator.of(ctx).pop();
              EventaContact.openWhatsApp(
                privilege
                    ? 'Bonjour Calandix, demande prioritaire : j’ai besoin d’aide.'
                          .tr
                    : 'Bonjour Calandix, j’ai besoin d’aide.'.tr,
              );
            },
          ),
          const SizedBox(height: 10),
          PillButton(
            label: 'Appeler · {0}'.trf([EventaContact.whatsapp]),
            icon: AppIcons.phone,
            tone: ButtonTone.ghost,
            onPressed: () {
              Navigator.of(ctx).pop();
              EventaContact.call();
            },
          ),
          const SizedBox(height: 10),
          PillButton(
            label: EventaContact.email,
            icon: AppIcons.mail,
            tone: ButtonTone.ghost,
            onPressed: () {
              Navigator.of(ctx).pop();
              EventaContact.openEmail();
            },
          ),
        ],
      ),
    ),
  );
}

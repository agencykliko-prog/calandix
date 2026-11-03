import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../app/router/app_router.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../events/presentation/events_providers.dart';
import '../../premium/presentation/premium_nudge.dart';
import '../../marketplace/data/vendor_media.dart';
import 'quote_compare_screen.dart';

/// Parcours de réservation en 7 étapes, sur un seul écran : chaque étape
/// affiche son contenu et une seule action principale.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _accepted = false;
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  BookingsNotifier get _n => ref.read(bookingsProvider.notifier);

  Future<void> _pay(Booking b, {required bool balance}) async {
    final q = b.quote!;
    final options = balance
        ? [PayOption('Solde'.tr, b.balance)]
        : [
            PayOption('Acompte 30 %'.tr, q.deposit, caption: 'Solde à J-7'.tr),
            PayOption('Montant total'.tr, q.total, caption: 'En une fois'.tr),
          ];
    final r = await showPaymentSheet(
      context,
      title: balance
          ? 'Solde {0}'.trf([b.vendor.name])
          : 'Réservation {0}'.trf([b.vendor.name]),
      payee: b.vendor.name,
      options: options,
      onPay: (amount, m) => _n.pay(b.id, amount, m),
    );
    if (r != null && mounted) {
      toast(context, 'Paiement confirmé · reçu {0}'.trf([r.ref]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(bookingProvider(widget.id));
    if (b == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Réservation introuvable'.tr)),
      );
    }
    final event = ref.watch(eventProvider(b.eventId)).value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: VendorPhoto(
                    b.vendor.image,
                    width: 42,
                    height: 42,
                    cacheWidth: 120,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.vendor.name,
                        style: context.text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        event?.name ?? '',
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StepTrack(step: b.step),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: Motion.base,
              switchInCurve: Motion.easeOut,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(b.step),
                child: _stepBody(context, b),
              ),
            ),
            if (b.receipts.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text('Reçus'.tr, style: context.text.titleLarge),
              const SizedBox(height: 10),
              for (final r in b.receipts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    padding: const EdgeInsets.all(14),
                    onTap: () => showEventaSheet<void>(
                      context,
                      builder: (ctx) => ReceiptView(
                        receipt: r,
                        onDone: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconTile(
                          icon: AppIcons.receipt,
                          hue: Hue.lagoon,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.label, style: context.text.titleSmall),
                              Text(
                                '${r.ref} · ${r.method.label}',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(fcfa(r.total), style: context.text.titleSmall),
                      ],
                    ),
                  ),
                ),
            ],
            if (b.step.index >= BookingStep.requested.index) ...[
              const SizedBox(height: 26),
              Text('Échanges'.tr, style: context.text.titleLarge),
              const SizedBox(height: 10),
              _Thread(messages: b.messages),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      decoration: InputDecoration(
                        hintText: 'Écrire au prestataire…'.tr,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                      ),
                      onSubmitted: (_) => _send(b),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: AppIcons.send,
                    background: Confetti.ink,
                    foreground: Colors.white,
                    size: 48,
                    tooltip: 'Envoyer',
                    onTap: () => _send(b),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _send(Booking b) {
    final t = _composer.text.trim();
    if (t.isEmpty) return;
    _n.message(b.id, t);
    _composer.clear();
  }

  Widget _stepBody(BuildContext context, Booking b) {
    switch (b.step) {
      case BookingStep.selected:
      case BookingStep.requested:
        return _Waiting(
          vendor: b.vendor.name,
          responseTime: b.vendor.responseTime,
        );
      case BookingStep.quoted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ref.watch(rivalQuotesProvider(b.id)) case final n when n > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PillButton(
                  key: const ValueKey('compare-quotes'),
                  label: 'Comparer avec {0} autre(s) devis'.trf([n]),
                  icon: AppIcons.chart,
                  tone: ButtonTone.ghost,
                  onPressed: () =>
                      context.push(Routes.compareQuotes(b.eventId)),
                ),
              ),
            _QuoteCard(quote: b.quote!),
            const SizedBox(height: 14),
            Pressable(
              onTap: () => setState(() => _accepted = !_accepted),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: Motion.fast,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _accepted ? Confetti.ink : Confetti.surface,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: _accepted ? Confetti.ink : Confetti.border,
                        width: 1.6,
                      ),
                    ),
                    child: _accepted
                        ? const Icon(
                            AppIcons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'J’accepte les conditions du devis et la politique d’annulation.'
                          .tr,
                      style: context.text.bodySmall?.copyWith(
                        color: Confetti.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Accepter et réserver'.tr,
              icon: AppIcons.calendarCheck,
              onPressed: _accepted
                  ? () {
                      _n.accept(b.id);
                      toast(
                        context,
                        'Date bloquée le {0}'.trf([mediumDate(b.request.date)]),
                      );
                      maybeShowPremiumNudge(
                        context,
                        ref,
                        PremiumNudge.booking,
                        delay: const Duration(milliseconds: 1600),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 10),
            PillButton(
              label: b.quote!.lastOffer
                  ? 'Dernière offre reçue'.tr
                  : 'Dernière offre'.tr,
              icon: AppIcons.handshake,
              tone: ButtonTone.ghost,
              onPressed: b.quote!.lastOffer
                  ? null
                  : () {
                      final saved = _n.lastOffer(b.id);
                      toast(
                        context,
                        'Dernière offre : {0} de moins'.trf([fcfa(saved)]),
                        icon: AppIcons.handshake,
                      );
                    },
            ),
          ],
        );
      case BookingStep.reserved:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              icon: AppIcons.calendarCheck,
              hue: Hue.violet,
              title: 'Date bloquée'.tr,
              text: '{0} réserve le {1} pour vous. Réglez l’acompte pour confirmer définitivement.'
                  .trf([b.vendor.name, longDate(b.request.date)]),
            ),
            const SizedBox(height: 12),
            _QuoteCard(quote: b.quote!, compact: true),
            const SizedBox(height: 14),
            PillButton(
              label: 'Payer en toute sécurité'.tr,
              icon: AppIcons.lock,
              onPressed: () => _pay(b, balance: false),
            ),
          ],
        );
      case BookingStep.paid:
      case BookingStep.executing:
        final days = daysUntil(b.request.date);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              icon: AppIcons.checkCircle,
              hue: Hue.lagoon,
              title: 'Réservation confirmée'.tr,
              text: 'Payé {0} sur {1}. {2}'.trf([
                fcfa(b.paidAmount),
                fcfa(b.quote!.total),
                b.balance > 0
                    ? 'Reste {0} à régler avant J-7.'.trf([fcfa(b.balance)])
                    : 'Tout est réglé.'.tr,
              ]),
            ),
            const SizedBox(height: 16),
            Text('Suivi'.tr, style: context.text.titleLarge),
            const SizedBox(height: 10),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _FollowRow(
                    icon: AppIcons.reminder,
                    title: 'Rappel solde'.tr,
                    caption: days > 7
                        ? 'Dans {0} jours (J-7)'.trf([days - 7])
                        : 'À régler maintenant'.tr,
                    done: b.balance <= 0,
                  ),
                  const Divider(height: 1),
                  _FollowRow(
                    icon: AppIcons.message,
                    title: 'Brief final avec le prestataire'.tr,
                    caption: days > 14
                        ? 'Programmé à J-14'.tr
                        : 'Cette semaine'.tr,
                    done: false,
                  ),
                  const Divider(height: 1),
                  _FollowRow(
                    icon: AppIcons.bell,
                    title: 'Notifications'.tr,
                    caption: 'Arrivée et installation le jour J'.tr,
                    done: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (b.balance > 0)
              PillButton(
                label: 'Payer le solde · {0}'.trf([fcfa(b.balance)]),
                icon: AppIcons.lock,
                onPressed: () => _pay(b, balance: true),
              )
            else
              PillButton(
                label: 'Valider la prestation et clôturer'.tr,
                icon: AppIcons.checkCircle,
                tone: ButtonTone.dark,
                onPressed: () {
                  _n.close(b.id);
                  toast(
                    context,
                    'Reversement envoyé à {0}'.trf([b.vendor.name]),
                    icon: AppIcons.bank,
                  );
                },
              ),
          ],
        );
      case BookingStep.closed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(
              icon: AppIcons.bank,
              hue: Hue.lagoon,
              title: 'Prestataire payé'.tr,
              text: 'Reversement automatique de {0} effectué à {1} après votre validation.'
                  .trf([fcfa(b.quote!.subtotal), b.vendor.name]),
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                children: [
                  Text(
                    b.rating == null
                        ? 'Comment s’est passée la prestation ?'.tr
                        : 'Merci pour votre avis !'.tr,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Pressable(
                          scale: 0.85,
                          onTap: () => _n.review(b.id, i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              (b.rating ?? 0) >= i
                                  ? AppIcons.star
                                  : AppIcons.starLine,
                              size: 32,
                              color: Confetti.mango,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: b.archived
                  ? 'Dossier archivé'.tr
                  : 'Archiver le dossier'.tr,
              icon: AppIcons.archive,
              tone: ButtonTone.ghost,
              onPressed: b.archived
                  ? null
                  : () {
                      _n.archive(b.id);
                      toast(
                        context,
                        'Dossier archivé dans le coffre-fort'.tr,
                        icon: AppIcons.archive,
                      );
                    },
            ),
          ],
        );
    }
  }
}

class _StepTrack extends StatelessWidget {
  const _StepTrack({required this.step});

  final BookingStep step;

  @override
  Widget build(BuildContext context) {
    final i = step.index;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Étape {0} sur 7'.trf([i + 1]),
                style: context.text.labelSmall?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
              const Spacer(),
              Text(
                step.status,
                style: context.text.labelMedium?.copyWith(
                  color: Confetti.violetText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var s = 0; s < BookingStep.values.length; s++) ...[
                if (s > 0) const SizedBox(width: 4),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: s <= i ? 1 : 0),
                    duration: Duration(milliseconds: 380 + s * 60),
                    curve: Motion.easeOut,
                    builder: (context, t, _) => Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Confetti.lavender,
                          s == i ? Confetti.violet : Confetti.ink,
                          t,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var s = 0; s < BookingStep.values.length; s++)
                Expanded(
                  child: Text(
                    BookingStep.values[s].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: context.text.labelSmall?.copyWith(
                      fontSize: 9,
                      color: s <= i ? Confetti.ink : Confetti.inkFaint,
                      fontWeight: s == i ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Waiting extends StatefulWidget {
  const _Waiting({required this.vendor, required this.responseTime});

  final String vendor;
  final String responseTime;

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          RotationTransition(
            turns: CurvedAnimation(parent: _c, curve: Motion.easeInOut),
            child: IconTile(
              icon: AppIcons.hourglass,
              hue: Hue.violet,
              size: 56,
            ),
          ),
          const SizedBox(height: 14),
          Text('Demande envoyée'.tr, style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text(
            '{0} prépare votre devis. Réponse moyenne en {1}.'.trf([
              widget.vendor,
              widget.responseTime,
            ]),
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 18),
          const Skeleton(height: 14),
          const SizedBox(height: 8),
          const Skeleton(height: 14, width: 200),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote, this.compact = false});

  final Quote quote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    Widget row(
      String a,
      int b, {
      bool strong = false,
      bool muted = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              a,
              style: strong
                  ? context.text.titleMedium
                  : context.text.bodyMedium?.copyWith(
                      color: muted ? Confetti.inkMuted : null,
                    ),
            ),
          ),
          Text(
            fcfa(b),
            style: (strong ? context.text.titleMedium : context.text.titleSmall)
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: AppIcons.file, hue: Hue.mango, size: 36),
              const SizedBox(width: 10),
              Expanded(child: Text('Devis'.tr, style: context.text.titleLarge)),
              Tag(
                label: 'Valable jusqu’au {0}'.trf([shortDate(q.validUntil)]),
                hue: Hue.mango,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!compact) ...[
            for (final l in q.lines)
              row(
                l.optional ? 'Option · {0}'.trf([l.label]) : l.label,
                l.amount,
              ),
            row('Frais de service'.tr, q.fees, muted: true),
            const Divider(height: 18),
          ],
          row('Total'.tr, q.total, strong: true),
          row('Acompte (30 %)'.tr, q.deposit, muted: true),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text('Conditions'.tr, style: context.text.labelMedium),
            const SizedBox(height: 6),
            for (final c in q.conditions)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        AppIcons.check,
                        size: 13,
                        color: Confetti.lagoonText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c, style: context.text.bodySmall)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.hue,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Hue hue;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: hue.tint,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, hue: hue, size: 40, solid: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleMedium?.copyWith(color: hue.deep),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: context.text.bodySmall?.copyWith(color: hue.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.done,
  });

  final IconData icon;
  final String title;
  final String caption;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: done ? Confetti.lagoon : Confetti.inkMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(caption, style: context.text.bodySmall),
              ],
            ),
          ),
          if (done)
            Icon(AppIcons.checkCircle, size: 18, color: Confetti.lagoon),
        ],
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final m in messages)
          Align(
            alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 290),
              decoration: BoxDecoration(
                color: m.fromMe ? Confetti.ink : Confetti.surface,
                border: m.fromMe ? null : Border.all(color: Confetti.line),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(m.fromMe ? 18 : 4),
                  bottomRight: Radius.circular(m.fromMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.text,
                    style: context.text.bodyMedium?.copyWith(
                      color: m.fromMe ? Confetti.onInk : Confetti.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeOf(m.at),
                    style: context.text.labelSmall?.copyWith(
                      color: m.fromMe ? Colors.white54 : Confetti.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

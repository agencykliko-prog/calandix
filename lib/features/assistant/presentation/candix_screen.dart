import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/contact_team.dart';
import '../../../ui/widgets/mascot.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../../marketplace/presentation/explore_screen.dart' show Choice;
import '../data/candix_answers.dart';

class _Line {
  const _Line(this.text, {this.mine = false});
  final String text;
  final bool mine;
}

/// Candix, l'assistance de l'application, et l'accès à un conseiller.
class CandixScreen extends StatefulWidget {
  const CandixScreen({super.key});

  @override
  State<CandixScreen> createState() => _CandixScreenState();
}

class _CandixScreenState extends State<CandixScreen> {
  final _field = TextEditingController();
  final _scroll = ScrollController();
  final _lines = <_Line>[
    _Line(
      'Bonjour, je suis Candix. Posez-moi vos questions sur Calandix : budget, prestataires, invités, paiements…'
          .tr,
    ),
  ];

  @override
  void dispose() {
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ask(String question) {
    final q = question.trim();
    if (q.isEmpty) return;
    setState(() {
      _lines
        ..add(_Line(q, mine: true))
        ..add(_Line(candixAnswer(q)));
      _field.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: Motion.base,
        curve: Motion.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Candix'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  const Center(child: Mascot(size: 110, waving: true)),
                  const SizedBox(height: 12),
                  for (final l in _lines) _Bubble(line: l),
                  if (_lines.length == 1) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in candixSuggestions)
                          Choice(
                            label: s.tr,
                            on: false,
                            onTap: () => _ask(s.tr),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Parler à un conseiller : une ligne, sans plus.
            Pressable(
              onTap: () => showContactTeam(context),
              semanticLabel: 'Parler à un conseiller'.tr,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.headset,
                      size: 17,
                      color: Confetti.violetText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Parler à un conseiller'.tr,
                      style: context.text.labelLarge?.copyWith(
                        color: Confetti.violetText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _field,
                      onSubmitted: _ask,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Votre question…'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: AppIcons.send,
                    tooltip: 'Envoyer',
                    size: 50,
                    background: Confetti.violet,
                    foreground: Confetti.onViolet,
                    onTap: () => _ask(_field.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line});

  final _Line line;

  @override
  Widget build(BuildContext context) {
    final mine = line.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? Confetti.violet : Confetti.surface,
          borderRadius: BorderRadius.circular(18),
          border: mine ? null : Border.all(color: Confetti.line),
        ),
        child: Text(
          line.text,
          style: context.text.bodyMedium?.copyWith(
            color: mine ? Confetti.onViolet : Confetti.ink,
          ),
        ),
      ),
    );
  }
}

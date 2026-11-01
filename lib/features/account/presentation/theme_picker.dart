import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/prefs/prefs_provider.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';

/// Thème prêt à l'emploi : une couleur principale et un fond.
class _Preset {
  const _Preset(this.name, this.accent, this.backdrop);
  final String name;
  final int accent;
  final int backdrop;
}

const _presets = [
  _Preset('Océan', 0xFF2373E1, 0xFFC8F0FD),
  _Preset('Forêt', 0xFF102930, 0xFFD4FDD1),
  _Preset('Couchant', 0xFFFF5C35, 0xFFFFFFFF),
  _Preset('Orchidée', 0xFFB400FF, 0xFFFFFFFF),
];

/// Couleurs assez soutenues pour porter boutons et accents.
const _accents = [
  0xFF0D1639,
  0xFF7DA1B1,
  0xFF0DD392,
  0xFF2373E1,
  0xFFB400FF,
  0xFFFF5C35,
  0xFF000000,
  0xFF454545,
  0xFF102930,
  0xFF4FA6F3,
  0xFFFD9467,
  0xFF808080,
];

/// Couleurs claires, pour le fond de l'interface.
const _backdrops = [0xFFFFFFFF, 0xFFD4FDD1, 0xFFC8F0FD];

/// Compte › Couleur du thème : quatre thèmes et un choix libre.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final n = ref.read(prefsProvider.notifier);
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final p in _presets)
                    SizedBox(
                      width: w,
                      child: _PresetCard(
                        preset: p,
                        selected:
                            prefs.accent == p.accent &&
                            prefs.backdrop == p.backdrop,
                        onTap: () => n.setTheme(p.accent, p.backdrop),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text('Couleur principale'.tr, style: context.text.titleSmall),
          const SizedBox(height: 10),
          _Swatches(
            colors: _accents,
            value: prefs.accent,
            onTap: (c) => n.setTheme(c, prefs.backdrop),
          ),
          const SizedBox(height: 18),
          Text('Fond'.tr, style: context.text.titleSmall),
          const SizedBox(height: 10),
          _Swatches(
            colors: _backdrops,
            value: prefs.backdrop,
            onTap: (c) => n.setTheme(prefs.accent, c),
          ),
          if (prefs.accent != null || prefs.backdrop != null) ...[
            const SizedBox(height: 14),
            PillButton(
              label: 'Revenir aux couleurs Calandix'.tr,
              icon: AppIcons.refresh,
              tone: ButtonTone.ghost,
              height: 46,
              onPressed: () => n.setTheme(null, null),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _Preset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: preset.name,
      child: AnimatedContainer(
        duration: Motion.fast,
        height: 74,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(preset.backdrop),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Confetti.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(preset.accent),
                shape: BoxShape.circle,
              ),
              child: selected
                  ? Icon(AppIcons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                preset.name.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(
                  color: Confetti.inkFixed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.colors,
    required this.value,
    required this.onTap,
  });

  final List<int> colors;
  final int? value;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colors)
          Pressable(
            onTap: () => onTap(c),
            semanticLabel: '#${c.toRadixString(16).substring(2).toUpperCase()}',
            child: AnimatedContainer(
              duration: Motion.fast,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: value == c ? Confetti.ink : Confetti.line,
                  width: value == c ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

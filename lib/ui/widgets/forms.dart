import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/tr.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/eventa_colors.dart';
import 'pressable.dart';
import 'ui.dart';

/// Libellé de champ : petit, au-dessus, aligné à gauche.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false, this.color});

  final String text;
  final bool optional;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7, left: 2),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (optional)
              TextSpan(
                text: '  facultatif',
                style: context.text.labelSmall?.copyWith(
                  color: Confetti.inkFaint,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        style: context.text.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

/// Champ texte avec libellé. Gère le mot de passe (afficher/masquer).
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard,
    this.password = false,
    this.optional = false,
    this.maxLines = 1,
    this.prefix,
    this.suffixText,
    this.validator,
    this.formatters,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.floating = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final bool password;
  final bool optional;
  final int maxLines;
  final Widget? prefix;
  final String? suffixText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Libellé dans le champ, qui flotte au-dessus au focus ou une fois
  /// rempli (écrans d'accès).
  final bool floating;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  bool _hidden = true;
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus != _focused) {
        setState(() => _focused = _focus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Le libellé se colore et glisse à peine quand le champ est actif.
        if (!widget.floating)
          AnimatedSlide(
            duration: Motion.fast,
            curve: Motion.easeOut,
            offset: Offset(_focused ? 0.012 : 0, 0),
            child: TweenAnimationBuilder<Color?>(
              duration: Motion.fast,
              tween: ColorTween(
                end: _focused ? Confetti.coralDeep : Confetti.ink,
              ),
              builder: (context, c, _) =>
                  FieldLabel(widget.label, optional: widget.optional, color: c),
            ),
          ),
        // Halo coloré et léger soulèvement au focus.
        AnimatedContainer(
          duration: Motion.base,
          curve: Motion.easeOut,
          transform: Matrix4.translationValues(0, _focused ? -1.5 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Confetti.coral.withValues(alpha: _focused ? 0.16 : 0),
                blurRadius: _focused ? 18 : 0,
                spreadRadius: _focused ? 1 : 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: widget.keyboard,
            obscureText: widget.password && _hidden,
            maxLines: widget.password ? 1 : widget.maxLines,
            minLines: widget.maxLines > 1 ? 3 : 1,
            autofocus: widget.autofocus,
            inputFormatters: widget.formatters,
            textInputAction: widget.maxLines > 1
                ? TextInputAction.newline
                : widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: context.text.bodyLarge,
            decoration: InputDecoration(
              labelText: widget.floating ? widget.label : null,
              floatingLabelStyle: TextStyle(
                color: Confetti.coralDeep,
                fontWeight: FontWeight.w500,
              ),
              labelStyle: TextStyle(color: Confetti.inkMuted),
              contentPadding: widget.floating
                  ? const EdgeInsets.fromLTRB(16, 20, 16, 12)
                  : null,
              // Le texte d'exemple s'estompe et glisse quand on entre.
              hint: hint == null || (widget.floating && !_focused)
                  ? null
                  : AnimatedSlide(
                      duration: Motion.base,
                      curve: Motion.easeOut,
                      offset: Offset(_focused ? 0.04 : 0, 0),
                      child: AnimatedOpacity(
                        duration: Motion.base,
                        opacity: _focused ? 0.45 : 1,
                        child: Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyLarge?.copyWith(
                            color: Confetti.inkFaint,
                          ),
                        ),
                      ),
                    ),
              prefixIcon: widget.prefix,
              suffixText: widget.suffixText,
              errorStyle: TextStyle(color: Confetti.danger, fontSize: 12),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Confetti.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Confetti.danger, width: 1.4),
              ),
              suffixIcon: widget.password
                  ? IconButton(
                      tooltip: _hidden ? 'Afficher'.tr : 'Masquer'.tr,
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: AnimatedSwitcher(
                        duration: Motion.fast,
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Icon(
                          _hidden ? AppIcons.eye : AppIcons.eyeOff,
                          key: ValueKey(_hidden),
                          size: 19,
                          color: Confetti.inkMuted,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Préfixe téléphone ivoirien (+225 par défaut).
class PhonePrefix extends StatelessWidget {
  const PhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const SizedBox(
              width: 18,
              height: 12,
              child: Row(
                children: [
                  Expanded(child: ColoredBox(color: Color(0xFFF77F00))),
                  Expanded(child: ColoredBox(color: Colors.white)),
                  Expanded(child: ColoredBox(color: Color(0xFF009E60))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('+225', style: context.text.titleSmall),
          const SizedBox(width: 10),
          Container(width: 1, height: 20, color: Confetti.line),
        ],
      ),
    );
  }
}

/// Menu déroulant homogène : un champ qui ouvre une liste d'options.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.hint = 'Choisir',
    this.iconOf,
    this.optional = false,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final ValueChanged<T> onChanged;
  final String hint;
  final bool optional;

  Future<void> _open(BuildContext context) async {
    final picked = await showEventaSheet<T>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Text(label, style: ctx.text.titleLarge),
          ),
          for (final o in options)
            Pressable(
              scale: 0.98,
              onTap: () => Navigator.of(ctx).pop(o),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: o == value
                      ? Confetti.lavender.withValues(alpha: 0.7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (iconOf != null) ...[
                      Icon(iconOf!(o), size: 19, color: Confetti.inkMuted),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(labelOf(o), style: ctx.text.titleSmall),
                    ),
                    if (o == value)
                      Icon(AppIcons.check, size: 17, color: Confetti.coral),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, optional: optional),
        Pressable(
          scale: 0.99,
          onTap: () => _open(context),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Confetti.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Confetti.line),
            ),
            child: Row(
              children: [
                if (v != null && iconOf != null) ...[
                  Icon(iconOf!(v), size: 18, color: Confetti.inkMuted),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    v == null ? hint : labelOf(v),
                    style: context.text.bodyLarge?.copyWith(
                      color: v == null ? Confetti.inkFaint : Confetti.ink,
                    ),
                  ),
                ),
                Icon(AppIcons.chevronDown, size: 16, color: Confetti.inkMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne avec case à cocher, et contenu conditionnel révélé quand cochée.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.caption,
    this.revealed,
  });

  final String label;
  final String? caption;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Champs supplémentaires affichés seulement si la case est cochée.
  final Widget? revealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.fast,
      decoration: BoxDecoration(
        color: Confetti.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? Confetti.ink : Confetti.line,
          width: value ? 1.3 : 1,
        ),
      ),
      child: Column(
        children: [
          Pressable(
            scale: 0.99,
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: Motion.fast,
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: value ? Confetti.ink : Confetti.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: value ? Confetti.ink : Confetti.border,
                        width: 1.5,
                      ),
                    ),
                    child: value
                        ? const Icon(
                            AppIcons.check,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: context.text.titleSmall),
                        if (caption != null)
                          Text(caption!, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: value && revealed != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: revealed,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Validateurs partagés.
abstract final class Validators {
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire'.tr : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ obligatoire'.tr;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
        ? null
        : 'Adresse e-mail invalide'.tr;
  }

  static String? phone(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    return d.length == 10 ? null : 'Numéro à 10 chiffres'.tr;
  }

  static String? password(String? v) {
    final p = v ?? '';
    if (p.length < 8) return '8 caractères minimum'.tr;
    if (p.length > 72) return '72 caractères maximum'.tr;
    if (!RegExp(r'[a-z]').hasMatch(p) ||
        !RegExp(r'[A-Z]').hasMatch(p) ||
        !RegExp(r'[0-9]').hasMatch(p)) {
      return 'Au moins une minuscule, une majuscule et un chiffre'.tr;
    }
    return null;
  }
}

const ivoryCities = [
  'Abidjan',
  'Bouaké',
  'Yamoussoukro',
  'San-Pédro',
  'Daloa',
  'Korhogo',
  'Man',
  'Grand-Bassam',
  'Assinie',
  'Autre',
];

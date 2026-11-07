import 'package:intl/intl.dart';

import '../i18n/tr.dart';

NumberFormat get _fcfa => NumberFormat.decimalPattern(L10n.intl);

/// Espace insécable : un montant ne se coupe jamais en fin de ligne.
const _nbsp = '\u00a0';

/// 12 500 000 FCFA
String fcfa(num amount) => '{0}{1}FCFA'.trf([
  _fcfa.format(amount).replaceAll('\u202f', _nbsp).replaceAll(' ', _nbsp),
  _nbsp,
]);

/// 2 000 — un nombre avec séparateur de milliers insécable.
String formatNumber(num n) =>
    _fcfa.format(n).replaceAll('\u202f', _nbsp).replaceAll(' ', _nbsp);

/// 12,5 M — pour les chiffres compacts des cartes.
String fcfaCompact(num amount) {
  if (amount >= 1000000) {
    final m = amount / 1000000;
    final s = m == m.roundToDouble()
        ? m.toStringAsFixed(0)
        : m.toStringAsFixed(1).replaceAll('.', ',');
    return '{0}{1}M'.trf([s, _nbsp]);
  }
  if (amount >= 1000) return '${(amount / 1000).round()}${_nbsp}k';
  return amount.toString();
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysUntil(DateTime date, {DateTime? from}) =>
    dateOnly(date).difference(dateOnly(from ?? DateTime.now())).inDays;

/// J-42, Jour J, J+3
String countdownLabel(DateTime date) {
  final d = daysUntil(date);
  if (d == 0) return 'Jour J'.tr;
  return d > 0 ? 'J-{0}'.trf([d]) : 'J+{0}'.trf([-d]);
}

String longDate(DateTime d) => DateFormat('EEEE d MMMM y', L10n.intl).format(d);
String mediumDate(DateTime d) => DateFormat('d MMM y', L10n.intl).format(d);
String shortDate(DateTime d) => DateFormat('d MMM', L10n.intl).format(d);
String weekdayShort(DateTime d) =>
    DateFormat('EEE', L10n.intl).format(d).replaceAll('.', '');
String timeOf(DateTime d) => DateFormat('HH:mm', L10n.intl).format(d);

String relativeDue(DateTime due) {
  final d = daysUntil(due);
  if (d < -1) return 'En retard de {0} j'.trf([-d]);
  if (d == -1) return 'Hier'.tr;
  if (d == 0) return 'Aujourd\'hui'.tr;
  if (d == 1) return 'Demain'.tr;
  if (d < 7) return 'Dans {0} jours'.trf([d]);
  return shortDate(due);
}

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 5 || h >= 18) return 'Bonsoir'.tr;
  return 'Bonjour'.tr;
}

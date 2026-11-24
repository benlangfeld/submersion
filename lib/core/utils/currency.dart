import 'package:intl/intl.dart';

import 'package:submersion/core/constants/currencies.dart';

/// Initial preferred currencies for users who have not configured their list.
/// Every picker also offers the full ISO 4217 catalog.
const List<String> kCommonCurrencyCodes = [
  'USD',
  'EUR',
  'GBP',
  'CHF',
  'AUD',
  'CAD',
  'NZD',
  'JPY',
  'SEK',
  'NOK',
  'DKK',
  'PLN',
  'THB',
  'EGP',
  'MXN',
  'IDR',
  'PHP',
  'ZAR',
];

/// Normalizes preferences without discarding historical or future ISO codes.
List<String> normalizeCurrencyPreferences(Iterable<String> codes) =>
    List.unmodifiable({
      for (final code in codes.map((raw) => raw.trim().toUpperCase()))
        if (RegExp(r'^[A-Z]{3}$').hasMatch(code)) code,
    });

bool currencyMatchesQuery(String code, String query) {
  final search = query.trim().toLowerCase();
  return code.toLowerCase().contains(search) ||
      (kCurrencyNames[code] ?? '').toLowerCase().contains(search);
}

/// Preferred currencies first, then the complete offline catalog by code.
/// A stored value outside the preferences leads the list, even if it is a
/// historical or custom code, so opening an editor never drops its currency.
List<String> currencyCodesWith(
  String? currentCode, {
  Iterable<String> preferred = kCommonCurrencyCodes,
}) {
  final current = (currentCode ?? '').trim().toUpperCase();
  final favorites = normalizeCurrencyPreferences(preferred);
  return List.unmodifiable({
    if (current.isNotEmpty && !favorites.contains(current)) current,
    ...favorites,
    ...kCurrencyNames.keys,
  });
}

/// The symbol for [currencyCode] (e.g. 'EUR' -> '€'), falling back to the
/// upper-cased code itself for anything intl doesn't recognise (or an empty
/// string for a blank code).
String currencySymbol(String currencyCode) {
  final code = currencyCode.trim().toUpperCase();
  if (code.isEmpty) return '';
  try {
    return NumberFormat.simpleCurrency(name: code).currencySymbol;
  } catch (_) {
    return code;
  }
}

/// Formats [amount] in [currencyCode] using the currency's symbol, falling back
/// to "CODE 12.34" for unrecognised codes.
String formatMoney(double amount, String currencyCode) {
  final code = currencyCode.trim().toUpperCase();
  try {
    return NumberFormat.simpleCurrency(name: code).format(amount);
  } catch (_) {
    final prefix = code.isEmpty ? '' : '$code ';
    return '$prefix${amount.toStringAsFixed(2)}';
  }
}

/// Formats [amount] as a plain localized number, with no currency symbol or
/// code - for a total that is already labeled with its currency elsewhere,
/// so the amount doesn't need to repeat it (and can't disagree with it: two
/// currencies can render the same symbol, e.g. USD and CAD both show '$').
/// Uses [currencyCode]'s own decimal precision (e.g. no decimals for JPY) so
/// it still matches formatMoney's per-record rows; falls back to two decimal
/// digits for unrecognised codes or locale data intl has no number symbols
/// for, the same degrade path as formatMoney.
String formatAmountOnly(double amount, String currencyCode) {
  final code = currencyCode.trim().toUpperCase();
  try {
    final decimalDigits = NumberFormat.simpleCurrency(name: code).decimalDigits;
    return NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
    ).format(amount).trim();
  } catch (_) {
    return amount.toStringAsFixed(2);
  }
}

/// [code] trimmed and upper-cased, or [fallback] when blank: legacy rows can
/// carry an empty or lowercase code, and each must land in one bucket.
String normalizeCurrencyCode(String code, {required String fallback}) {
  final trimmed = code.trim().toUpperCase();
  return trimmed.isEmpty ? fallback : trimmed;
}

/// Sums the amounts in [items] grouped by their currency, so a collection
/// priced in more than one currency is never added into a single misleading
/// figure.
///
/// [amountOf] returns null for items with no price (those are skipped), and a
/// blank [currencyOf] falls back to [fallbackCode] - legacy rows can carry an
/// empty code. Entries come back ordered by descending total, then by code, so
/// the display order is stable across rebuilds.
List<MapEntry<String, double>> sumByCurrency<T>(
  Iterable<T> items, {
  required double? Function(T item) amountOf,
  required String Function(T item) currencyOf,
  required String fallbackCode,
}) {
  final fallback = normalizeCurrencyCode(fallbackCode, fallback: '');
  final totals = <String, double>{};
  for (final item in items) {
    final amount = amountOf(item);
    if (amount == null) continue;
    final code = normalizeCurrencyCode(currencyOf(item), fallback: fallback);
    totals[code] = (totals[code] ?? 0) + amount;
  }
  final entries = totals.entries.toList()
    ..sort((a, b) {
      final byTotal = b.value.compareTo(a.value);
      return byTotal != 0 ? byTotal : a.key.compareTo(b.key);
    });
  return entries;
}

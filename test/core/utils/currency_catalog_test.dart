import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/core/constants/currencies.dart';
import 'package:submersion/core/utils/currency.dart';

void main() {
  test('catalog includes BRL and currencies beyond the old presets', () {
    expect(kCurrencyNames['BRL'], 'Brazilian Real');
    expect(
      kCurrencyNames.keys,
      containsAll(['INR', 'CNY', 'ISK', 'XCG', 'ZWG']),
    );
    expect(kCurrencyNames.length, greaterThan(150));
    expect(
      kCurrencyNames.keys.toList(),
      orderedEquals(kCurrencyNames.keys.toList()..sort()),
    );
  });

  test('preferences lead every catalog without hiding other currencies', () {
    final codes = currencyCodesWith('EUR', preferred: [' brl ', 'USD', 'BRL']);
    expect(codes.take(3), ['EUR', 'BRL', 'USD']);
    expect(codes, containsAll(kCurrencyNames.keys));
    expect(codes.toSet(), hasLength(codes.length));
  });

  test('empty preferences still offer the complete catalog', () {
    expect(
      currencyCodesWith(null, preferred: []),
      kCurrencyNames.keys.toList(),
    );
  });

  test('stored historical and custom codes remain selectable', () {
    final codes = currencyCodesWith(' hrk ', preferred: ['ZWG']);
    expect(codes.first, 'HRK');
    expect(codes, containsAll(kCurrencyNames.keys));
  });

  test(
    'preference normalization keeps unknown codes but rejects malformed ones',
    () {
      expect(
        normalizeCurrencyPreferences([' brl ', 'BRL', '', 'US', 'ZZZ', '12!']),
        ['BRL', 'ZZZ'],
      );
    },
  );
}

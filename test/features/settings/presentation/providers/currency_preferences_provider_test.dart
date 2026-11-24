import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/core/constants/currencies.dart';
import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/core/utils/currency.dart';
import 'package:submersion/features/settings/data/repositories/app_settings_repository.dart';
import 'package:submersion/features/settings/presentation/providers/currency_preferences_provider.dart';
import 'package:submersion/features/settings/presentation/providers/settings_providers.dart';

class _Repository extends AppSettingsRepository {
  List<String>? preferred;
  final changes = StreamController<void>.broadcast();

  @override
  Future<List<String>?> getPreferredCurrencyCodes() async => preferred;

  @override
  Stream<void> watchSettingsChanges() => changes.stream;
}

void main() {
  late _Repository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _Repository();
    container = ProviderContainer(
      overrides: [appSettingsRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() async {
    container.dispose();
    await repo.changes.close();
  });

  test('unset preferences use the existing defaults', () async {
    expect(
      await container.read(preferredCurrencyCodesProvider.future),
      kCommonCurrencyCodes,
    );
  });

  test(
    'empty preferences expose the full catalog without default favorites',
    () async {
      repo.preferred = [];
      await container.read(preferredCurrencyCodesProvider.future);
      expect(
        container.read(currencyOptionsProvider(null)),
        kCurrencyNames.keys.toList(),
      );
    },
  );

  test(
    'a sync change reorders every selector without hiding other codes',
    () async {
      repo.preferred = ['BRL'];
      container.listen(currencyOptionsProvider(null), (_, _) {});
      await container.read(preferredCurrencyCodesProvider.future);
      expect(container.read(currencyOptionsProvider(null)).first, 'BRL');
      expect(container.read(currencyOptionsProvider('HRK')).first, 'HRK');

      repo.preferred = ['JPY', 'BRL'];
      repo.changes.add(null);
      await Future<void>.delayed(Duration.zero);
      await container.read(preferredCurrencyCodesProvider.future);
      final updated = container.read(currencyOptionsProvider(null));
      expect(updated.take(2), ['JPY', 'BRL']);
      expect(updated, containsAll(kCurrencyNames.keys));
    },
  );
}

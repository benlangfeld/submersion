import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/core/utils/currency.dart';
import 'package:submersion/features/settings/presentation/providers/settings_providers.dart';

/// Shared library preference. Remote sync edits refresh every open selector.
final preferredCurrencyCodesProvider = FutureProvider<List<String>>((
  ref,
) async {
  final repo = ref.watch(appSettingsRepositoryProvider);
  ref.invalidateSelfWhen(repo.watchSettingsChanges());
  return await repo.getPreferredCurrencyCodes() ?? kCommonCurrencyCodes;
});

final currencyOptionsProvider = Provider.family<List<String>, String?>((
  ref,
  current,
) {
  return currencyCodesWith(
    current,
    preferred:
        ref.watch(preferredCurrencyCodesProvider).value ?? kCommonCurrencyCodes,
  );
});

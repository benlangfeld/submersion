import 'package:flutter/material.dart';

import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/features/settings/presentation/providers/currency_preferences_provider.dart';
import 'package:submersion/features/settings/presentation/providers/settings_providers.dart';
import 'package:submersion/l10n/l10n_extension.dart';
import 'package:submersion/shared/widgets/currency_picker_dialog.dart';

class PreferredCurrenciesTile extends ConsumerWidget {
  const PreferredCurrenciesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferred = ref.watch(preferredCurrencyCodesProvider).value;
    return ListTile(
      title: Text(context.l10n.settings_currency_preferred_title),
      subtitle: Text(context.l10n.settings_currency_preferred_subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: preferred == null
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (_) => PreferredCurrenciesDialog(
                preferred: preferred,
                onSave: (codes) async {
                  await ref
                      .read(appSettingsRepositoryProvider)
                      .setPreferredCurrencyCodes(codes);
                  ref.invalidate(preferredCurrencyCodesProvider);
                },
              ),
            ),
    );
  }
}

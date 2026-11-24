import 'package:flutter/material.dart';

import 'package:submersion/core/constants/currencies.dart';
import 'package:submersion/core/utils/currency.dart';
import 'package:submersion/l10n/l10n_extension.dart';

/// Searchable offline catalog shared by the default picker and preferences.
class CurrencyPickerDialog extends StatefulWidget {
  const CurrencyPickerDialog({
    super.key,
    required this.currentCode,
    required this.preferred,
  });

  final String currentCode;
  final List<String> preferred;

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.settings_units_dialog_defaultCurrency),
    content: _CurrencyList(
      codes: currencyCodesWith(widget.currentCode, preferred: widget.preferred),
      query: _query,
      onQueryChanged: (value) => setState(() => _query = value),
      row: (code) => ListTile(
        key: ValueKey('currency-$code'),
        title: Text(code),
        subtitle: Text(kCurrencyNames[code] ?? code),
        leading: SizedBox(width: 40, child: Text(currencySymbol(code))),
        trailing: code == widget.currentCode.trim().toUpperCase()
            ? const Icon(Icons.check)
            : null,
        onTap: () => Navigator.of(context).pop(code),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.common_action_cancel),
      ),
    ],
  );
}

/// Changes are staged until Save; a failed write keeps the edits open.
class PreferredCurrenciesDialog extends StatefulWidget {
  const PreferredCurrenciesDialog({
    super.key,
    required this.preferred,
    required this.onSave,
  });

  final List<String> preferred;
  final Future<void> Function(List<String>) onSave;

  @override
  State<PreferredCurrenciesDialog> createState() =>
      _PreferredCurrenciesDialogState();
}

class _PreferredCurrenciesDialogState extends State<PreferredCurrenciesDialog> {
  late List<String> _selected = normalizeCurrencyPreferences(widget.preferred);
  late final _codes = currencyCodesWith(null, preferred: widget.preferred);
  String _query = '';
  bool _saving = false;
  bool _failed = false;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(_selected);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(context.l10n.settings_currency_preferred_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.settings_currency_preferred_subtitle),
          const SizedBox(height: 12),
          Flexible(
            child: _CurrencyList(
              codes: _codes,
              query: _query,
              onQueryChanged: (value) => setState(() => _query = value),
              row: (code) => CheckboxListTile(
                key: ValueKey('currency-$code'),
                title: Text(code),
                subtitle: Text(kCurrencyNames[code] ?? code),
                value: _selected.contains(code),
                onChanged: _saving
                    ? null
                    : (checked) => setState(() {
                        _selected = checked == true
                            ? [..._selected, code]
                            : _selected
                                  .where((value) => value != code)
                                  .toList();
                      }),
              ),
            ),
          ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                context.l10n.common_error_tryAgain,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_action_cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(context.l10n.common_action_save),
        ),
      ],
    ),
  );
}

class _CurrencyList extends StatelessWidget {
  const _CurrencyList({
    required this.codes,
    required this.query,
    required this.onQueryChanged,
    required this.row,
  });

  final List<String> codes;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Widget Function(String code) row;

  @override
  Widget build(BuildContext context) {
    final matches = codes
        .where((code) => currencyMatchesQuery(code, query))
        .toList();
    return SizedBox(
      width: 480,
      height: 440,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: context.l10n.currency_search_hint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: matches.isEmpty
                ? Center(child: Text(context.l10n.currency_noResults))
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (_, index) => row(matches[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

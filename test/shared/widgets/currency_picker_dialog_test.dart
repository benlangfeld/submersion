import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/l10n/arb/app_localizations.dart';
import 'package:submersion/shared/widgets/currency_picker_dialog.dart';

void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => const CurrencyPickerDialog(
                  currentCode: 'ZZZ',
                  preferred: ['BRL'],
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('long currency names fit a small phone with enlarged text', (
    tester,
  ) async {
    await pumpPicker(tester, size: const Size(320, 568), textScale: 1.6);
    await tester.enterText(find.byType(TextField), 'XXX');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('currency-XXX')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'no such currency');
    await tester.pumpAndSettle();
    expect(find.text('No matching currencies'), findsOneWidget);
  });

  for (final width in [390.0, 1200.0]) {
    testWidgets('searches by name and code at width $width', (tester) async {
      await pumpPicker(tester, size: Size(width, 844));
      expect(find.byKey(const ValueKey('currency-ZZZ')), findsOneWidget);
      expect(find.byKey(const ValueKey('currency-BRL')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'brazil');
      await tester.pumpAndSettle();
      expect(find.text('Brazilian Real'), findsOneWidget);
      expect(find.text('USD'), findsNothing);
      await tester.enterText(find.byType(TextField), ' brl ');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('currency-BRL')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('currency-BRL')));
      await tester.pumpAndSettle();
      expect(find.byType(CurrencyPickerDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('preference edits are saved together and failures stay visible', (
    tester,
  ) async {
    List<String>? saved;
    var fail = true;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Open'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PreferredCurrenciesDialog(
                  preferred: const ['USD'],
                  onSave: (codes) async {
                    if (fail) throw StateError('unavailable');
                    saved = codes;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'BRL');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('currency-BRL')));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, ['USD', 'BRL']);
    expect(find.byType(PreferredCurrenciesDialog), findsNothing);
  });

  testWidgets('cancelling preferences leaves storage unchanged', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('Open'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PreferredCurrenciesDialog(
                  preferred: const [],
                  onSave: (_) async {
                    saved = true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'BRL');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('currency-BRL')));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
  });
}

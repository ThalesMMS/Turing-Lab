import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_parser.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/widgets/grammar/grammar_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/grammar/user_derivation_workspace.dart';

final _input = find.byKey(const ValueKey('grammar-parser-input'));
final _includeSpaces = find.byKey(
  const ValueKey('grammar-include-spaces-in-input'),
);

Future<void> _pumpPanel(
  WidgetTester tester,
  GrammarProvider grammar, {
  ParsingStrategyHint strategy = ParsingStrategyHint.cyk,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [grammarProvider.overrideWith((ref) => grammar)],
      child: const MaterialApp(
        home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
      ),
    ),
  );
  if (strategy != ParsingStrategyHint.cyk) {
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(GrammarParser.capabilityFor(strategy).label).last,
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _parseAndExpect(WidgetTester tester, String status) async {
  final parse = find.text('Parse String');
  await tester.ensureVisible(parse);
  await tester.tap(parse);
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text(status).evaluate().isNotEmpty) break;
  }
  expect(find.text(status), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _toggleSpaces(WidgetTester tester) async {
  await tester.ensureVisible(_includeSpaces);
  await tester.tap(_includeSpaces);
  await tester.pump();
}

void main() {
  for (final strategy in ParsingStrategyHint.values) {
    testWidgets('$strategy ignores spaces by default and retains typed text', (
      tester,
    ) async {
      final grammar = GrammarProvider()
        ..addProduction(leftSide: ['S'], rightSide: const ['id', '+', 'id']);
      await _pumpPanel(tester, grammar, strategy: strategy);
      await tester.enterText(_input, ' id + id ');

      await _parseAndExpect(tester, 'Accepted');

      expect(tester.widget<CheckboxListTile>(_includeSpaces).value, isFalse);
      expect(tester.widget<TextField>(_input).controller!.text, ' id + id ');
      await _toggleSpaces(tester);
      expect(find.text('Accepted'), findsNothing);
      expect(find.text('No parse results yet'), findsOneWidget);
      expect(tester.widget<TextField>(_input).controller!.text, ' id + id ');
    });
  }

  testWidgets('includes spaces within a terminal and at both ends on request', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(
        leftSide: ['S'],
        rightSide: const [' ', 'hello world', ' '],
      );
    await _pumpPanel(tester, grammar);
    await tester.enterText(_input, ' hello world ');
    await _toggleSpaces(tester);

    await _parseAndExpect(tester, 'Accepted');

    await _toggleSpaces(tester);
    expect(find.text('Accepted'), findsNothing);
    expect(find.text('No parse results yet'), findsOneWidget);
    expect(tester.widget<TextField>(_input).controller!.text, ' hello world ');
  });

  testWidgets('leaves tabs and nonbreaking spaces in the input', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a\t\u00a0b']);
    await _pumpPanel(tester, grammar);
    await tester.enterText(_input, ' a\t\u00a0b ');

    await _parseAndExpect(tester, 'Accepted');
  });

  testWidgets('treats an input containing only spaces as the empty word', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const [], isLambda: true);
    await _pumpPanel(tester, grammar);
    await tester.enterText(_input, '   ');

    await _parseAndExpect(tester, 'Accepted');
    expect(tester.widget<TextField>(_input).controller!.text, '   ');
  });

  testWidgets(
    'uses the space option for manual targets and invalidates sessions',
    (tester) async {
      final grammar = GrammarProvider()
        ..addProduction(leftSide: ['S'], rightSide: const ['id', '+', 'id'])
        ..addProduction(
          leftSide: ['S'],
          rightSide: const ['id', ' ', '+', ' ', 'id'],
        );
      await _pumpPanel(tester, grammar);
      await tester.enterText(_input, 'id + id');
      final start = find.byKey(const ValueKey('start-manual-derivation'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();

      UserDerivationWorkspace workspace() =>
          tester.widget<UserDerivationWorkspace>(
            find.byType(UserDerivationWorkspace),
          );
      expect(workspace().target.symbols.map((symbol) => symbol.value), [
        'id',
        '+',
        'id',
      ]);
      await _toggleSpaces(tester);
      expect(
        workspace().invalidationCode,
        UserDerivationDiagnosticCode.targetChanged,
      );

      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(workspace().invalidationCode, isNull);
      expect(workspace().target.symbols.map((symbol) => symbol.value), [
        'id',
        ' ',
        '+',
        ' ',
        'id',
      ]);
      expect(tester.widget<TextField>(_input).controller!.text, 'id + id');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('discards a pending parse when the space option changes', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['id', '+', 'id']);
    await _pumpPanel(tester, grammar);
    await tester.enterText(_input, 'id + id');
    await tester.tap(find.text('Parse String'));
    await _toggleSpaces(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsNothing);
    expect(find.text('Rejected'), findsNothing);
    expect(find.text('No parse results yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

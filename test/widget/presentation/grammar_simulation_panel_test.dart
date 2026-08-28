import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/widgets/grammar_simulation_panel.dart';

void main() {
  testWidgets('exposes only available parser strategies', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();

    expect(find.text('CYK (Cocke-Younger-Kasami)'), findsWidgets);
    expect(find.text('Automatic (Earley)'), findsWidgets);
    expect(find.text('Brute force'), findsOneWidget);
    expect(find.text('LL(1)'), findsOneWidget);
    expect(find.text('Canonical LR(1)'), findsOneWidget);
  });

  testWidgets('selects canonical LR(1) and navigates synchronized execution', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canonical LR(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('lr1-parse-table')).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Canonical collection'), findsOneWidget);
    expect(find.byKey(const ValueKey('lr1-parse-table')), findsOneWidget);
    expect(find.text('Shift-reduce execution'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('lr1-production-p1')), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Next step'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next step'));
    await tester.pump();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.textContaining('Reduction: p1'), findsOneWidget);

    await tester.tap(find.byTooltip('Reset execution'));
    await tester.pump();
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Play execution'));
    await tester.pump(const Duration(milliseconds: 850));
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.byTooltip('Pause execution'), findsOneWidget);
  });

  testWidgets('preserves and explains canonical LR(1) conflicts', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..updateStartSymbol('E')
      ..addProduction(leftSide: ['E'], rightSide: const ['E', '+', 'E'])
      ..addProduction(leftSide: ['E'], rightSide: const ['id']);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canonical LR(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'id+id');
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Canonical LR(1) conflict').evaluate().isNotEmpty) break;
    }

    expect(find.text('Canonical LR(1) conflict'), findsOneWidget);
    expect(find.text('Conflicts (all actions preserved)'), findsOneWidget);
    expect(find.textContaining('Shift/reduce at [I'), findsOneWidget);
    expect(find.textContaining('Witness prefix:'), findsOneWidget);
    expect(find.textContaining('Sources:'), findsOneWidget);
  });

  testWidgets('adapts canonical LR(1) to narrow high-scale text', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canonical LR(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('lr1-parse-table')).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('lr1-parse-table')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discards a stale canonical LR(1) result after input changes', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canonical LR(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));
    await tester.enterText(find.byType(TextField), 'b');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsNothing);
    expect(find.byKey(const ValueKey('lr1-parse-table')), findsNothing);
    expect(find.text('No parse results yet'), findsOneWidget);
  });

  testWidgets('selects LL(1) and navigates its predictive trace', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LL(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));

    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('LL(1) Steps').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('LL(1) Steps'), findsOneWidget);
    expect(find.text('LL(1) teaching workspace'), findsOneWidget);
    expect(find.text('FIRST(S)'), findsOneWidget);
    expect(find.text('FOLLOW(S)'), findsOneWidget);
    expect(find.byKey(const ValueKey('ll1-cell-S-a')), findsOneWidget);
    expect(find.text('Expand S'), findsOneWidget);
    expect(find.text('S → a'), findsOneWidget);
    expect(find.text('p1'), findsWidgets);
    expect(find.text(r'$ S'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Next step'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next step'));
    await tester.pump();

    expect(find.text('Match "a"'), findsOneWidget);
    expect(find.text(r'$ a'), findsOneWidget);

    await tester.tap(find.byTooltip('Reset'));
    await tester.pump();
    expect(find.text('Expand S'), findsOneWidget);

    await tester.tap(find.byTooltip('Play'));
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Match "a"'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();

    await tester.ensureVisible(find.text('Preview left factoring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview left factoring'));
    await tester.pumpAndSettle();
    expect(
      find.text('Preview only. The source grammar will not change.'),
      findsOneWidget,
    );
    expect(grammar.state.productions.single.rightSide, ['a']);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows typed LL(1) conflicts and selects their table cell', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a'])
      ..addProduction(leftSide: ['S'], rightSide: const ['a', 'a']);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LL(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('LL(1) conflict').evaluate().isNotEmpty) break;
    }

    expect(find.text('LL(1) conflict'), findsOneWidget);
    const conflictLabel =
        'FIRST/FIRST conflict in [S, a]: p1 S → a | p2 S → a a.';
    expect(find.text(conflictLabel), findsOneWidget);
    await tester.ensureVisible(find.text(conflictLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(conflictLabel));
    await tester.pump();
    expect(find.textContaining('[S, a]'), findsWidgets);
    expect(find.textContaining('p1: S → a — FIRST'), findsOneWidget);
  });

  testWidgets('does not attach a result after the grammar or input changes', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LL(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));
    grammar.updateProduction(
      'p1',
      leftSide: const ['S'],
      rightSide: const ['b'],
    );

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsNothing);
    expect(find.text('LL(1) teaching workspace'), findsNothing);
    expect(find.text('No parse results yet'), findsOneWidget);

    grammar.updateProduction(
      'p1',
      leftSide: const ['S'],
      rightSide: const ['a'],
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));
    await tester.enterText(find.byType(TextField), 'b');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsNothing);
    expect(find.text('LL(1) teaching workspace'), findsNothing);
  });

  testWidgets('adapts the LL(1) workspace to narrow high-scale text', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LL(1)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('LL(1) teaching workspace').evaluate().isNotEmpty) break;
    }

    expect(find.text('LL(1) teaching workspace'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parses blank input as epsilon', (tester) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const [], isLambda: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );

    expect(
      find.text('Leave blank for ε; whitespace is preserved'),
      findsOneWidget,
    );
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Accepted').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Please enter a string to parse'), findsNothing);
  });

  testWidgets(
    'runs bounded brute force and navigates ambiguous derivation witnesses',
    (tester) async {
      String? copiedReport;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedReport =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      final grammar = GrammarProvider()
        ..addProduction(leftSide: ['S'], rightSide: const ['A'])
        ..addProduction(leftSide: ['S'], rightSide: const ['A'])
        ..addProduction(leftSide: ['A'], rightSide: const ['a']);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [grammarProvider.overrideWith((ref) => grammar)],
          child: const MaterialApp(
            home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
          ),
        ),
      );

      await tester.tap(
        find.byType(DropdownButtonFormField<ParsingStrategyHint>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brute force').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('brute-force-search-options')),
        findsOneWidget,
      );
      expect(find.text('Maximum depth'), findsOneWidget);
      expect(find.text('Leftmost'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('grammar-parser-input')),
        'a',
      );
      await tester.ensureVisible(find.text('Parse String'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parse String'));
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump(const Duration(milliseconds: 20));
        if (find
            .byKey(const ValueKey('brute-force-teaching-workspace'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      expect(find.text('Accepted'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('brute-force-teaching-workspace')),
        findsOneWidget,
      );
      expect(find.text('Witnesses'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('brute-force-witness-selector')),
        findsOneWidget,
      );
      expect(find.textContaining('production p1'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Next derivation step'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next derivation step'));
      await tester.pump();
      expect(find.textContaining('Step 2 of 2'), findsOneWidget);
      expect(find.textContaining('production p3'), findsOneWidget);

      final witnessSelector = find.byKey(
        const ValueKey('brute-force-witness-selector'),
      );
      await tester.ensureVisible(witnessSelector);
      await tester.pumpAndSettle();
      await tester.tap(witnessSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Witness 2').last);
      await tester.pump();
      expect(find.textContaining('production p2'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Copy JSON report'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Copy JSON report'));
      await tester.pumpAndSettle();
      expect(copiedReport, contains('"outcome": "accepted"'));
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    },
  );

  testWidgets('reports a brute-force depth bound as inconclusive', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brute force').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('brute-force-depth-limit')),
      '0',
    );
    await tester.enterText(
      find.byKey(const ValueKey('grammar-parser-input')),
      'a',
    );
    await tester.ensureVisible(find.text('Parse String'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Inconclusive within limits').evaluate().isNotEmpty) break;
    }

    expect(find.text('Inconclusive within limits'), findsOneWidget);
    expect(find.text('Rejected'), findsNothing);
    expect(find.text('Reached limit'), findsOneWidget);
    expect(find.text('depth'), findsOneWidget);
  });

  testWidgets('cancels a cooperative brute-force search responsively', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['S', 'S'])
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brute force').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('grammar-parser-input')),
      'aaaaaaaaaaaaaa',
    );
    await tester.ensureVisible(find.text('Parse String'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parse String'));
    await tester.pump();
    expect(find.text('Cancel search'), findsOneWidget);
    await tester.tap(find.text('Cancel search'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Cancelled').evaluate().isNotEmpty) break;
    }

    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Rejected'), findsNothing);
  });

  testWidgets('keeps brute-force controls usable at phone width and 2x text', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ParsingStrategyHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brute force').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('grammar-parser-input')),
      'a',
    );
    await tester.ensureVisible(find.text('Parse String'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parse String'));
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (find
          .byKey(const ValueKey('brute-force-teaching-workspace'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.byKey(const ValueKey('brute-force-teaching-workspace')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('starts and invalidates a user-controlled CFG derivation', (
    tester,
  ) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const ['a']);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(body: GrammarSimulationPanel(useExpanded: false)),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('grammar-parser-input')),
      'a',
    );
    final start = find.byKey(const ValueKey('start-manual-derivation'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('user-derivation-workspace')),
      findsOneWidget,
    );
    final production = find.byKey(const ValueKey('manual-production-p1'));
    await tester.ensureVisible(production);
    await tester.tap(production);
    await tester.pumpAndSettle();
    final occurrence = find.byKey(const ValueKey('manual-occurrence-p1-0'));
    await tester.ensureVisible(occurrence);
    await tester.tap(occurrence);
    await tester.pumpAndSettle();
    final commit = find.byKey(const ValueKey('manual-derivation-commit'));
    await tester.ensureVisible(commit);
    await tester.tap(commit);
    await tester.pump();
    expect(find.text('Target reached'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('grammar-parser-input')),
      'b',
    );
    await tester.pump();
    expect(
      find.text('The grammar or target changed. Start a new session.'),
      findsOneWidget,
    );
  });
}

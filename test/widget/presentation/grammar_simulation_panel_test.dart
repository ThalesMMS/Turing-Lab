import 'package:flutter/material.dart';
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
          home: Scaffold(
            body: GrammarSimulationPanel(useExpanded: false),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byType(DropdownButtonFormField<ParsingStrategyHint>),
    );
    await tester.pumpAndSettle();

    expect(find.text('CYK (Cocke-Younger-Kasami)'), findsWidgets);
    expect(find.text('Automatic (Earley)'), findsWidgets);
    expect(find.text('Brute force'), findsOneWidget);
    expect(find.text('LL(1)'), findsNothing);
    expect(find.text('LR'), findsNothing);
  });

  testWidgets('parses blank input as epsilon', (tester) async {
    final grammar = GrammarProvider()
      ..addProduction(leftSide: ['S'], rightSide: const [], isLambda: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [grammarProvider.overrideWith((ref) => grammar)],
        child: const MaterialApp(
          home: Scaffold(
            body: GrammarSimulationPanel(useExpanded: false),
          ),
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
}

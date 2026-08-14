import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/pda_algorithm_panel.dart';

class _FakePdaExamplesDataSource extends ExamplesAssetDataSource {
  _FakePdaExamplesDataSource() : example = _buildPdaExample();

  final AssetExample<PDA> example;

  @override
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() async {
    return Success([example]);
  }

  @override
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) async {
    return Success(example);
  }
}

Future<PDAEditorNotifier> _pumpPdaAlgorithmPanel(WidgetTester tester) async {
  final pdaNotifier = PDAEditorNotifier();
  final examplesDataSource = _FakePdaExamplesDataSource();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdaEditorProvider.overrideWith((ref) => pdaNotifier),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PDAAlgorithmPanel(
            useExpanded: false,
            examplesDataSource: examplesDataSource,
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await _pumpUntilFound(tester, find.text('APD - Palíndromo'));

  return pdaNotifier;
}

AssetExample<PDA> _buildPdaExample() {
  final start = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final transition = PDATransition(
    id: 't0',
    fromState: start,
    toState: accept,
    label: 'a,Z/Z',
    type: TransitionType.deterministic,
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
  );
  final pda = PDA(
    id: 'pda-palindrome',
    name: 'APD - Palíndromo',
    states: {start, accept},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
  );

  return AssetExample<PDA>(
    name: pda.name,
    description: 'Fake PDA example for widget tests',
    category: ExampleCategory.pda,
    difficultyLevel: DifficultyLevel.easy,
    complexityLevel: ExampleComplexityLevel.low,
    tags: const ['test'],
    payload: pda,
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for $finder. Visible text: $visibleText');
}

Future<void> _pumpUntilPdaLoaded(
  WidgetTester tester,
  PDAEditorNotifier pdaNotifier,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (pdaNotifier.state.pda != null) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for PDA example to load');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows empty results before running an analysis', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    expect(find.text('No analysis results yet'), findsOneWidget);
    expect(
      find.text('Select an algorithm above to analyze your PDA'),
      findsOneWidget,
    );
  });

  testWidgets('renders PDA actions through AlgorithmButton', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    expect(find.byType(AlgorithmButton), findsNWidgets(6));
    expect(find.text('Convert to CFG'), findsOneWidget);
    expect(find.text('Minimize PDA'), findsOneWidget);
    expect(find.text('Check Determinism'), findsOneWidget);
    expect(find.text('Find Reachable States'), findsOneWidget);
    expect(find.text('Language Analysis'), findsOneWidget);
    expect(find.text('Stack Operations'), findsOneWidget);
  });

  testWidgets('PDA action still reports missing editor PDA', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    await tester.ensureVisible(find.text('Convert to CFG'));
    await tester.pump();

    await tester.tap(find.text('Convert to CFG'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Draw a PDA before converting to a grammar.'),
      findsOneWidget,
    );
  });

  testWidgets('loads PDA examples from the configured catalog into the editor',
      (
    tester,
  ) async {
    final pdaNotifier = await _pumpPdaAlgorithmPanel(tester);

    expect(find.text('APD - Palíndromo'), findsOneWidget);

    await tester.tap(find.text('APD - Palíndromo'));
    await _pumpUntilPdaLoaded(tester, pdaNotifier);

    final pda = pdaNotifier.state.pda;
    expect(pda, isNotNull);
    expect(pda!.name, equals('APD - Palíndromo'));
    expect(pda.pdaTransitions, isNotEmpty);
    expect(pda.initialStackSymbol, equals('Z'));
  });
}

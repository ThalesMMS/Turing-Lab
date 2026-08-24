import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/grammar_algorithm_panel.dart';

class _MockGrammarNotifier extends GrammarProvider {
  _MockGrammarNotifier({
    GrammarState? initialState,
    this.grammarOverride,
    this.convertToFsaResult,
    this.convertToPdaResult,
    this.convertToPdaStandardResult,
    this.convertToPdaGreibachResult,
  }) : super() {
    if (initialState != null) {
      state = initialState;
    }
  }

  final Result<FSA>? convertToFsaResult;
  final Grammar? grammarOverride;
  final Result<PDA>? convertToPdaResult;
  final Result<PDA>? convertToPdaStandardResult;
  final Result<PDA>? convertToPdaGreibachResult;
  @override
  Grammar buildGrammar() {
    if (grammarOverride != null) return grammarOverride!;
    return Grammar(
      id: 'test-grammar-${DateTime.now().millisecondsSinceEpoch}',
      name: state.name,
      terminals: const {'a', 'b'},
      nonterminals: const {'S'},
      startSymbol: state.startSymbol,
      productions: state.productions.toSet(),
      type: state.type,
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }

  @override
  Future<Result<FSA>> convertToAutomaton() async {
    state = state.copyWith(
      isConverting: true,
      activeConversion: GrammarConversionKind.grammarToFsa,
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final initialState = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: false,
    );

    final result = convertToFsaResult ??
        Success(
          FSA(
            id: 'test-fsa-${DateTime.now().millisecondsSinceEpoch}',
            name: 'Converted FSA',
            states: {initialState},
            transitions: const {},
            alphabet: const {'a', 'b'},
            initialState: initialState,
            acceptingStates: const {},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
          ),
        );

    state = state.copyWith(isConverting: false, activeConversion: null);

    return result;
  }

  @override
  Future<Result<PDA>> convertToPda() async {
    state = state.copyWith(
      isConverting: true,
      activeConversion: GrammarConversionKind.grammarToPda,
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final initialState = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: false,
    );

    final result = convertToPdaResult ??
        Success(
          PDA(
            id: 'test-pda-${DateTime.now().millisecondsSinceEpoch}',
            name: 'Converted PDA',
            states: {initialState},
            transitions: const {},
            alphabet: const {'a', 'b'},
            initialState: initialState,
            acceptingStates: const {},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
            stackAlphabet: const {'Z'},
            initialStackSymbol: 'Z',
          ),
        );

    state = state.copyWith(
      isConverting: false,
      activeConversion: null,
      lastPdaResult: result,
    );

    return result;
  }

  @override
  Future<Result<PDA>> convertToPdaStandard() async {
    state = state.copyWith(
      isConverting: true,
      activeConversion: GrammarConversionKind.grammarToPdaStandard,
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final initialState = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: false,
    );

    final result = convertToPdaStandardResult ??
        Success(
          PDA(
            id: 'test-pda-std-${DateTime.now().millisecondsSinceEpoch}',
            name: 'Converted PDA (Standard)',
            states: {initialState},
            transitions: const {},
            alphabet: const {'a', 'b'},
            initialState: initialState,
            acceptingStates: const {},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
            stackAlphabet: const {'Z'},
            initialStackSymbol: 'Z',
          ),
        );

    state = state.copyWith(
      isConverting: false,
      activeConversion: null,
      lastPdaResult: result,
    );

    return result;
  }

  @override
  Future<Result<PDA>> convertToPdaGreibach() async {
    state = state.copyWith(
      isConverting: true,
      activeConversion: GrammarConversionKind.grammarToPdaGreibach,
    );

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final initialState = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: false,
    );

    final result = convertToPdaGreibachResult ??
        Success(
          PDA(
            id: 'test-pda-greibach-${DateTime.now().millisecondsSinceEpoch}',
            name: 'Converted PDA (Greibach)',
            states: {initialState},
            transitions: const {},
            alphabet: const {'a', 'b'},
            initialState: initialState,
            acceptingStates: const {},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
            stackAlphabet: const {'Z'},
            initialStackSymbol: 'Z',
          ),
        );

    state = state.copyWith(
      isConverting: false,
      activeConversion: null,
      lastPdaResult: result,
    );

    return result;
  }
}

class _MockPdaEditorNotifier extends PDAEditorNotifier {
  _MockPdaEditorNotifier() : super();

  @override
  void setPda(PDA pda) {
    state = state.copyWith(pda: pda);
  }
}

class _MockAutomatonStateNotifier extends AutomatonStateNotifier {
  _MockAutomatonStateNotifier() : super();

  @override
  void updateAutomaton(FSA automaton) {
    state = state.copyWith(currentAutomaton: automaton);
  }
}

class _MockHomeNavigationNotifier extends HomeNavigationNotifier {
  _MockHomeNavigationNotifier() : super();

  int fsaCallCount = 0;
  int pdaCallCount = 0;

  @override
  void goToFsa() {
    fsaCallCount++;
    super.goToFsa();
  }

  @override
  void goToPda() {
    pdaCallCount++;
    super.goToPda();
  }
}

Future<void> _pumpGrammarAlgorithmPanel(
  WidgetTester tester, {
  GrammarState? grammarState,
  Grammar? grammarOverride,
  Result<FSA>? convertToFsaResult,
  Result<PDA>? convertToPdaResult,
  Result<PDA>? convertToPdaStandardResult,
  Result<PDA>? convertToPdaGreibachResult,
  _MockHomeNavigationNotifier? navigationNotifier,
  bool hasAnimatingIndicator = false,
}) async {
  final mockGrammarNotifier = _MockGrammarNotifier(
    initialState: grammarState,
    grammarOverride: grammarOverride,
    convertToFsaResult: convertToFsaResult,
    convertToPdaResult: convertToPdaResult,
    convertToPdaStandardResult: convertToPdaStandardResult,
    convertToPdaGreibachResult: convertToPdaGreibachResult,
  );

  final mockAutomatonStateNotifier = _MockAutomatonStateNotifier();
  final mockPdaNotifier = _MockPdaEditorNotifier();
  final mockNavNotifier = navigationNotifier ?? _MockHomeNavigationNotifier();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        grammarProvider.overrideWith((ref) => mockGrammarNotifier),
        automatonStateProvider.overrideWith(
          (ref) => mockAutomatonStateNotifier,
        ),
        pdaEditorProvider.overrideWith((ref) => mockPdaNotifier),
        homeNavigationProvider.overrideWith((ref) => mockNavNotifier),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GrammarAlgorithmPanel(useExpanded: false),
          ),
        ),
      ),
    ),
  );

  // Use pump() instead of pumpAndSettle() when a CircularProgressIndicator
  // is visible, because its animation never settles.
  if (hasAnimatingIndicator) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GrammarAlgorithmPanel', () {
    testWidgets('renders header with title and icon', (tester) async {
      await _pumpGrammarAlgorithmPanel(tester);

      expect(find.text('Grammar Analysis'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('renders all conversion buttons', (tester) async {
      await _pumpGrammarAlgorithmPanel(tester);

      expect(find.text('Conversions'), findsOneWidget);
      expect(find.text('Convert Right-Linear Grammar to FSA'), findsOneWidget);
      expect(find.text('Convert Grammar to PDA (General)'), findsOneWidget);
      expect(find.text('Convert Grammar to PDA (Standard)'), findsOneWidget);
      expect(find.text('Convert Grammar to PDA (Greibach)'), findsOneWidget);
    });

    testWidgets('renders all algorithm buttons', (tester) async {
      await _pumpGrammarAlgorithmPanel(tester);

      expect(find.byType(AlgorithmButton), findsNWidgets(12));
      expect(find.text('Remove Left Recursion'), findsOneWidget);
      expect(find.text('Left Factor'), findsOneWidget);
      expect(find.text('Find First Sets'), findsOneWidget);
      expect(find.text('Find Follow Sets'), findsOneWidget);
      expect(find.text('Build Parse Table'), findsOneWidget);
      expect(find.text('Check Ambiguity'), findsOneWidget);
    });

    testWidgets('renders analysis results section', (tester) async {
      await _pumpGrammarAlgorithmPanel(tester);

      expect(find.text('Analysis Results'), findsOneWidget);
      expect(find.text('No analysis results yet'), findsOneWidget);
      expect(
        find.text('Select an algorithm above to analyze your grammar'),
        findsOneWidget,
      );
    });

    testWidgets('displays help text when no productions exist', (tester) async {
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial(),
      );

      expect(
        find.text('Add at least one production rule to enable conversions.'),
        findsOneWidget,
      );
    });

    testWidgets('disables conversion buttons when no productions exist', (
      tester,
    ) async {
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial(),
      );

      final conversionButtons = tester.widgetList<AlgorithmButton>(
        find.ancestor(
          of: find.text('Convert Right-Linear Grammar to FSA'),
          matching: find.byType(AlgorithmButton),
        ),
      );

      expect(conversionButtons.length, 1);
      final button = conversionButtons.first;
      expect(button.onPressed, isNull);
    });

    testWidgets('enables conversion buttons when productions exist', (
      tester,
    ) async {
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a', 'B'],
              isLambda: false,
            ),
          ],
        ),
      );

      final conversionButtons = tester.widgetList<AlgorithmButton>(
        find.ancestor(
          of: find.text('Convert Right-Linear Grammar to FSA'),
          matching: find.byType(AlgorithmButton),
        ),
      );

      expect(conversionButtons.length, 1);
      final button = conversionButtons.first;
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays error message when present', (tester) async {
      const errorMessage = 'Test error message';
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(error: errorMessage),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('shows processing state for FSA conversion when converting', (
      tester,
    ) async {
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
          isConverting: true,
          activeConversion: GrammarConversionKind.grammarToFsa,
        ),
        hasAnimatingIndicator: true,
      );

      expect(find.text('Converting to FSA...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows processing state for PDA conversion when converting', (
      tester,
    ) async {
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
          isConverting: true,
          activeConversion: GrammarConversionKind.grammarToPda,
        ),
        hasAnimatingIndicator: true,
      );

      expect(find.text('Converting to PDA...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets(
      'shows processing state for PDA Standard conversion when converting',
      (tester) async {
        await _pumpGrammarAlgorithmPanel(
          tester,
          grammarState: GrammarState.initial().copyWith(
            productions: [
              const Production(
                id: 'p1',
                order: 0,
                leftSide: ['S'],
                rightSide: ['a'],
                isLambda: false,
              ),
            ],
            isConverting: true,
            activeConversion: GrammarConversionKind.grammarToPdaStandard,
          ),
          hasAnimatingIndicator: true,
        );

        expect(find.text('Converting (Standard)...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      },
    );

    testWidgets(
      'shows processing state for PDA Greibach conversion when converting',
      (tester) async {
        await _pumpGrammarAlgorithmPanel(
          tester,
          grammarState: GrammarState.initial().copyWith(
            productions: [
              const Production(
                id: 'p1',
                order: 0,
                leftSide: ['S'],
                rightSide: ['a'],
                isLambda: false,
              ),
            ],
            isConverting: true,
            activeConversion: GrammarConversionKind.grammarToPdaGreibach,
          ),
          hasAnimatingIndicator: true,
        );

        expect(find.text('Converting (Greibach)...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      },
    );

    testWidgets('tapping FSA conversion button triggers conversion', (
      tester,
    ) async {
      final navNotifier = _MockHomeNavigationNotifier();

      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
        ),
        navigationNotifier: navNotifier,
      );

      expect(navNotifier.fsaCallCount, 0);

      await tester.ensureVisible(
        find.text('Convert Right-Linear Grammar to FSA'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Convert Right-Linear Grammar to FSA'));
      await tester.pumpAndSettle();

      expect(navNotifier.fsaCallCount, 1);
      expect(
        find.text('Grammar converted to automaton. Switched to FSA workspace.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping PDA General conversion button triggers conversion', (
      tester,
    ) async {
      final navNotifier = _MockHomeNavigationNotifier();

      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
        ),
        navigationNotifier: navNotifier,
      );

      expect(navNotifier.pdaCallCount, 0);

      await tester.ensureVisible(find.text('Convert Grammar to PDA (General)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Convert Grammar to PDA (General)'));
      await tester.pumpAndSettle();

      expect(navNotifier.pdaCallCount, 1);
      expect(
        find.text(
          'Grammar converted to PDA (general). Switched to PDA workspace.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping PDA Standard conversion button triggers conversion', (
      tester,
    ) async {
      final navNotifier = _MockHomeNavigationNotifier();

      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
        ),
        navigationNotifier: navNotifier,
      );

      expect(navNotifier.pdaCallCount, 0);

      await tester.ensureVisible(
        find.text('Convert Grammar to PDA (Standard)'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Convert Grammar to PDA (Standard)'));
      await tester.pumpAndSettle();

      expect(navNotifier.pdaCallCount, 1);
      expect(
        find.text(
          'Grammar converted to PDA (standard). Switched to PDA workspace.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping PDA Greibach conversion button triggers conversion', (
      tester,
    ) async {
      final navNotifier = _MockHomeNavigationNotifier();

      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
        ),
        navigationNotifier: navNotifier,
      );

      expect(navNotifier.pdaCallCount, 0);

      await tester.ensureVisible(
        find.text('Convert Grammar to PDA (Greibach)'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Convert Grammar to PDA (Greibach)'));
      await tester.pumpAndSettle();

      expect(navNotifier.pdaCallCount, 1);
      expect(
        find.text(
          'Grammar converted to PDA (Greibach). Switched to PDA workspace.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles FSA conversion error gracefully', (tester) async {
      const errorMessage = 'Grammar is not right-linear';
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
        ),
        convertToFsaResult: const Failure(errorMessage),
      );

      await tester.ensureVisible(
        find.text('Convert Right-Linear Grammar to FSA'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Convert Right-Linear Grammar to FSA'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('handles PDA conversion error gracefully', (tester) async {
      const errorMessage = 'Invalid grammar structure';
      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: GrammarState.initial().copyWith(
          productions: [
            const Production(
              id: 'p1',
              order: 0,
              leftSide: ['S'],
              rightSide: ['a'],
              isLambda: false,
            ),
          ],
        ),
        convertToPdaResult: const Failure(errorMessage),
      );

      await tester.ensureVisible(find.text('Convert Grammar to PDA (General)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Convert Grammar to PDA (General)'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('algorithm buttons have correct icons', (tester) async {
      await _pumpGrammarAlgorithmPanel(tester);

      await tester.ensureVisible(find.text('Convert to CNF'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.filter_list), findsWidgets);

      await tester.ensureVisible(find.text('Convert to GNF'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.format_list_numbered), findsWidgets);

      await tester.ensureVisible(find.text('Remove Left Recursion'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.transform), findsWidgets);

      await tester.ensureVisible(find.text('Left Factor'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.account_tree), findsWidgets);

      await tester.ensureVisible(find.text('Find First Sets'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.first_page), findsWidgets);

      await tester.ensureVisible(find.text('Find Follow Sets'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.last_page), findsWidgets);

      await tester.ensureVisible(find.text('Build Parse Table'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.table_chart), findsWidgets);

      await tester.ensureVisible(find.text('Check Ambiguity'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.rule), findsWidgets);
    });

    testWidgets('conversion buttons have correct icons', (tester) async {
      await _pumpGrammarAlgorithmPanel(tester);

      await tester.ensureVisible(
        find.text('Convert Right-Linear Grammar to FSA'),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.sync_alt), findsWidgets);

      await tester.ensureVisible(find.text('Convert Grammar to PDA (General)'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.auto_fix_high), findsWidgets);

      await tester.ensureVisible(
        find.text('Convert Grammar to PDA (Standard)'),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.layers), findsWidgets);

      await tester.ensureVisible(
        find.text('Convert Grammar to PDA (Greibach)'),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stacked_bar_chart), findsWidgets);
    });

    testWidgets('algorithm button descriptions are visible', (tester) async {
      await _pumpGrammarAlgorithmPanel(tester);

      await tester.ensureVisible(
        find.text('Convert grammar to Chomsky Normal Form'),
      );
      expect(
        find.text('Convert grammar to Chomsky Normal Form'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.text('Convert grammar to Greibach Normal Form'),
      );
      expect(
        find.text('Convert grammar to Greibach Normal Form'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.text('Eliminate direct and indirect left recursion'),
      );
      expect(
        find.text('Eliminate direct and indirect left recursion'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Apply left factoring to grammar'));
      expect(find.text('Apply left factoring to grammar'), findsOneWidget);

      await tester.ensureVisible(
        find.text('Calculate FIRST sets for all variables'),
      );
      expect(
        find.text('Calculate FIRST sets for all variables'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.text('Calculate FOLLOW sets for all variables'),
      );
      expect(
        find.text('Calculate FOLLOW sets for all variables'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.text('Generate LL(1) or LR(1) parse table'),
      );
      expect(find.text('Generate LL(1) or LR(1) parse table'), findsOneWidget);

      await tester.ensureVisible(find.text('Detect if grammar is ambiguous'));
      expect(find.text('Detect if grammar is ambiguous'), findsOneWidget);
    });

    testWidgets('left-recursion action shows substitution and direct steps', (
      tester,
    ) async {
      final productions = [
        const Production(
          id: 'p0',
          order: 0,
          leftSide: ['S'],
          rightSide: ['A', 'a'],
        ),
        const Production(
          id: 'p1',
          order: 1,
          leftSide: ['S'],
          rightSide: ['b'],
        ),
        const Production(
          id: 'p2',
          order: 2,
          leftSide: ['A'],
          rightSide: ['S', 'c'],
        ),
        const Production(
          id: 'p3',
          order: 3,
          leftSide: ['A'],
          rightSide: ['d'],
        ),
      ];
      final grammar = Grammar(
        id: 'indirect-widget',
        name: 'Indirect recursion',
        terminals: const {'a', 'b', 'c', 'd'},
        nonterminals: const {'S', 'A'},
        startSymbol: 'S',
        productions: productions.toSet(),
        type: GrammarType.contextFree,
        created: DateTime(2026),
        modified: DateTime(2026),
      );
      final grammarState = GrammarState.initial().copyWith(
        name: grammar.name,
        startSymbol: grammar.startSymbol,
        productions: productions,
        type: grammar.type,
      );

      await _pumpGrammarAlgorithmPanel(
        tester,
        grammarState: grammarState,
        grammarOverride: grammar,
      );
      await tester.ensureVisible(find.text('Remove Left Recursion'));
      await tester.tap(find.text('Remove Left Recursion'));
      await tester.pumpAndSettle();

      expect(find.text('Transformation steps'), findsOneWidget);
      expect(
        find.textContaining('Substitution for A via S'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Direct recursion removal for A'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Direct and Indirect Left Recursion Removal'),
        findsOneWidget,
      );
    });
  });
}

//
//  language_comparison_viewer_test.dart
//  Turing Lab
//
//  Suite abrangente que testa o widget LanguageComparisonViewer, validando
//  visualização de resultados de comparação de equivalência, exibição de
//  contraexemplos, estatísticas, autômatos lado a lado, autômato produto
//  (colapsável) e passos do algoritmo, garantindo comportamento correto em
//  cenários de equivalência e não-equivalência de linguagens.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_viewer.dart';
import 'package:turing_lab/presentation/widgets/read_only_fsa_graphview_canvas.dart';

/// Helper function to create a simple test FSA
FSA _createTestFSA({
  required String id,
  required String name,
  required int stateCount,
  required int transitionCount,
}) {
  final states = <automaton_state.State>{};
  final transitions = <FSATransition>{};

  // Create states
  for (int i = 0; i < stateCount; i++) {
    states.add(
      automaton_state.State(
        id: '$id-q$i',
        label: 'q$i',
        position: Vector2(i * 100.0, 0),
      ),
    );
  }

  // Create transitions
  int transIdx = 0;
  final stateList = states.toList();
  for (int i = 0; i < transitionCount && i < stateList.length - 1; i++) {
    transitions.add(
      FSATransition(
        id: '$id-t$transIdx',
        fromState: stateList[i],
        toState: stateList[i + 1],
        label: 'a',
        inputSymbols: const {'a'},
      ),
    );
    transIdx++;
  }

  return FSA(
    id: id,
    name: name,
    states: states,
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime(2025, 1, 1),
    modified: DateTime(2025, 1, 1),
    bounds: const math.Rectangle(0, 0, 800, 600),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

/// Helper function to create an equivalent comparison result
EquivalenceComparisonResult _createEquivalentResult() {
  final automatonA = _createTestFSA(
    id: 'test-a',
    name: 'Automaton A',
    stateCount: 3,
    transitionCount: 2,
  );
  final automatonB = _createTestFSA(
    id: 'test-b',
    name: 'Automaton B',
    stateCount: 3,
    transitionCount: 2,
  );

  return EquivalenceComparisonResult(
    originalAutomaton: automatonA,
    comparedAutomaton: automatonB,
    isEquivalent: true,
    distinguishingString: null,
    productAutomaton: null,
    steps: [],
    executionTimeMs: 42,
    timestamp: DateTime(2025, 1, 25),
  );
}

/// Helper function to create a non-equivalent comparison result
EquivalenceComparisonResult _createNonEquivalentResult({
  String? distinguishingString = 'ab',
  bool includeProductAutomaton = false,
  bool includeSteps = false,
}) {
  final automatonA = _createTestFSA(
    id: 'test-a',
    name: 'Automaton A',
    stateCount: 2,
    transitionCount: 1,
  );
  final automatonB = _createTestFSA(
    id: 'test-b',
    name: 'Automaton B',
    stateCount: 4,
    transitionCount: 3,
  );

  final productAutomaton = includeProductAutomaton
      ? _createTestFSA(
          id: 'product',
          name: 'Product Automaton',
          stateCount: 5,
          transitionCount: 4,
        )
      : null;

  final steps = includeSteps
      ? [
          {
            'type': 'initialization',
            'description': 'Initialize product automaton construction',
          },
          {'type': 'bfs_exploration', 'description': 'Exploring state (q0,p0)'},
          {
            'type': 'counterexample_found',
            'description': 'Found distinguishing string: ab',
          },
        ]
      : <Map<String, dynamic>>[];

  return EquivalenceComparisonResult(
    originalAutomaton: automatonA,
    comparedAutomaton: automatonB,
    isEquivalent: false,
    distinguishingString: distinguishingString,
    productAutomaton: productAutomaton,
    steps: steps,
    executionTimeMs: 87,
    timestamp: DateTime(2025, 1, 25),
  );
}

EquivalenceComparisonResult _createResultWithSteps(
  List<Map<String, dynamic>> steps,
) {
  final automatonA = _createTestFSA(
    id: 'test-a',
    name: 'Automaton A',
    stateCount: 2,
    transitionCount: 1,
  );
  final automatonB = _createTestFSA(
    id: 'test-b',
    name: 'Automaton B',
    stateCount: 3,
    transitionCount: 2,
  );

  return EquivalenceComparisonResult(
    originalAutomaton: automatonA,
    comparedAutomaton: automatonB,
    isEquivalent: false,
    distinguishingString: 'ab',
    productAutomaton: null,
    steps: steps,
    executionTimeMs: 87,
    timestamp: DateTime(2025, 1, 25),
  );
}

Future<void> _pumpLanguageComparisonViewer(
  WidgetTester tester, {
  required EquivalenceComparisonResult comparisonResult,
  String? automatonATitle,
  String? automatonBTitle,
  bool showProductAutomaton = false,
  bool showSteps = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: SingleChildScrollView(
              child: SizedBox(
                height: 1500,
                child: LanguageComparisonViewer(
                  comparisonResult: comparisonResult,
                  automatonATitle: automatonATitle,
                  automatonBTitle: automatonBTitle,
                  showProductAutomaton: showProductAutomaton,
                  showSteps: showSteps,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageComparisonViewer', () {
    group('Equivalent Automata', () {
      testWidgets('displays EQUIVALENT badge when automata are equivalent', (
        tester,
      ) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('EQUIVALENT'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('NOT EQUIVALENT'), findsNothing);
      });

      testWidgets('displays execution time for equivalent automata', (
        tester,
      ) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('42ms'), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('does not display counterexample section when equivalent', (
        tester,
      ) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('Distinguishing String Found'), findsNothing);
        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });

      testWidgets('displays statistics for both automata', (tester) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('States (A)'), findsOneWidget);
        expect(find.text('States (B)'), findsOneWidget);
        expect(find.text('Transitions (A)'), findsOneWidget);
        expect(find.text('Transitions (B)'), findsOneWidget);
        expect(find.text('3'), findsNWidgets(2)); // 3 states in each
        expect(find.text('2'), findsNWidgets(2)); // 2 transitions in each
      });

      testWidgets('displays default titles for automata', (tester) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('Automaton A'), findsOneWidget);
        expect(find.text('Automaton B'), findsOneWidget);
      });

      testWidgets('displays custom titles for automata when provided', (
        tester,
      ) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          automatonATitle: 'Original DFA',
          automatonBTitle: 'Minimized DFA',
        );

        expect(find.text('Original DFA'), findsOneWidget);
        expect(find.text('Minimized DFA'), findsOneWidget);
        expect(find.text('Automaton A'), findsNothing);
        expect(find.text('Automaton B'), findsNothing);
      });
    });

    group('Non-Equivalent Automata', () {
      testWidgets('displays NOT EQUIVALENT badge when automata differ', (
        tester,
      ) async {
        final result = _createNonEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('NOT EQUIVALENT'), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.text('EQUIVALENT'), findsNothing);
      });

      testWidgets('displays counterexample section with distinguishing string',
          (
        tester,
      ) async {
        final result = _createNonEquivalentResult(distinguishingString: 'ab');

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('Distinguishing String Found'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        expect(find.text('"ab"'), findsOneWidget);
        expect(
          find.textContaining(
            'This string is accepted by one automaton but rejected by the other',
          ),
          findsOneWidget,
        );
      });

      testWidgets('displays empty string counterexample correctly', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(distinguishingString: '');

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('Distinguishing String Found'), findsOneWidget);
        expect(find.text('ε (empty string)'), findsOneWidget);
      });

      testWidgets('displays execution time for non-equivalent automata', (
        tester,
      ) async {
        final result = _createNonEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('87ms'), findsOneWidget);
      });

      testWidgets('displays statistics with different state counts', (
        tester,
      ) async {
        final result = _createNonEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        // Automaton A has 2 states, B has 4 states
        expect(find.text('States (A)'), findsOneWidget);
        expect(find.text('States (B)'), findsOneWidget);
        expect(find.text('2'), findsAtLeastNWidgets(1));
        expect(find.text('4'), findsAtLeastNWidgets(1));
      });
    });

    group('Product Automaton Section', () {
      testWidgets(
        'does not show product automaton section when not available',
        (tester) async {
          final result = _createNonEquivalentResult(
            includeProductAutomaton: false,
          );

          await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

          expect(find.text('Product Automaton'), findsNothing);
        },
      );

      testWidgets(
        'shows collapsible product automaton section when available',
        (tester) async {
          final result = _createNonEquivalentResult(
            includeProductAutomaton: true,
          );

          await _pumpLanguageComparisonViewer(
            tester,
            comparisonResult: result,
            showProductAutomaton: false,
          );

          expect(find.text('Product Automaton'), findsOneWidget);
          expect(find.text('Optional'), findsOneWidget);
          expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
        },
      );

      testWidgets('expands product automaton section when initially open', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(
          includeProductAutomaton: true,
        );

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showProductAutomaton: true,
        );

        expect(find.text('Product Automaton'), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(1));
      });

      testWidgets('renders detached canvases when product section opens', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(
          includeProductAutomaton: true,
        );

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
        );

        await tester.ensureVisible(find.text('Product Automaton'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Product Automaton'));
        await tester.pumpAndSettle();

        expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(3));
        final canvases = tester
            .widgetList<ReadOnlyFsaGraphViewCanvas>(
              find.byType(ReadOnlyFsaGraphViewCanvas),
            )
            .toList();
        expect(
          canvases.map((canvas) => canvas.edgeRenderMode),
          everyElement(TuringLabEdgeRenderMode.groupedFsa),
        );
        final innerCanvases = tester
            .widgetList<AutomatonGraphViewCanvas>(
              find.byType(AutomatonGraphViewCanvas),
            )
            .toList();
        expect(innerCanvases, hasLength(3));
        expect(
          innerCanvases.map(
            (canvas) => canvas.customization!.edgeRenderMode,
          ),
          everyElement(TuringLabEdgeRenderMode.groupedFsa),
        );
        final canvasKeys = canvases.map((canvas) => canvas.canvasKey).toSet();
        expect(canvasKeys, hasLength(3));
        expect(
          innerCanvases.map((canvas) => canvas.canvasKey).toSet(),
          equals(canvasKeys),
        );
        for (final canvasKey in canvasKeys) {
          expect(find.byKey(canvasKey), findsOneWidget);
        }
      });

      testWidgets('toggles product automaton section when tapped', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(
          includeProductAutomaton: true,
        );

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showProductAutomaton: false,
        );

        // Initially collapsed
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));

        // Scroll to the Product Automaton section to make it visible
        await tester.ensureVisible(find.text('Product Automaton'));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Product Automaton'));
        await tester.pumpAndSettle();

        // Should now be expanded
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(1));

        // Scroll to ensure it's still visible after expansion
        await tester.ensureVisible(find.text('Product Automaton'));
        await tester.pumpAndSettle();

        // Tap to collapse
        await tester.tap(find.text('Product Automaton'));
        await tester.pumpAndSettle();

        // Should be collapsed again
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
      });
    });

    group('Algorithm Steps Section', () {
      testWidgets('does not show steps section when steps are empty', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(includeSteps: false);

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('Algorithm Steps'), findsNothing);
      });

      testWidgets('shows collapsible steps section when steps are available', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: false,
        );

        expect(find.text('Algorithm Steps'), findsOneWidget);
        expect(find.text('3 steps'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
      });

      testWidgets('expands steps section when initially open', (tester) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Algorithm Steps'), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(1));
      });

      testWidgets('toggles steps section when tapped', (tester) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: false,
        );

        // Initially collapsed
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));

        // Scroll to the Algorithm Steps section to make it visible
        await tester.ensureVisible(find.text('Algorithm Steps'));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Algorithm Steps'));
        await tester.pumpAndSettle();

        // Should now be expanded
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(1));

        // Scroll to ensure it's still visible after expansion
        await tester.ensureVisible(find.text('Algorithm Steps'));
        await tester.pumpAndSettle();

        // Tap to collapse
        await tester.tap(find.text('Algorithm Steps'));
        await tester.pumpAndSettle();

        // Should be collapsed again
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
      });

      testWidgets('displays step information when expanded', (tester) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        // Check semantic step titles are displayed
        expect(find.text('Initialization'), findsOneWidget);
        expect(find.text('State Pair Visit'), findsOneWidget);
        expect(find.text('Counterexample Found'), findsOneWidget);

        // Check step descriptions
        expect(
          find.text('Initialize product automaton construction'),
          findsOneWidget,
        );
        expect(find.text('Exploring state (q0,p0)'), findsOneWidget);
        expect(find.text('Found distinguishing string: ab'), findsOneWidget);

        // Check step numbers
        expect(find.text('1'), findsAtLeastNWidgets(1));
        expect(find.text('2'), findsAtLeastNWidgets(1));
        expect(find.text('3'), findsAtLeastNWidgets(1));
      });

      testWidgets('renders semantic alphabet normalization details', (
        tester,
      ) async {
        final result = _createResultWithSteps([
          {
            'stepNumber': 1,
            'type': 'alphabet_normalization',
            'description': 'Combining alphabets from both automata',
            'data': {
              'alphabetA': ['a'],
              'alphabetB': ['b'],
              'sharedAlphabet': ['a', 'b'],
            },
          },
        ]);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Alphabet Normalization'), findsOneWidget);
        expect(find.text('Shared alphabet'), findsOneWidget);
        expect(find.text('a, b'), findsOneWidget);
      });

      testWidgets('renders semantic counterexample details', (tester) async {
        final result = _createResultWithSteps([
          {
            'stepNumber': 7,
            'type': 'bfs_distinguishing_found',
            'description': 'Found distinguishing string: ab',
            'data': {
              'stateA': 'q1',
              'stateB': 'p2',
              'acceptsA': true,
              'acceptsB': false,
              'distinguishingString': 'ab',
              'symbol': 'b',
            },
          },
        ]);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Counterexample Found'), findsOneWidget);
        expect(find.text('Distinguishing string'), findsOneWidget);
        expect(find.text('"ab"'), findsAtLeastNWidgets(1));
        expect(find.text('Acceptance'), findsOneWidget);
        expect(find.text('A accepts, B rejects'), findsOneWidget);
      });

      testWidgets('renders a structured fallback for unknown step payloads', (
        tester,
      ) async {
        final result = _createResultWithSteps([
          {
            'stepNumber': 3,
            'type': 'mystery_payload',
            'description': 'Opaque comparison step',
            'data': {'rawKey': 'rawValue'},
          },
        ]);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Unknown Step'), findsOneWidget);
        expect(find.text('Raw type'), findsOneWidget);
        expect(find.text('mystery_payload'), findsOneWidget);
        expect(find.text('rawKey'), findsOneWidget);
        expect(find.text('rawValue'), findsOneWidget);
      });
    });

    group('Layout and Icons', () {
      testWidgets('displays proper icons for sections', (tester) async {
        final result = _createNonEquivalentResult(
          includeProductAutomaton: true,
          includeSteps: true,
        );

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        // Automaton section icons
        expect(find.byIcon(Icons.account_tree), findsNWidgets(2));

        // Product automaton icon
        expect(find.byIcon(Icons.grid_on), findsOneWidget);

        // Steps section icon
        expect(find.byIcon(Icons.list_alt), findsOneWidget);

        // Counterexample section icons
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        expect(find.byIcon(Icons.text_fields), findsOneWidget);
      });

      testWidgets('renders within a Card widget', (tester) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles null distinguishing string for non-equivalent', (
        tester,
      ) async {
        final automatonA = _createTestFSA(
          id: 'test-a',
          name: 'Automaton A',
          stateCount: 2,
          transitionCount: 1,
        );
        final automatonB = _createTestFSA(
          id: 'test-b',
          name: 'Automaton B',
          stateCount: 3,
          transitionCount: 2,
        );

        final result = EquivalenceComparisonResult(
          originalAutomaton: automatonA,
          comparedAutomaton: automatonB,
          isEquivalent: false,
          distinguishingString: null,
          executionTimeMs: 50,
        );

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        // Should not crash and should show NOT EQUIVALENT
        expect(find.text('NOT EQUIVALENT'), findsOneWidget);
        // But no counterexample section since string is null
        expect(find.text('Distinguishing String Found'), findsNothing);
      });

      testWidgets('handles automata with no transitions', (tester) async {
        final automatonA = _createTestFSA(
          id: 'test-a',
          name: 'Automaton A',
          stateCount: 2,
          transitionCount: 0,
        );
        final automatonB = _createTestFSA(
          id: 'test-b',
          name: 'Automaton B',
          stateCount: 2,
          transitionCount: 0,
        );

        final result = EquivalenceComparisonResult(
          originalAutomaton: automatonA,
          comparedAutomaton: automatonB,
          isEquivalent: true,
          executionTimeMs: 10,
        );

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('EQUIVALENT'), findsOneWidget);
        expect(find.text('0'), findsNWidgets(2)); // 0 transitions in each
      });

      testWidgets('handles both product automaton and steps together', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(
          includeProductAutomaton: true,
          includeSteps: true,
        );

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showProductAutomaton: true,
          showSteps: true,
        );

        expect(find.text('Product Automaton'), findsOneWidget);
        expect(find.text('Algorithm Steps'), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(2));
      });
    });
  });
}

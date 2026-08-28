//
//  language_comparison_viewer_test.dart
//  Turing Lab
//
//  Comprehensive suite for LanguageComparisonViewer: verdict rendering,
//  counterexamples, statistics, read-only automata canvases, the collapsible
//  product automaton, the navigable typed algorithm trace, the explicit
//  stopped-comparison surfaces, responsive side-by-side and stacked layouts,
//  and the English/Portuguese semantics contract.
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
import 'package:turing_lab/core/models/language_comparison_outcome.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/algorithms/language_comparison_messages.dart';
import 'package:turing_lab/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_semantics.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_viewer.dart';
import 'package:turing_lab/presentation/widgets/read_only_fsa_graphview_canvas.dart';

/// Display strings are read from the generated localizations instead of being
/// retyped, so the suite is not sensitive to wording or capitalization.
final AppLocalizations _en = AppLocalizationsEn();
final AppLocalizations _pt = AppLocalizationsPt();

/// Window wide enough for the side-by-side arrangement.
const Size _wideWindow = Size(1000, 900);

/// Window narrow enough to force the stacked arrangement.
const Size _narrowWindow = Size(480, 900);

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
EquivalenceComparisonResult _createEquivalentResult({
  int executionTimeMs = 42,
}) {
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
    executionTimeMs: executionTimeMs,
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
          {
            'type': 'bfs_exploration',
            'description': 'Exploring state (q0,p0)',
            'data': {'stateA': 'q0', 'stateB': 'p0'},
          },
          {
            'type': 'counterexample_found',
            'description': 'Found distinguishing string: ab',
            'data': {'distinguishingString': 'ab'},
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

void _applyWindow(WidgetTester tester, Size size, double textScale) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> _pumpLanguageComparisonViewer(
  WidgetTester tester, {
  EquivalenceComparisonResult? comparisonResult,
  LanguageComparisonFailure? failure,
  String? automatonATitle,
  String? automatonBTitle,
  bool showProductAutomaton = false,
  bool showSteps = false,
  Size window = _wideWindow,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  bool unboundedHost = false,
}) async {
  _applyWindow(tester, window, textScale);

  final viewer = failure != null
      ? LanguageComparisonViewer.unavailable(failure: failure)
      : LanguageComparisonViewer(
          comparisonResult: comparisonResult,
          automatonATitle: automatonATitle,
          automatonBTitle: automatonBTitle,
          showProductAutomaton: showProductAutomaton,
          showSteps: showSteps,
        );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: unboundedHost ? SingleChildScrollView(child: viewer) : viewer,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _tapSectionToggle(WidgetTester tester, String title) async {
  await tester.ensureVisible(find.text(title));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

Future<void> _tapStepButton(WidgetTester tester, String identifier) async {
  final finder = find.byKey(ValueKey<String>(identifier));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _semanticsLabel(WidgetTester tester, String identifier) {
  return tester.getSemantics(find.bySemanticsIdentifier(identifier)).label;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageComparisonViewer', () {
    group('Equivalent Automata', () {
      testWidgets('displays the equivalent verdict when automata match', (
        tester,
      ) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(
          find.byKey(
            LanguageComparisonSemantics.statusKey(
              LanguageComparisonStatus.equivalent,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(_en.equivalent), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text(_en.notEquivalent), findsNothing);
      });

      testWidgets('displays execution time for equivalent automata', (
        tester,
      ) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text('42ms'), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('formats execution time in Portuguese', (tester) async {
        final result = _createEquivalentResult(executionTimeMs: 1234);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          locale: const Locale('pt'),
        );

        expect(find.text('1.234ms'), findsOneWidget);
        expect(find.text('1234ms'), findsNothing);
      });

      testWidgets('does not display counterexample section when equivalent', (
        tester,
      ) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text(_en.distinguishingStringFound), findsNothing);
        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });

      testWidgets('displays statistics for both automata', (tester) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text(_en.statesA), findsOneWidget);
        expect(find.text(_en.statesB), findsOneWidget);
        expect(find.text(_en.transitionsA), findsOneWidget);
        expect(find.text(_en.transitionsB), findsOneWidget);
        expect(find.text('3'), findsNWidgets(2)); // 3 states in each
        expect(find.text('2'), findsNWidgets(2)); // 2 transitions in each
      });

      testWidgets('displays default titles for automata', (tester) async {
        final result = _createEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text(_en.automatonA), findsOneWidget);
        expect(find.text(_en.automatonB), findsOneWidget);
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
        expect(find.text(_en.automatonA), findsNothing);
        expect(find.text(_en.automatonB), findsNothing);
      });
    });

    group('Non-Equivalent Automata', () {
      testWidgets('displays the not-equivalent verdict when automata differ', (
        tester,
      ) async {
        final result = _createNonEquivalentResult();

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(
          find.byKey(
            LanguageComparisonSemantics.statusKey(
              LanguageComparisonStatus.notEquivalent,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(_en.notEquivalent), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.text(_en.equivalent), findsNothing);
      });

      testWidgets(
        'displays counterexample section with distinguishing string',
        (tester) async {
          final result = _createNonEquivalentResult(distinguishingString: 'ab');

          await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

          expect(find.text(_en.distinguishingStringFound), findsOneWidget);
          expect(find.byIcon(Icons.warning_amber), findsOneWidget);
          expect(find.text('"ab"'), findsOneWidget);
          expect(
            find.text(_en.distinguishingStringExplanation),
            findsOneWidget,
          );
        },
      );

      testWidgets('displays empty string counterexample correctly', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(distinguishingString: '');

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text(_en.distinguishingStringFound), findsOneWidget);
        expect(find.text(_en.emptyStringEpsilon), findsOneWidget);
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
        expect(find.text(_en.statesA), findsOneWidget);
        expect(find.text(_en.statesB), findsOneWidget);
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

          expect(find.text(_en.productAutomaton), findsNothing);
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

          expect(find.text(_en.productAutomaton), findsOneWidget);
          expect(find.text(_en.optional), findsOneWidget);
          expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
          expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(2));
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

        expect(find.text(_en.productAutomaton), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(1));
      });

      testWidgets('renders detached canvases when product section opens', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(
          includeProductAutomaton: true,
        );

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        await _tapSectionToggle(tester, _en.productAutomaton);

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
          innerCanvases.map((canvas) => canvas.customization!.edgeRenderMode),
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

        expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(2));

        await _tapSectionToggle(tester, _en.productAutomaton);
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(1));
        expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(3));

        await _tapSectionToggle(tester, _en.productAutomaton);
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
        expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(2));
      });

      testWidgets('keeps the verdict and witness while the section toggles', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(
          includeProductAutomaton: true,
        );

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        await _tapSectionToggle(tester, _en.productAutomaton);

        expect(
          find.byKey(
            LanguageComparisonSemantics.statusKey(
              LanguageComparisonStatus.notEquivalent,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('"ab"'), findsOneWidget);
      });
    });

    group('Algorithm Steps Section', () {
      testWidgets('does not show steps section when steps are empty', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(includeSteps: false);

        await _pumpLanguageComparisonViewer(tester, comparisonResult: result);

        expect(find.text(_en.algorithmSteps), findsNothing);
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

        expect(find.text(_en.algorithmSteps), findsOneWidget);
        expect(find.text(_en.stepsCount(3)), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
      });

      testWidgets('expands steps section when initially open', (tester) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text(_en.algorithmSteps), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(1));
        expect(find.text(_en.stepOf(1, 3)), findsOneWidget);
      });

      testWidgets('toggles steps section when tapped', (tester) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: false,
        );

        expect(find.text(_en.stepOf(1, 3)), findsNothing);

        await _tapSectionToggle(tester, _en.algorithmSteps);
        expect(find.text(_en.stepOf(1, 3)), findsOneWidget);

        await _tapSectionToggle(tester, _en.algorithmSteps);
        expect(find.text(_en.stepOf(1, 3)), findsNothing);
      });

      testWidgets('navigates the trace one step at a time', (tester) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Initialization'), findsOneWidget);
        expect(
          find.text('Initialize product automaton construction'),
          findsOneWidget,
        );

        await _tapStepButton(tester, LanguageComparisonSemantics.nextStep);
        expect(find.text(_en.stepOf(2, 3)), findsOneWidget);
        expect(find.text('State Pair Visit'), findsOneWidget);
        expect(
          find.text(_en.languageComparisonDescriptionExplorePair('q0', 'p0')),
          findsOneWidget,
        );
        expect(find.text('Initialization'), findsNothing);

        await _tapStepButton(tester, LanguageComparisonSemantics.nextStep);
        expect(find.text(_en.stepOf(3, 3)), findsOneWidget);
        expect(find.text('Counterexample Found'), findsOneWidget);

        await _tapStepButton(tester, LanguageComparisonSemantics.previousStep);
        expect(find.text(_en.stepOf(2, 3)), findsOneWidget);
      });

      testWidgets('disables navigation at both ends of the trace', (
        tester,
      ) async {
        final result = _createNonEquivalentResult(includeSteps: true);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        IconButton buttonFor(String identifier) =>
            tester.widget<IconButton>(find.byKey(ValueKey<String>(identifier)));

        expect(
          buttonFor(LanguageComparisonSemantics.previousStep).onPressed,
          isNull,
        );
        expect(
          buttonFor(LanguageComparisonSemantics.nextStep).onPressed,
          isNotNull,
        );

        await _tapStepButton(tester, LanguageComparisonSemantics.nextStep);
        await _tapStepButton(tester, LanguageComparisonSemantics.nextStep);

        expect(
          buttonFor(LanguageComparisonSemantics.previousStep).onPressed,
          isNotNull,
        );
        expect(
          buttonFor(LanguageComparisonSemantics.nextStep).onPressed,
          isNull,
        );
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
        expect(find.text('ab'), findsAtLeastNWidgets(1));
        expect(find.text('Acceptance'), findsOneWidget);
        expect(
          find.text(_en.languageComparisonValueAcceptance('true', 'false')),
          findsOneWidget,
        );
      });

      testWidgets('renders a product-state payload with its state pair', (
        tester,
      ) async {
        final result = _createResultWithSteps([
          {
            'stepNumber': 4,
            'type': 'product_state_created',
            'description': 'Created initial product state',
            'data': {
              'stateA': 'q0',
              'stateB': 'p0',
              'productState': '(q0,p0)',
              'isAccepting': false,
            },
          },
        ]);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Product State Created'), findsOneWidget);
        expect(find.text('State pair'), findsOneWidget);
        expect(find.text('q0 / p0'), findsOneWidget);
        expect(find.text('(q0,p0)'), findsOneWidget);
      });

      testWidgets('renders an equivalence result payload', (tester) async {
        final result = _createResultWithSteps([
          {
            'stepNumber': 9,
            'type': 'result',
            'description': 'Automata are equivalent - same language recognized',
            'data': {'isEquivalent': true},
          },
        ]);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Comparison Result'), findsOneWidget);
        expect(find.text('Equivalent'), findsOneWidget);
        expect(find.text(_en.yes), findsOneWidget);
      });

      testWidgets('renders an error payload as an error step', (tester) async {
        final result = _createResultWithSteps([
          {
            'stepNumber': 5,
            'type': 'error',
            'description': 'Determinization of automaton A failed',
            'data': {
              'reason': 'determinization',
              'stage': 'nfa_to_dfa',
              'message': 'state limit exceeded',
            },
          },
        ]);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: result,
          showSteps: true,
        );

        expect(find.text('Comparison Error'), findsOneWidget);
        expect(find.text('Reason'), findsOneWidget);
        expect(find.text('determinization'), findsOneWidget);
        expect(find.text('state limit exceeded'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsAtLeastNWidgets(1));
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

    group('Stopped Comparisons', () {
      testWidgets('never derives a verdict from a stopped comparison', (
        tester,
      ) async {
        for (final reason in LanguageComparisonFailureReason.values) {
          await _pumpLanguageComparisonViewer(
            tester,
            failure: LanguageComparisonFailure(
              reason: reason,
              message: 'engine detail for ${reason.name}',
            ),
          );

          expect(
            find.byKey(LanguageComparisonSemantics.failureKey(reason)),
            findsOneWidget,
            reason: 'the ${reason.name} panel must be identified',
          );
          expect(
            find.byKey(
              LanguageComparisonSemantics.statusKey(
                reason.isInconclusive
                    ? LanguageComparisonStatus.inconclusive
                    : LanguageComparisonStatus.error,
              ),
            ),
            findsOneWidget,
            reason: '${reason.name} must map to its own status',
          );

          // No verdict badge, no automaton, no statistics: there is nothing a
          // reader could mistake for an equivalence answer.
          expect(
            find.byKey(
              LanguageComparisonSemantics.statusKey(
                LanguageComparisonStatus.equivalent,
              ),
            ),
            findsNothing,
          );
          expect(
            find.byKey(
              LanguageComparisonSemantics.statusKey(
                LanguageComparisonStatus.notEquivalent,
              ),
            ),
            findsNothing,
          );
          expect(find.text(_en.equivalent), findsNothing);
          expect(find.text(_en.notEquivalent), findsNothing);
          expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNothing);
          expect(find.text(_en.statesA), findsNothing);
          expect(find.text(_en.distinguishingStringFound), findsNothing);
          expect(find.text(_en.algorithmSteps), findsNothing);
        }
      });

      testWidgets('shows a localized explanation next to the headline', (
        tester,
      ) async {
        await _pumpLanguageComparisonViewer(
          tester,
          failure: const LanguageComparisonFailure(
            reason: LanguageComparisonFailureReason.determinization,
            message: 'Automaton A could not be determinized',
          ),
        );

        expect(
          find.text(_en.languageComparisonFailureDeterminizationExplanation),
          findsOneWidget,
        );
        expect(find.textContaining('could not be determinized'), findsNothing);
      });

      testWidgets('renders without an engine detail message', (tester) async {
        await _pumpLanguageComparisonViewer(
          tester,
          failure: const LanguageComparisonFailure(
            reason: LanguageComparisonFailureReason.timeout,
          ),
        );

        expect(
          find.byKey(
            LanguageComparisonSemantics.statusKey(
              LanguageComparisonStatus.inconclusive,
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(_en.timeout), findsAtLeastNWidgets(1));
      });

      testWidgets(
        'renders a structured validation detail in the active locale',
        (tester) async {
          await _pumpLanguageComparisonViewer(
            tester,
            failure: LanguageComparisonFailure(
              reason: LanguageComparisonFailureReason.malformedInput,
              structuredMessage: LanguageComparisonMessages.missingInitialState(
                'B',
              ),
            ),
          );

          expect(
            find.text('Automaton B must have an initial state'),
            findsOneWidget,
          );
          expect(find.text(_en.languageComparisonInvalidInput), findsOneWidget);
        },
      );
    });

    group('Responsive Presentation', () {
      testWidgets('places the automata side by side on a wide surface', (
        tester,
      ) async {
        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(),
        );

        expect(
          find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: false)),
          findsOneWidget,
        );
        expect(
          find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: true)),
          findsNothing,
        );
      });

      testWidgets('stacks the automata on a compact surface', (tester) async {
        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(),
          window: _narrowWindow,
        );

        expect(
          find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: true)),
          findsOneWidget,
        );
        expect(
          find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: false)),
          findsNothing,
        );
        expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(2));
      });

      testWidgets(
        'preserves the verdict, witness and selected step across layouts',
        (tester) async {
          await _pumpLanguageComparisonViewer(
            tester,
            comparisonResult: _createNonEquivalentResult(includeSteps: true),
            showSteps: true,
          );

          await _tapStepButton(tester, LanguageComparisonSemantics.nextStep);
          expect(find.text(_en.stepOf(2, 3)), findsOneWidget);
          expect(
            find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: false)),
            findsOneWidget,
          );

          tester.view.physicalSize = _narrowWindow;
          await tester.pumpAndSettle();

          expect(
            find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: true)),
            findsOneWidget,
          );
          expect(
            find.byKey(
              LanguageComparisonSemantics.statusKey(
                LanguageComparisonStatus.notEquivalent,
              ),
            ),
            findsOneWidget,
          );
          expect(find.text('"ab"'), findsOneWidget);
          expect(find.text(_en.stepOf(2, 3)), findsOneWidget);
          expect(find.text('State Pair Visit'), findsOneWidget);
        },
      );

      testWidgets('lays out inside a host that imposes no height', (
        tester,
      ) async {
        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(
            includeProductAutomaton: true,
            includeSteps: true,
          ),
          showProductAutomaton: true,
          showSteps: true,
          unboundedHost: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(LanguageComparisonViewer), findsOneWidget);
        expect(find.byType(ReadOnlyFsaGraphViewCanvas), findsNWidgets(3));
      });

      testWidgets('lays out on a narrow phone at the accessibility scale', (
        tester,
      ) async {
        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(
            includeProductAutomaton: true,
            includeSteps: true,
          ),
          showProductAutomaton: true,
          showSteps: true,
          window: const Size(320, 568),
          textScale: 2.0,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: true)),
          findsOneWidget,
        );
      });

      testWidgets('lays out in landscape on a phone-sized window', (
        tester,
      ) async {
        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(includeSteps: true),
          showSteps: true,
          window: const Size(844, 390),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(LanguageComparisonSemantics.layoutKey(isStacked: false)),
          findsOneWidget,
        );
      });
    });

    group('Semantics', () {
      testWidgets('publishes stable identifiers for a decided comparison', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(
            includeProductAutomaton: true,
            includeSteps: true,
          ),
          showProductAutomaton: true,
          showSteps: true,
        );

        for (final identifier in [
          LanguageComparisonSemantics.status,
          LanguageComparisonSemantics.witness,
          LanguageComparisonSemantics.statistics,
          LanguageComparisonSemantics.canvasA,
          LanguageComparisonSemantics.canvasB,
          LanguageComparisonSemantics.productCanvas,
          LanguageComparisonSemantics.stepNavigation,
          LanguageComparisonSemantics.previousStep,
          LanguageComparisonSemantics.nextStep,
          LanguageComparisonSemantics.selectedStep,
        ]) {
          expect(
            find.bySemanticsIdentifier(identifier),
            findsOneWidget,
            reason: '$identifier must be published',
          );
        }
        handle.dispose();
      });

      testWidgets('publishes an error identifier for a stopped comparison', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await _pumpLanguageComparisonViewer(
          tester,
          failure: const LanguageComparisonFailure(
            reason: LanguageComparisonFailureReason.malformedInput,
            message: 'Automaton B must have an initial state',
          ),
        );

        expect(
          find.bySemanticsIdentifier(LanguageComparisonSemantics.error),
          findsOneWidget,
        );
        expect(
          find.bySemanticsIdentifier(LanguageComparisonSemantics.canvasA),
          findsNothing,
        );
        expect(
          find.bySemanticsIdentifier(LanguageComparisonSemantics.witness),
          findsNothing,
        );
        handle.dispose();
      });

      testWidgets('labels the verdict, witness and steps in English', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(includeSteps: true),
          showSteps: true,
        );

        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.status),
          _en.languageComparisonStatusSemantic(_en.notEquivalent),
        );
        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.witness),
          _en.languageComparisonWitnessSemantic('"ab"'),
        );
        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.stepNavigation),
          _en.stepOf(1, 3),
        );
        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.canvasA),
          contains(_en.automatonA),
        );
        handle.dispose();
      });

      testWidgets('labels the verdict, witness and steps in Portuguese', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(includeSteps: true),
          showSteps: true,
          locale: const Locale('pt'),
        );

        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.status),
          _pt.languageComparisonStatusSemantic(_pt.notEquivalent),
        );
        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.witness),
          _pt.languageComparisonWitnessSemantic('"ab"'),
        );
        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.stepNavigation),
          _pt.stepOf(1, 3),
        );
        expect(
          _semanticsLabel(tester, LanguageComparisonSemantics.canvasA),
          contains(_pt.automatonA),
        );

        // The two locales must not collapse onto the same wording.
        expect(_pt.notEquivalent, isNot(_en.notEquivalent));
        expect(_pt.languageComparisonTitle, isNot(_en.languageComparisonTitle));
        handle.dispose();
      });

      testWidgets('labels a stopped comparison in both locales', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();

        const failure = LanguageComparisonFailure(
          reason: LanguageComparisonFailureReason.timeout,
          message: 'budget exhausted',
        );

        await _pumpLanguageComparisonViewer(tester, failure: failure);
        final englishLabel = _semanticsLabel(
          tester,
          LanguageComparisonSemantics.error,
        );
        expect(englishLabel, contains(_en.timeout));

        await _pumpLanguageComparisonViewer(
          tester,
          failure: failure,
          locale: const Locale('pt'),
        );
        final portugueseLabel = _semanticsLabel(
          tester,
          LanguageComparisonSemantics.error,
        );
        expect(portugueseLabel, contains(_pt.timeout));
        expect(portugueseLabel, isNot(englishLabel));
        handle.dispose();
      });

      testWidgets('renders Portuguese section titles', (tester) async {
        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: _createNonEquivalentResult(
            includeProductAutomaton: true,
            includeSteps: true,
          ),
          locale: const Locale('pt'),
        );

        expect(find.text(_pt.productAutomaton), findsOneWidget);
        expect(find.text(_pt.algorithmSteps), findsOneWidget);
        expect(find.text(_pt.statesA), findsOneWidget);
        expect(find.text(_pt.notEquivalent), findsOneWidget);
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

        // Should not crash and should still report the verdict.
        expect(
          find.byKey(
            LanguageComparisonSemantics.statusKey(
              LanguageComparisonStatus.notEquivalent,
            ),
          ),
          findsOneWidget,
        );
        // But no counterexample section since the string is null.
        expect(find.text(_en.distinguishingStringFound), findsNothing);
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

        expect(find.text(_en.equivalent), findsOneWidget);
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

        expect(find.text(_en.productAutomaton), findsOneWidget);
        expect(find.text(_en.algorithmSteps), findsOneWidget);
        expect(find.byIcon(Icons.expand_more), findsAtLeastNWidgets(2));
      });

      testWidgets('clamps the selected step when the trace shrinks', (
        tester,
      ) async {
        final longTrace = _createResultWithSteps([
          {'type': 'initialization', 'description': 'first'},
          {'type': 'bfs_exploration', 'description': 'second'},
          {'type': 'counterexample_found', 'description': 'third'},
        ]);

        await _pumpLanguageComparisonViewer(
          tester,
          comparisonResult: longTrace,
          showSteps: true,
        );

        await _tapStepButton(tester, LanguageComparisonSemantics.nextStep);
        await _tapStepButton(tester, LanguageComparisonSemantics.nextStep);
        expect(find.text(_en.stepOf(3, 3)), findsOneWidget);

        final shortTrace = _createResultWithSteps([
          {'type': 'initialization', 'description': 'only step'},
        ]);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: LanguageComparisonViewer(
                  comparisonResult: shortTrace,
                  showSteps: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(_en.stepOf(1, 1)), findsOneWidget);
        expect(
          find.text(_en.languageComparisonDescriptionInitialization),
          findsOneWidget,
        );
      });
    });
  });
}

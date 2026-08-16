import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/pda_trace_viewer.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/tm_trace_viewer.dart';
import 'package:turing_lab/presentation/widgets/trace_viewers/base_trace_viewer.dart';

class _SpyHighlightService extends SimulationHighlightService {
  final emittedIndices = <int>[];
  int clearCount = 0;

  @override
  SimulationHighlight emitFromSteps(
    List<SimulationStep> steps,
    int currentIndex,
  ) {
    emittedIndices.add(currentIndex);
    return super.emitFromSteps(steps, currentIndex);
  }

  @override
  void clear() {
    clearCount++;
    super.clear();
  }
}

Future<void> _pumpPDATraceViewer(
  WidgetTester tester, {
  required PDASimulationResult result,
  SimulationHighlightService? highlightService,
  ValueChanged<int>? onStepChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PDATraceViewer(
          result: result,
          highlightService: highlightService,
          onStepChanged: onStepChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTMTraceViewer(
  WidgetTester tester, {
  required TMSimulationResult result,
  SimulationHighlightService? highlightService,
  ValueChanged<int>? onStepChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TMTraceViewer(
          result: result,
          highlightService: highlightService,
          onStepChanged: onStepChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBaseTraceViewer(
  WidgetTester tester, {
  required SimulationResult result,
  SimulationHighlightService? highlightService,
  ValueChanged<int>? onStepChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BaseTraceViewer(
          result: result,
          title: 'Trace (${result.steps.length} steps)',
          highlightService: highlightService ?? SimulationHighlightService(),
          animationSpeed: 10,
          onStepChanged: onStepChanged,
          buildStepLine: (step, index) =>
              Text('${index + 1}. ${step.currentState}'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BaseTraceViewer playback', () {
    testWidgets('cancels stale playback timer after pause and replay', (
      tester,
    ) async {
      final result = SimulationResult.success(
        inputString: 'aaa',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'aaa',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'aa',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: 'a',
            stepNumber: 2,
          ),
          const SimulationStep(
            currentState: 'q3',
            remainingInput: '',
            stepNumber: 3,
          ),
        ],
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpBaseTraceViewer(tester, result: result);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 65));

      expect(find.text('1 / 4'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 40));

      expect(find.text('2 / 4'), findsOneWidget);
    });

    testWidgets('manual navigation pauses playback and cancels pending timer', (
      tester,
    ) async {
      final result = SimulationResult.success(
        inputString: 'aaa',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'aaa',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'aa',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: 'a',
            stepNumber: 2,
          ),
          const SimulationStep(
            currentState: 'q3',
            remainingInput: '',
            stepNumber: 3,
          ),
        ],
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpBaseTraceViewer(tester, result: result);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      await tester.tap(find.byTooltip('Next Step'));
      await tester.pump();
      await tester.tap(find.byTooltip('Next Step'));
      await tester.pump();

      expect(find.text('3 / 4'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 110));

      expect(find.text('3 / 4'), findsOneWidget);
    });
  });

  group('BaseTraceViewer highlight lifecycle', () {
    SimulationResult result(String state) => SimulationResult.success(
          inputString: 'a',
          steps: [
            SimulationStep(
              currentState: state,
              remainingInput: 'a',
              stepNumber: 0,
            ),
            SimulationStep(
              currentState: '${state}1',
              remainingInput: '',
              stepNumber: 1,
            ),
          ],
          executionTime: Duration.zero,
        );

    SimulationResult emptyResult() => SimulationResult.success(
          inputString: '',
          steps: const [],
          executionTime: Duration.zero,
        );

    testWidgets('synchronizes init, navigation, playback, and reset',
        (tester) async {
      final service = _SpyHighlightService();
      final selected = <int>[];
      await _pumpBaseTraceViewer(
        tester,
        result: result('q0'),
        highlightService: service,
        onStepChanged: selected.add,
      );

      expect(service.emittedIndices, [0]);
      expect(selected, [0]);

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pump();
      expect(service.emittedIndices.last, 1);

      await tester.tap(find.byTooltip('Reset'));
      await tester.pump();
      expect(service.emittedIndices.last, 0);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Play'));
      await tester.pump(const Duration(milliseconds: 110));
      expect(service.emittedIndices.last, 1);
    });

    testWidgets(
        'resets to zero without clearing borrowed services on replacement or dispose',
        (tester) async {
      final oldService = _SpyHighlightService();
      await _pumpBaseTraceViewer(
        tester,
        result: result('old'),
        highlightService: oldService,
      );

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pump();
      expect(oldService.emittedIndices.last, 1);

      await _pumpBaseTraceViewer(
        tester,
        result: result('new'),
        highlightService: oldService,
      );
      expect(oldService.clearCount, 0);
      expect(oldService.emittedIndices.last, 0);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pump();
      expect(oldService.emittedIndices.last, 1);

      final newService = _SpyHighlightService();
      await _pumpBaseTraceViewer(
        tester,
        result: result('new'),
        highlightService: newService,
      );
      expect(oldService.clearCount, 0);
      expect(newService.emittedIndices, [0]);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(newService.clearCount, 0);
    });

    testWidgets('empty result clears the current service exactly once',
        (tester) async {
      final service = _SpyHighlightService();
      await _pumpBaseTraceViewer(
        tester,
        result: result('nonempty'),
        highlightService: service,
      );

      await _pumpBaseTraceViewer(
        tester,
        result: emptyResult(),
        highlightService: service,
      );

      expect(service.clearCount, 1);
      expect(service.emittedIndices, [0]);
    });

    testWidgets('empty result with a new service clears only the new service',
        (tester) async {
      final oldService = _SpyHighlightService();
      final newService = _SpyHighlightService();
      await _pumpBaseTraceViewer(
        tester,
        result: result('nonempty'),
        highlightService: oldService,
      );

      await _pumpBaseTraceViewer(
        tester,
        result: emptyResult(),
        highlightService: newService,
      );

      expect(oldService.clearCount, 0);
      expect(newService.clearCount, 1);
      expect(newService.emittedIndices, isEmpty);
    });

    testWidgets('keeps the active row visible across the fold boundary',
        (tester) async {
      final longResult = SimulationResult.success(
        inputString: '',
        steps: List.generate(
          101,
          (index) => SimulationStep(
            currentState: 'q$index',
            remainingInput: '',
            stepNumber: index,
          ),
        ),
        executionTime: Duration.zero,
      );
      await _pumpBaseTraceViewer(tester, result: longResult);

      void select(int index) {
        tester.widget<Slider>(find.byType(Slider)).onChanged!(index.toDouble());
      }

      for (final index in [49, 50, 100]) {
        select(index);
        await tester.pumpAndSettle();
        expect(find.text('${index + 1}. q$index'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.selected == true &&
                widget.properties.label == 'Active step ${index + 1} of 101',
          ),
          findsOneWidget,
        );
      }

      await tester.tap(find.text('Expand'));
      await tester.pumpAndSettle();
      expect(find.text('101. q100'), findsOneWidget);

      await tester.tap(find.text('Collapse'));
      await tester.pumpAndSettle();
      expect(find.text('101. q100'), findsOneWidget);

      await tester.tap(find.byTooltip('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('1. q0'), findsOneWidget);
      expect(find.text('1 / 101'), findsOneWidget);
    });
  });

  group('PDATraceViewer', () {
    testWidgets(
      'keeps its generic adapter stable and forwards step changes',
      (tester) async {
        PDASimulationResult result() => PDASimulationResult.success(
              inputString: 'ab',
              steps: const [
                SimulationStep(
                  currentState: 'q0',
                  remainingInput: 'ab',
                  stackContents: 'Z',
                  stepNumber: 0,
                ),
                SimulationStep(
                  currentState: 'q1',
                  remainingInput: 'b',
                  stackContents: 'AZ',
                  stepNumber: 1,
                ),
                SimulationStep(
                  currentState: 'q2',
                  remainingInput: '',
                  stackContents: 'Z',
                  stepNumber: 2,
                ),
              ],
              executionTime: Duration.zero,
            );

        final specializedResult = result();
        final service = _SpyHighlightService();
        final selected = <int>[];
        await _pumpPDATraceViewer(
          tester,
          result: specializedResult,
          highlightService: service,
          onStepChanged: selected.add,
        );
        final initialAdapter =
            tester.widget<BaseTraceViewer>(find.byType(BaseTraceViewer)).result;

        await tester.tap(find.byTooltip('Next Step'));
        await tester.pumpAndSettle();
        expect(selected.last, 1);
        expect(service.emittedIndices.last, 1);
        expect(find.text('2 / 3'), findsOneWidget);

        final emissionCount = service.emittedIndices.length;
        final callbackCount = selected.length;
        await _pumpPDATraceViewer(
          tester,
          result: specializedResult,
          highlightService: service,
          onStepChanged: selected.add,
        );
        final stableAdapter =
            tester.widget<BaseTraceViewer>(find.byType(BaseTraceViewer)).result;

        expect(stableAdapter, same(initialAdapter));
        expect(service.emittedIndices.length, emissionCount);
        expect(selected.length, callbackCount);
        expect(find.text('2 / 3'), findsOneWidget);

        await _pumpPDATraceViewer(
          tester,
          result: result(),
          highlightService: service,
          onStepChanged: selected.add,
        );
        final replacementAdapter =
            tester.widget<BaseTraceViewer>(find.byType(BaseTraceViewer)).result;

        expect(replacementAdapter, isNot(same(initialAdapter)));
        expect(service.emittedIndices.last, 0);
        expect(selected.last, 0);
        expect(find.text('1 / 3'), findsOneWidget);
      },
    );

    testWidgets('renders with accepted result and displays correct title', (
      tester,
    ) async {
      final result = PDASimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stackContents: 'Z',
            usedTransition: 'b',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 10),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('PDA Trace (3 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
      final stepRowInkWell = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(InkWell),
          )
          .first;
      expect(
        tester.getSize(stepRowInkWell).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('renders with rejected result and displays correct icon', (
      tester,
    ) async {
      final result = PDASimulationResult.failure(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        errorMessage: 'No valid transition',
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('PDA Trace (2 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays lambda for empty remaining input', (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stackContents: 'Z',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.text('PDA Trace (2 steps)'), findsOneWidget);
      expect(find.textContaining('rem=λ'), findsOneWidget);
    });

    testWidgets('displays lambda for empty stack', (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stackContents: '',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.textContaining('stack=λ'), findsOneWidget);
    });

    testWidgets(
      'displays step information with state, remaining input, and stack',
      (tester) async {
        final result = PDASimulationResult.success(
          inputString: 'abc',
          steps: [
            const SimulationStep(
              currentState: 'q0',
              remainingInput: 'abc',
              stackContents: 'Z',
              stepNumber: 0,
            ),
            const SimulationStep(
              currentState: 'q1',
              remainingInput: 'bc',
              stackContents: 'AZ',
              usedTransition: 'a',
              stepNumber: 1,
            ),
          ],
          executionTime: const Duration(milliseconds: 8),
        );

        await _pumpPDATraceViewer(tester, result: result);

        expect(find.textContaining('q=q0'), findsOneWidget);
        expect(find.textContaining('rem=abc'), findsOneWidget);
        expect(find.textContaining('stack=Z'), findsOneWidget);
        expect(find.textContaining('q=q1'), findsOneWidget);
        expect(find.textContaining('rem=bc'), findsOneWidget);
        expect(find.textContaining('stack=AZ'), findsOneWidget);
      },
    );

    testWidgets('displays transition information when available', (
      tester,
    ) async {
      final result = PDASimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stackContents: 'AZ',
            usedTransition: 'a, Z -> AZ',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stackContents: 'Z',
            usedTransition: 'b, A -> ε',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 12),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.textContaining('a, Z -> AZ'), findsOneWidget);
      expect(find.textContaining('b, A -> ε'), findsOneWidget);
    });

    testWidgets('displays step numbers in sequence', (tester) async {
      final result = PDASimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'bc',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: 'c',
            stackContents: 'BZ',
            usedTransition: 'b',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 15),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
    });

    testWidgets('handles empty steps list', (tester) async {
      final result = PDASimulationResult.failure(
        inputString: '',
        steps: const [],
        errorMessage: 'Invalid automaton',
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.text('PDA Trace (0 steps)'), findsOneWidget);
      expect(find.text('No steps recorded'), findsOneWidget);
    });

    testWidgets('handles timeout result', (tester) async {
      final result = PDASimulationResult.timeout(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(seconds: 5),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('handles infinite loop result', (tester) async {
      final result = PDASimulationResult.infiniteLoop(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stackContents: 'Z',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(seconds: 3),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('renders all step containers with proper styling', (
      tester,
    ) async {
      final result = PDASimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stackContents: 'Z',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stackContents: 'AZ',
            usedTransition: 'a',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 6),
      );

      await _pumpPDATraceViewer(tester, result: result);

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Container),
        ),
      );

      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('handles step without transition', (tester) async {
      final result = PDASimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            stackContents: 'Z',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpPDATraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('rem=λ'), findsOneWidget);
      expect(find.textContaining('stack=Z'), findsOneWidget);
    });
  });

  group('TMTraceViewer', () {
    testWidgets('keeps its generic adapter stable for the same TM result', (
      tester,
    ) async {
      TMSimulationResult result() => TMSimulationResult.success(
            inputString: 'ab',
            steps: const [
              SimulationStep(
                currentState: 'q0',
                remainingInput: '',
                tapeContents: 'ab',
                stepNumber: 0,
              ),
              SimulationStep(
                currentState: 'q1',
                remainingInput: '',
                tapeContents: 'Xb',
                stepNumber: 1,
              ),
              SimulationStep(
                currentState: 'q2',
                remainingInput: '',
                tapeContents: 'XY',
                stepNumber: 2,
              ),
            ],
            executionTime: Duration.zero,
          );

      final specializedResult = result();
      final service = _SpyHighlightService();
      final selected = <int>[];
      await _pumpTMTraceViewer(
        tester,
        result: specializedResult,
        highlightService: service,
        onStepChanged: selected.add,
      );
      final initialAdapter =
          tester.widget<BaseTraceViewer>(find.byType(BaseTraceViewer)).result;

      await tester.tap(find.byTooltip('Next Step'));
      await tester.pumpAndSettle();
      final emissionCount = service.emittedIndices.length;
      final callbackCount = selected.length;

      await _pumpTMTraceViewer(
        tester,
        result: specializedResult,
        highlightService: service,
        onStepChanged: selected.add,
      );
      final stableAdapter =
          tester.widget<BaseTraceViewer>(find.byType(BaseTraceViewer)).result;

      expect(stableAdapter, same(initialAdapter));
      expect(service.emittedIndices.length, emissionCount);
      expect(selected.length, callbackCount);
      expect(service.emittedIndices.last, 1);
      expect(selected.last, 1);
      expect(find.text('2 / 3'), findsOneWidget);

      await _pumpTMTraceViewer(
        tester,
        result: result(),
        highlightService: service,
        onStepChanged: selected.add,
      );
      final replacementAdapter =
          tester.widget<BaseTraceViewer>(find.byType(BaseTraceViewer)).result;

      expect(replacementAdapter, isNot(same(initialAdapter)));
      expect(service.emittedIndices.last, 0);
      expect(selected.last, 0);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('renders with accepted result and displays correct title', (
      tester,
    ) async {
      final result = TMSimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            tapeContents: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            tapeContents: 'Xbc',
            usedTransition: 'a/X,R',
            stepNumber: 1,
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            tapeContents: 'XYc',
            usedTransition: 'b/Y,R',
            stepNumber: 2,
          ),
        ],
        executionTime: const Duration(milliseconds: 10),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('TM Trace (3 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders with rejected result and displays correct icon', (
      tester,
    ) async {
      final result = TMSimulationResult.failure(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'ab',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xb',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        errorMessage: 'No valid transition',
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byType(BaseTraceViewer), findsOneWidget);
      expect(find.text('TM Trace (2 steps)'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays blank square for empty tape', (tester) async {
      final result = TMSimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: '',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: '',
            usedTransition: '□/□,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 5),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('TM Trace (2 steps)'), findsOneWidget);
      expect(find.textContaining('tape=□'), findsNWidgets(2));
    });

    testWidgets('displays step information with state and tape', (
      tester,
    ) async {
      final result = TMSimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xbc',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 8),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('tape=abc'), findsOneWidget);
      expect(find.textContaining('q=q1'), findsOneWidget);
      expect(find.textContaining('tape=Xbc'), findsOneWidget);
    });

    testWidgets('displays transition information when available', (
      tester,
    ) async {
      final result = TMSimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'ab',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xb',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q2',
            tapeContents: 'XY',
            usedTransition: 'b/Y,R',
            stepNumber: 2,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 12),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('δ: a/X,R'), findsOneWidget);
      expect(find.textContaining('δ: b/Y,R'), findsOneWidget);
    });

    testWidgets('displays step numbers in sequence', (tester) async {
      final result = TMSimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xbc',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q2',
            tapeContents: 'XYc',
            usedTransition: 'b/Y,R',
            stepNumber: 2,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 15),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
    });

    testWidgets('handles empty steps list', (tester) async {
      final result = TMSimulationResult.failure(
        inputString: '',
        steps: const [],
        errorMessage: 'Invalid Turing machine',
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('TM Trace (0 steps)'), findsOneWidget);
      expect(find.text('No steps recorded'), findsOneWidget);
    });

    testWidgets('handles timeout result', (tester) async {
      final result = TMSimulationResult.timeout(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(seconds: 5),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('handles infinite loop result', (tester) async {
      final result = TMSimulationResult.infiniteLoop(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'abc',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(seconds: 3),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('renders all step containers with proper styling', (
      tester,
    ) async {
      final result = TMSimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'ab',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'Xb',
            usedTransition: 'a/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 6),
      );

      await _pumpTMTraceViewer(tester, result: result);

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Container),
        ),
      );

      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('displays correct information for single step', (tester) async {
      final result = TMSimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: 'X',
            usedTransition: 'a/X,R',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 2),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.text('TM Trace (1 steps)'), findsOneWidget);
      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('tape=X'), findsOneWidget);
      expect(find.textContaining('δ: a/X,R'), findsOneWidget);
    });

    testWidgets('handles step without transition', (tester) async {
      final result = TMSimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: '',
            stepNumber: 0,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 1),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('q=q0'), findsOneWidget);
      expect(find.textContaining('tape=□'), findsOneWidget);
      expect(find.textContaining('δ:'), findsNothing);
    });

    testWidgets('displays tape contents correctly for complex strings', (
      tester,
    ) async {
      final result = TMSimulationResult.success(
        inputString: '0011',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            tapeContents: '0011',
            stepNumber: 0,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q1',
            tapeContents: 'X011',
            usedTransition: '0/X,R',
            stepNumber: 1,
            remainingInput: '',
          ),
          const SimulationStep(
            currentState: 'q2',
            tapeContents: 'XX11',
            usedTransition: '0/X,R',
            stepNumber: 2,
            remainingInput: '',
          ),
        ],
        executionTime: const Duration(milliseconds: 10),
      );

      await _pumpTMTraceViewer(tester, result: result);

      expect(find.textContaining('tape=0011'), findsOneWidget);
      expect(find.textContaining('tape=X011'), findsOneWidget);
      expect(find.textContaining('tape=XX11'), findsOneWidget);
    });
  });
}

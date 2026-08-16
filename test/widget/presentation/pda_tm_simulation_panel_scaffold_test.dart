import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/core/services/simulation_runner.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/pda_simulation_provider.dart'
    show pdaSimulationProvider;
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';
import 'package:turing_lab/presentation/widgets/pda_simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/tm/tape_drawer.dart';
import 'package:turing_lab/presentation/widgets/tm_simulation_panel.dart';

Future<void> _pumpPanel(
  WidgetTester tester,
  Widget panel, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 720,
            child: panel,
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (find.text(text).evaluate().isNotEmpty) return;
  }
}

class _PendingTask<T> implements SimulationTask<T> {
  final completer = Completer<SimulationOutcome<T>>();
  var cancelled = false;

  @override
  Future<SimulationOutcome<T>> get outcome => completer.future;

  @override
  void cancel() {
    cancelled = true;
  }
}

class _FakeSimulationBackend implements SimulationRunnerBackend {
  final pdaTasks = <_PendingTask<PDASimulationResult>>[];
  final tmTasks = <_PendingTask<TMSimulationResult>>[];
  final pdaStepByStepValues = <bool>[];

  @override
  SimulationTask<PDASimulationResult> runPda(
    PDA pda,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    pdaStepByStepValues.add(stepByStep);
    final task = _PendingTask<PDASimulationResult>();
    pdaTasks.add(task);
    return task;
  }

  @override
  SimulationTask<TMSimulationResult> runTm(
    TM tm,
    String inputString, {
    required bool stepByStep,
    required Duration timeout,
  }) {
    final task = _PendingTask<TMSimulationResult>();
    tmTasks.add(task);
    return task;
  }
}

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

PDAEditorNotifier _pdaEditorWithInitialState() {
  final notifier = PDAEditorNotifier();
  notifier.updateFromCanvas(
    states: [
      automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: true,
      ),
    ],
    transitions: const [],
  );
  return notifier;
}

TMEditorNotifier _tmEditorWithInitialState() {
  final notifier = TMEditorNotifier();
  notifier.upsertState(
    id: 'q0',
    label: 'q0',
    x: 0,
    y: 0,
    isInitial: true,
    isAccepting: true,
  );
  return notifier;
}

PDASimulationResult _pdaTraceResult() => PDASimulationResult.success(
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
          usedTransition: 'a,Z -> AZ',
          stepNumber: 1,
        ),
        SimulationStep(
          currentState: 'q2',
          remainingInput: '',
          stackContents: 'Z',
          usedTransition: 'b,A -> epsilon',
          stepNumber: 2,
        ),
      ],
      executionTime: Duration.zero,
    );

TMSimulationResult _tmTraceResult() => TMSimulationResult.success(
      inputString: 'ab',
      steps: const [
        SimulationStep(
          currentState: 'q0',
          remainingInput: '',
          tapeContents: 'ab',
          headPosition: 0,
          stepNumber: 0,
        ),
        SimulationStep(
          currentState: 'q1',
          remainingInput: '',
          tapeContents: 'Xb',
          headPosition: 1,
          stepNumber: 1,
        ),
        SimulationStep(
          currentState: 'q2',
          remainingInput: '',
          tapeContents: 'XY',
          headPosition: 2,
          stepNumber: 2,
        ),
      ],
      executionTime: Duration.zero,
    );

Future<void> _completeLatestPdaSimulation(
  WidgetTester tester,
  _FakeSimulationBackend backend,
) async {
  backend.pdaTasks.last.completer.complete(
    SimulationOutcome(
      kind: SimulationOutcomeKind.accepted,
      result: _pdaTraceResult(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _completeLatestTmSimulation(
  WidgetTester tester,
  _FakeSimulationBackend backend,
) async {
  backend.tmTasks.last.completer.complete(
    SimulationOutcome(
      kind: SimulationOutcomeKind.accepted,
      result: _tmTraceResult(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PDA/TM simulation panel shared scaffolding', () {
    testWidgets('PDA panel keeps stack-specific input slots', (tester) async {
      await _pumpPanel(tester, const PDASimulationPanel());

      expect(find.text('PDA Simulation'), findsOneWidget);
      expect(find.text('Simulation Input'), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(
        find.text('Leave blank for ε; whitespace is preserved'),
        findsOneWidget,
      );
      expect(find.text('Initial Stack Symbol'), findsOneWidget);
      expect(find.text('Record step-by-step trace'), findsOneWidget);
      expect(find.text('Simulate PDA'), findsOneWidget);
      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('No simulation results yet'), findsOneWidget);
    });

    testWidgets('TM panel keeps tape-oriented input slots', (tester) async {
      await _pumpPanel(tester, const TMSimulationPanel());

      expect(find.text('TM Simulation'), findsOneWidget);
      expect(find.text('Simulation Input'), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(
        find.text('Leave blank for ε; whitespace is preserved'),
        findsOneWidget,
      );
      expect(
        find.text('Examples: 101 (binary), 1100 (palindrome), 111 (counting)'),
        findsOneWidget,
      );
      expect(find.text('Simulate TM'), findsOneWidget);
      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('No simulation results yet'), findsOneWidget);
    });

    testWidgets('PDA panel simulates blank input as epsilon', (tester) async {
      final notifier = PDAEditorNotifier();
      notifier.updateFromCanvas(
        states: [
          automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: true,
          ),
        ],
        transitions: const [],
      );

      await _pumpPanel(
        tester,
        const PDASimulationPanel(),
        overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simulate PDA'));
      await _pumpUntilText(tester, 'Accepted');

      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Please enter an input string'), findsNothing);
    });

    testWidgets('TM panel simulates blank input as epsilon', (tester) async {
      final notifier = TMEditorNotifier();
      notifier.upsertState(
        id: 'q0',
        label: 'q0',
        x: 0,
        y: 0,
        isInitial: true,
        isAccepting: true,
      );

      await _pumpPanel(
        tester,
        const TMSimulationPanel(),
        overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.text('Simulate TM'));
      await _pumpUntilText(tester, 'Accepted');

      expect(find.text('Accepted'), findsOneWidget);
    });

    testWidgets('PDA simulation can be cancelled and ignores its stale result',
        (tester) async {
      final notifier = PDAEditorNotifier();
      notifier.updateFromCanvas(
        states: [
          automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: true,
          ),
        ],
        transitions: const [],
      );
      final backend = _FakeSimulationBackend();
      final runner = SimulationRunner(backendOverride: backend);

      await _pumpPanel(
        tester,
        PDASimulationPanel(simulationRunner: runner),
        overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.text('Simulate PDA'));
      await tester.pump();
      expect(find.text('Cancel simulation'), findsOneWidget);

      await tester.tap(find.text('Cancel simulation'));
      await tester.pump();
      expect(backend.pdaTasks.single.cancelled, isTrue);
      expect(find.text('Simulation cancelled'), findsOneWidget);

      await tester.tap(find.text('Simulate PDA'));
      await tester.pump();
      final latestTask = backend.pdaTasks.last;
      latestTask.completer.complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.accepted,
          result: PDASimulationResult.success(
            inputString: '',
            steps: const [],
            executionTime: Duration.zero,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Accepted'), findsOneWidget);

      backend.pdaTasks.first.completer.complete(
        SimulationOutcome(
          kind: SimulationOutcomeKind.rejected,
          result: PDASimulationResult.failure(
            inputString: '',
            steps: const [],
            errorMessage: 'stale rejection',
            executionTime: Duration.zero,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('stale rejection'), findsNothing);
    });

    testWidgets('TM simulation exposes cancellation', (tester) async {
      final notifier = TMEditorNotifier();
      notifier.upsertState(
        id: 'q0',
        label: 'q0',
        x: 0,
        y: 0,
        isInitial: true,
        isAccepting: true,
      );
      final backend = _FakeSimulationBackend();

      await _pumpPanel(
        tester,
        TMSimulationPanel(
          simulationRunner: SimulationRunner(backendOverride: backend),
        ),
        overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
      );
      await tester.tap(find.text('Simulate TM'));
      await tester.pump();
      await tester.tap(find.text('Cancel simulation'));
      await tester.pump();

      expect(backend.tmTasks.single.cancelled, isTrue);
      expect(find.text('Simulation cancelled'), findsOneWidget);
    });

    testWidgets(
      'PDA trace is the sole cursor and keeps provider, stack, and highlight synchronized',
      (tester) async {
        final backend = _FakeSimulationBackend();
        final service = _SpyHighlightService();
        final stackStates = <StackState>[];
        await _pumpPanel(
          tester,
          PDASimulationPanel(
            simulationRunner: SimulationRunner(backendOverride: backend),
            highlightService: service,
            onStackChanged: stackStates.add,
          ),
          overrides: [
            pdaEditorProvider.overrideWith(
              (ref) => _pdaEditorWithInitialState(),
            ),
          ],
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PDASimulationPanel)),
        );
        var providerNotifications = 0;
        final subscription = container.listen(
          pdaSimulationProvider,
          (_, __) => providerNotifications++,
        );

        await tester.tap(find.text('Simulate PDA'));
        await tester.pump();
        await _completeLatestPdaSimulation(tester, backend);

        expect(find.byIcon(Icons.skip_previous), findsOneWidget);
        expect(find.byIcon(Icons.skip_next), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);
        expect(container.read(pdaSimulationProvider).currentStepIndex, 0);
        expect(stackStates.last.symbols, ['Z']);
        expect(service.emittedIndices.last, 0);
        expect(providerNotifications, 3);

        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pumpAndSettle();

        expect(find.text('2 / 3'), findsOneWidget);
        expect(container.read(pdaSimulationProvider).currentStepIndex, 1);
        expect(stackStates.last.symbols, ['A', 'Z']);
        expect(service.emittedIndices.last, 1);
        expect(providerNotifications, 4);

        final emissionCount = service.emittedIndices.length;
        final clearCount = service.clearCount;
        final stackCallbackCount = stackStates.length;
        await tester.ensureVisible(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(find.text('Current Stack State'), findsOneWidget);
        await tester.ensureVisible(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(service.emittedIndices.length, emissionCount);
        expect(service.clearCount, clearCount);
        expect(stackStates.length, stackCallbackCount);
        expect(container.read(pdaSimulationProvider).currentStepIndex, 1);
        expect(stackStates.last.symbols, ['A', 'Z']);
        expect(providerNotifications, 4);

        await tester.ensureVisible(find.text('Simulate PDA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simulate PDA'));
        await tester.pump();
        await _completeLatestPdaSimulation(tester, backend);

        expect(find.text('1 / 3'), findsOneWidget);
        expect(container.read(pdaSimulationProvider).currentStepIndex, 0);
        expect(stackStates.last.symbols, ['Z']);
        expect(service.emittedIndices.last, 0);
        expect(providerNotifications, 7);

        subscription.close();
        final clearCountBeforeDispose = service.clearCount;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(service.clearCount, clearCountBeforeDispose);
      },
    );

    testWidgets(
      'PDA unrecorded success still initializes all consumers at step zero',
      (tester) async {
        final backend = _FakeSimulationBackend();
        final service = _SpyHighlightService();
        final stackStates = <StackState>[];
        await _pumpPanel(
          tester,
          PDASimulationPanel(
            simulationRunner: SimulationRunner(backendOverride: backend),
            highlightService: service,
            onStackChanged: stackStates.add,
          ),
          overrides: [
            pdaEditorProvider.overrideWith(
              (ref) => _pdaEditorWithInitialState(),
            ),
          ],
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PDASimulationPanel)),
        );

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simulate PDA'));
        await tester.pump();
        await _completeLatestPdaSimulation(tester, backend);

        expect(backend.pdaStepByStepValues, [false]);
        expect(container.read(pdaSimulationProvider).currentStepIndex, 0);
        expect(stackStates.last.symbols, ['Z']);
        expect(service.emittedIndices.last, 0);
        expect(find.text('Current Stack State'), findsOneWidget);
      },
    );

    testWidgets(
      'TM panel emits reset and selected trace tape states',
      (tester) async {
        final backend = _FakeSimulationBackend();
        final tapeStates = <TapeState>[];
        final notifier = _tmEditorWithInitialState();
        notifier.setTm(
          notifier.state.tm!.copyWith(
            tapeAlphabet: {'a', 'b', '_'},
            blankSymbol: '_',
          ),
        );
        await _pumpPanel(
          tester,
          TMSimulationPanel(
            simulationRunner: SimulationRunner(backendOverride: backend),
            onTapeChanged: tapeStates.add,
          ),
          overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
        );

        await tester.tap(find.text('Simulate TM'));
        await tester.pump();

        expect(tapeStates.last.cells, isEmpty);
        expect(tapeStates.last.headPosition, 0);
        expect(tapeStates.last.blankSymbol, '_');

        await _completeLatestTmSimulation(tester, backend);

        expect(tapeStates.last.cells, ['a', 'b']);
        expect(tapeStates.last.headPosition, 0);
        expect(tapeStates.last.blankSymbol, '_');

        await tester.tap(find.byTooltip('Next Step'));
        await tester.pumpAndSettle();

        expect(tapeStates.last.cells, ['X', 'b']);
        expect(tapeStates.last.headPosition, 1);
        expect(tapeStates.last.blankSymbol, '_');
      },
    );

    testWidgets(
      'TM panel clears its trace and tape when the editor machine changes',
      (tester) async {
        final backend = _FakeSimulationBackend();
        final tapeStates = <TapeState>[];
        final notifier = _tmEditorWithInitialState();
        await _pumpPanel(
          tester,
          TMSimulationPanel(
            simulationRunner: SimulationRunner(backendOverride: backend),
            onTapeChanged: tapeStates.add,
          ),
          overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
        );

        await tester.tap(find.text('Simulate TM'));
        await tester.pump();
        await _completeLatestTmSimulation(tester, backend);
        expect(tapeStates.last.cells, ['a', 'b']);
        expect(find.text('1 / 3'), findsOneWidget);

        notifier.setTm(
          notifier.state.tm!.copyWith(
            id: 'replacement-tm',
            name: 'Replacement TM',
            tapeAlphabet: {'#'},
            blankSymbol: '#',
          ),
        );
        await tester.pumpAndSettle();

        expect(tapeStates.last.cells, isEmpty);
        expect(tapeStates.last.headPosition, 0);
        expect(tapeStates.last.blankSymbol, '#');
        expect(find.text('No simulation results yet'), findsOneWidget);
        expect(find.text('1 / 3'), findsNothing);
      },
    );

    testWidgets(
      'TM trace selection survives tape animation rebuilds and borrowed teardown',
      (tester) async {
        final backend = _FakeSimulationBackend();
        final service = _SpyHighlightService();
        await _pumpPanel(
          tester,
          TMSimulationPanel(
            simulationRunner: SimulationRunner(backendOverride: backend),
            highlightService: service,
          ),
          overrides: [
            tmEditorProvider.overrideWith(
              (ref) => _tmEditorWithInitialState(),
            ),
          ],
        );

        await tester.tap(find.text('Simulate TM'));
        await tester.pump();
        await _completeLatestTmSimulation(tester, backend);
        await tester.tap(find.byTooltip('Next Step'));
        await tester.pumpAndSettle();

        expect(find.text('2 / 3'), findsOneWidget);
        expect(service.emittedIndices.last, 1);
        expect(find.textContaining('Xb'), findsWidgets);

        final clearCountBeforeDispose = service.clearCount;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(service.clearCount, clearCountBeforeDispose);
      },
    );

    testWidgets('PDA and TM service replacement never clears borrowed services',
        (
      tester,
    ) async {
      final oldPdaService = _SpyHighlightService();
      final newPdaService = _SpyHighlightService();
      await _pumpPanel(
        tester,
        PDASimulationPanel(
          key: const ValueKey('pda-panel'),
          highlightService: oldPdaService,
        ),
      );
      await _pumpPanel(
        tester,
        PDASimulationPanel(
          key: const ValueKey('pda-panel'),
          highlightService: newPdaService,
        ),
      );
      expect(oldPdaService.clearCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(newPdaService.clearCount, 0);

      final oldTmService = _SpyHighlightService();
      final newTmService = _SpyHighlightService();
      await _pumpPanel(
        tester,
        TMSimulationPanel(
          key: const ValueKey('tm-panel'),
          highlightService: oldTmService,
        ),
      );
      await _pumpPanel(
        tester,
        TMSimulationPanel(
          key: const ValueKey('tm-panel'),
          highlightService: newTmService,
        ),
      );
      expect(oldTmService.clearCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(newTmService.clearCount, 0);
    });
  });
}

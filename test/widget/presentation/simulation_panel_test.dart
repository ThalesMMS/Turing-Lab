import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';
import 'package:turing_lab/presentation/widgets/error_banner.dart';

class _TestSimulationHighlightService extends SimulationHighlightService {
  int clearCallCount = 0;
  int emitFromStepsCallCount = 0;
  List<int> emittedIndices = [];

  @override
  void clear() {
    clearCallCount++;
    super.clear();
  }

  @override
  SimulationHighlight emitFromSteps(
    List<SimulationStep> steps,
    int currentIndex,
  ) {
    emitFromStepsCallCount++;
    emittedIndices.add(currentIndex);
    return super.emitFromSteps(steps, currentIndex);
  }
}

class _SimulationCallback {
  _SimulationCallback({this.completeImmediately = true});

  final List<String> receivedInputs = [];
  final bool completeImmediately;
  final List<Completer<void>> _pending = [];

  Future<void> call(String input) {
    receivedInputs.add(input);
    if (completeImmediately) return Future.value();
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext() => _pending.removeAt(0).complete();
}

SimulationResult _traceResult(String state) => SimulationResult.success(
  inputString: 'a',
  steps: [
    SimulationStep(currentState: state, remainingInput: 'a', stepNumber: 0),
  ],
  executionTime: Duration.zero,
);

SimulationResult _emptyTraceResult() => SimulationResult.success(
  inputString: '',
  steps: const [],
  executionTime: Duration.zero,
);

Future<void> _pumpSimulationPanel(
  WidgetTester tester, {
  required _SimulationCallback onSimulate,
  SimulationResult? simulationResult,
  String? errorMessage,
  String? regexResult,
  _TestSimulationHighlightService? highlightService,
  double animationSpeed = 1.0,
  ValueChanged<double>? onAnimationSpeedChanged,
  ValueChanged<List<SimulationStep>>? onViewOnCanvas,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SimulationPanel(
          onSimulate: onSimulate.call,
          simulationResult: simulationResult,
          errorMessage: errorMessage,
          regexResult: regexResult,
          highlightService:
              highlightService ?? _TestSimulationHighlightService(),
          animationSpeed: animationSpeed,
          onAnimationSpeedChanged: onAnimationSpeedChanged,
          onViewOnCanvas: onViewOnCanvas,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

/// Scrolls the element found by [finder] into view and taps it.
Future<void> _ensureVisibleAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimulationPanel', () {
    testWidgets('View on Canvas hands the exact FSA trace to its callback', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: const [
          SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
          ),
          SimulationStep(currentState: 'q2', remainingInput: '', stepNumber: 2),
        ],
        executionTime: Duration.zero,
      );
      List<SimulationStep>? received;

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        onViewOnCanvas: (steps) => received = steps,
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await _ensureVisibleAndTap(tester, find.text('View on Canvas'));

      expect(received, orderedEquals(result.steps));
      expect(() => received!.add(result.steps.first), throwsUnsupportedError);
    });

    testWidgets('View on Canvas is absent without a callback', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: _traceResult('q0'),
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('View on Canvas'), findsNothing);
    });

    testWidgets('renders basic UI elements', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      expect(find.text('Simulation'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Input String'), findsOneWidget);
      expect(
        find.text('Leave blank for ε; whitespace is preserved'),
        findsOneWidget,
      );
      expect(find.text('Simulate'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Step-by-Step Mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('disables smart text features for the input field', (
      tester,
    ) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      final field = tester.widget<TextField>(find.byType(TextField));

      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.keyboardType, TextInputType.visiblePassword);
    });

    testWidgets('exposes semantic labels for primary simulation controls', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final handle = tester.ensureSemantics();
      var handleDisposed = false;
      addTearDown(() {
        if (!handleDisposed) {
          handle.dispose();
          handleDisposed = true;
        }
      });

      await _pumpSimulationPanel(tester, onSimulate: callback);

      expect(find.bySemanticsLabel('Simulation input string'), findsOneWidget);
      expect(find.bySemanticsLabel('Run simulation'), findsOneWidget);
      expect(find.bySemanticsLabel('Step-by-step mode'), findsOneWidget);

      handle.dispose();
      handleDisposed = true;
    });

    testWidgets('calls onSimulate when simulate button is pressed', (
      tester,
    ) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simulate'));
      await tester.pumpAndSettle();

      expect(callback.receivedInputs, contains('abc'));
    });

    testWidgets('preserves a literal space input', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);
      await tester.enterText(find.byType(TextField), ' ');
      await tester.tap(find.text('Simulate'));
      await tester.pump();

      expect(callback.receivedInputs, [' ']);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('calls onSimulate when Enter is pressed in text field', (
      tester,
    ) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(callback.receivedInputs, contains('test'));
    });

    testWidgets('submits empty input as epsilon', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.tap(find.text('Simulate'));
      await tester.pumpAndSettle();

      expect(callback.receivedInputs, ['']);
    });

    testWidgets('shows simulating state when simulating', (tester) async {
      final callback = _SimulationCallback(completeImmediately: false);

      await _pumpSimulationPanel(tester, onSimulate: callback);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simulate'));
      await tester.pump();

      expect(find.text('Simulating...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ElevatedButton.icon() creates a private subclass in Flutter 3.27+,
      // so use find.bySubtype<ButtonStyleButton>() instead of
      // find.widgetWithText(ElevatedButton, ...).
      final buttonFinder = find.ancestor(
        of: find.text('Simulating...'),
        matching: find.bySubtype<ButtonStyleButton>(),
      );
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<ButtonStyleButton>(buttonFinder);
      expect(button.onPressed, isNull);

      callback.completeNext();
      await tester.pump();
    });

    testWidgets('an older run cannot end a newer run loading state', (
      tester,
    ) async {
      final callback = _SimulationCallback(completeImmediately: false);

      await _pumpSimulationPanel(tester, onSimulate: callback);
      await tester.enterText(find.byType(TextField), 'A');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      callback.completeNext();
      await tester.pump();
      expect(find.text('Simulate'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'B');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Simulating...'), findsOneWidget);

      // This is past the old run A safety timeout. Run B still owns loading.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Simulating...'), findsOneWidget);
      expect(callback.receivedInputs, ['A', 'B']);

      callback.completeNext();
      await tester.pump();
      expect(find.text('Simulate'), findsOneWidget);
    });

    testWidgets('displays accepted simulation result', (tester) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'abc',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'abc',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      expect(find.text('Simulation Result'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      // Icons.check_circle appears in the result card header and also in the
      // path visualization for the final accepted state chip.
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
      // SimulationResultCard renders "Steps: " and the value in separate Text
      // widgets, so match them individually.
      expect(find.textContaining('Steps'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays rejected simulation result with error message', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.failure(
        inputString: 'xyz',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'xyz',
            stepNumber: 0,
          ),
        ],
        errorMessage: 'No valid transition found',
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      expect(find.text('Simulation Result'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
      // "Steps: " and the count are in separate Text widgets.
      expect(find.textContaining('Steps'), findsAtLeastNWidgets(1));
      // The error message is displayed without an "Error: " prefix.
      expect(find.textContaining('No valid transition found'), findsOneWidget);
    });

    testWidgets('displays a simulation workflow error without a result', (
      tester,
    ) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        errorMessage: 'The automaton must have an initial state.',
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(
        find.text('The automaton must have an initial state.'),
        findsOneWidget,
      );
    });

    testWidgets('displays regex result', (tester) async {
      final callback = _SimulationCallback();

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        regexResult: 'a(b|c)*d',
      );

      expect(find.text('Regex Result'), findsOneWidget);
      expect(find.text('Regular Expression'), findsOneWidget);
      expect(find.text('a(b|c)*d'), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('publishes step zero on mount while detailed mode is off', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
      final result = _traceResult('q0');

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(highlightService.emittedIndices, [0]);
      expect(highlightService.clearCallCount, 0);
    });

    testWidgets('publishes step zero when the result changes in detailed off', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
      final firstResult = _traceResult('q0');
      final secondResult = _traceResult('q1');

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: firstResult,
        highlightService: highlightService,
      );
      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: secondResult,
        highlightService: highlightService,
      );

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(highlightService.emittedIndices, [0, 0]);
      expect(highlightService.clearCallCount, 0);
    });

    testWidgets(
      'publishes step zero to a replacement service without clearing the old service',
      (tester) async {
        final callback = _SimulationCallback();
        final oldService = _TestSimulationHighlightService();
        final newService = _TestSimulationHighlightService();
        final result = _traceResult('q0');

        await _pumpSimulationPanel(
          tester,
          onSimulate: callback,
          simulationResult: result,
          highlightService: oldService,
        );
        await _pumpSimulationPanel(
          tester,
          onSimulate: callback,
          simulationResult: result,
          highlightService: newService,
        );

        expect(oldService.emittedIndices, [0]);
        expect(oldService.clearCallCount, 0);
        expect(newService.emittedIndices, [0]);
        expect(newService.clearCallCount, 0);
      },
    );

    testWidgets(
      'clears the current service when the result becomes null or empty',
      (tester) async {
        final callback = _SimulationCallback();
        final highlightService = _TestSimulationHighlightService();
        final result = _traceResult('q0');

        await _pumpSimulationPanel(
          tester,
          onSimulate: callback,
          simulationResult: result,
          highlightService: highlightService,
        );
        await _pumpSimulationPanel(
          tester,
          onSimulate: callback,
          highlightService: highlightService,
        );
        expect(highlightService.clearCallCount, 1);

        await _pumpSimulationPanel(
          tester,
          onSimulate: callback,
          simulationResult: _emptyTraceResult(),
          highlightService: highlightService,
        );

        expect(highlightService.clearCallCount, 2);
        expect(highlightService.emittedIndices, [0]);
      },
    );

    testWidgets('toggles step-by-step mode on', (tester) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(find.text('Step-by-Step Execution'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(highlightService.emitFromStepsCallCount, greaterThan(0));
    });

    testWidgets('toggles step-by-step mode off and resets highlight', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      final switchFinder = find.byType(Switch);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      await _ensureVisibleAndTap(tester, find.byTooltip('Next Step'));
      expect(highlightService.emittedIndices.last, 1);
      final clearCountBefore = highlightService.clearCallCount;

      await _ensureVisibleAndTap(tester, switchFinder);

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(find.text('Step-by-Step Execution'), findsNothing);
      expect(highlightService.clearCallCount, clearCountBefore);
      expect(highlightService.emittedIndices.last, 0);
    });

    testWidgets('navigates to next step in step-by-step mode', (tester) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);

      await _ensureVisibleAndTap(tester, find.byTooltip('Next Step'));

      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(highlightService.emittedIndices, contains(1));
    });

    testWidgets('navigates to previous step in step-by-step mode', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await _ensureVisibleAndTap(tester, find.byTooltip('Next Step'));

      expect(find.text('Step 2 of 3'), findsOneWidget);

      await _ensureVisibleAndTap(tester, find.byTooltip('Previous Step'));

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(highlightService.emittedIndices, contains(0));
    });

    testWidgets('resets to first step when reset button is pressed', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        highlightService: highlightService,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await _ensureVisibleAndTap(tester, find.byTooltip('Next Step'));

      expect(find.text('Step 2 of 2'), findsOneWidget);

      await _ensureVisibleAndTap(tester, find.byTooltip('Reset'));

      expect(find.text('Step 1 of 2'), findsOneWidget);
    });

    testWidgets('disables previous button at first step', (tester) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final prevFinder = find.widgetWithIcon(IconButton, Icons.skip_previous);
      await tester.ensureVisible(prevFinder);
      await tester.pumpAndSettle();

      final previousButton = tester.widget<IconButton>(prevFinder);
      expect(previousButton.onPressed, isNull);
    });

    testWidgets('disables next button at last step', (tester) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await _ensureVisibleAndTap(tester, find.byTooltip('Next Step'));

      expect(find.text('Step 2 of 2'), findsOneWidget);

      final nextFinder = find.widgetWithIcon(IconButton, Icons.skip_next);
      await tester.ensureVisible(nextFinder);
      await tester.pumpAndSettle();

      final nextButton = tester.widget<IconButton>(nextFinder);
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('displays step descriptions in step list', (tester) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNWidgets(3));
    });

    testWidgets('highlights current step in step list', (tester) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final avatars = tester.widgetList<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatars.length, 2);
    });

    testWidgets('shows play/pause button in step-by-step mode', (tester) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Play'), findsOneWidget);
      // Icons.play_arrow appears in the simulate button, the step-by-step
      // play button, and possibly in path visualization state chips.
      expect(find.byIcon(Icons.play_arrow), findsAtLeastNWidgets(2));
    });

    testWidgets('cancels stale playback timer after pause and replay', (
      tester,
    ) async {
      final callback = _SimulationCallback();
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
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        animationSpeed: 10,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Play'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 65));

      expect(find.text('Step 1 of 4'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 40));

      expect(find.text('Step 2 of 4'), findsOneWidget);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
    });

    testWidgets('manual navigation pauses playback and cancels pending timer', (
      tester,
    ) async {
      final callback = _SimulationCallback();
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
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
        animationSpeed: 10,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Play'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Next Step'));
      await tester.pump();
      await tester.tap(find.byTooltip('Next Step'));
      await tester.pump();

      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 110));

      expect(find.text('Step 2 of 4'), findsOneWidget);
    });

    testWidgets('does not clear an injected highlight service on dispose', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final highlightService = _TestSimulationHighlightService();

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        highlightService: highlightService,
      );

      final clearCountBefore = highlightService.clearCallCount;

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(highlightService.clearCallCount, clearCountBefore);
    });

    testWidgets('updates when simulation result changes', (tester) async {
      final callback = _SimulationCallback();
      final result1 = SimulationResult.success(
        inputString: 'a',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'a',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result1,
      );

      // SimulationResultCard renders "Steps: " and the count value in
      // separate Text widgets, so use textContaining.
      expect(find.textContaining('Steps'), findsAtLeastNWidgets(1));

      final result2 = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result2,
      );

      expect(find.textContaining('Steps'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays current step information in step-by-step mode', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: 'b',
            stepNumber: 1,
            usedTransition: 'a',
          ),
          const SimulationStep(
            currentState: 'q2',
            remainingInput: '',
            stepNumber: 2,
            usedTransition: 'b',
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Step 1'), findsOneWidget);
      // The description text appears in both _buildCurrentStep and
      // _buildStepList, so expect at least 1.
      expect(find.textContaining('Start at q0'), findsAtLeastNWidgets(1));

      await _ensureVisibleAndTap(tester, find.byTooltip('Next Step'));

      expect(find.text('Step 2'), findsOneWidget);
      expect(find.textContaining('Consumed: "a"'), findsOneWidget);
      expect(find.textContaining('Next state: q2'), findsOneWidget);
      expect(find.textContaining('Remaining input: "b"'), findsOneWidget);
    });

    testWidgets('shows final step with acceptance verdict', (tester) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: 'ab',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: 'ab',
            stepNumber: 0,
          ),
          const SimulationStep(
            currentState: 'q1',
            remainingInput: '',
            stepNumber: 1,
          ),
        ],
        executionTime: const Duration(milliseconds: 100),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await _ensureVisibleAndTap(tester, find.byTooltip('Next Step'));

      expect(find.text('Step 2'), findsOneWidget);
      expect(find.textContaining('input accepted'), findsAtLeastNWidgets(1));
    });

    testWidgets('handles epsilon transitions in step descriptions', (
      tester,
    ) async {
      final callback = _SimulationCallback();
      final result = SimulationResult.success(
        inputString: '',
        steps: [
          const SimulationStep(
            currentState: 'q0',
            remainingInput: '',
            stepNumber: 0,
          ),
        ],
        executionTime: const Duration(milliseconds: 50),
      );

      await _pumpSimulationPanel(
        tester,
        onSimulate: callback,
        simulationResult: result,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Epsilon appears in multiple places: the description text, the
      // remaining input text, and the step list description.
      expect(find.textContaining('\u03B5'), findsAtLeastNWidgets(1));
    });
  });
}

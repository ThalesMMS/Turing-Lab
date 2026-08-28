import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/presentation/transducers/transducer_batch_comparison_panel.dart';
import 'package:turing_lab/presentation/transducers/transducer_batch_comparison_strings.dart';

void main() {
  testWidgets('batch preserves JSON token vectors and typed outcomes', (
    tester,
  ) async {
    await _pumpPanel(tester, machine: _completeMachine());

    await tester.enterText(
      find.byKey(const ValueKey('transducer_batch_input')),
      '[]\n["a,b","🙂"]\n["missing"]',
    );
    await tester.tap(find.byKey(const ValueKey('run_transducer_batch')));
    await tester.pump();

    expect(find.text('Input: []'), findsOneWidget);
    expect(find.text('Input: ["a,b","🙂"]'), findsOneWidget);
    expect(find.text('Input: ["missing"]'), findsOneWidget);
    expect(find.text('Success'), findsNWidgets(2));
    expect(find.text('Invalid input'), findsOneWidget);
    expect(find.text('Output: ["idle"]'), findsOneWidget);
    expect(find.text('Output: ["idle","hit","idle"]'), findsOneWidget);
  });

  testWidgets('batch reports the exact malformed JSON line', (tester) async {
    await _pumpPanel(tester, machine: _completeMachine());

    await tester.enterText(
      find.byKey(const ValueKey('transducer_batch_input')),
      '["a,b"]\nnot-json',
    );
    await tester.tap(find.byKey(const ValueKey('run_transducer_batch')));
    await tester.pump();

    expect(find.text('Line 2 must be a JSON string array.'), findsOneWidget);
    expect(find.byType(TransducerBatchResultsView), findsNothing);
  });

  testWidgets('result view distinguishes undefined, bounded, and cancelled', (
    tester,
  ) async {
    final partialSimulator = DeterministicTransducerSimulator.moore(
      _partialMachine(),
    );
    final completeSimulator = DeterministicTransducerSimulator.moore(
      _completeMachine(),
    );
    final cancelledToken = TransducerCancellationToken()..cancel();
    final input = TransducerInputWord.fromValues(const ['a,b', '🙂']);
    final report = TransducerBatchReport([
      TransducerBatchItem(
        input: input,
        outcome: partialSimulator.run(input),
      ),
      TransducerBatchItem(
        input: input,
        outcome: completeSimulator.run(
          input,
          options: const TransducerSimulationOptions(maxSteps: 0),
        ),
      ),
      TransducerBatchItem(
        input: input,
        outcome: completeSimulator.run(
          input,
          options: TransducerSimulationOptions(
            cancellationToken: cancelledToken,
          ),
        ),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransducerBatchResultsView(
            report: report,
            strings: _strings,
          ),
        ),
      ),
    );

    expect(find.text('Undefined transition'), findsOneWidget);
    expect(find.text('Bounded'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('exact comparison reports equivalence and counterexample', (
    tester,
  ) async {
    var selected = _equivalentMachine();
    await _pumpPanel(
      tester,
      machine: _completeMachine(),
      comparisonMachine: selected,
      selector: () async => _differentMachine(),
      onSelected: (machine) => selected = machine!,
    );

    await tester.tap(find.byKey(const ValueKey('compare_transducers')));
    await tester.pump();
    expect(find.text('Exactly equivalent'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('select_transducer_comparison_machine')),
    );
    await tester.pump();
    expect(selected.name, 'Different');
    expect(find.text('Selected: Different'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('compare_transducers')));
    await tester.pump();
    expect(find.text('Different (exact)'), findsOneWidget);
    expect(find.text('Witness: []'), findsOneWidget);
    expect(find.text('Left output: ["idle"]'), findsOneWidget);
    expect(find.text('Right output: ["changed"]'), findsOneWidget);
  });

  testWidgets('machine selector failure stays in accessible panel state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpPanel(
      tester,
      machine: _completeMachine(),
      selector: () async => throw StateError('picker unavailable'),
    );

    await tester.tap(
      find.byKey(const ValueKey('select_transducer_comparison_machine')),
    );
    await tester.pump();

    final error = find.byKey(
      const ValueKey('transducer_comparison_machine_selection_error'),
    );
    expect(error, findsOneWidget);
    expect(find.text('Could not select a comparison machine.'), findsOneWidget);
    expect(
      tester
          .getSemantics(error)
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('bounded comparison stays explicitly inconclusive', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      machine: _completeMachine(),
      comparisonMachine: _equivalentMachine(),
    );

    await tester.tap(
      find.byKey(const ValueKey('transducer_comparison_mode')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bounded search').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transducer_comparison_bound')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('compare_transducers')));
    await tester.pump();

    expect(find.text('Inconclusive within bound'), findsOneWidget);
    expect(find.text('Exactly equivalent'), findsNothing);
  });

  testWidgets('320 px at 200 percent reflows with accessible native controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var disposed = false;
    addTearDown(() {
      if (!disposed) semantics.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;

    await _pumpPanel(
      tester,
      machine: _completeMachine(),
      comparisonMachine: _equivalentMachine(),
      textScaler: const TextScaler.linear(2),
    );
    await tester.enterText(
      find.byKey(const ValueKey('transducer_batch_input')),
      '["a,b"]',
    );
    await tester.tap(find.byKey(const ValueKey('run_transducer_batch')));
    await tester.pump();

    for (final key in const [
      'run_transducer_batch',
      'compare_transducers',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(
      tester
          .getSemantics(find.text('Batch'))
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
    expect(
      tester
          .getSemantics(find.byType(TransducerBatchResultsView))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    final compare = tester
        .getSemantics(find.byKey(const ValueKey('compare_transducers')))
        .getSemanticsData();
    expect(compare.flagsCollection.isButton, isTrue);
    expect(compare.flagsCollection.isEnabled, Tristate.isTrue);

    semantics.dispose();
    disposed = true;
  });

  testWidgets('Tab and Enter run a batch without pointer input',
      (tester) async {
    await _pumpPanel(tester, machine: _completeMachine());
    await tester.enterText(
      find.byKey(const ValueKey('transducer_batch_input')),
      '["a,b"]',
    );
    FocusManager.instance.primaryFocus?.unfocus();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.byType(TransducerBatchResultsView), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required MooreMachine machine,
  MooreMachine? comparisonMachine,
  TransducerComparisonMachineSelector<MooreMachine>? selector,
  ValueChanged<MooreMachine?>? onSelected,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: TransducerBatchComparisonPanel<MooreMachine>(
              machine: machine,
              simulatorFor: DeterministicTransducerSimulator.moore,
              strings: _strings,
              comparisonMachine: comparisonMachine,
              selectComparisonMachine: selector,
              onComparisonMachineChanged: onSelected,
            ),
          ),
        ),
      ),
    );

const _strings = TransducerBatchComparisonStrings(
  batchTitle: 'Batch',
  batchInputLabel: 'Input vectors',
  batchInputHelper: 'One JSON string array per line. Use [] for empty input.',
  runBatch: 'Run batch',
  batchEmpty: 'No batch cases.',
  batchSuccess: 'Success',
  batchUndefined: 'Undefined transition',
  batchInvalidMachine: 'Invalid machine',
  batchInvalidInput: 'Invalid input',
  batchCancelled: 'Cancelled',
  batchBounded: 'Bounded',
  comparisonTitle: 'Comparison',
  comparisonModeLabel: 'Comparison mode',
  exactMode: 'Exact',
  boundedMode: 'Bounded search',
  boundLabel: 'Maximum input length',
  chooseMachine: 'Choose machine',
  machineSelectionFailed: 'Could not select a comparison machine.',
  compare: 'Compare',
  noComparisonMachine: 'No comparison machine selected.',
  exactEquivalent: 'Exactly equivalent',
  exactDifferent: 'Different (exact)',
  boundedDifferent: 'Different (bounded witness)',
  boundedInconclusive: 'Inconclusive within bound',
  comparisonInvalid: 'Comparison inputs are invalid.',
  inputLabel: 'Input',
  outputLabel: 'Output',
  leftOutputLabel: 'Left output',
  rightOutputLabel: 'Right output',
  witnessLabel: 'Witness',
  invalidBatchLine: _invalidBatchLine,
  selectedMachine: _selectedMachine,
  exploredPairs: _exploredPairs,
);

String _invalidBatchLine(int line) => 'Line $line must be a JSON string array.';

String _selectedMachine(String name) => 'Selected: $name';

String _exploredPairs(int count) => 'Explored pairs: $count';

MooreMachine _completeMachine({
  String id = 'complete',
  String name = 'Complete',
  TransducerOutputWord initialOutput = TransducerOutputWord.empty,
}) =>
    MooreMachine(
      id: TransducerMachineId(id),
      name: name,
      revision: const TransducerRevision(0),
      inputAlphabet: {
        const TransducerInputSymbol('a,b'),
        const TransducerInputSymbol('🙂'),
      },
      outputAlphabet: {
        const TransducerOutputSymbol('idle'),
        const TransducerOutputSymbol('hit'),
        const TransducerOutputSymbol('changed'),
      },
      states: [
        MooreState(
          id: const TransducerStateId('q0'),
          label: 'Idle',
          position: const TransducerPoint(0, 0),
          output: initialOutput == TransducerOutputWord.empty
              ? TransducerOutputWord.fromValues(const ['idle'])
              : initialOutput,
          isInitial: true,
        ),
        MooreState(
          id: const TransducerStateId('q1'),
          label: 'Hit',
          position: const TransducerPoint(120, 0),
          output: TransducerOutputWord.fromValues(const ['hit']),
        ),
      ],
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('q0-comma'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a,b'),
        ),
        MooreTransition(
          id: TransducerTransitionId('q0-emoji'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('🙂'),
        ),
        MooreTransition(
          id: TransducerTransitionId('q1-comma'),
          from: TransducerStateId('q1'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a,b'),
        ),
        MooreTransition(
          id: TransducerTransitionId('q1-emoji'),
          from: TransducerStateId('q1'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('🙂'),
        ),
      ],
    );

MooreMachine _equivalentMachine() => _completeMachine(
      id: 'equivalent',
      name: 'Equivalent',
    );

MooreMachine _differentMachine() => _completeMachine(
      id: 'different',
      name: 'Different',
      initialOutput: TransducerOutputWord.fromValues(const ['changed']),
    );

MooreMachine _partialMachine() => _completeMachine(
      id: 'partial',
      name: 'Partial',
    ).copyWith(
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('q0-comma'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a,b'),
        ),
      ],
    );

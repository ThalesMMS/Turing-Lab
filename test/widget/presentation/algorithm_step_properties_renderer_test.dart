//
//  algorithm_step_properties_renderer_test.dart
//  Turing Lab
//
//  Verifies that the NFA→DFA, DFA minimization and Regex→NFA renderers read
//  the generic AlgorithmStep.properties contract produced by toProperties()
//  and keep the same didactic data visible, including after a JSON round
//  trip and for steps without optional fields.
//

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/dfa_minimization_step.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';
import 'package:turing_lab/core/models/state.dart' as automata;
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_renderer_registry.dart';
import 'package:turing_lab/presentation/widgets/algorithm_step_viewer.dart';
import 'package:vector_math/vector_math_64.dart';

automata.State _state(String id, {String? label}) {
  return automata.State(
    id: id,
    label: label ?? id,
    position: Vector2.zero(),
    isInitial: false,
    isAccepting: false,
  );
}

AlgorithmStep _roundTrip(AlgorithmStep step) {
  return AlgorithmStep.fromJson(
    jsonDecode(jsonEncode(step.toJson())) as Map<String, dynamic>,
  );
}

Future<void> _pump(
  WidgetTester tester,
  AlgorithmStep step, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: AlgorithmStepViewer(
            step: step,
            rendererRegistry: AlgorithmStepRendererRegistry.withDefaults(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('NFA to DFA renderer', () {
    final q0 = _state('q0');
    final q1 = _state('q1');
    final typed = NFAToDFAStep(
      baseStep: AlgorithmStep(
        id: 'nfa-1',
        stepNumber: 1,
        title: 'Process symbol',
        explanation: 'Process a from {q0}',
        type: AlgorithmType.nfaToDfa,
      ),
      stepType: NFAToDFAStepType.processSymbol,
      currentStateSet: {q0},
      processedSymbol: 'a',
      reachableStates: {q1},
      nextStateSet: {q0, q1},
      isNewState: true,
      dfaStateId: 'q1_q0_q1',
      dfaStateLabel: '{q0,q1}',
    );

    for (final (label, step) in [
      ('properties', typed.baseStep.copyWith(properties: typed.toProperties())),
      (
        'JSON round trip',
        _roundTrip(typed.baseStep.copyWith(properties: typed.toProperties())),
      ),
    ]) {
      testWidgets('renders every produced property from $label', (
        tester,
      ) async {
        await _pump(tester, step);

        expect(find.text('Typed Step Data'), findsOneWidget);
        expect(find.text('Operation'), findsOneWidget);
        expect(find.text('Process Symbol'), findsOneWidget);
        expect(find.text('Current states'), findsOneWidget);
        expect(find.text('q0'), findsOneWidget);
        expect(find.text('Processed symbol'), findsOneWidget);
        expect(find.text('a'), findsOneWidget);
        expect(find.text('Reachable states'), findsOneWidget);
        expect(find.text('q1'), findsOneWidget);
        expect(find.text('Next state set'), findsOneWidget);
        expect(find.text('q0, q1'), findsOneWidget);
        expect(find.text('New state'), findsOneWidget);
        expect(find.text('DFA state'), findsOneWidget);
        expect(find.text('{q0,q1}'), findsOneWidget);
        expect(find.text('q1_q0_q1'), findsNothing);
        // The raw property keys never leak into the typed section.
        expect(find.text('Current State Ids'), findsNothing);
        expect(find.text('Step Data'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('prefers state labels over identifiers', (tester) async {
      final labelled = NFAToDFAStep.initialEpsilonClosure(
        id: 'nfa-0',
        stepNumber: 0,
        initialState: _state('state-7', label: 'S'),
        epsilonClosure: {
          _state('state-7', label: 'S'),
          _state('state-8', label: 'T'),
        },
        containsAcceptingState: true,
      );
      await _pump(
        tester,
        labelled.baseStep.copyWith(properties: labelled.toProperties()),
      );

      expect(find.text('S'), findsOneWidget);
      expect(find.text('S, T'), findsOneWidget);
      expect(find.textContaining('state-7'), findsNothing);
    });

    testWidgets('renders a step without optional fields', (tester) async {
      final minimal = NFAToDFAStep(
        baseStep: AlgorithmStep(
          id: 'nfa-min',
          stepNumber: 0,
          title: 'Completion',
          explanation: 'Done',
          type: AlgorithmType.nfaToDfa,
        ),
        stepType: NFAToDFAStepType.completion,
        currentStateSet: const {},
      );
      await _pump(
        tester,
        minimal.baseStep.copyWith(properties: minimal.toProperties()),
      );

      expect(find.text('Typed Step Data'), findsOneWidget);
      expect(find.text('Operation'), findsOneWidget);
      expect(find.text('Completion'), findsWidgets);
      expect(find.text('Accepting state'), findsOneWidget);
      expect(find.text('New state'), findsOneWidget);
      expect(find.text('Current states'), findsNothing);
      expect(find.text('DFA state'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('DFA minimization renderer', () {
    final q0 = _state('q0');
    final q1 = _state('q1');
    final q2 = _state('q2');

    testWidgets('renders split data from properties and after JSON', (
      tester,
    ) async {
      final typed = DFAMinimizationStep.splitClass(
        id: 'dfa-1',
        stepNumber: 1,
        currentPartition: [
          {q0, q1, q2},
        ],
        splitSet: {q0, q1, q2},
        intersection: {q0},
        difference: {q1, q2},
        symbol: 'b',
        newPartition: [
          {q0},
          {q1, q2},
        ],
      );
      final step = _roundTrip(
        typed.baseStep.copyWith(properties: typed.toProperties()),
      );
      await _pump(tester, step);

      expect(find.text('Typed Step Data'), findsOneWidget);
      expect(find.text('Split Class'), findsOneWidget);
      expect(find.text('Partition size'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Distinguishing symbol'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('Split set'), findsOneWidget);
      expect(find.text('q0, q1, q2'), findsOneWidget);
      expect(find.text('Caused split'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Split Set Ids'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the equivalence class labels of a merged state', (
      tester,
    ) async {
      final typed = DFAMinimizationStep.createMinimizedState(
        id: 'dfa-2',
        stepNumber: 2,
        stateId: 'q1_min',
        equivalenceClass: {
          _state('q1', label: 'B'),
          _state('q2', label: 'C'),
        },
        isAccepting: false,
        isInitial: false,
      );
      await _pump(
        tester,
        typed.baseStep.copyWith(properties: typed.toProperties()),
      );

      expect(find.text('Equivalence class'), findsOneWidget);
      expect(find.text('B, C'), findsOneWidget);
      expect(find.text('q1_min'), findsNothing);
    });

    testWidgets('renders a step without optional fields', (tester) async {
      final minimal = DFAMinimizationStep(
        baseStep: AlgorithmStep(
          id: 'dfa-min',
          stepNumber: 0,
          title: 'Stable',
          explanation: 'Partition is stable',
          type: AlgorithmType.dfaMinimization,
        ),
        stepType: DFAMinimizationStepType.partitionStable,
        currentPartition: const [],
      );
      await _pump(
        tester,
        minimal.baseStep.copyWith(properties: minimal.toProperties()),
      );

      expect(find.text('Typed Step Data'), findsOneWidget);
      expect(find.text('Partition Stable'), findsOneWidget);
      expect(find.text('Partition size'), findsOneWidget);
      expect(find.text('Caused split'), findsOneWidget);
      expect(find.text('Processing set'), findsNothing);
      expect(find.text('Equivalence class'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Regex to NFA renderer', () {
    final q0 = _state('s0', label: 'q0');
    final q1 = _state('s1', label: 'q1');
    final typed = RegexToNFAStep.basicSymbol(
      id: 'regex-1',
      stepNumber: 1,
      symbol: 'a',
      position: 0,
      startState: q0,
      acceptState: q1,
      transition: FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      ),
      stackSize: 1,
    );

    testWidgets('renders labels, transition summaries and localized '
        'operation after JSON', (tester) async {
      final step = _roundTrip(
        typed.baseStep.copyWith(properties: typed.toProperties()),
      );
      await _pump(tester, step);

      expect(find.text('Typed Step Data'), findsOneWidget);
      expect(find.text('Operation'), findsOneWidget);
      expect(find.text('Basic symbol'), findsOneWidget);
      expect(find.text('Regex fragment'), findsOneWidget);
      expect(find.text('Regex position'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Created states'), findsOneWidget);
      expect(find.text('q0, q1'), findsOneWidget);
      expect(find.text('Created transitions'), findsOneWidget);
      expect(find.text('q0 → q1 (a)'), findsOneWidget);
      expect(find.text('Fragment start'), findsOneWidget);
      expect(find.text('Fragment accept'), findsOneWidget);
      expect(find.text('Stack size'), findsOneWidget);
      expect(find.text('Final NFA'), findsOneWidget);
      expect(find.text('t0'), findsNothing);
      expect(find.textContaining('s0'), findsNothing);
      expect(find.textContaining('regex.to-nfa'), findsNothing);
      expect(tester.takeException(), isNull);

      await _pump(tester, step, locale: const Locale('pt'));
      expect(find.text('Símbolo básico'), findsOneWidget);
      expect(find.text('Estados criados'), findsOneWidget);
      expect(find.text('Dados tipados da etapa'), findsOneWidget);
    });

    testWidgets('renders a step without optional fields', (tester) async {
      final minimal = RegexToNFAStep(
        baseStep: AlgorithmStep(
          id: 'regex-min',
          stepNumber: 0,
          title: 'Start',
          explanation: 'Begin',
          type: AlgorithmType.regexToNfa,
        ),
        stepType: RegexToNFAStepType.start,
      );
      await _pump(
        tester,
        minimal.baseStep.copyWith(properties: minimal.toProperties()),
      );

      expect(find.text('Typed Step Data'), findsOneWidget);
      expect(find.text('Operation'), findsOneWidget);
      expect(find.text('Final NFA'), findsOneWidget);
      expect(find.text('Created states'), findsNothing);
      expect(find.text('Fragment start'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('falls back to the generic property list for steps without '
      'recognized properties', (tester) async {
    final step = AlgorithmStep(
      id: 'foreign',
      stepNumber: 0,
      title: 'Foreign',
      explanation: 'No contract keys',
      type: AlgorithmType.nfaToDfa,
      properties: const {'custom': 'value'},
    );
    await _pump(tester, step);

    expect(find.text('Typed Step Data'), findsNothing);
    expect(find.text('Step Data'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });
}

// Mutable fixture collections verify constructor snapshot behavior.
// ignore_for_file: prefer_const_constructors

import 'dart:math';

import 'package:test/test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

void main() {
  group('typed structural analysis', () {
    test('diagnoses zero and multiple initial roles independently', () {
      final noInitial = TransducerAnalyzer.analyze(
        _base().copyWith(
          states:
              _base().states.map((state) => state.copyWith(isInitial: false)),
        ),
      );
      final twoInitial = TransducerAnalyzer.analyze(
        _base().copyWith(
          states: [
            ..._base().states,
            const MealyState(
              id: TransducerStateId('q1'),
              label: 'second',
              position: TransducerPoint(1, 0),
              isInitial: true,
            ),
          ],
        ),
      );

      expect(
        noInitial.diagnostics.map((diagnostic) => diagnostic.code),
        contains(TransducerDiagnosticCode.missingInitialState),
      );
      expect(
        twoInitial.diagnostics.map((diagnostic) => diagnostic.code),
        contains(TransducerDiagnosticCode.multipleInitialStates),
      );
    });

    test('diagnoses duplicate IDs, dangling endpoints, and alphabets', () {
      final machine = _base().copyWith(
        outputAlphabet: {TransducerOutputSymbol('x')},
        states: [
          MealyState(
            id: TransducerStateId('same'),
            label: 'first',
            position: TransducerPoint(0, 0),
            isInitial: true,
          ),
          MealyState(
            id: TransducerStateId('same'),
            label: 'duplicate',
            position: TransducerPoint(1, 1),
          ),
        ],
        transitions: [
          MealyTransition(
            id: TransducerTransitionId('duplicate'),
            from: TransducerStateId('same'),
            to: TransducerStateId('missing'),
            input: TransducerInputSymbol('?'),
            output: TransducerOutputWord([TransducerOutputSymbol('bad')]),
          ),
          MealyTransition(
            id: TransducerTransitionId('duplicate'),
            from: TransducerStateId('same'),
            to: TransducerStateId('same'),
            input: TransducerInputSymbol('a'),
            output: TransducerOutputWord.empty,
          ),
        ],
      );

      final codes = TransducerAnalyzer.analyze(machine)
          .diagnostics
          .map((diagnostic) => diagnostic.code)
          .toSet();
      expect(
        codes,
        containsAll({
          TransducerDiagnosticCode.duplicateStateId,
          TransducerDiagnosticCode.duplicateTransitionId,
          TransducerDiagnosticCode.danglingTargetState,
          TransducerDiagnosticCode.inputSymbolOutsideAlphabet,
          TransducerDiagnosticCode.outputSymbolOutsideAlphabet,
        }),
      );
    });

    test(
        'represents invalid identifiers, symbols, and revisions diagnostically',
        () {
      final report = TransducerAnalyzer.analyze(
        MealyMachine(
          id: const TransducerMachineId(''),
          name: 'invalid',
          revision: const TransducerRevision(-1),
          inputAlphabet: {TransducerInputSymbol('')},
          outputAlphabet: {TransducerOutputSymbol('')},
          states: [
            const MealyState(
              id: TransducerStateId(''),
              label: 'invalid',
              position: TransducerPoint(0, 0),
              isInitial: true,
            ),
          ],
          transitions: [],
        ),
      );

      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          TransducerDiagnosticCode.emptyIdentifier,
          TransducerDiagnosticCode.emptyInputSymbol,
          TransducerDiagnosticCode.emptyOutputSymbol,
          TransducerDiagnosticCode.negativeRevision,
        }),
      );
      expect(report.isStructurallyValid, isFalse);
    });

    test('distinguishes nondeterminism from incompleteness', () {
      final nondeterministic = _base().copyWith(
        transitions: [
          ..._base().transitions,
          MealyTransition(
            id: TransducerTransitionId('also-a'),
            from: TransducerStateId('q0'),
            to: TransducerStateId('q0'),
            input: TransducerInputSymbol('a'),
            output: TransducerOutputWord.empty,
          ),
        ],
      );
      final incomplete = _base().copyWith(
        inputAlphabet: {
          TransducerInputSymbol('a'),
          TransducerInputSymbol('b'),
        },
      );

      final nondeterministicReport =
          TransducerAnalyzer.analyze(nondeterministic);
      final incompleteReport = TransducerAnalyzer.analyze(incomplete);
      expect(nondeterministicReport.isDeterministic, isFalse);
      expect(nondeterministicReport.isStructurallyValid, isFalse);
      expect(incompleteReport.isDeterministic, isTrue);
      expect(incompleteReport.isComplete, isFalse);
      expect(incompleteReport.isStructurallyValid, isTrue);
    });

    test('lookup is deterministic and reports missing or ambiguous entries',
        () {
      final validIndex = TransducerTransitionIndex(_base());
      expect(
        validIndex.lookup(
          const TransducerStateId('q0'),
          const TransducerInputSymbol('a'),
        ),
        isA<TransducerTransitionFound>(),
      );
      expect(
        validIndex.lookup(
          const TransducerStateId('q0'),
          const TransducerInputSymbol('b'),
        ),
        isA<TransducerTransitionMissing>(),
      );

      final ambiguous = TransducerTransitionIndex(
        _base().copyWith(
          transitions: [
            ..._base().transitions,
            MealyTransition(
              id: TransducerTransitionId('duplicate-a'),
              from: TransducerStateId('q0'),
              to: TransducerStateId('q0'),
              input: TransducerInputSymbol('a'),
              output: TransducerOutputWord.empty,
            ),
          ],
        ),
      );
      expect(
        ambiguous.lookup(
          const TransducerStateId('q0'),
          const TransducerInputSymbol('a'),
        ),
        isA<TransducerTransitionAmbiguous>(),
      );
    });
  });

  group('equivalent-output comparison', () {
    test('exact product proves complete deterministic machines equivalent', () {
      final result = TransducerEquivalenceComparator.compare(
        DeterministicTransducerSimulator.mealy(_base()),
        DeterministicTransducerSimulator.mealy(_base().copyWith(name: 'copy')),
        semantics: const ExactTransducerComparison(),
      );

      expect(result.kind, TransducerComparisonKind.equivalent);
      expect(result.isExact, isTrue);
      expect(result.witness, isNull);
    });

    test('exact comparison includes Moore initial output and each prefix', () {
      final left = _moore(initialOutput: 'left', nextOutput: 'same');
      final rightInitial = _moore(initialOutput: 'right', nextOutput: 'same');
      final initialMismatch = TransducerEquivalenceComparator.compare(
        DeterministicTransducerSimulator.moore(left),
        DeterministicTransducerSimulator.moore(rightInitial),
        semantics: const ExactTransducerComparison(),
      );
      expect(initialMismatch.kind, TransducerComparisonKind.different);
      expect(initialMismatch.witness?.symbols, isEmpty);

      final prefixMismatch = TransducerEquivalenceComparator.compare(
        DeterministicTransducerSimulator.moore(left),
        DeterministicTransducerSimulator.moore(
          _moore(initialOutput: 'left', nextOutput: 'different'),
        ),
        semantics: const ExactTransducerComparison(),
      );
      expect(prefixMismatch.kind, TransducerComparisonKind.different);
      expect(prefixMismatch.witness?.values, ['a']);
    });

    test('exact proof refuses incomplete machines', () {
      final incomplete = _base().copyWith(transitions: []);
      final result = TransducerEquivalenceComparator.compare(
        DeterministicTransducerSimulator.mealy(incomplete),
        DeterministicTransducerSimulator.mealy(incomplete),
        semantics: const ExactTransducerComparison(),
      );

      expect(result.kind, TransducerComparisonKind.invalid);
      expect(result.isExact, isFalse);
    });

    test('bounded comparison never claims exact equivalence', () {
      final result = TransducerEquivalenceComparator.compare(
        DeterministicTransducerSimulator.mealy(_base()),
        DeterministicTransducerSimulator.mealy(_base()),
        semantics: const BoundedTransducerComparison(maxInputLength: 3),
      );

      expect(result.kind, TransducerComparisonKind.inconclusive);
      expect(result.isExact, isFalse);
      expect(result.bound, 3);
    });

    test('bounded comparison reports an explicit witness', () {
      final different = _base().copyWith(
        outputAlphabet: {
          TransducerOutputSymbol('x'),
          TransducerOutputSymbol('y'),
        },
        transitions: [
          MealyTransition(
            id: TransducerTransitionId('t0'),
            from: TransducerStateId('q0'),
            to: TransducerStateId('q0'),
            input: TransducerInputSymbol('a'),
            output: TransducerOutputWord([TransducerOutputSymbol('y')]),
          ),
        ],
      );
      final result = TransducerEquivalenceComparator.compare(
        DeterministicTransducerSimulator.mealy(_base()),
        DeterministicTransducerSimulator.mealy(different),
        semantics: const BoundedTransducerComparison(maxInputLength: 1),
      );

      expect(result.kind, TransducerComparisonKind.different);
      expect(result.witness?.values, ['a']);
      expect(result.leftOutput?.values, ['x']);
      expect(result.rightOutput?.values, ['y']);
    });
  });

  group('order independence', () {
    test('analysis, serialization, and output ignore insertion order', () {
      final random = Random(308);
      final baseline = _base();
      for (var iteration = 0; iteration < 40; iteration++) {
        final states = baseline.states.toList()..shuffle(random);
        final transitions = baseline.transitions.toList()..shuffle(random);
        final machine = baseline.copyWith(
          states: states,
          transitions: transitions,
        );
        expect(machine.toJson(), baseline.toJson());
        expect(
          TransducerAnalyzer.analyze(machine).diagnostics.map((d) => d.code),
          TransducerAnalyzer.analyze(baseline).diagnostics.map((d) => d.code),
        );
        expect(
          DeterministicTransducerSimulator.mealy(machine)
              .run(TransducerInputWord.fromValues(['a', 'a']))
              .output,
          DeterministicTransducerSimulator.mealy(baseline)
              .run(TransducerInputWord.fromValues(['a', 'a']))
              .output,
        );
      }
    });
  });
}

MealyMachine _base() => MealyMachine(
      id: const TransducerMachineId('base'),
      name: 'Base',
      revision: const TransducerRevision(1),
      inputAlphabet: {TransducerInputSymbol('a')},
      outputAlphabet: {TransducerOutputSymbol('x')},
      states: [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'zero',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: [
        MealyTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
          output: TransducerOutputWord([TransducerOutputSymbol('x')]),
        ),
      ],
    );

MooreMachine _moore({
  required String initialOutput,
  required String nextOutput,
}) =>
    MooreMachine(
      id: const TransducerMachineId('moore'),
      name: 'Moore',
      revision: const TransducerRevision(1),
      inputAlphabet: {TransducerInputSymbol('a')},
      outputAlphabet: {
        TransducerOutputSymbol(initialOutput),
        TransducerOutputSymbol(nextOutput),
      },
      states: [
        MooreState(
          id: const TransducerStateId('q0'),
          label: 'zero',
          position: const TransducerPoint(0, 0),
          isInitial: true,
          output: TransducerOutputWord([TransducerOutputSymbol(initialOutput)]),
        ),
        MooreState(
          id: const TransducerStateId('q1'),
          label: 'one',
          position: const TransducerPoint(1, 0),
          output: TransducerOutputWord([TransducerOutputSymbol(nextOutput)]),
        ),
      ],
      transitions: [
        MooreTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a'),
        ),
        MooreTransition(
          id: TransducerTransitionId('t1'),
          from: TransducerStateId('q1'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );

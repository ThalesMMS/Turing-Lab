import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/transducers/mealy_example_catalog.dart';
import 'package:turing_lab/data/transducers/moore_example_catalog.dart';

TransducerInputSymbol _i(String v) => TransducerInputSymbol(v);
TransducerOutputSymbol _o(String v) => TransducerOutputSymbol(v);
TransducerOutputWord _w(List<String> v) => TransducerOutputWord.fromValues(v);

MealyState _ms(String id, {bool initial = false}) => MealyState(
  id: TransducerStateId(id),
  label: id,
  position: const TransducerPoint(0, 0),
  isInitial: initial,
);

MooreState _mo(String id, List<String> output, {bool initial = false}) =>
    MooreState(
      id: TransducerStateId(id),
      label: id,
      position: const TransducerPoint(0, 0),
      isInitial: initial,
      output: _w(output),
    );

MealyTransition _mt(
  String id,
  String from,
  String to,
  String input,
  List<String> output,
) => MealyTransition(
  id: TransducerTransitionId(id),
  from: TransducerStateId(from),
  to: TransducerStateId(to),
  input: _i(input),
  output: _w(output),
);

MooreTransition _mot(String id, String from, String to, String input) =>
    MooreTransition(
      id: TransducerTransitionId(id),
      from: TransducerStateId(from),
      to: TransducerStateId(to),
      input: _i(input),
    );

MealyMachine _mealy({
  required List<MealyState> states,
  required List<MealyTransition> transitions,
  Set<String> inputs = const {'a', 'b'},
  Set<String> outputs = const {'0', '1'},
}) => MealyMachine(
  id: const TransducerMachineId('mealy'),
  name: 'Mealy',
  revision: const TransducerRevision(1),
  inputAlphabet: inputs.map(_i),
  outputAlphabet: outputs.map(_o),
  states: states,
  transitions: transitions,
);

MooreMachine _moore({
  required List<MooreState> states,
  required List<MooreTransition> transitions,
  Set<String> inputs = const {'a', 'b'},
  Set<String> outputs = const {'0', '1'},
}) => MooreMachine(
  id: const TransducerMachineId('moore'),
  name: 'Moore',
  revision: const TransducerRevision(1),
  inputAlphabet: inputs.map(_i),
  outputAlphabet: outputs.map(_o),
  states: states,
  transitions: transitions,
);

/// Compares outputs of both machines on every word up to length 4; a run
/// that stops early on either side must stop at the same prefix on both.
void _expectSameOutputs(
  DeterministicTransducerSimulator left,
  DeterministicTransducerSimulator right, {
  TransducerOutputWord? rightPrefix,
}) {
  final alphabet = left.machine.inputAlphabet.map((s) => s.value).toList()
    ..sort();
  var words = <List<String>>[[]];
  for (var length = 0; length <= 4; length++) {
    for (final word in words) {
      final input = TransducerInputWord.fromValues(word);
      final l = left.run(input);
      final r = right.run(input);
      expect(r.runtimeType, l.runtimeType, reason: 'word $word');
      expect(
        r.processedInputCount,
        l.processedInputCount,
        reason: 'word $word consumes the same prefix on both sides',
      );
      final expected = [...?rightPrefix?.values, ...l.output.values];
      expect(r.output.values, expected, reason: 'word $word');
    }
    words = [
      for (final word in words)
        for (final symbol in alphabet) [...word, symbol],
    ];
  }
}

void main() {
  group('Mealy to Moore', () {
    test('empty word emits nothing on both sides and copies split outputs', () {
      // q0 --a/1--> q1, q0 --b/0--> q1, q1 --a/0--> q0, q1 --b/1--> q0:
      // q1 receives outputs 1 and 0, so it needs two copies.
      final mealy = _mealy(
        states: [_ms('q0', initial: true), _ms('q1')],
        transitions: [
          _mt('t0', 'q0', 'q1', 'a', ['1']),
          _mt('t1', 'q0', 'q1', 'b', ['0']),
          _mt('t2', 'q1', 'q0', 'a', ['0']),
          _mt('t3', 'q1', 'q0', 'b', ['1']),
        ],
      );
      final report =
          TransducerConverter.mealyToMoore(mealy)
              as TransducerConversionReport<MooreMachine>;
      expect(report.outcome, TransducerConversionOutcome.exact);
      final moore = report.machine;
      final initial = moore.states.singleWhere((s) => s.isInitial);
      expect(initial.output, TransducerOutputWord.empty);
      expect(moore.states.map((s) => s.label).toSet(), {
        'q0',
        'q0/0',
        'q0/1',
        'q1/1',
        'q1/0',
      });
      expect(
        TransducerEquivalenceComparator.compare(
          DeterministicTransducerSimulator.mealy(mealy),
          DeterministicTransducerSimulator.moore(moore),
          semantics: const ExactTransducerComparison(),
        ).kind,
        TransducerComparisonKind.equivalent,
      );
      _expectSameOutputs(
        DeterministicTransducerSimulator.mealy(mealy),
        DeterministicTransducerSimulator.moore(moore),
      );
      expect(
        report.steps.where(
          (s) => s.kind == TransducerConversionStepKind.createStateCopy,
        ),
        hasLength(5),
      );
    });

    test(
      'keeps missing transitions undefined and prunes unreachable copies',
      () {
        final mealy = _mealy(
          states: [_ms('q0', initial: true), _ms('q1'), _ms('q2')],
          transitions: [
            _mt('t0', 'q0', 'q1', 'a', ['1']),
            _mt('t1', 'q1', 'q1', 'a', []),
            // q2 is never reached; its transition still creates the copy
            // (q1, 0), which nothing reaches and is pruned.
            _mt('t2', 'q2', 'q1', 'b', ['0']),
          ],
        );
        final report =
            TransducerConverter.mealyToMoore(mealy)
                as TransducerConversionReport<MooreMachine>;
        final moore = report.machine;
        expect(moore.states.map((s) => s.label), isNot(contains('q2')));
        expect(
          report.steps.any(
            (s) => s.kind == TransducerConversionStepKind.pruneUnreachableCopy,
          ),
          isTrue,
        );
        final left = DeterministicTransducerSimulator.mealy(mealy);
        final right = DeterministicTransducerSimulator.moore(moore);
        expect(
          left.run(TransducerInputWord.fromValues(['b'])).runtimeType,
          right.run(TransducerInputWord.fromValues(['b'])).runtimeType,
        );
        _expectSameOutputs(left, right);
        final bounded = TransducerEquivalenceComparator.compare(
          left,
          right,
          semantics: const BoundedTransducerComparison(maxInputLength: 4),
        );
        expect(bounded.kind, isNot(TransducerComparisonKind.different));
      },
    );

    test('rejects a nondeterministic Mealy machine with diagnostics', () {
      final mealy = _mealy(
        states: [_ms('q0', initial: true)],
        transitions: [
          _mt('t0', 'q0', 'q0', 'a', ['0']),
          _mt('t1', 'q0', 'q0', 'a', ['1']),
        ],
      );
      final result = TransducerConverter.mealyToMoore(mealy);
      expect(result, isA<TransducerConversionFailure<MooreMachine>>());
      expect(
        (result as TransducerConversionFailure<MooreMachine>).diagnostics.map(
          (d) => d.code,
        ),
        contains(TransducerDiagnosticCode.nondeterministicTransition),
      );
    });

    test('bundled Mealy examples convert exactly', () async {
      for (final example in await MealyExampleCatalog().loadExamples()) {
        final result = TransducerConverter.mealyToMoore(example.payload);
        expect(
          result,
          isA<TransducerConversionReport<MooreMachine>>(),
          reason: example.id,
        );
        final report = result as TransducerConversionReport<MooreMachine>;
        expect(report.outcome, TransducerConversionOutcome.exact);
        _expectSameOutputs(
          DeterministicTransducerSimulator.mealy(example.payload),
          DeterministicTransducerSimulator.moore(report.machine),
        );
      }
    });
  });

  group('Moore to Mealy', () {
    test('is exact when the initial output is empty', () {
      final moore = _moore(
        states: [
          _mo('p0', [], initial: true),
          _mo('p1', ['1']),
          _mo('p2', []),
        ],
        transitions: [
          _mot('t0', 'p0', 'p1', 'a'),
          _mot('t1', 'p0', 'p2', 'b'),
          _mot('t2', 'p1', 'p2', 'a'),
          _mot('t3', 'p1', 'p1', 'b'),
          _mot('t4', 'p2', 'p0', 'a'),
          _mot('t5', 'p2', 'p1', 'b'),
        ],
      );
      final report =
          TransducerConverter.mooreToMealy(moore)
              as TransducerConversionReport<MealyMachine>;
      expect(report.outcome, TransducerConversionOutcome.exact);
      expect(report.droppedInitialOutput, isNull);
      expect(report.machine.states, hasLength(3));
      expect(
        report.machine.transitions
            .singleWhere((t) => t.id.value == 't0')
            .output
            .values,
        ['1'],
      );
      expect(
        TransducerEquivalenceComparator.compare(
          DeterministicTransducerSimulator.moore(moore),
          DeterministicTransducerSimulator.mealy(report.machine),
          semantics: const ExactTransducerComparison(),
        ).kind,
        TransducerComparisonKind.equivalent,
      );
    });

    test('reports the dropped initial output as a convention difference', () {
      final moore = _moore(
        states: [
          _mo('p0', ['1'], initial: true),
          _mo('p1', ['0']),
        ],
        transitions: [
          _mot('t0', 'p0', 'p1', 'a'),
          _mot('t1', 'p0', 'p0', 'b'),
          _mot('t2', 'p1', 'p0', 'a'),
          _mot('t3', 'p1', 'p1', 'b'),
        ],
      );
      final report =
          TransducerConverter.mooreToMealy(moore)
              as TransducerConversionReport<MealyMachine>;
      expect(report.outcome, TransducerConversionOutcome.conventionDifference);
      expect(report.droppedInitialOutput?.values, ['1']);
      expect(
        report.steps.last.kind,
        TransducerConversionStepKind.dropInitialOutput,
      );
      final left = DeterministicTransducerSimulator.moore(moore);
      final right = DeterministicTransducerSimulator.mealy(report.machine);
      // The exact comparator names the empty word as the witness.
      final exact = TransducerEquivalenceComparator.compare(
        left,
        right,
        semantics: const ExactTransducerComparison(),
      );
      expect(exact.kind, TransducerComparisonKind.different);
      expect(exact.witness, TransducerInputWord.empty);
      // Modulo the initial output, every word agrees.
      _expectSameOutputs(right, left, rightPrefix: _w(['1']));
    });

    test('keeps missing transitions undefined', () {
      final moore = _moore(
        states: [
          _mo('p0', [], initial: true),
          _mo('p1', ['0']),
        ],
        transitions: [_mot('t0', 'p0', 'p1', 'a')],
      );
      final report =
          TransducerConverter.mooreToMealy(moore)
              as TransducerConversionReport<MealyMachine>;
      _expectSameOutputs(
        DeterministicTransducerSimulator.moore(moore),
        DeterministicTransducerSimulator.mealy(report.machine),
      );
    });

    test(
      'bundled Moore examples convert and agree after the initial output',
      () async {
        for (final example in await MooreExampleCatalog().loadExamples()) {
          final moore = example.payload;
          final result = TransducerConverter.mooreToMealy(moore);
          expect(
            result,
            isA<TransducerConversionReport<MealyMachine>>(),
            reason: example.id,
          );
          final report = result as TransducerConversionReport<MealyMachine>;
          _expectSameOutputs(
            DeterministicTransducerSimulator.mealy(report.machine),
            DeterministicTransducerSimulator.moore(moore),
            rightPrefix: report.droppedInitialOutput,
          );
        }
      },
    );
  });
}

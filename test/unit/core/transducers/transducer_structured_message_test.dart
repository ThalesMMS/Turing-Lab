import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

void main() {
  group('transducer structured execution messages', () {
    test('outcomes expose stable codes and typed arguments', () {
      final invalidMachine = TransducerInvalidMachine(
        input: TransducerInputWord.empty,
        analysis: TransducerAnalysisReport(
          diagnostics: const [
            TransducerDiagnostic(
              code: TransducerDiagnosticCode.missingInitialState,
              severity: TransducerDiagnosticSeverity.error,
              subject: 'machine',
            ),
          ],
          isDeterministic: false,
          isComplete: false,
        ),
      );
      final invalidSymbol = TransducerInvalidInput(
        input: TransducerInputWord.empty,
        invalidSymbol: const TransducerInputSymbol('β'),
      );
      final incomplete = TransducerIncomplete(
        input: TransducerInputWord.fromValues(const ['a']),
        output: TransducerOutputWord.empty,
        trace: const [],
        processedInputCount: 0,
        stateId: const TransducerStateId('q0'),
        nextInput: const TransducerInputSymbol('a'),
      );
      final bounded = TransducerBounded(
        input: TransducerInputWord.fromValues(const ['a', 'a']),
        output: TransducerOutputWord.fromValues(const ['x']),
        trace: const [],
        processedInputCount: 1,
        maxSteps: 1,
      );

      expect(
        invalidMachine.structuredMessage.stableCode,
        'transducer.execution.invalid-machine',
      );
      expect(
        invalidMachine.structuredMessage.arguments['diagnostic-count']?.kind,
        StructuredMessageArgumentKind.count,
      );
      expect(
        invalidSymbol.structuredMessage.stableCode,
        'transducer.execution.invalid-input-symbol',
      );
      expect(
        invalidSymbol.structuredMessage.arguments['symbol']?.role,
        'input-symbol',
      );
      expect(
        incomplete.structuredMessage.arguments['state']?.kind,
        StructuredMessageArgumentKind.identifier,
      );
      expect(incomplete.structuredMessage.arguments['state']?.role, 'state');
      expect(
        bounded.structuredMessage.arguments['limit']?.kind,
        StructuredMessageArgumentKind.bound,
      );
      expect(bounded.structuredMessage.arguments['processed']?.value, 1);
    });

    test('tokenization failures retain their source offset', () {
      final outcome = TransducerInvalidInput(
        input: TransducerInputWord.empty,
        invalidSymbol: null,
        tokenizationFailure: const TransducerTokenizationFailure(
          offset: 3,
          remaining: 'β',
          prefix: TransducerInputWord.empty,
        ),
      );

      expect(
        outcome.structuredMessage.stableCode,
        'transducer.execution.tokenization-failure',
      );
      expect(outcome.structuredMessage.arguments['offset']?.value, 3);
      expect(
        outcome.structuredMessage.arguments['offset']?.role,
        'input-offset',
      );
    });

    test('sync and async option validation use stable diagnostics', () async {
      final simulator = DeterministicTransducerSimulator.mealy(_machine());
      final matcher = throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'message',
          contains('transducer.validation.non-negative-required'),
        ),
      );

      expect(
        () => simulator.run(
          TransducerInputWord.empty,
          options: const TransducerSimulationOptions(maxSteps: -1),
        ),
        matcher,
      );
      await expectLater(
        simulator.runAsync(
          TransducerInputWord.empty,
          options: const TransducerSimulationOptions(maxSteps: -1),
        ),
        matcher,
      );
    });
  });

  group('transducer structured analysis messages', () {
    test('every diagnostic code exposes a complete typed payload', () {
      final diagnostics = <TransducerDiagnostic>[
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.missingInitialState,
          severity: TransducerDiagnosticSeverity.error,
          subject: 'machine',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.multipleInitialStates,
          severity: TransducerDiagnosticSeverity.error,
          subject: 'q0,q1',
          count: 2,
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.duplicateStateId,
          severity: TransducerDiagnosticSeverity.error,
          subject: 'q0',
          identifier: 'q0',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.duplicateTransitionId,
          severity: TransducerDiagnosticSeverity.error,
          subject: 't0',
          identifier: 't0',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.danglingSourceState,
          severity: TransducerDiagnosticSeverity.error,
          subject: 't1',
          identifier: 't1',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.danglingTargetState,
          severity: TransducerDiagnosticSeverity.error,
          subject: 't2',
          identifier: 't2',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.inputSymbolOutsideAlphabet,
          severity: TransducerDiagnosticSeverity.error,
          subject: 't3',
          identifier: 't3',
          symbol: 'β',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.outputSymbolOutsideAlphabet,
          severity: TransducerDiagnosticSeverity.error,
          subject: 't4',
          symbol: 'γ',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.nondeterministicTransition,
          severity: TransducerDiagnosticSeverity.error,
          subject: 'q0:a',
          identifier: 'q0',
          symbol: 'a',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.incompleteTransitionFunction,
          severity: TransducerDiagnosticSeverity.warning,
          subject: 'q1:b',
          identifier: 'q1',
          symbol: 'b',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.emptyIdentifier,
          severity: TransducerDiagnosticSeverity.error,
          subject: 'state',
          outcome: 'state',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.emptyInputSymbol,
          severity: TransducerDiagnosticSeverity.error,
          subject: 'alphabet',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.emptyOutputSymbol,
          severity: TransducerDiagnosticSeverity.error,
          subject: 'alphabet',
        ),
        const TransducerDiagnostic(
          code: TransducerDiagnosticCode.negativeRevision,
          severity: TransducerDiagnosticSeverity.error,
          subject: '-1',
          integer: -1,
        ),
      ];

      expect(
        diagnostics.map((diagnostic) => diagnostic.structuredMessage).toList(),
        hasLength(TransducerDiagnosticCode.values.length),
      );
      expect(diagnostics[6].structuredMessage.arguments['symbol']?.value, 'β');
      expect(diagnostics[7].structuredMessage.arguments['symbol']?.value, 'γ');
      expect(diagnostics[1].structuredMessage.arguments.keys, ['count']);
    });

    test('incomplete diagnostic metadata yields a resolver-safe payload', () {
      const diagnostic = TransducerDiagnostic(
        code: TransducerDiagnosticCode.duplicateTransitionId,
        severity: TransducerDiagnosticSeverity.error,
        subject: 'legacy-subject',
      );

      expect(
        diagnostic.structuredMessage.stableCode,
        'transducer.analysis.duplicate-transition-id',
      );
      expect(diagnostic.structuredMessage.arguments, isEmpty);
    });
  });
}

MealyMachine _machine() => MealyMachine(
  id: const TransducerMachineId('message-test'),
  name: 'Message test',
  revision: const TransducerRevision(0),
  inputAlphabet: const {},
  outputAlphabet: const {},
  states: const [
    MealyState(
      id: TransducerStateId('q0'),
      label: 'q0',
      position: TransducerPoint(0, 0),
      isInitial: true,
    ),
  ],
  transitions: const [],
);

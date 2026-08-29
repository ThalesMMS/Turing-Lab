import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/models/validation_diagnostic.dart';
import 'package:turing_lab/core/validators/input_validators.dart';
import 'package:turing_lab/core/validators/validation_issue_to_diagnostic.dart';
import 'package:turing_lab/core/validators/validation_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  late final StructuredMessage Function(
    String code,
    String name,
    StructuredMessageArgument argument,
  )
  messageWithArgument;
  late final void Function(Iterable<ValidationIssue> issues)
  expectDiagnosticRoundTrip;
  late final FSA Function() fsaWithIssues;
  late final PDA Function() pdaWithIssues;

  test('FSA validation issues retain legacy text and typed payloads', () {
    final issues = InputValidators.validateFSA(fsaWithIssues());
    final byCode = {for (final issue in issues) issue.code: issue};

    expect(
      byCode.keys,
      containsAll([
        'FSA_INVALID_INITIAL',
        'FSA_INVALID_ACCEPTING',
        'FSA_BAD_FROM',
        'FSA_BAD_TO',
        'FSA_BAD_SYMBOL',
        'FSA_NONDETERMINISTIC',
      ]),
    );
    expect(
      byCode['FSA_INVALID_INITIAL']!.message,
      'Initial state q1 is not in states set',
    );
    expect(
      byCode['FSA_INVALID_INITIAL']!.structuredMessage,
      messageWithArgument(
        'fsa-invalid-initial',
        'state',
        StructuredMessageArgument.identifier('q1', role: 'state-id'),
      ),
    );
    expect(
      byCode['FSA_NONDETERMINISTIC']!
          .structuredMessage!
          .arguments['count']!
          .kind,
      StructuredMessageArgumentKind.count,
    );
    expect(
      byCode['FSA_NONDETERMINISTIC']!
          .structuredMessage!
          .arguments['count']!
          .value,
      2,
    );

    expectDiagnosticRoundTrip(byCode.values);
  });

  test('PDA validation issues retain legacy text and typed payloads', () {
    final issues = InputValidators.validatePDA(pdaWithIssues());
    final byCode = {for (final issue in issues) issue.code: issue};

    expect(
      byCode.keys,
      containsAll([
        'PDA_INVALID_INITIAL',
        'PDA_INVALID_INITIAL_STACK',
        'PDA_INVALID_ACCEPTING',
        'PDA_BAD_FROM',
        'PDA_BAD_TO',
        'PDA_BAD_INPUT_SYMBOL',
        'PDA_BAD_STACK_SYMBOL',
        'PDA_BAD_PUSH_SYMBOL',
      ]),
    );
    expect(
      byCode['PDA_INVALID_INITIAL_STACK']!.message,
      'Initial stack symbol "X" is not in stack alphabet',
    );
    expect(
      byCode['PDA_INVALID_INITIAL_STACK']!
          .structuredMessage!
          .arguments['symbol']!
          .kind,
      StructuredMessageArgumentKind.symbol,
    );
    expect(
      byCode['PDA_INVALID_INITIAL_STACK']!
          .structuredMessage!
          .arguments['symbol']!
          .value,
      'X',
    );
    expect(
      byCode['PDA_BAD_PUSH_SYMBOL']!
          .structuredMessage!
          .arguments['symbol']!
          .role,
      'stack-symbol',
    );

    expectDiagnosticRoundTrip(byCode.values);
  });

  test('FSA and PDA legacy codes have stable validation identities', () {
    const expectedCodes = {
      'FSA_EMPTY': 'validation.fsa-empty',
      'FSA_NO_INITIAL': 'validation.fsa-no-initial',
      'FSA_INVALID_INITIAL': 'validation.fsa-invalid-initial',
      'FSA_EMPTY_ALPHABET': 'validation.fsa-empty-alphabet',
      'FSA_INVALID_ACCEPTING': 'validation.fsa-invalid-accepting',
      'FSA_BAD_FROM': 'validation.fsa-bad-from',
      'FSA_BAD_TO': 'validation.fsa-bad-to',
      'FSA_BAD_SYMBOL': 'validation.fsa-bad-symbol',
      'FSA_NONDETERMINISTIC': 'validation.fsa-nondeterministic',
      'PDA_EMPTY': 'validation.pda-empty',
      'PDA_NO_INITIAL': 'validation.pda-no-initial',
      'PDA_INVALID_INITIAL': 'validation.pda-invalid-initial',
      'PDA_NO_ACCEPTING': 'validation.pda-no-accepting',
      'PDA_EMPTY_INPUT_ALPHABET': 'validation.pda-empty-input-alphabet',
      'PDA_EMPTY_STACK_ALPHABET': 'validation.pda-empty-stack-alphabet',
      'PDA_INVALID_INITIAL_STACK': 'validation.pda-invalid-initial-stack',
      'PDA_INVALID_ACCEPTING': 'validation.pda-invalid-accepting',
      'PDA_BAD_FROM': 'validation.pda-bad-from',
      'PDA_BAD_TO': 'validation.pda-bad-to',
      'PDA_BAD_INPUT_SYMBOL': 'validation.pda-bad-input-symbol',
      'PDA_BAD_STACK_SYMBOL': 'validation.pda-bad-stack-symbol',
      'PDA_BAD_PUSH_SYMBOL': 'validation.pda-bad-push-symbol',
    };

    for (final entry in expectedCodes.entries) {
      final message = ValidationMessages.forCode(entry.key);
      expect(message.stableCode, entry.value);
      expect(message.category, StructuredMessageCategory.validation);
      expect(message.severity, StructuredMessageSeverity.error);
      expect(
        StructuredMessage.fromJson(Map<String, Object?>.from(message.toJson())),
        message,
      );
    }
  });

  messageWithArgument =
      (String code, String name, StructuredMessageArgument argument) =>
          StructuredMessage(
            namespace: 'validation',
            code: code,
            category: StructuredMessageCategory.validation,
            severity: StructuredMessageSeverity.error,
            arguments: {name: argument},
          );

  expectDiagnosticRoundTrip = (Iterable<ValidationIssue> issues) {
    for (final issue in issues) {
      final message = issue.structuredMessage;
      expect(message, isNotNull, reason: issue.code);

      final diagnostic = ValidationIssueToDiagnostic.fromIssue(issue);
      expect(diagnostic.structuredMessage, message, reason: issue.code);

      final restored = ValidationDiagnostic.fromJson(
        Map<String, dynamic>.from(diagnostic.toJson()),
      );
      expect(restored.structuredMessage, message, reason: issue.code);
      expect(restored.code, issue.code, reason: issue.code);
      expect(restored.summary, issue.message, reason: issue.code);
    }
  };

  fsaWithIssues = () {
    final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
    final q1 = State(id: 'q1', label: 'q1', position: Vector2(1, 0));
    final q2 = State(id: 'q2', label: 'q2', position: Vector2(2, 0));
    final q3 = State(id: 'q3', label: 'q3', position: Vector2(3, 0));
    final q4 = State(id: 'q4', label: 'q4', position: Vector2(4, 0));

    return FSA(
      id: 'fsa-validation',
      name: 'FSA validation',
      states: {q0},
      transitions: <Transition>{
        FSATransition(id: 'bad-from', fromState: q3, toState: q0, symbol: 'a'),
        FSATransition(id: 'bad-to', fromState: q0, toState: q4, symbol: 'a'),
        FSATransition(
          id: 'bad-symbol',
          fromState: q0,
          toState: q0,
          symbol: 'b',
        ),
        FSATransition(
          id: 'nondeterministic',
          fromState: q0,
          toState: q0,
          symbol: 'a',
        ),
      },
      alphabet: const {'a'},
      initialState: q1,
      acceptingStates: {q2},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 100, 100),
    );
  };

  pdaWithIssues = () {
    final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
    final q1 = State(id: 'q1', label: 'q1', position: Vector2(1, 0));
    final q2 = State(id: 'q2', label: 'q2', position: Vector2(2, 0));
    final q3 = State(id: 'q3', label: 'q3', position: Vector2(3, 0));
    final q4 = State(id: 'q4', label: 'q4', position: Vector2(4, 0));

    return PDA(
      id: 'pda-validation',
      name: 'PDA validation',
      states: {q0},
      transitions: <Transition>{
        PDATransition(
          id: 'bad-from',
          fromState: q3,
          toState: q0,
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          label: 'a,Z/Z',
        ),
        PDATransition(
          id: 'bad-to',
          fromState: q0,
          toState: q4,
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          label: 'a,Z/Z',
        ),
        PDATransition(
          id: 'bad-input',
          fromState: q0,
          toState: q0,
          inputSymbol: 'b',
          popSymbol: 'Z',
          pushSymbol: 'Z',
          label: 'b,Z/Z',
        ),
        PDATransition(
          id: 'bad-pop',
          fromState: q0,
          toState: q0,
          inputSymbol: 'a',
          popSymbol: 'X',
          pushSymbol: 'Z',
          label: 'a,X/Z',
        ),
        PDATransition(
          id: 'bad-push',
          fromState: q0,
          toState: q0,
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'X',
          label: 'a,Z/X',
        ),
      },
      alphabet: const {'a'},
      initialState: q1,
      acceptingStates: {q2},
      stackAlphabet: const {'Z'},
      initialStackSymbol: 'X',
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 100, 100),
    );
  };
}

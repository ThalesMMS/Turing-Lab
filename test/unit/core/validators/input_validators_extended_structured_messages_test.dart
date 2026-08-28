import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/validators/input_validators.dart';
import 'package:turing_lab/core/validators/validation_messages.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('grammar validation issues carry typed messages in both locales', () {
    final grammar = Grammar(
      id: 'invalid-grammar',
      name: 'Invalid grammar',
      terminals: const {'a'},
      nonterminals: const {'S'},
      startSymbol: 'A',
      productions: {
        const Production(id: 'empty', leftSide: [], rightSide: []),
        const Production(id: 'bad', leftSide: ['A'], rightSide: ['x']),
      },
      type: GrammarType.contextFree,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
    );

    final issues = InputValidators.validateGrammar(grammar);
    final codes = issues.map((issue) => issue.code).toSet();

    expect(
      codes,
      containsAll([
        'CFG_BAD_START',
        'CFG_EMPTY_LEFT',
        'CFG_EMPTY_RIGHT',
        'CFG_BAD_LEFT',
        'CFG_BAD_SYMBOL',
      ]),
    );
    for (final issue in issues) {
      final message = issue.structuredMessage;
      expect(message, isNotNull, reason: issue.code);
      expect(message!.namespace, 'validation');
      expect(message.stableCode, startsWith('validation.'));
      expect(
        StructuredMessage.fromJson(Map<String, Object?>.from(message.toJson())),
        message,
      );
    }

    final badLeft = issues.firstWhere((issue) => issue.code == 'CFG_BAD_LEFT');
    expect(
      en.resolveStructuredMessage(badLeft.structuredMessage!),
      contains('not a nonterminal'),
    );
    expect(
      pt.resolveStructuredMessage(badLeft.structuredMessage!),
      contains('não é um não terminal'),
    );
  });

  test('TM validation issues preserve symbols and state identifiers', () {
    final q0 = State(id: 'q0', label: 'q0', position: Vector2.zero());
    final q1 = State(id: 'q1', label: 'q1', position: Vector2(1, 0));
    final q2 = State(id: 'q2', label: 'q2', position: Vector2(2, 0));
    final tm = TM(
      id: 'invalid-tm',
      name: 'Invalid TM',
      states: {q0},
      transitions: <Transition>{
        TMTransition(
          id: 'bad-transition',
          fromState: q1,
          toState: q2,
          readSymbol: 'x',
          writeSymbol: 'y',
          direction: TapeDirection.left,
          label: 'x/y,L',
        ),
      },
      alphabet: const {'a'},
      initialState: q1,
      acceptingStates: {q2},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const Rectangle(0, 0, 100, 100),
      tapeAlphabet: const {'B'},
      blankSymbol: 'Z',
    );

    final issues = InputValidators.validateTM(tm);
    final byCode = {for (final issue in issues) issue.code: issue};
    expect(
      byCode.keys,
      containsAll([
        'TM_INVALID_INITIAL',
        'TM_BLANK_NOT_IN_TAPE',
        'TM_INPUT_NOT_IN_TAPE',
        'TM_INVALID_ACCEPTING',
        'TM_BAD_FROM',
        'TM_BAD_TO',
        'TM_BAD_READ_SYMBOL',
        'TM_BAD_WRITE_SYMBOL',
      ]),
    );

    for (final issue in issues) {
      expect(issue.structuredMessage, isNotNull, reason: issue.code);
      expect(issue.structuredMessage!.stableCode, startsWith('validation.tm-'));
    }
    expect(
      en.resolveStructuredMessage(
        byCode['TM_BAD_READ_SYMBOL']!.structuredMessage!,
      ),
      contains('symbol x'),
    );
    expect(
      pt.resolveStructuredMessage(
        byCode['TM_BAD_READ_SYMBOL']!.structuredMessage!,
      ),
      contains('símbolo x'),
    );
  });

  test('input validation exposes a typed position and localized text', () {
    final issue = InputValidators.validateInputString('ab', const {'a'}).single;

    expect(issue.code, 'INPUT_INVALID_SYMBOL');
    expect(issue.message, 'Input contains invalid symbol "b" at position 1');
    expect(
      issue.structuredMessage?.stableCode,
      'validation.input-invalid-symbol',
    );
    expect(
      issue.structuredMessage!.arguments['position']!.kind,
      StructuredMessageArgumentKind.positionIndex,
    );
    expect(
      en.resolveStructuredMessage(issue.structuredMessage!),
      'Input contains invalid symbol b at position 1.',
    );
    expect(
      pt.resolveStructuredMessage(issue.structuredMessage!),
      'A entrada contém o símbolo inválido b na posição 1.',
    );
  });

  test('all extended validation codes have stable identities', () {
    const codes = [
      'TM_EMPTY',
      'TM_NO_INITIAL',
      'TM_INVALID_INITIAL',
      'TM_NO_ACCEPTING',
      'TM_EMPTY_INPUT_ALPHABET',
      'TM_EMPTY_TAPE_ALPHABET',
      'TM_EMPTY_BLANK',
      'TM_BLANK_NOT_IN_TAPE',
      'TM_INPUT_NOT_IN_TAPE',
      'TM_INVALID_ACCEPTING',
      'TM_BAD_FROM',
      'TM_BAD_TO',
      'TM_BAD_READ_SYMBOL',
      'TM_BAD_WRITE_SYMBOL',
      'TM_BAD_MOVE',
      'CFG_EMPTY',
      'CFG_NO_NONTERMINALS',
      'CFG_NO_TERMINALS',
      'CFG_EMPTY_START',
      'CFG_BAD_START',
      'CFG_EMPTY_LEFT',
      'CFG_BAD_LEFT',
      'CFG_EMPTY_RIGHT',
      'CFG_BAD_SYMBOL',
      'INPUT_EMPTY',
      'INPUT_INVALID_SYMBOL',
    ];

    for (final code in codes) {
      final message = ValidationMessages.forCode(code);
      expect(message.namespace, 'validation');
      expect(message.category, StructuredMessageCategory.validation);
      expect(message.severity, StructuredMessageSeverity.error);
    }
  });
}

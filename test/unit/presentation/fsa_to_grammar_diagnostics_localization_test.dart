import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa_to_grammar_converter.dart';
import 'package:turing_lab/core/algorithms/fsa_to_grammar_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves FSA-to-grammar diagnostics in both locales', () {
    expect(
      en.resolveStructuredMessage(FsaToGrammarMessages.emptyAutomaton()),
      en.fsaToGrammarEmptyAutomaton,
    );
    expect(
      pt.resolveStructuredMessage(FsaToGrammarMessages.missingInitialState()),
      pt.fsaToGrammarMissingInitialState,
    );
    expect(
      en.resolveStructuredMessage(
        FsaToGrammarMessages.initialStateOutsideSet(),
      ),
      en.fsaToGrammarInitialStateOutsideSet,
    );
    expect(
      pt.resolveStructuredMessage(
        FsaToGrammarMessages.acceptingStateOutsideSet(),
      ),
      pt.fsaToGrammarAcceptingStateOutsideSet,
    );
  });

  test('converter preserves a structured empty-input diagnostic', () {
    final result = FSAToGrammarConverter.tryConvert(
      FSA.empty(id: 'empty', name: 'Empty'),
    );

    expect(result.isFailure, isTrue);
    expect(result.error, 'Automaton must contain at least one state.');
    expect(result.structuredError, FsaToGrammarMessages.emptyAutomaton());
  });

  test('converter preserves structured state-set diagnostics', () {
    final inside = State(
      id: 'inside',
      label: 'inside',
      position: Vector2.zero(),
    );
    final outside = State(
      id: 'outside',
      label: 'outside',
      position: Vector2(40, 0),
    );

    FSA make({State? initial, Set<State> accepting = const {}}) => FSA(
      id: 'invalid',
      name: 'Invalid',
      states: {inside},
      transitions: const {},
      alphabet: const {},
      initialState: initial,
      acceptingStates: accepting,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 100, 100),
    );

    final initialResult = FSAToGrammarConverter.tryConvert(
      make(initial: outside),
    );
    expect(
      initialResult.structuredError,
      FsaToGrammarMessages.initialStateOutsideSet(),
    );

    final acceptingResult = FSAToGrammarConverter.tryConvert(
      make(initial: inside, accepting: {outside}),
    );
    expect(
      acceptingResult.structuredError,
      FsaToGrammarMessages.acceptingStateOutsideSet(),
    );
    expect(
      pt.resolveStructuredMessage(acceptingResult.structuredError!),
      pt.fsaToGrammarAcceptingStateOutsideSet,
    );
  });

  test('unknown FSA-to-grammar codes use the stable fallback', () {
    expect(
      en.resolveStructuredMessage(
        StructuredMessage(
          namespace: 'automaton.fsa-to-grammar',
          code: 'future',
          category: StructuredMessageCategory.analysis,
          severity: StructuredMessageSeverity.error,
        ),
      ),
      contains('automaton.fsa-to-grammar.future'),
    );
  });
}

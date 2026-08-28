import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fa_to_regex_converter.dart';
import 'package:turing_lab/core/algorithms/fa_to_regex_messages.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves FA-to-regex diagnostics in both locales', () {
    expect(
      en.resolveStructuredMessage(FaToRegexMessages.emptyAutomaton()),
      en.faToRegexEmptyAutomaton,
    );
    expect(
      pt.resolveStructuredMessage(FaToRegexMessages.missingInitialState()),
      pt.faToRegexMissingInitialState,
    );
    expect(
      en.resolveStructuredMessage(FaToRegexMessages.internalFailure()),
      en.faToRegexInternalFailure,
    );
  });

  test('converter returns a structured empty-input diagnostic', () {
    final result = FAToRegexConverter.convert(
      FSA.empty(id: 'empty', name: 'Empty'),
    );

    expect(result.isFailure, isTrue);
    expect(result.error, 'automaton.fa-to-regex.empty-automaton');
    expect(result.structuredError, FaToRegexMessages.emptyAutomaton());
    expect(
      pt.resolveStructuredMessage(result.structuredError!),
      'O autômato finito deve conter pelo menos um estado.',
    );
  });

  test('converter returns a structured missing-initial-state diagnostic', () {
    final state = State(id: 'q0', label: 'q0', position: Vector2(40, 100));
    final input = FSA(
      id: 'missing-initial',
      name: 'Missing initial',
      states: {state},
      transitions: const {},
      alphabet: const {},
      initialState: null,
      acceptingStates: const {},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 800, 600),
    );

    final result = FAToRegexConverter.convertWithSteps(input);

    expect(result.isFailure, isTrue);
    expect(result.error, 'automaton.fa-to-regex.missing-initial-state');
    expect(result.structuredError, FaToRegexMessages.missingInitialState());
  });

  test('malformed or future codes use the stable fallback', () {
    expect(
      en.resolveStructuredMessage(
        StructuredMessage(
          namespace: 'automaton.fa-to-regex',
          code: 'future',
          category: StructuredMessageCategory.analysis,
          severity: StructuredMessageSeverity.error,
        ),
      ),
      contains('automaton.fa-to-regex.future'),
    );
  });
}

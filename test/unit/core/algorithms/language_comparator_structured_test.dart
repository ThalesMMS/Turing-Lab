import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/language_comparator.dart';
import 'package:turing_lab/core/algorithms/language_comparison_step_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('structured trace stays aligned with the legacy equivalent trace', () {
    final result = LanguageComparator.compareLanguages(
      _dfa(id: 'rejects-a', name: 'Rejects A'),
      _dfa(id: 'rejects-b', name: 'Rejects B'),
    );

    expect(result.isSuccess, isTrue);
    final comparison = result.data!;
    expect(comparison, isA<EquivalenceComparisonResult>());
    expect(comparison.isEquivalent, isTrue);
    expect(comparison.structuredSteps.length, comparison.steps.length);
    expect(comparison.steps.first['type'], 'validation');
    expect(comparison.steps.first['description'], 'Validating input automata');
    expect(comparison.steps.last['type'], 'result');
    expect(
      comparison.steps.last['description'],
      'Automata are equivalent - same language recognized',
    );

    final expectedCodes = <String, String>{
      'validation': 'language.comparison.trace.validation',
      'alphabet_normalization':
          'language.comparison.trace.alphabet-normalization',
      'dfa_completion': 'language.comparison.trace.dfa-completion',
      'product_construction_start':
          'language.comparison.trace.product-construction-start',
      'product_state_created':
          'language.comparison.trace.product-state-created',
      'product_transition_created':
          'language.comparison.trace.product-transition-created',
      'product_construction_complete':
          'language.comparison.trace.product-construction-complete',
      'bfs_search_start': 'language.comparison.trace.bfs-search-start',
      'bfs_initial_check': 'language.comparison.trace.bfs-initial-check',
      'bfs_explore_pair': 'language.comparison.trace.bfs-explore-pair',
      'bfs_complete': 'language.comparison.trace.bfs-complete',
      'result': 'language.comparison.trace.result',
    };
    expect(
      comparison.structuredSteps.map((message) => message.stableCode),
      orderedEquals(
        comparison.steps.map(
          (step) => expectedCodes[step['type']] ?? 'missing-code',
        ),
      ),
    );

    final completion = comparison.structuredSteps.firstWhere(
      (message) => message.code == 'dfa-completion',
    );
    expect(
      completion.arguments['automaton'],
      StructuredMessageArgument.identifier('A', role: 'automaton-side'),
    );

    final transition = comparison.structuredSteps.firstWhere(
      (message) => message.code == 'product-transition-created',
    );
    expect(
      transition.arguments['symbol']?.kind,
      StructuredMessageArgumentKind.symbol,
    );
    expect(transition.arguments['symbol']?.role, 'input-symbol');
    expect(transition.arguments['symbol']?.value, 'a');

    final initialCheck = comparison.structuredSteps.firstWhere(
      (message) => message.code == 'bfs-initial-check',
    );
    expect(
      initialCheck.arguments['different'],
      StructuredMessageArgument.boolean(false, role: 'acceptance-difference'),
    );

    final resultMessage = comparison.structuredSteps.last;
    expect(resultMessage.code, 'result');
    expect(resultMessage.arguments['equivalent']?.value, isTrue);

    for (final message in comparison.structuredSteps) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }

    // EquivalenceComparisonResult has no toJson method. Keeping the original
    // map trace untouched preserves its existing JSON encoding contract.
    expect(jsonDecode(jsonEncode(comparison.steps)), isA<List<dynamic>>());
  });

  test('non-equivalent result carries the distinguishing step payload', () {
    final result = LanguageComparator.compareLanguages(
      _dfa(id: 'accepts-a', name: 'Accepts A', acceptsA: true),
      _dfa(id: 'rejects-b', name: 'Rejects B'),
    );

    expect(result.isSuccess, isTrue);
    final comparison = result.data!;
    expect(comparison.isEquivalent, isFalse);
    expect(comparison.distinguishingString, 'a');
    expect(
      comparison.structuredSteps.map((message) => message.code),
      contains('bfs-distinguishing-found'),
    );
    final distinguishing = comparison.structuredSteps.firstWhere(
      (message) => message.code == 'bfs-distinguishing-found',
    );
    expect(distinguishing.arguments['value']?.value, 'a');
    expect(distinguishing.arguments['value']?.role, 'distinguishing-string');
    expect(comparison.structuredSteps.last.code, 'result');
    expect(
      comparison.structuredSteps.last.arguments['equivalent']?.value,
      isFalse,
    );
  });

  test('NFA conversion steps carry the automaton side argument', () {
    final result = LanguageComparator.compareLanguages(
      _nfa(),
      _dfa(id: 'all-strings', name: 'All strings', acceptsA: true),
    );

    expect(result.isSuccess, isTrue);
    final comparison = result.data!;
    final conversionMessages = comparison.structuredSteps
        .where((message) => message.code == 'nfa-to-dfa')
        .toList();
    expect(conversionMessages, hasLength(1));
    expect(conversionMessages.single.arguments['automaton']?.value, 'A');
    expect(
      conversionMessages.single.arguments['automaton']?.role,
      'automaton-side',
    );
  });

  test('companion has stable fallbacks for legacy and future trace types', () {
    expect(
      LanguageComparisonStepMessages.fromLegacyStep({
        'type': 'initialization',
      }).stableCode,
      'language.comparison.trace.initialization',
    );
    expect(
      LanguageComparisonStepMessages.fromLegacyStep({'type': 'error'}).code,
      'error',
    );
    final unknown = LanguageComparisonStepMessages.fromLegacyStep({
      'type': 'future_step',
    });
    expect(unknown.stableCode, 'language.comparison.trace.unknown');
    expect(unknown.arguments['type']?.value, 'future_step');
  });
}

FSA _dfa({required String id, required String name, bool acceptsA = false}) {
  final q0 = State(
    id: '${id}_q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: '${id}_q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: acceptsA,
  );
  return FSA(
    id: id,
    name: name,
    states: {q0, q1},
    transitions: {
      FSATransition.deterministic(
        id: '${id}_t0',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: '${id}_t1',
        fromState: q1,
        toState: q1,
        symbol: 'a',
      ),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: acceptsA ? {q1} : const {},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 100, 100),
  );
}

FSA _nfa() {
  final q0 = State(
    id: 'nfa_q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'nfa_q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return FSA(
    id: 'nfa',
    name: 'NFA',
    states: {q0, q1},
    transitions: {
      FSATransition.epsilon(id: 'nfa_epsilon', fromState: q0, toState: q1),
      FSATransition.deterministic(
        id: 'nfa_a',
        fromState: q1,
        toState: q1,
        symbol: 'a',
      ),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 100, 100),
  );
}

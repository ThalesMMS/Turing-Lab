//
//  responsive_fixtures.dart
//  Turing Lab
//
//  Populated machines and documents the responsive gate loads before it
//  asserts, so every workspace renders a non-empty canvas, a real production
//  list and a validated expression instead of an empty placeholder.
//
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';

final DateTime _fixtureTimestamp = DateTime.utc(2026, 1, 1);

/// Regular expression loaded into the regex workspace.
const String kResponsiveRegexFixture = '(a|b)*abb';

/// Test string matched against [kResponsiveRegexFixture].
const String kResponsiveRegexTestString = 'aabb';

/// Three-state DFA accepting strings that end in `ab`.
FSA buildResponsiveFsaFixture() {
  final q0 = automaton_state.State(
    id: 'fsa-q0',
    label: 'q0',
    position: Vector2(140, 200),
    isInitial: true,
  );
  final q1 = automaton_state.State(
    id: 'fsa-q1',
    label: 'q1',
    position: Vector2(380, 200),
  );
  final q2 = automaton_state.State(
    id: 'fsa-q2',
    label: 'q2',
    position: Vector2(620, 200),
    isAccepting: true,
  );

  return FSA(
    id: 'responsive-fsa',
    name: 'Ends with ab',
    states: {q0, q1, q2},
    transitions: {
      FSATransition.deterministic(
        id: 'fsa-t0',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 'fsa-t1',
        fromState: q1,
        toState: q2,
        symbol: 'b',
      ),
      FSATransition.deterministic(
        id: 'fsa-t2',
        fromState: q1,
        toState: q1,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 'fsa-t3',
        fromState: q2,
        toState: q1,
        symbol: 'a',
      ),
    },
    alphabet: const {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: _fixtureTimestamp,
    modified: _fixtureTimestamp,
    bounds: const math.Rectangle(0, 0, 800, 480),
  );
}

/// Pushdown automaton for `a^n b^n`.
PDA buildResponsivePdaFixture() {
  final q0 = automaton_state.State(
    id: 'pda-q0',
    label: 'q0',
    position: Vector2(140, 200),
    isInitial: true,
  );
  final q1 = automaton_state.State(
    id: 'pda-q1',
    label: 'q1',
    position: Vector2(400, 200),
  );
  final q2 = automaton_state.State(
    id: 'pda-q2',
    label: 'q2',
    position: Vector2(660, 200),
    isAccepting: true,
  );

  final transitions = <Transition>{
    PDATransition(
      id: 'pda-t0',
      fromState: q0,
      toState: q0,
      label: 'a, Z/AZ',
      inputSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'AZ',
    ),
    PDATransition(
      id: 'pda-t1',
      fromState: q0,
      toState: q1,
      label: 'b, A/λ',
      inputSymbol: 'b',
      popSymbol: 'A',
      pushSymbol: '',
    ),
    PDATransition(
      id: 'pda-t2',
      fromState: q1,
      toState: q2,
      label: 'λ, Z/Z',
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: 'Z',
    ),
  };

  return PDA(
    id: 'responsive-pda',
    name: 'a^n b^n',
    states: {q0, q1, q2},
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: _fixtureTimestamp,
    modified: _fixtureTimestamp,
    bounds: const math.Rectangle(0, 0, 800, 480),
    stackAlphabet: const {'A', 'Z'},
    initialStackSymbol: 'Z',
  );
}

/// Turing machine that rewrites `a` into `x` and halts on the blank.
TM buildResponsiveTmFixture() {
  final q0 = automaton_state.State(
    id: 'tm-q0',
    label: 'q0',
    position: Vector2(140, 200),
    isInitial: true,
  );
  final q1 = automaton_state.State(
    id: 'tm-q1',
    label: 'q1',
    position: Vector2(400, 200),
  );
  final q2 = automaton_state.State(
    id: 'tm-q2',
    label: 'q2',
    position: Vector2(660, 200),
    isAccepting: true,
  );

  final transitions = <Transition>{
    TMTransition(
      id: 'tm-t0',
      fromState: q0,
      toState: q1,
      label: 'a/x,R',
      readSymbol: 'a',
      writeSymbol: 'x',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 'tm-t1',
      fromState: q1,
      toState: q1,
      label: 'b/b,R',
      readSymbol: 'b',
      writeSymbol: 'b',
      direction: TapeDirection.right,
    ),
    TMTransition(
      id: 'tm-t2',
      fromState: q1,
      toState: q2,
      label: 'B/B,L',
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.left,
    ),
  };

  return TM(
    id: 'responsive-tm',
    name: 'Rewrite a as x',
    states: {q0, q1, q2},
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: q0,
    acceptingStates: {q2},
    created: _fixtureTimestamp,
    modified: _fixtureTimestamp,
    bounds: const math.Rectangle(0, 0, 800, 480),
    tapeAlphabet: const {'a', 'b', 'x', 'B'},
    blankSymbol: 'B',
  );
}

/// Loads a populated machine or document into every workspace provider.
Future<void> loadResponsiveFixtures(ProviderContainer container) async {
  container
      .read(automatonStateProvider.notifier)
      .updateAutomaton(buildResponsiveFsaFixture());
  container
      .read(pdaEditorProvider.notifier)
      .setPda(buildResponsivePdaFixture());
  container.read(tmEditorProvider.notifier).setTm(buildResponsiveTmFixture());

  final grammar = container.read(grammarProvider.notifier);
  grammar.createNewGrammar(
    name: 'Balanced brackets',
    startSymbol: 'S',
    type: GrammarType.contextFree,
  );
  grammar
      .addProduction(leftSide: const ['S'], rightSide: const ['a', 'S', 'b']);
  grammar.addProduction(leftSide: const ['S'], rightSide: const ['a', 'b']);
  grammar.addProduction(leftSide: const ['S'], rightSide: const ['S', 'S']);

  final regex = container.read(regexEditorProvider.notifier);
  regex.validateRegex(kResponsiveRegexFixture);
  await regex.testStringMatch(kResponsiveRegexTestString);
}

//
//  pda_to_cfg_converter_test.dart
//  Turing Lab
//
//  Conjunto de testes que confirma a conversão de autômatos de pilha em
//  gramáticas livres de contexto, cobrindo a derivação de produções a partir
//  de transições, a montagem de regras iniciais com estados intermediários e a
//  sinalização de erros quando o autômato de origem é inválido.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/result.dart';

void main() {
  Vector2 position(double x) => Vector2(x, x);

  State buildState(
    String id, {
    bool isInitial = false,
    bool isAccepting = false,
  }) {
    return State(
      id: id,
      label: id,
      position: position(id.codeUnitAt(0).toDouble()),
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
  }

  PDA buildPda({
    required Set<State> states,
    required Set<PDATransition> transitions,
    required State initial,
    required Set<State> accepting,
    Set<String>? inputAlphabet,
    Set<String>? stackAlphabet,
  }) {
    final now = DateTime.utc(2024, 1, 1);
    return PDA(
      id: 'pda',
      name: 'Test PDA',
      states: states,
      transitions: transitions,
      alphabet: inputAlphabet ?? {'a'},
      initialState: initial,
      acceptingStates: accepting,
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 300, 200),
      stackAlphabet: stackAlphabet ?? {'Z'},
      initialStackSymbol: 'Z',
    );
  }

  String productionToString(Production production) {
    final left = production.leftSide.join(' ');
    final right = production.isLambda ? 'λ' : production.rightSide.join(' ');
    return '$left → $right';
  }

  group('PDAtoCFGConverter', () {
    test(
      'creates terminal productions for transitions that pop without push',
      () {
        final initial = buildState('p', isInitial: true);
        final accept = buildState('q', isAccepting: true);
        final transition = PDATransition(
          id: 't0',
          fromState: initial,
          toState: accept,
          label: 'a,Z→ε',
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: '',
          isLambdaPush: true,
        );
        final pda = buildPda(
          states: {initial, accept},
          transitions: {transition},
          initial: initial,
          accepting: {accept},
        );

        final result = PDAtoCFGConverter.convert(pda);
        expect(result, isA<Success<PdaToCfgConversion>>());
        final conversion = (result as Success<PdaToCfgConversion>).data;
        final grammar = conversion.grammar;

        final productionStrings =
            grammar.productions.map(productionToString).toSet();

        expect(
          productionStrings,
          containsAll(<String>{'S → [p, Z, q]', '[p, Z, q] → a'}),
        );
      },
    );

    test('rejects lambda-pop transitions before generating a grammar', () {
      final initial = buildState('p', isInitial: true);
      final accept = buildState('q', isAccepting: true);
      final transition = PDATransition(
        id: 't-lambda-pop',
        fromState: initial,
        toState: accept,
        label: 'a,lambda->lambda',
        inputSymbol: 'a',
        popSymbol: '',
        pushSymbol: '',
        isLambdaPop: true,
        isLambdaPush: true,
      );
      final pda = buildPda(
        states: {initial, accept},
        transitions: {transition},
        initial: initial,
        accepting: {accept},
      );

      final result = PDAtoCFGConverter.convert(pda);

      expect(result, isA<Failure<PdaToCfgConversion>>());
      expect(result.error, contains('pop exactly one stack symbol'));
      expect(result.error, contains('t-lambda-pop'));
    });

    test('expands pushed strings across intermediate states', () {
      final p = buildState('p', isInitial: true);
      final r = buildState('r', isAccepting: true);
      final q = buildState('q');

      final transition = PDATransition(
        id: 't1',
        fromState: p,
        toState: q,
        label: 'a,Z→XY',
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'XY',
      );

      final states = {p, q, r};
      final pda = buildPda(
        states: states,
        transitions: {transition},
        initial: p,
        accepting: {r},
        stackAlphabet: {'X', 'Y', 'Z'},
      );

      final result = PDAtoCFGConverter.convert(pda);
      expect(result, isA<Success<PdaToCfgConversion>>());
      final conversion = (result as Success<PdaToCfgConversion>).data;
      final grammar = conversion.grammar;

      final productionStrings = grammar.productions
          .map(productionToString)
          .where((rule) => !rule.startsWith('S →'))
          .toSet();

      final expected = <String>{};
      final stateLabels = states.map((state) => state.label).toList();
      for (final target in stateLabels) {
        for (final intermediate in stateLabels) {
          expected.add(
            '[p, Z, $target] → a [q, X, $intermediate] '
            '[$intermediate, Y, $target]',
          );
        }
      }

      expect(productionStrings, containsAll(expected));
    });

    test('omits terminals for lambda-input transitions that push symbols', () {
      final p = buildState('p', isInitial: true);
      final q = buildState('q', isAccepting: true);
      final r = buildState('r');

      final transition = PDATransition(
        id: 'tλ',
        fromState: p,
        toState: r,
        label: 'ε,Z→X',
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: 'X',
        isLambdaInput: true,
      );

      final states = {p, q, r};
      final pda = buildPda(
        states: states,
        transitions: {transition},
        initial: p,
        accepting: {q},
        stackAlphabet: {'X', 'Z'},
      );

      final result = PDAtoCFGConverter.convert(pda);
      expect(result, isA<Success<PdaToCfgConversion>>());
      final conversion = (result as Success<PdaToCfgConversion>).data;
      final grammar = conversion.grammar;

      final productionStrings = grammar.productions
          .map(productionToString)
          .where((rule) => !rule.startsWith('S →'))
          .toSet();

      final stateLabels = states.map((state) => state.label).toList();
      for (final target in stateLabels) {
        expect(
          productionStrings,
          contains('[p, Z, $target] → [r, X, $target]'),
        );
      }

      // Ensure no production introduces an unexpected terminal symbol.
      for (final rule in productionStrings) {
        if (rule.contains('→')) {
          final rightSide = rule.split('→')[1];
          expect(rightSide.trim().startsWith('['), isTrue);
        }
      }
    });

    test('creates lambda productions for pure stack transitions', () {
      final p = buildState('p', isInitial: true);
      final q = buildState('q', isAccepting: true);

      final transition = PDATransition(
        id: 't2',
        fromState: p,
        toState: q,
        label: 'ε,Z→ε',
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: '',
        isLambdaInput: true,
        isLambdaPush: true,
      );

      final pda = buildPda(
        states: {p, q},
        transitions: {transition},
        initial: p,
        accepting: {q},
      );

      final result = PDAtoCFGConverter.convert(pda);
      expect(result, isA<Success<PdaToCfgConversion>>());
      final conversion = (result as Success<PdaToCfgConversion>).data;
      final grammar = conversion.grammar;

      final productionStrings =
          grammar.productions.map(productionToString).toSet();

      expect(productionStrings, contains('[p, Z, q] → λ'));
    });
  });
}

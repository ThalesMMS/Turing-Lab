import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm_transition.dart';

void main() {
  group('transition display labels', () {
    test('formats concrete and lambda PDA operations canonically', () {
      expect(
        PDATransition.formatLabel(
          inputSymbol: 'a',
          popSymbol: 'Z',
          pushSymbol: 'AZ',
          isLambdaInput: false,
          isLambdaPop: false,
          isLambdaPush: false,
        ),
        'a, Z/AZ',
      );
      expect(
        PDATransition.formatLabel(
          inputSymbol: 'ignored-input',
          popSymbol: 'Z',
          pushSymbol: 'ignored-push',
          isLambdaInput: true,
          isLambdaPop: false,
          isLambdaPush: true,
        ),
        'λ, Z/λ',
      );
    });

    test('formats every TM direction canonically', () {
      expect(
        TMTransition.formatLabel(
          readSymbol: 'a',
          writeSymbol: 'b',
          direction: TapeDirection.left,
        ),
        'a/b,L',
      );
      expect(
        TMTransition.formatLabel(
          readSymbol: 'x',
          writeSymbol: 'y',
          direction: TapeDirection.right,
        ),
        'x/y,R',
      );
      expect(
        TMTransition.formatLabel(
          readSymbol: '0',
          writeSymbol: '1',
          direction: TapeDirection.stay,
        ),
        '0/1,S',
      );
      expect(
        TMTransition.formatLabel(
          readSymbol: '',
          writeSymbol: '',
          direction: TapeDirection.right,
        ),
        '∅/∅,R',
      );
    });

    test('PDA factories use the canonical input, pop/push label format', () {
      final from = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
      );
      final to = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2.zero(),
      );

      expect(
        PDATransition.epsilon(id: 'e', fromState: from, toState: to).label,
        'λ, λ/λ',
      );
      expect(
        PDATransition.readAndStack(
          id: 'r',
          fromState: from,
          toState: to,
          inputSymbol: '',
          popSymbol: 'Z',
          pushSymbol: '',
        ).label,
        'λ, Z/λ',
      );
      expect(
        PDATransition.readOnly(
          id: 'read',
          fromState: from,
          toState: to,
          inputSymbol: 'a',
        ).label,
        'a, λ/λ',
      );
      expect(
        PDATransition.stackOnly(
          id: 'stack',
          fromState: from,
          toState: to,
          popSymbol: '',
          pushSymbol: 'A',
        ).label,
        'λ, λ/A',
      );
    });
  });
}

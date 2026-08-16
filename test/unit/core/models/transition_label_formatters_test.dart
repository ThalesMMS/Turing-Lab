import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/pda_transition.dart';
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
  });
}

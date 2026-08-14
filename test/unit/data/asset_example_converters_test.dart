import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/data/converters/asset_example_converters.dart';

void main() {
  group('PDA asset conversion', () {
    test('rejects an initial stack with more than one symbol', () {
      final result = convertAssetJsonToPda(
        _pdaJson(initialStack: ['Z', 'A']),
        'Multiple initial symbols',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('exactly one symbol'));
    });

    test('rejects an initial symbol outside the stack alphabet', () {
      final result = convertAssetJsonToPda(
        _pdaJson(initialStack: ['X']),
        'Unknown initial symbol',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('must be in stackAlphabet'));
    });

    test('accepts one initial symbol from the stack alphabet', () {
      final result = convertAssetJsonToPda(
        _pdaJson(initialStack: ['Z']),
        'Valid initial symbol',
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.initialStackSymbol, 'Z');
      expect(result.data!.validate(), isEmpty);
    });
  });
}

Map<String, dynamic> _pdaJson({required List<String> initialStack}) {
  return <String, dynamic>{
    'id': 'pda_asset',
    'name': 'PDA asset',
    'alphabet': <String>['a'],
    'stackAlphabet': <String>['Z', 'A'],
    'states': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'q0',
        'name': 'q0',
        'x': 0,
        'y': 0,
        'isInitial': true,
        'isFinal': true,
      },
    ],
    'transitions': <String, dynamic>{},
    'initialId': 'q0',
    'initialStack': initialStack,
    'finalStates': <String>['q0'],
  };
}

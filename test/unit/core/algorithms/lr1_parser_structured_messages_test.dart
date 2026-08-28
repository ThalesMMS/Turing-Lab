import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/lr1_parser.dart';
import 'package:turing_lab/core/algorithms/lr1_parser_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/lr1_models.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final grammar = Grammar(
    id: 'lr1-structured-step-test',
    name: 'LR(1) structured step test grammar',
    terminals: {'a'},
    nonterminals: {'S'},
    startSymbol: 'S',
    productions: {
      const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    },
    type: GrammarType.contextFree,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );

  StructuredMessage roundTrip(StructuredMessage message) {
    final encoded = jsonEncode(message.toJson());
    return StructuredMessage.fromJson(
      Map<String, Object?>.from(jsonDecode(encoded) as Map),
    );
  }

  test('structures successful shift, reduce, and accept trace prose', () {
    final result = LR1Parser.parse(grammar, 'a');

    expect(result.outcome, LR1ParseOutcome.accepted);
    expect(result.steps.map((step) => step.action?.kind), [
      LR1ActionKind.shift,
      LR1ActionKind.reduce,
      LR1ActionKind.accept,
    ]);

    final shift = result.steps[0];
    expect(shift.message, 'Shifted a and entered I2.');
    expect(shift.structuredMessage?.stableCode, 'grammar.lr1.shifted');
    expect(
      shift.structuredMessage?.arguments['symbol']?.kind,
      StructuredMessageArgumentKind.symbol,
    );
    expect(shift.structuredMessage?.arguments['symbol']?.value, 'a');
    expect(
      shift.structuredMessage?.arguments['target-state']?.kind,
      StructuredMessageArgumentKind.identifier,
    );
    expect(shift.structuredMessage?.arguments['target-state']?.value, 'I2');

    final reduce = result.steps[1];
    expect(reduce.message, 'Reduced by p1: S → a.');
    expect(reduce.structuredMessage?.stableCode, 'grammar.lr1.reduced');
    expect(
      reduce.structuredMessage?.arguments['production']?.kind,
      StructuredMessageArgumentKind.identifier,
    );
    expect(reduce.structuredMessage?.arguments['production']?.value, 'p1');
    expect(reduce.structuredMessage?.arguments['left-side']?.value, 'S');
    expect(reduce.structuredMessage?.arguments['right-side']?.value, 'a');

    final accept = result.steps[2];
    expect(accept.message, 'Accepted on the completed augmented start item.');
    expect(accept.structuredMessage?.stableCode, 'grammar.lr1.accepted');
    expect(accept.structuredMessage?.arguments, isEmpty);
  });

  test(
    'successful trace messages are fully serializable and locale-neutral',
    () {
      final result = LR1Parser.parse(grammar, 'a');

      for (final step in result.steps) {
        final message = step.structuredMessage;
        expect(message, isNotNull);
        expect(roundTrip(message!), message);
        expect(message.namespace, 'grammar.lr1');
        expect(message.category, StructuredMessageCategory.parsing);
        expect(message.severity, StructuredMessageSeverity.information);
      }

      final direct = Lr1ParserMessages.reduced(
        productionId: 'pε',
        leftSide: 'S',
        rightSide: 'ε',
      );
      expect(roundTrip(direct), direct);
      expect(direct.arguments['right-side']?.value, 'ε');
    },
  );
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';

void main() {
  group('StructuredMessage', () {
    test('round-trips stable wire codes and typed arguments', () {
      final message = StructuredMessage(
        namespace: 'simulation.tm',
        code: 'bounded-unknown',
        category: StructuredMessageCategory.simulation,
        severity: StructuredMessageSeverity.warning,
        arguments: {
          'state': StructuredMessageArgument.identifier(
            'q-user-authored',
            role: 'state',
          ),
          'symbol': StructuredMessageArgument.symbol('β'),
          'steps': StructuredMessageArgument.count(12),
          'limit': StructuredMessageArgument.bound(10),
          'elapsed': StructuredMessageArgument.duration(
            const Duration(milliseconds: 250),
          ),
          'position': StructuredMessageArgument.index(3),
          'point': StructuredMessageArgument.coordinate(x: 1.5, y: -2),
          'strategy': StructuredMessageArgument.strategy('breadth-first'),
          'outcome': StructuredMessageArgument.outcome('bounded-unknown'),
          'formal-text': StructuredMessageArgument.literal('q0 → q1'),
        },
        source: StructuredMessageSource(
          kind: 'transition',
          identifier: 't7',
          path: r'$.transitions[7]',
          index: 7,
        ),
        suggestedAction: StructuredMessageAction(
          code: 'increase-step-bound',
          arguments: {'minimum': StructuredMessageArgument.bound(11)},
        ),
      );

      final json = message.toJson();
      final restored = StructuredMessage.fromJson(json);

      expect(restored, message);
      expect(restored.stableCode, 'simulation.tm.bounded-unknown');
      expect(json['version'], 1);
      expect(json['category'], 'simulation');
      expect(json['severity'], 'warning');
      expect(
        ((json['arguments']! as Map)['elapsed']! as Map)['kind'],
        'duration-ms',
      );
      expect(
        ((json['arguments']! as Map)['position']! as Map)['kind'],
        'index',
      );
    });

    test('legacy adapter cannot persist explanatory prose', () {
      const prose = 'Simulation timed out after one second';
      final message = StructuredMessage.legacyAdapter(
        namespace: 'simulation',
        code: 'legacy-failure',
        category: StructuredMessageCategory.simulation,
      );

      expect(jsonEncode(message.toJson()), isNot(contains(prose)));
      expect(message.stableCode, 'simulation.legacy-failure');
    });

    test('rejects malformed literal arguments and unsupported schemas', () {
      expect(
        () =>
            StructuredMessageArgument.fromJson({'kind': 'literal', 'value': 7}),
        throwsFormatException,
      );
      expect(() => StructuredMessageArgument.count(-1), throwsFormatException);
      expect(
        () => StructuredMessageAction(code: 'Translated action'),
        throwsArgumentError,
      );
      expect(
        () => StructuredMessage(
          namespace: 'trace',
          code: 'invalid-arguments',
          category: StructuredMessageCategory.trace,
          severity: StructuredMessageSeverity.error,
          arguments: {'Translated key': StructuredMessageArgument.count(1)},
        ),
        throwsArgumentError,
      );
      expect(
        () => StructuredMessageArgument.fromJson({
          'kind': 'coordinate',
          'value': {'x': null, 'y': 1},
        }),
        throwsFormatException,
      );
      expect(
        () => StructuredMessageArgument.fromJson({
          'kind': 'coordinate',
          'value': {'x': 'left', 'y': 1},
        }),
        throwsFormatException,
      );
      expect(
        () => StructuredMessageArgument.fromJson({
          'kind': 'future-kind',
          'value': 1,
        }),
        throwsFormatException,
      );
      expect(
        () => StructuredMessageArgument.fromJson({
          'kind': 'identifier',
          'value': 'q0',
        }),
        throwsFormatException,
      );
      expect(
        () => StructuredMessage.fromJson({
          'schema': StructuredMessage.schema,
          'version': 99,
          'namespace': 'simulation',
          'code': 'failure',
          'category': 'simulation',
          'severity': 'error',
        }),
        throwsFormatException,
      );
    });

    test('preserves unknown category and severity wire codes', () {
      final restored = StructuredMessage.fromJson({
        'schema': StructuredMessage.schema,
        'version': StructuredMessage.schemaVersion,
        'namespace': 'trace',
        'code': 'future-message',
        'category': 'future-category',
        'severity': 'future-severity',
        'arguments': const <String, Object?>{},
      });

      expect(restored.category, StructuredMessageCategory.unknown);
      expect(restored.severity, StructuredMessageSeverity.unknown);
      expect(restored.toJson()['category'], 'future-category');
      expect(restored.toJson()['severity'], 'future-severity');

      final otherFuture = StructuredMessage.fromJson({
        ...restored.toJson(),
        'category': 'other-future-category',
        'severity': 'other-future-severity',
      });
      expect(restored, isNot(otherFuture));
      expect({restored, otherFuture}, hasLength(2));
    });
  });
}

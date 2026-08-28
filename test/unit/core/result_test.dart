//
//  result_test.dart
//  Turing Lab
//
//  Unit tests that confirm Result class extensions when propagating success and failure.
//  Especially validates mapOrElse, preserving error messages and types in failure scenarios.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/result.dart';

void main() {
  group('Result.mapOrElse', () {
    test('preserves failure state and message', () {
      const failure = Failure<int>('original error');

      final result = failure.mapOrElse(
        (value) => value.toString(),
        (message) => message,
      );

      expect(result.isFailure, isTrue);
      expect(result, isA<Failure<String>>());
      expect(result.error, equals('original error'));
    });
  });

  test('map preserves locale-neutral failure details', () {
    final message = StructuredMessage(
      namespace: 'parser.test',
      code: 'invalid-document',
      category: StructuredMessageCategory.parsing,
      severity: StructuredMessageSeverity.error,
    );
    final failure = Failure<int>(
      message.stableCode,
      structuredMessage: message,
    );

    final mapped = failure.map((value) => value.toString());

    expect(mapped.error, message.stableCode);
    expect(mapped.structuredError, message);
  });

  test('mapOrElse preserves locale-neutral failure details', () {
    final message = StructuredMessage(
      namespace: 'parser.test',
      code: 'invalid-document',
      category: StructuredMessageCategory.parsing,
      severity: StructuredMessageSeverity.error,
    );
    final failure = Failure<int>(
      message.stableCode,
      structuredMessage: message,
    );

    final mapped = failure.mapOrElse(
      (value) => value.toString(),
      (error) => 'wrapped: $error',
    );

    expect(mapped.error, 'wrapped: ${message.stableCode}');
    expect(mapped.structuredError, message);
  });

  test('collect preserves the first locale-neutral failure details', () {
    final message = StructuredMessage(
      namespace: 'parser.test',
      code: 'invalid-document',
      category: StructuredMessageCategory.parsing,
      severity: StructuredMessageSeverity.error,
    );
    final results = <Result<int>>[
      const Success(1),
      Failure(message.stableCode, structuredMessage: message),
      const Failure('later failure'),
    ];

    final collected = results.collect();

    expect(collected.error, message.stableCode);
    expect(collected.structuredError, message);
  });
}

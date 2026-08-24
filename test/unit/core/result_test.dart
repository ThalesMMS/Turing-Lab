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
}

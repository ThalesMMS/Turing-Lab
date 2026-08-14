import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/conversion_step_history.dart';

void main() {
  group('ConversionHistory copyWith', () {
    test('can clear initial and final snapshots', () {
      const history = ConversionHistory(
        id: 'history',
        algorithmType: AlgorithmType.nfaToDfa,
        initialSnapshot: {'before': true},
        finalSnapshot: {'after': true},
      );

      final cleared = history.copyWith(
        initialSnapshot: null,
        finalSnapshot: null,
      );

      expect(cleared.initialSnapshot, isNull);
      expect(cleared.finalSnapshot, isNull);
    });
  });

  group('ConversionHistoryStep copyWith', () {
    test('can clear before and after snapshots', () {
      final step = ConversionHistoryStep(
        id: 'step',
        stepNumber: 0,
        algorithmStep: AlgorithmStep(
          id: 'algorithm-step',
          stepNumber: 0,
          title: 'Step',
          explanation: 'Explanation',
          type: AlgorithmType.nfaToDfa,
        ),
        beforeSnapshot: const {'before': true},
        afterSnapshot: const {'after': true},
        timestamp: DateTime(2026, 1, 1),
      );

      final cleared = step.copyWith(
        beforeSnapshot: null,
        afterSnapshot: null,
      );

      expect(cleared.beforeSnapshot, isNull);
      expect(cleared.afterSnapshot, isNull);
    });
  });
}

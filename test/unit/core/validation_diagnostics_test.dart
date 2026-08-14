import 'package:flutter_test/flutter_test.dart';

import 'dart:math';

import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/models/validation_diagnostic.dart';
import 'package:turing_lab/core/validators/input_validators.dart';
import 'package:turing_lab/core/validators/validation_issue_to_diagnostic.dart';

void main() {
  group('Validation diagnostics mapping (codes + highlight targets)', () {
    test('FSA_NO_INITIAL maps to suggested fix to set initial state', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
      );

      final fsa = FSA(
        id: 'fsa1',
        name: 'Test',
        states: {q0},
        transitions: const {},
        alphabet: const {'a'},
        initialState: null,
        acceptingStates: const {},
        created: DateTime(2026, 1, 1),
        modified: DateTime(2026, 1, 1),
        bounds: const Rectangle<double>(0, 0, 100, 100),
      );

      final issues = InputValidators.validateFSA(fsa);
      expect(issues.map((e) => e.code), contains('FSA_NO_INITIAL'));

      final diag = ValidationIssueToDiagnostic.fromIssue(
        issues.firstWhere((e) => e.code == 'FSA_NO_INITIAL'),
      );

      expect(diag.code, 'FSA_NO_INITIAL');
      expect(
        diag.suggestedFixes.any((f) => f.actionId == 'canvas.setInitialState'),
        isTrue,
      );
    });

    test(
        'Explicit diagnostics payload is preserved (including highlight target)',
        () {
      const issue = ValidationIssue(
        'FSA_NO_INITIAL',
        'Automaton has no initial state',
        diagnostic: ValidationDiagnostic(
          code: 'FSA_NO_INITIAL',
          summary: 'Missing initial state',
          details: 'Pick one state and mark it as start.',
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.state,
              id: 'q0',
            ),
          ],
        ),
      );

      final diag = ValidationIssueToDiagnostic.fromIssue(issue);
      expect(diag.code, 'FSA_NO_INITIAL');
      expect(diag.summary, 'Missing initial state');
      expect(diag.highlights, isNotNull);
      expect(diag.highlights.single.type, HighlightTargetType.state);
      expect(diag.highlights.single.id, 'q0');
    });
  });
}

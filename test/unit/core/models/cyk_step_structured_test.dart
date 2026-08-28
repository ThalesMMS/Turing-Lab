import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/cyk_step.dart';
import 'package:turing_lab/core/models/cyk_step_messages.dart';

void main() {
  final steps = <CYKStep>[
    CYKStep.initialize(
      id: 'initialize',
      stepNumber: 1,
      inputString: 'a b',
      tableSize: 2,
    ),
    CYKStep.fillBaseCase(
      id: 'base-case',
      stepNumber: 2,
      position: 0,
      terminal: 'a',
      derivingVariables: {'A', 'B'},
    ),
    CYKStep.processCell(
      id: 'process-cell',
      stepNumber: 3,
      row: 1,
      col: 0,
      substring: 'a b',
      length: 2,
    ),
    CYKStep.checkSplit(
      id: 'check-split',
      stepNumber: 4,
      row: 1,
      col: 0,
      substring: 'a b',
      substringLength: 2,
      splitPoint: 1,
      leftSubstring: 'a',
      rightSubstring: 'b',
      leftRow: 0,
      leftCol: 0,
      rightRow: 0,
      rightCol: 1,
      leftNonTerminals: {'A'},
      rightNonTerminals: {},
    ),
    CYKStep.applyProduction(
      id: 'apply-production',
      stepNumber: 5,
      row: 1,
      col: 0,
      variable: 'S',
      leftVar: 'A',
      rightVar: 'B',
      substring: 'a b',
      substringLength: 2,
    ),
    CYKStep.completeCell(
      id: 'complete-cell',
      stepNumber: 6,
      row: 1,
      col: 0,
      substring: 'a b',
      substringLength: 2,
      cellNonTerminals: {'S'},
    ),
    CYKStep.checkAcceptance(
      id: 'check-acceptance',
      stepNumber: 7,
      inputString: 'a b',
      startSymbol: 'S',
      finalCellNonTerminals: {'S'},
      isAccepted: true,
    ),
    CYKStep.completion(
      id: 'completion',
      stepNumber: 8,
      inputString: 'a b',
      isAccepted: false,
      totalCells: 3,
      filledCells: 2,
    ),
  ];

  test('all CYK factories expose locale-neutral messages', () {
    expect(steps.map((step) => step.titleMessage?.stableCode), [
      'grammar.cyk.step.initialize-title',
      'grammar.cyk.step.fill-base-case-title',
      'grammar.cyk.step.process-cell-title',
      'grammar.cyk.step.check-split-title',
      'grammar.cyk.step.apply-production-title',
      'grammar.cyk.step.complete-cell-title',
      'grammar.cyk.step.check-acceptance-title',
      'grammar.cyk.step.completion-title',
    ]);
    expect(steps.map((step) => step.explanationMessage?.stableCode), [
      'grammar.cyk.step.initialize-explanation',
      'grammar.cyk.step.fill-base-case-explanation',
      'grammar.cyk.step.process-cell-explanation',
      'grammar.cyk.step.check-split-explanation',
      'grammar.cyk.step.apply-production-explanation',
      'grammar.cyk.step.complete-cell-explanation',
      'grammar.cyk.step.check-acceptance-explanation',
      'grammar.cyk.step.completion-explanation',
    ]);
    expect(steps.map((step) => step.stepExplanationTitleMessage?.stableCode), [
      'grammar.cyk.step.initialize-step-title',
      'grammar.cyk.step.fill-base-case-step-title',
      'grammar.cyk.step.process-cell-step-title',
      'grammar.cyk.step.check-split-step-title',
      'grammar.cyk.step.apply-production-step-title',
      'grammar.cyk.step.complete-cell-step-title',
      'grammar.cyk.step.check-acceptance-step-title',
      'grammar.cyk.step.completion-step-title',
    ]);

    expect(steps.map((step) => step.bulletMessages.length), [
      2,
      3,
      2,
      3,
      3,
      2,
      2,
      2,
    ]);
    for (final step in steps) {
      expect(step.titleMessage, isNotNull);
      expect(step.explanationMessage, isNotNull);
      expect(step.stepExplanationTitleMessage, isNotNull);
      expect(step.baseStep.stepExplanation, isNotNull);
      expect(
        step.baseStep.stepExplanation!.titleMessage,
        step.stepExplanationTitleMessage,
      );
      expect(
        step.baseStep.stepExplanation!.bulletMessages,
        step.bulletMessages,
      );
      expect(step.baseStep.stepExplanation!.bulletMessages, isNotEmpty);
      expect(step.titleMessage!.category, StructuredMessageCategory.parsing);
      expect(
        step.explanationMessage!.severity,
        StructuredMessageSeverity.information,
      );

      final properties = step.baseStep.properties;
      expect(properties[cykStepTitleMessageProperty], isA<Map>());
      expect(properties[cykStepExplanationMessageProperty], isA<Map>());
      final stepExplanationJson =
          step.baseStep.toJson()['stepExplanation'] as Map;
      expect(stepExplanationJson['titleMessage'], isA<Map>());
      expect(stepExplanationJson['bulletMessages'], isA<List>());

      final restored = CYKStep.fromJson(step.toJson());
      expect(restored.titleMessage, step.titleMessage);
      expect(restored.explanationMessage, step.explanationMessage);
      expect(
        restored.stepExplanationTitleMessage,
        step.stepExplanationTitleMessage,
      );
      expect(restored.bulletMessages, step.bulletMessages);
      expect(
        restored.baseStep.stepExplanation!.titleMessage,
        step.baseStep.stepExplanation!.titleMessage,
      );
      expect(
        restored.baseStep.stepExplanation!.bulletMessages,
        step.baseStep.stepExplanation!.bulletMessages,
      );
      for (final message in [
        step.titleMessage!,
        step.explanationMessage!,
        step.stepExplanationTitleMessage!,
        ...step.bulletMessages,
      ]) {
        expect(StructuredMessage.fromJson(message.toJson()), message);
      }
    }
  });

  test('legacy CYK teaching copy and formal payload remain unchanged', () {
    expect(steps.map((step) => step.title), [
      'Initialize CYK table',
      'Fill base case for "a"',
      'Process cell [1][0]',
      'Check split at position 1',
      'Apply production S → A B',
      'Complete cell [1][0]',
      'Check acceptance',
      'Parsing complete',
    ]);
    expect(
      steps.map(
        (step) => step.baseStep.stepExplanation!.titleMessage?.stableCode,
      ),
      [
        'grammar.cyk.step.initialize-step-title',
        'grammar.cyk.step.fill-base-case-step-title',
        'grammar.cyk.step.process-cell-step-title',
        'grammar.cyk.step.check-split-step-title',
        'grammar.cyk.step.apply-production-step-title',
        'grammar.cyk.step.complete-cell-step-title',
        'grammar.cyk.step.check-acceptance-step-title',
        'grammar.cyk.step.completion-step-title',
      ],
    );
    expect(
      steps.first.baseStep.stepExplanation!.bulletMessages.map(
        (message) => message.stableCode,
      ),
      [
        'grammar.cyk.step.initialize-input-bullet',
        'grammar.cyk.step.initialize-table-bullet',
      ],
    );
    expect(
      steps[3].baseStep.stepExplanation!.bulletMessages.map(
        (message) => message.stableCode,
      ),
      [
        'grammar.cyk.step.check-split-left-bullet',
        'grammar.cyk.step.check-split-right-bullet',
        'grammar.cyk.step.check-split-production-bullet',
      ],
    );
    expect(steps[4].production, 'S → A B');
    expect(steps[4].productionLeft, 'S');
    expect(steps[4].productionRight, ['A', 'B']);
    expect(steps[4].addedNonTerminal, 'S');
    expect(steps[4].cellModified, isTrue);
    expect(steps[6].cellNonTerminals, {'S'});
    expect(steps[6].isAccepted, isTrue);
    expect(steps[7].isAccepted, isFalse);
  });

  test('structured arguments preserve CYK positions and outcomes', () {
    final process = steps[2].explanationMessage!;
    expect(
      process.arguments['row']?.kind,
      StructuredMessageArgumentKind.positionIndex,
    );
    expect(process.arguments['row']?.value, 1);
    expect(
      process.arguments['length']?.kind,
      StructuredMessageArgumentKind.count,
    );

    final split = steps[3].explanationMessage!;
    expect(split.arguments['left-variables']?.value, 'A');
    expect(split.arguments['right-variables']?.value, '');
    expect(split.arguments['has-right-variables']?.value, isFalse);

    final production = steps[4].titleMessage!;
    expect(
      production.arguments['variable']?.kind,
      StructuredMessageArgumentKind.identifier,
    );
    expect(production.arguments['variable']?.value, 'S');

    final completion = steps[7].explanationMessage!;
    expect(completion.arguments['total-cells']?.value, 3);
    expect(completion.arguments['filled-cells']?.value, 2);
    expect(completion.arguments['accepted']?.value, isFalse);
  });

  test('empty-cell branches carry presentation-neutral presence flags', () {
    final emptyBase = CYKStep.fillBaseCase(
      id: 'empty-base',
      stepNumber: 1,
      position: 2,
      terminal: 'c',
      derivingVariables: {},
    );
    final emptyCell = CYKStep.completeCell(
      id: 'empty-cell',
      stepNumber: 2,
      row: 0,
      col: 2,
      substring: 'c',
      substringLength: 1,
      cellNonTerminals: {},
    );
    expect(
      emptyBase.baseStep.stepExplanation!.bulletMessages.last.code,
      'fill-base-case-empty-bullet',
    );
    expect(emptyBase.bulletMessages.last.code, 'fill-base-case-empty-bullet');
    expect(
      emptyBase.explanationMessage!.arguments['has-variables']?.value,
      isFalse,
    );
    expect(emptyCell.bulletMessages.last.code, 'complete-cell-empty-bullet');
    expect(
      emptyCell.explanationMessage!.arguments['has-nonterminals']?.value,
      isFalse,
    );
  });
}

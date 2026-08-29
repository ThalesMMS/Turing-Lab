import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_simplification_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/regex_simplification_step.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('step factories keep prose out of semantic state', () {
    final step = RegexSimplificationStep.start(
      id: 'start',
      stepNumber: 1,
      regex: '(a|b)*',
      starHeight: 1,
      nestingDepth: 1,
      operatorCount: 2,
    );

    expect(step.title, 'regex.simplification.step.start-title');
    expect(step.explanation, 'regex.simplification.step.start-explanation');
    expect(
      RegexSimplificationStep.fromJson(step.toJson()).explanationMessage,
      step.explanationMessage,
    );
    expect(
      en.resolveStructuredMessage(step.titleMessage),
      'Begin regex simplification',
    );
    expect(
      pt.resolveStructuredMessage(step.titleMessage),
      'Iniciar simplificação da expressão regular',
    );
    expect(
      en.resolveStructuredMessage(step.explanationMessage),
      contains('(a|b)*'),
    );
    expect(
      pt.resolveStructuredMessage(step.explanationMessage),
      contains('(a|b)*'),
    );
  });

  test('rule application resolves in English and Portuguese', () {
    final step = RegexSimplificationStep.applyRule(
      id: 'apply',
      stepNumber: 2,
      originalRegex: 'a|∅',
      simplifiedRegex: 'a',
      rule: SimplificationRule.emptyUnion,
      matchedSubexpression: 'a|∅',
      replacementSubexpression: 'a',
      position: 0,
      totalRulesApplied: 1,
    );

    final english = en.resolveStructuredMessage(step.explanationMessage);
    final portuguese = pt.resolveStructuredMessage(step.explanationMessage);
    expect(english, contains('Empty union'));
    expect(english, contains('Saved'));
    expect(portuguese, contains('União com conjunto vazio'));
    expect(portuguese, contains('economizados'));
    expect(english, isNot(portuguese));
  });

  test('length growth is reported instead of being called unchanged', () {
    final step = RegexSimplificationStep.applyRule(
      id: 'expand',
      stepNumber: 2,
      originalRegex: 'a+',
      simplifiedRegex: 'aa*',
      rule: SimplificationRule.plusExpansion,
      matchedSubexpression: 'a+',
      replacementSubexpression: 'aa*',
      position: 0,
      totalRulesApplied: 1,
    );

    expect(step.charactersSaved, -1);
    expect(
      en.resolveStructuredMessage(step.explanationMessage),
      contains('grew by one character'),
    );
    expect(
      pt.resolveStructuredMessage(step.explanationMessage),
      contains('aumentou em um caractere'),
    );
  });

  test('every step type and rule has strict bilingual presentation', () {
    for (final type in RegexSimplificationStepType.values) {
      final english = en.resolveStructuredMessage(type.labelMessage);
      final portuguese = pt.resolveStructuredMessage(type.labelMessage);
      expect(english, isNot(contains(type.labelMessage.stableCode)));
      expect(portuguese, isNot(contains(type.labelMessage.stableCode)));
      expect(english, isNot(portuguese));
    }

    for (final rule in SimplificationRule.values) {
      final english = en.resolveStructuredMessage(rule.descriptionMessage);
      final portuguese = pt.resolveStructuredMessage(rule.descriptionMessage);
      expect(english, isNot(contains(rule.descriptionMessage.stableCode)));
      expect(portuguese, isNot(contains(rule.descriptionMessage.stableCode)));
      expect(english, isNot(portuguese));
      expect(rule.formalNotation, isNotEmpty);
    }
  });

  test('resolver rejects extra arguments and future enum outcomes', () {
    final extraArgument = StructuredMessage(
      namespace: 'regex.simplification.rule',
      code: 'name',
      category: StructuredMessageCategory.transformation,
      severity: StructuredMessageSeverity.information,
      arguments: {
        'rule': StructuredMessageArgument.outcome(
          'emptyUnion',
          role: 'simplification-rule',
        ),
        'extra': StructuredMessageArgument.literal('not allowed'),
      },
    );
    final futureRule = StructuredMessage(
      namespace: 'regex.simplification.rule',
      code: 'name',
      category: StructuredMessageCategory.transformation,
      severity: StructuredMessageSeverity.information,
      arguments: {
        'rule': StructuredMessageArgument.outcome(
          'futureRule',
          role: 'simplification-rule',
        ),
      },
    );

    expect(
      en.resolveStructuredMessage(extraArgument),
      contains(extraArgument.stableCode),
    );
    expect(
      pt.resolveStructuredMessage(extraArgument),
      contains(extraArgument.stableCode),
    );
    expect(
      en.resolveStructuredMessage(futureRule),
      contains(futureRule.stableCode),
    );
    expect(
      pt.resolveStructuredMessage(futureRule),
      contains(futureRule.stableCode),
    );
  });

  test('validation messages resolve in English and Portuguese', () {
    final messages = [
      RegexSimplificationMessages.emptyInput(),
      RegexSimplificationMessages.unmatchedClosingParenthesis(2),
      RegexSimplificationMessages.unclosedOpeningParentheses(3),
    ];

    expect(
      en.resolveStructuredMessage(messages[0]),
      'A regular expression is required.',
    );
    expect(
      pt.resolveStructuredMessage(messages[0]),
      'É necessária uma expressão regular.',
    );
    expect(
      en.resolveStructuredMessage(messages[1]),
      'Unmatched closing parenthesis at position 3.',
    );
    expect(
      pt.resolveStructuredMessage(messages[1]),
      'Parêntese de fechamento sem correspondência na posição 3.',
    );
    expect(
      en.resolveStructuredMessage(messages[2]),
      '3 opening parentheses are not closed.',
    );
    expect(
      pt.resolveStructuredMessage(messages[2]),
      '3 parênteses de abertura não foram fechados.',
    );
    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });
}

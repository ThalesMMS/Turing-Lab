import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('step state stores stable codes and resolves in both locales', () {
    final result = RegexToNFAConverter.convertWithSteps('(a|b)*c+');
    expect(result.isSuccess, true, reason: result.error);

    for (final step in result.data!.steps) {
      expect(step.baseStep.title, startsWith('regex.to-nfa.step.'));
      expect(step.baseStep.explanation, startsWith('regex.to-nfa.step.'));

      final title = StructuredMessage.fromJson(step.titleMessage.toJson());
      final explanation = StructuredMessage.fromJson(
        step.explanationMessage.toJson(),
      );
      expect(en.resolveStructuredMessage(title), isNot(title.stableCode));
      expect(pt.resolveStructuredMessage(title), isNot(title.stableCode));
      expect(
        en.resolveStructuredMessage(explanation),
        isNot(explanation.stableCode),
      );
      expect(
        pt.resolveStructuredMessage(explanation),
        isNot(explanation.stableCode),
      );
    }
  });

  test('legacy stepType property and JSON round-trip remain compatible', () {
    final result = RegexToNFAConverter.convertWithSteps('a');
    final step = result.data!.steps.firstWhere(
      (candidate) => candidate.stepType == RegexToNFAStepType.basicSymbol,
    );
    final properties = step.toProperties();

    expect(properties['stepType'], 'Basic Symbol');
    expect(properties['stepTypeCode'], 'basicSymbol');
    expect(properties[regexToNfaTitleMessageProperty], isA<Map>());
    expect(properties[regexToNfaExplanationMessageProperty], isA<Map>());

    final restored = AlgorithmStep.fromJson(
      step.baseStep.copyWith(properties: properties).toJson(),
    );
    final restoredTitle = StructuredMessage.fromJson(
      Map<String, Object?>.from(
        restored.properties[regexToNfaTitleMessageProperty] as Map,
      ),
    );
    expect(en.resolveStructuredMessage(restoredTitle), 'Create an NFA for "a"');
    expect(pt.resolveStructuredMessage(restoredTitle), 'Criar um AFN para "a"');
  });

  test('all step types have bilingual labels and descriptions', () {
    for (final type in RegexToNFAStepType.values) {
      final englishLabel = en.resolveStructuredMessage(type.labelMessage);
      final portugueseLabel = pt.resolveStructuredMessage(type.labelMessage);
      expect(englishLabel, isNot(type.labelMessage.stableCode));
      expect(portugueseLabel, isNot(type.labelMessage.stableCode));
      expect(englishLabel, isNot(portugueseLabel));
      expect(
        en.resolveStructuredMessage(type.descriptionMessage),
        isNot(type.descriptionMessage.stableCode),
      );
      expect(
        pt.resolveStructuredMessage(type.descriptionMessage),
        isNot(type.descriptionMessage.stableCode),
      );
    }
  });

  test('strict resolver rejects extra fields and future step types', () {
    final extraField = StructuredMessage(
      namespace: 'regex.to-nfa.step-type',
      code: 'label',
      category: StructuredMessageCategory.transformation,
      severity: StructuredMessageSeverity.information,
      arguments: {
        'type': StructuredMessageArgument.outcome(
          'start',
          role: 'regex-to-nfa-step-type',
        ),
        'extra': StructuredMessageArgument.literal('not allowed'),
      },
    );
    final futureType = StructuredMessage(
      namespace: 'regex.to-nfa.step-type',
      code: 'label',
      category: StructuredMessageCategory.transformation,
      severity: StructuredMessageSeverity.information,
      arguments: {
        'type': StructuredMessageArgument.outcome(
          'futureType',
          role: 'regex-to-nfa-step-type',
        ),
      },
    );

    expect(
      en.resolveStructuredMessage(extraField),
      contains(extraField.stableCode),
    );
    expect(
      pt.resolveStructuredMessage(extraField),
      contains(extraField.stableCode),
    );
    expect(
      en.resolveStructuredMessage(futureType),
      contains(futureType.stableCode),
    );
    expect(
      pt.resolveStructuredMessage(futureType),
      contains(futureType.stableCode),
    );
  });
}

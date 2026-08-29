import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/fa_to_regex_step.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  test('FA-to-regex step contracts survive JSON and resolve in EN/PT', () {
    final step = FAToRegexStep.validation(
      id: 'validation',
      stepNumber: 0,
      stateCount: 3,
      transitionCount: 2,
      hasInitialState: true,
      hasAcceptingStates: false,
    );
    final restored = FAToRegexStep.fromJson(step.toJson());
    final title = restored.titleMessage!;
    final explanation = restored.explanationMessage!;
    final en = AppLocalizationsEn();
    final pt = AppLocalizationsPt();

    expect(restored.baseStep.title, title.stableCode);
    expect(restored.baseStep.explanation, explanation.stableCode);
    expect(en.resolveStructuredMessage(title), 'Validate input automaton');
    expect(pt.resolveStructuredMessage(title), 'Validar autômato de entrada');
    expect(en.resolveStructuredMessage(explanation), contains('3 states'));
    expect(pt.resolveStructuredMessage(explanation), contains('3 estados'));
    expect(en.resolveStructuredMessage(explanation), isNot(contains('false')));
    expect(pt.resolveStructuredMessage(explanation), isNot(contains('false')));

    final malformed = StructuredMessage(
      namespace: title.namespace,
      code: title.code,
      category: title.category,
      severity: title.severity,
      arguments: {
        ...title.arguments,
        'extra': StructuredMessageArgument.literal('not allowed'),
      },
    );
    expect(
      en.resolveStructuredMessage(malformed),
      contains(malformed.stableCode),
    );
  });

  test('FA-to-regex type labels and descriptions resolve in EN/PT', () {
    final en = AppLocalizationsEn();
    final pt = AppLocalizationsPt();

    for (final type in FAToRegexStepType.values) {
      final englishLabel = en.resolveStructuredMessage(type.labelMessage);
      final portugueseLabel = pt.resolveStructuredMessage(type.labelMessage);
      expect(englishLabel, isNot(type.labelMessage.stableCode));
      expect(portugueseLabel, isNot(type.labelMessage.stableCode));
      expect(
        en.resolveStructuredMessage(type.descriptionMessage),
        isNot(type.descriptionMessage.stableCode),
      );
      expect(
        pt.resolveStructuredMessage(type.descriptionMessage),
        isNot(type.descriptionMessage.stableCode),
      );
    }

    expect(
      en.resolveStructuredMessage(FAToRegexStepType.selectState.labelMessage),
      'Select state',
    );
    expect(
      pt.resolveStructuredMessage(FAToRegexStepType.selectState.labelMessage),
      'Selecionar estado',
    );
  });

  test('FA-to-regex elimination summaries resolve without domain prose', () {
    final step = FAToRegexStep.findIncomingTransitions(
      id: 'summary',
      stepNumber: 1,
      eliminatedState: State(id: 'q1', label: 'q1', position: Vector2.zero()),
      incomingStates: {State(id: 'q0', label: 'q0', position: Vector2.zero())},
      incomingTransitions: const {},
    );
    final message = step.eliminationSummaryMessage;

    expect(step.eliminationSummary, '${message.stableCode}.with-state');
    expect(
      AppLocalizationsEn().resolveStructuredMessage(message),
      'Eliminating q1: 1 incoming state, no outgoing states, no self-loop.',
    );
    expect(
      AppLocalizationsPt().resolveStructuredMessage(message),
      'Eliminando q1: 1 estado de entrada, nenhum estado de saída e nenhum laço.',
    );
  });
}

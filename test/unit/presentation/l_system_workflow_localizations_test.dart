import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('resolves every reachable expander and turtle diagnostic', () {
    final messages = <String, String>{
      'Production IDs must be unique.':
          'Os IDs das produções devem ser únicos.',
      'stochastic L-systems are preserved but not expanded.':
          'Sistemas L estocásticos são preservados, mas não expandidos.',
      'parametric L-systems are preserved but not expanded.':
          'Sistemas L paramétricos são preservados, mas não expandidos.',
      'contextSensitive L-systems are preserved but not expanded.':
          'Sistemas L sensíveis ao contexto são preservados, mas não expandidos.',
      'Turtle command turn requires a finite number.':
          'O comando da tartaruga turn exige um número finito.',
      'Turtle movement produced non-finite geometry.':
          'O movimento da tartaruga produziu geometria não finita.',
      'Turtle branch stack exceeded its configured limit.':
          'A pilha de ramificações da tartaruga excedeu o limite configurado.',
      'A branch pop has no matching push.':
          'Uma remoção da ramificação não tem inserção correspondente.',
      'Turtle line width must remain positive and finite.':
          'A largura da linha da tartaruga deve permanecer positiva e finita.',
      'Nested turtle polygons are not supported.':
          'Polígonos aninhados da tartaruga não são compatíveis.',
      'A polygon close has no matching begin command.':
          'Um fechamento de polígono não tem comando de início correspondente.',
      'A turtle polygon requires at least three points.':
          'Um polígono da tartaruga exige pelo menos três pontos.',
      'Turtle color commands require a supported color.':
          'Os comandos de cor da tartaruga exigem uma cor compatível.',
      'Turtle line width increment must be positive and finite.':
          'O incremento da largura da linha da tartaruga deve ser positivo e finito.',
      'Turtle distance must be positive and finite.':
          'A distância da tartaruga deve ser positiva e finita.',
      'A turtle polygon was not closed.':
          'Um polígono da tartaruga não foi fechado.',
      '1 turtle branch state(s) were not restored.':
          '1 estado de ramificação da tartaruga não foi restaurado.',
      '3 turtle branch state(s) were not restored.':
          '3 estados de ramificação da tartaruga não foram restaurados.',
    };

    for (final entry in messages.entries) {
      expect(en.localizeWorkflowText(entry.key), entry.key);
      expect(pt.localizeWorkflowText(entry.key), entry.value);
    }
  });

  test('localizes concatenated static and dynamic diagnostics', () {
    const source =
        'Production IDs must be unique. '
        'Turtle command turn requires a finite number. '
        '2 turtle branch state(s) were not restored.';

    expect(
      pt.localizeWorkflowText(source),
      'Os IDs das produções devem ser únicos. '
      'O comando da tartaruga turn exige um número finito. '
      '2 estados de ramificação da tartaruga não foram restaurados.',
    );
  });

  test('resolves typed diagnostics, bounds, and safe fallback in EN/PT', () {
    final command = StructuredMessage(
      namespace: 'l-system.turtle',
      code: 'finite-command-argument-required',
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
      arguments: {
        'command': StructuredMessageArgument.literal(
          'F_α',
          role: 'turtle-command',
        ),
      },
    );
    expect(
      en.resolveStructuredMessage(command),
      'Turtle command F_α requires a finite number.',
    );
    expect(
      pt.resolveStructuredMessage(command),
      'O comando da tartaruga F_α exige um número finito.',
    );

    final memoryBound = StructuredMessage(
      namespace: 'l-system.execution',
      code: 'expansion-bounded',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.warning,
      arguments: {
        'kind': StructuredMessageArgument.outcome(
          'estimatedMemory',
          role: 'expansion-limit-kind',
        ),
        'maximum': StructuredMessageArgument.bound(64),
        'estimate': StructuredMessageArgument.integer(
          65,
          role: 'estimated-resource-use',
        ),
      },
    );
    expect(
      en.resolveStructuredMessage(memoryBound),
      'Expansion stopped at the estimatedBytes limit.',
    );
    expect(
      pt.resolveStructuredMessage(memoryBound),
      'A expansão parou no limite de bytes estimados.',
    );

    final malformed = StructuredMessage(
      namespace: 'l-system.turtle',
      code: 'finite-command-argument-required',
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
    );
    expect(
      pt.resolveStructuredMessage(malformed),
      pt.structuredMessageUnknown(malformed.stableCode),
    );
  });
}

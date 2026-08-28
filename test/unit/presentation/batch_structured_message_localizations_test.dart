import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/batch_execution/batch_execution.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:turing_lab/l10n/app_localizations_workflows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('batch validation and execution messages resolve in both locales', () {
    final messages = [
      _message(
        'batch.validation',
        'maximum',
        arguments: {
          'field': StructuredMessageArgument.outcome(
            'batch-size',
            role: 'validation-field',
          ),
          'bound': StructuredMessageArgument.bound(10000),
        },
      ),
      _message(
        'batch.validation',
        'duplicate-case-id',
        arguments: {
          'case': StructuredMessageArgument.identifier('case-α', role: 'case'),
        },
      ),
      _message('batch.execution', 'grammar-tokenization-mismatch'),
      _message(
        'batch.execution',
        'tm-policy-reason',
        arguments: {
          'policy': StructuredMessageArgument.outcome(
            'finalStateOrHalting',
            role: 'tm-acceptance-policy',
          ),
          'reason': StructuredMessageArgument.outcome(
            'configurationLimit',
            role: 'tm-acceptance-reason',
          ),
        },
      ),
      _message(
        'batch.import',
        'case-limit',
        arguments: {
          'count': StructuredMessageArgument.count(12),
          'bound': StructuredMessageArgument.bound(10),
        },
      ),
    ];

    for (final message in messages) {
      final restored = StructuredMessage.fromJson(message.toJson());
      expect(restored, message);
      expect(
        en.resolveStructuredMessage(restored),
        isNot(contains(message.stableCode)),
      );
      expect(
        pt.resolveStructuredMessage(restored),
        isNot(contains(message.stableCode)),
      );
      expect(
        en.resolveStructuredMessage(restored),
        isNot(pt.resolveStructuredMessage(restored)),
      );
    }
    expect(
      pt.resolveStructuredMessage(messages[messages.length - 2]),
      'Política: Estado final ou parada. Motivo: o limite de configurações foi atingido.',
    );
  });

  test('invalid typed contract uses the localized safe fallback', () {
    final invalid = _message(
      'batch.validation',
      'maximum',
      arguments: {
        'field': StructuredMessageArgument.literal('batch-size'),
        'bound': StructuredMessageArgument.bound(10000),
      },
    );

    expect(
      en.resolveStructuredMessage(invalid),
      'Message unavailable (${invalid.stableCode}).',
    );
    expect(
      pt.resolveStructuredMessage(invalid),
      'Mensagem indisponível (${invalid.stableCode}).',
    );
  });

  test('batch result persistence keeps the structured message payload', () {
    final message = _message('batch.execution', 'scalar-tokenization-required');
    final result = BatchCaseResult(
      inputCase: BatchInputCase(
        id: 'case-1',
        input: 'token',
        tokens: const ['token'],
      ),
      outcome: BatchOutcomeCode.invalidInput,
      elapsed: const Duration(microseconds: 4),
      diagnosticCode: 'batch.scalar-tokenization-required',
      structuredMessage: message,
    );

    final json = result.toJson();
    final restored = StructuredMessage.fromJson(
      Map<String, Object?>.from(json['structuredMessage']! as Map),
    );
    expect(restored, message);
    expect(json['case'], containsPair('tokens', ['token']));
  });

  test('TM acceptance workflow copy resolves static and combined results', () {
    expect(
      pt.localizeWorkflowText(
        'Policy: Final state or halting. Reason: the timeout was reached.',
      ),
      'Política: Estado final ou parada. Motivo: o limite de tempo foi atingido.',
    );
    expect(
      pt.localizeWorkflowText(
        'Rejected: Configuration limit reached; the result is inconclusive',
      ),
      'Rejeitada: Limite de configurações atingido; o resultado é inconclusivo',
    );
    expect(en.localizeWorkflowText('Simulation Steps:'), 'Simulation Steps:');
    expect(
      pt.localizeWorkflowText('Simulation Steps:'),
      'Passos da simulação:',
    );
  });

  test('Regex fragment workflow copy resolves dynamic summaries', () {
    expect(pt.localizeWorkflowText('0 of 1 expected'), '0 de 1 esperados');
    expect(
      pt.localizeWorkflowText(
        '0 states, 0 transitions, one entry state, and 0 accepting states. '
        'Alphabet: a.',
      ),
      '0 estados, 0 transições, uma entrada e 0 estados de aceitação. '
      'Alfabeto: a.',
    );
    expect(
      pt.localizeWorkflowText('Remove q0 and its 2 connected transitions?'),
      'Remover q0 e suas 2 transições conectadas?',
    );
    expect(
      pt.localizeWorkflowText('Remove q0 and its 1 connected transition?'),
      'Remover q0 e sua 1 transição conectada?',
    );
  });
}

StructuredMessage _message(
  String namespace,
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: namespace,
  code: code,
  category: StructuredMessageCategory.validation,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

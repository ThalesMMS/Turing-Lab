import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/services/simulation_runner_messages.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  test('runner failures round-trip and resolve in English and Portuguese', () {
    final cases = <(StructuredMessage, String, String)>[
      (
        SimulationRunnerMessages.startFailed(),
        'The simulation worker could not start.',
        'Não foi possível iniciar o processo de simulação.',
      ),
      (
        SimulationRunnerMessages.executionFailed(),
        'The simulation could not be completed.',
        'Não foi possível concluir a simulação.',
      ),
      (
        SimulationRunnerMessages.workerFailed(),
        'The simulation worker failed.',
        'O processo de simulação falhou.',
      ),
      (
        SimulationRunnerMessages.workerExitedUnexpectedly(),
        'The simulation worker exited unexpectedly.',
        'O processo de simulação foi encerrado inesperadamente.',
      ),
      (
        SimulationRunnerMessages.invalidWorkerResponse(),
        'The simulation worker returned an invalid response.',
        'O processo de simulação retornou uma resposta inválida.',
      ),
    ];

    for (final (message, english, portuguese) in cases) {
      final restored = StructuredMessage.fromJson(message.toJson());
      expect(restored, message);
      expect(AppLocalizationsEn().resolveStructuredMessage(restored), english);
      expect(
        AppLocalizationsPt().resolveStructuredMessage(restored),
        portuguese,
      );
    }
  });

  test('unexpected runner arguments use the localized safe fallback', () {
    final malformed = StructuredMessage(
      namespace: 'service.simulation-runner',
      code: 'execution-failed',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.error,
      arguments: {'detail': StructuredMessageArgument.literal('internal')},
    );

    expect(
      AppLocalizationsEn().resolveStructuredMessage(malformed),
      contains(malformed.stableCode),
    );
    expect(
      AppLocalizationsPt().resolveStructuredMessage(malformed),
      contains(malformed.stableCode),
    );
  });
}

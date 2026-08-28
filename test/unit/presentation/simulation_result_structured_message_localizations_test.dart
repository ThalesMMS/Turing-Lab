import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('simulation outcomes resolve persisted contracts in both locales', () {
    final results = <SimulationResult>[
      SimulationResult.timeout(
        inputString: 'ab',
        steps: const [],
        executionTime: const Duration(seconds: 2),
      ),
      SimulationResult.infiniteLoop(
        inputString: 'ab',
        steps: const [],
        executionTime: const Duration(milliseconds: 50),
      ),
      SimulationResult.failure(
        inputString: 'ab',
        steps: const [],
        errorMessage: 'legacy internal detail',
        executionTime: const Duration(milliseconds: 50),
      ),
    ];

    for (final result in results) {
      final message = result.message!;
      final restored = StructuredMessage.fromJson(message.toJson());
      final english = en.resolveStructuredMessage(restored);
      final portuguese = pt.resolveStructuredMessage(restored);

      expect(english, isNot(contains(restored.stableCode)));
      expect(portuguese, isNot(contains(restored.stableCode)));
      expect(english, isNot(portuguese));
      expect(english, isNot(contains('legacy internal detail')));
      expect(portuguese, isNot(contains('legacy internal detail')));
    }
  });

  test('malformed simulation outcome contracts fail closed', () {
    final malformed = StructuredMessage(
      namespace: 'simulation',
      code: 'timeout',
      category: StructuredMessageCategory.simulation,
      severity: StructuredMessageSeverity.warning,
      arguments: {'elapsed': StructuredMessageArgument.count(2)},
    );

    expect(
      en.resolveStructuredMessage(malformed),
      'Message unavailable (${malformed.stableCode}).',
    );
    expect(
      pt.resolveStructuredMessage(malformed),
      'Mensagem indisponível (${malformed.stableCode}).',
    );
  });
}

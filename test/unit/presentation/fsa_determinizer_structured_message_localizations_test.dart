import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('determinization failures resolve in English and Portuguese', () {
    final message = _failureMessage('A');

    expect(
      en.resolveStructuredMessage(message),
      'Automaton A could not be determinized.',
    );
    expect(
      pt.resolveStructuredMessage(message),
      'Não foi possível determinizar o autômato A.',
    );
    expect(StructuredMessage.fromJson(message.toJson()), message);
  });

  test('malformed determinization contracts use the safe fallback', () {
    final wrongKind = StructuredMessage(
      namespace: 'algorithm.fsa-determinizer',
      code: 'failed',
      category: StructuredMessageCategory.conversion,
      severity: StructuredMessageSeverity.error,
      arguments: {
        'automaton': StructuredMessageArgument.identifier(
          'A',
          role: 'automaton-label',
        ),
      },
    );
    final extraArgument = _failureMessage(
      'A',
      extraArguments: {
        'cause': StructuredMessageArgument.outcome('invalid-machine'),
      },
    );

    for (final message in [wrongKind, extraArgument]) {
      expect(
        en.resolveStructuredMessage(message),
        en.structuredMessageUnknown(message.stableCode),
      );
      expect(
        pt.resolveStructuredMessage(message),
        pt.structuredMessageUnknown(message.stableCode),
      );
    }
  });
}

StructuredMessage _failureMessage(
  String automaton, {
  Map<String, StructuredMessageArgument> extraArguments = const {},
}) => StructuredMessage(
  namespace: 'algorithm.fsa-determinizer',
  code: 'failed',
  category: StructuredMessageCategory.conversion,
  severity: StructuredMessageSeverity.error,
  arguments: {
    'automaton': StructuredMessageArgument.literal(
      automaton,
      role: 'automaton-label',
    ),
    ...extraArguments,
  },
);

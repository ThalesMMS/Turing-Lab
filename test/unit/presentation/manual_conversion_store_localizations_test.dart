import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  test('resolves malformed saved construction in English and Portuguese', () {
    final message = StructuredMessage(
      namespace: 'service',
      code: 'manual-conversion-store.malformed-payload',
      category: StructuredMessageCategory.conversion,
      severity: StructuredMessageSeverity.error,
    );

    expect(
      lookupAppLocalizations(
        const Locale('en'),
      ).resolveStructuredMessage(message),
      'The saved construction is malformed.',
    );
    expect(
      lookupAppLocalizations(
        const Locale('pt', 'BR'),
      ).resolveStructuredMessage(message),
      'A construção salva está malformada.',
    );
  });
}

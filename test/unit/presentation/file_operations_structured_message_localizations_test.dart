import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));
  StructuredMessage fileOperationMessage(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'service.file-operations',
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  test('file-operation fallback contracts resolve in both locales', () {
    final messages = <StructuredMessage>[
      for (final entry in const {
        'operation-failed': 'download',
        'access-denied': 'write',
        'location-missing': 'delete',
        'access-failed': 'read',
        'web-unsupported': 'exportPng',
      }.entries)
        fileOperationMessage(
          entry.key,
          arguments: {
            'operation': StructuredMessageArgument.outcome(
              entry.value,
              role: 'file-operation',
            ),
          },
        ),
      fileOperationMessage(
        'codec-unsupported',
        arguments: {
          'reason': StructuredMessageArgument.outcome(
            'feature',
            role: 'codec-unsupported-reason',
          ),
        },
      ),
      fileOperationMessage(
        'codec-ambiguous',
        arguments: {
          'count': StructuredMessageArgument.count(2, role: 'codec-count'),
        },
      ),
      fileOperationMessage(
        'codec-malformed',
        arguments: {
          'reason': StructuredMessageArgument.outcome(
            'invalidUtf8',
            role: 'codec-malformed-reason',
          ),
        },
      ),
      fileOperationMessage(
        'codec-resource-limit',
        arguments: {
          'limit': StructuredMessageArgument.outcome(
            'xmlDepth',
            role: 'codec-resource-limit',
          ),
          'maximum': StructuredMessageArgument.bound(64),
          'actual': StructuredMessageArgument.count(65),
        },
      ),
      fileOperationMessage(
        'codec-internal-failure',
        arguments: {
          'stage': StructuredMessageArgument.outcome(
            'decode',
            role: 'codec-stage',
          ),
        },
      ),
      fileOperationMessage('interoperability-review-required'),
      fileOperationMessage('lossy-export-requires-confirmation'),
      fileOperationMessage('invalid-model-type'),
    ];

    for (final message in messages) {
      final english = en.resolveStructuredMessage(message);
      final portuguese = pt.resolveStructuredMessage(message);

      expect(english, isNot(contains(message.stableCode)));
      expect(portuguese, isNot(contains(message.stableCode)));
      expect(english, isNot(portuguese));
      expect(
        StructuredMessage.fromJson(message.toJson()),
        message,
        reason: message.stableCode,
      );
    }
  });

  test('invalid file-operation contract uses the safe coded fallback', () {
    final malformed = fileOperationMessage(
      'codec-ambiguous',
      arguments: {
        'count': StructuredMessageArgument.integer(2, role: 'codec-count'),
      },
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

  test('future operation values use localized other branches', () {
    final message = fileOperationMessage(
      'operation-failed',
      arguments: {
        'operation': StructuredMessageArgument.outcome(
          'futureOperation',
          role: 'file-operation',
        ),
      },
    );

    expect(
      en.resolveStructuredMessage(message),
      'The file operation could not be completed.',
    );
    expect(
      pt.resolveStructuredMessage(message),
      'Não foi possível concluir a operação de arquivo.',
    );
  });

  test('missing operation argument fails closed', () {
    final malformed = fileOperationMessage('operation-failed');

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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('file-operation fallback contracts resolve in both locales', () {
    final messages = <StructuredMessage>[
      for (final entry in const {
        'operation-failed': 'download',
        'access-denied': 'write',
        'location-missing': 'delete',
        'access-failed': 'read',
        'web-unsupported': 'exportPng',
      }.entries)
        _message(
          entry.key,
          arguments: {
            'operation': StructuredMessageArgument.outcome(
              entry.value,
              role: 'file-operation',
            ),
          },
        ),
      _message(
        'codec-unsupported',
        arguments: {
          'reason': StructuredMessageArgument.outcome(
            'feature',
            role: 'codec-unsupported-reason',
          ),
        },
      ),
      _message(
        'codec-ambiguous',
        arguments: {
          'count': StructuredMessageArgument.count(2, role: 'codec-count'),
        },
      ),
      _message(
        'codec-malformed',
        arguments: {
          'reason': StructuredMessageArgument.outcome(
            'invalidUtf8',
            role: 'codec-malformed-reason',
          ),
        },
      ),
      _message(
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
      _message(
        'codec-internal-failure',
        arguments: {
          'stage': StructuredMessageArgument.outcome(
            'decode',
            role: 'codec-stage',
          ),
        },
      ),
      _message('interoperability-review-required'),
      _message('lossy-export-requires-confirmation'),
      _message('invalid-model-type'),
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
    final malformed = _message(
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
    final message = _message(
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
    final malformed = _message('operation-failed');

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

StructuredMessage _message(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'service.file-operations',
  code: code,
  category: StructuredMessageCategory.interoperability,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

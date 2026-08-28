import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the PDA JFLAP XML codec.
///
/// The codec keeps its legacy message and diagnostic-code fields for callers
/// that still consume them. Presentation code should resolve these payloads
/// from the active locale instead of displaying those compatibility fields.
abstract final class PdaJflapMessages {
  static const namespace = 'codec.pda-jflap';

  static StructuredMessage invalidUtf8() => _malformed('invalid-utf8');

  static StructuredMessage malformedXml() => _malformed('malformed-xml');

  static StructuredMessage invalidRoot() => _malformed('invalid-root');

  static StructuredMessage unsupportedDocumentType(String type) => _unsupported(
    'unsupported-document-type',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'document-type'),
    },
  );

  static StructuredMessage missingAutomaton() =>
      _malformed('missing-automaton');

  static StructuredMessage missingStateId() => _malformed('missing-state-id');

  static StructuredMessage duplicateStateId(String stateId) => _malformed(
    'duplicate-state-id',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage invalidStateCoordinate(String stateId) => _malformed(
    'invalid-state-coordinate',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage invalidDocument() => _malformed('invalid-document');

  static StructuredMessage unknownTransitionEndpoints({
    required String? from,
    required String? to,
  }) => _malformed(
    'unknown-transition-endpoints',
    arguments: {
      if (from != null)
        'from': StructuredMessageArgument.identifier(
          from,
          role: 'source-state',
        ),
      if (to != null)
        'to': StructuredMessageArgument.identifier(to, role: 'target-state'),
    },
  );

  static StructuredMessage invalidTransitionId() =>
      _malformed('invalid-transition-id');

  static StructuredMessage duplicateTransitionId() =>
      _malformed('duplicate-transition-id');

  static StructuredMessage invalidAcceptanceMode() =>
      _malformed('invalid-acceptance-mode');

  static StructuredMessage malformedExtension() =>
      _malformed('malformed-extension');

  static StructuredMessage canonicalOrderImport() =>
      _information('canonical-order-import');

  static StructuredMessage staleTokenExtension() =>
      _warning('stale-token-extension');

  static StructuredMessage explicitEpsilonAliasInterpreted() =>
      _warning('explicit-epsilon-alias-interpreted');

  static StructuredMessage popWordTreatedAsAtomicToken() =>
      _warning('pop-word-treated-as-atomic-token');

  static StructuredMessage acceptanceModeAssumedFinalState() =>
      _information('acceptance-mode-assumed-final-state');

  static StructuredMessage requiresPdaDocument() =>
      _unsupported('requires-pda-document');

  static StructuredMessage unsupportedSchema(int version) => _unsupported(
    'unsupported-schema',
    arguments: {
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage extensionPortability() =>
      _warning('extension-portability');

  static StructuredMessage initialStackSymbolNotPortable() =>
      _warning('initial-stack-symbol-not-portable');

  static StructuredMessage acceptanceModeNotPortable() =>
      _warning('acceptance-mode-not-portable');

  static StructuredMessage atomicPopTokenNotPortable() =>
      _warning('atomic-pop-token-not-portable');

  static StructuredMessage atomicPushTokenNotPortable() =>
      _warning('atomic-push-token-not-portable');

  static StructuredMessage unknownOptionalElement(String key) => _information(
    'unknown-optional-element',
    arguments: {
      'extension': StructuredMessageArgument.literal(
        key,
        role: 'extension-key',
      ),
    },
  );

  static StructuredMessage unknownOptionalAttribute(String key) => _information(
    'unknown-optional-attribute',
    arguments: {
      'extension': StructuredMessageArgument.literal(
        key,
        role: 'extension-key',
      ),
    },
  );

  static StructuredMessage invalidNotePosition() =>
      _warning('invalid-note-position');

  static StructuredMessage notesNormalized() =>
      _information('notes-normalized');

  static StructuredMessage notePresentationDropped() =>
      _warning('note-presentation-dropped');

  static StructuredMessage unknownDiagnostic() =>
      _information('unknown-diagnostic');

  static StructuredMessage _malformed(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(code, arguments: arguments);

  static StructuredMessage _unsupported(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(code, arguments: arguments);

  static StructuredMessage _warning(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.warning,
    arguments: arguments,
  );

  static StructuredMessage _information(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: severity,
    arguments: arguments,
  );
}

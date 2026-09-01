import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the Grammar JFLAP XML codec.
///
/// The codec keeps its legacy message and diagnostic-code fields for callers
/// that still consume them. Presentation code should resolve these payloads
/// from the active locale instead of displaying those compatibility fields.
abstract final class GrammarJflapMessages {
  static const namespace = 'codec.grammar-jflap';

  static StructuredMessage unsupportedDocumentType(String type) => _error(
    'unsupported-document-type',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'document-type'),
    },
  );

  static StructuredMessage emptyGrammar() => _error('empty-grammar');

  static StructuredMessage missingProductionSide(int index) => _error(
    'missing-production-side',
    arguments: {
      'index': StructuredMessageArgument.index(index, role: 'production-index'),
    },
  );

  static StructuredMessage startSymbolUndetermined() =>
      _error('start-symbol-undetermined');

  static StructuredMessage unknownGrammarTypePreserved(String type) => _warning(
    'unknown-grammar-type-preserved',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'grammar-type'),
    },
  );

  static StructuredMessage unknownOptionalElement(String key) => _information(
    'unknown-optional-element',
    arguments: {
      'extension': StructuredMessageArgument.literal(
        key,
        role: 'extension-key',
      ),
    },
  );

  static StructuredMessage tokenizationNormalized() =>
      _information('tokenization-normalized');

  static StructuredMessage requiresGrammarDocument() =>
      _error('requires-grammar-document');

  static StructuredMessage unsupportedSchema(int version) => _error(
    'unsupported-schema',
    arguments: {
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage invalidDocument() => _error('invalid-document');

  static StructuredMessage tokenBoundariesLossy(String tokens) => _warning(
    'token-boundaries-lossy',
    arguments: {
      'tokens': StructuredMessageArgument.literal(tokens, role: 'token-list'),
    },
  );

  static StructuredMessage classificationLossy(String classification) =>
      _warning(
        'classification-lossy',
        arguments: {
          'classification': StructuredMessageArgument.literal(
            classification,
            role: 'grammar-classification',
          ),
        },
      );

  static StructuredMessage startOrderNormalized() =>
      _information('start-order-normalized');

  static StructuredMessage _error(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

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
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: StructuredMessageCategory.interoperability,
    severity: severity,
    arguments: arguments,
  );
}

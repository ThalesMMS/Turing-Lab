import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the L-system JFLAP XML codec.
///
/// The codec keeps its legacy message and diagnostic-code fields for callers
/// that still consume them. Presentation code should resolve these payloads
/// from the active locale instead of displaying those compatibility fields.
abstract final class LSystemJflapMessages {
  static const namespace = 'codec.l-system-jflap';

  static StructuredMessage invalidRoot() => _error('invalid-root');

  static StructuredMessage unsupportedDocumentType(String type) => _error(
    'unsupported-document-type',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'document-type'),
    },
  );

  static StructuredMessage missingAxiom() => _error('missing-axiom');

  static StructuredMessage malformedXml() => _error('malformed-xml');

  static StructuredMessage invalidUtf8() => _error('invalid-utf8');

  static StructuredMessage emptyPredecessor() => _error('empty-predecessor');

  static StructuredMessage invalidContextPredecessor(String production) =>
      _error(
        'invalid-context-predecessor',
        arguments: {
          'production': StructuredMessageArgument.literal(
            production,
            role: 'production-left',
          ),
        },
      );

  static StructuredMessage invalidParameter({
    required String name,
    String? value,
  }) => _error(
    'invalid-parameter',
    arguments: {
      'parameter': StructuredMessageArgument.literal(
        name,
        role: 'parameter-name',
      ),
      if (value != null)
        'value': StructuredMessageArgument.literal(
          value,
          role: 'parameter-value',
        ),
    },
  );

  static StructuredMessage invalidExtension(String name) => _error(
    'invalid-extension',
    arguments: {
      'extension': StructuredMessageArgument.literal(
        name,
        role: 'extension-key',
      ),
    },
  );

  static StructuredMessage invalidProductionMetadata(String field) => _error(
    'invalid-production-metadata',
    arguments: {
      'field': StructuredMessageArgument.literal(field, role: 'metadata-field'),
    },
  );

  static StructuredMessage invalidCommandMapping() => _error(
    'invalid-command-mapping',
    arguments: {
      'parameter': StructuredMessageArgument.literal(
        'turingLabCommandMapping',
        role: 'parameter-name',
      ),
    },
  );

  static StructuredMessage invalidDocument() => _error('invalid-document');

  static StructuredMessage requiresLSystemDocument() =>
      _error('requires-l-system-document');

  static StructuredMessage unsupportedSchema(int version) => _error(
    'unsupported-schema',
    arguments: {
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage decodeFailed() => _error('decode-failed');

  static StructuredMessage encodeFailed() => _error('encode-failed');

  static StructuredMessage advancedVariantPreserved({
    String variants = 'parametric',
  }) => _warning(
    'advanced-variant-preserved',
    arguments: {
      'variants': StructuredMessageArgument.literal(
        variants,
        role: 'unsupported-variant-list',
      ),
    },
  );

  static StructuredMessage parametersPreserved(String parameters) =>
      _information(
        'parameters-preserved',
        arguments: {
          'parameters': StructuredMessageArgument.literal(
            parameters,
            role: 'parameter-list',
          ),
        },
      );

  static StructuredMessage executionExtensionRestored({
    String features =
        'production-metadata, random-seed, ignored-context-symbols',
  }) => _information(
    'execution-extension-restored',
    arguments: {
      'features': StructuredMessageArgument.literal(
        features,
        role: 'extension-feature-list',
      ),
    },
  );

  static StructuredMessage elementsPreserved() =>
      _information('elements-preserved');

  static StructuredMessage executionExtension({
    String features = 'random-seed, ignored-context-symbols, weighted-choices',
  }) => _warning(
    'execution-extension',
    arguments: {
      'features': StructuredMessageArgument.literal(
        features,
        role: 'extension-feature-list',
      ),
    },
  );

  static StructuredMessage advancedVariantExtension({
    String variants = 'parametric, stochastic, contextSensitive',
  }) => _warning(
    'advanced-variant-extension',
    arguments: {
      'variants': StructuredMessageArgument.literal(
        variants,
        role: 'unsupported-variant-list',
      ),
    },
  );

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

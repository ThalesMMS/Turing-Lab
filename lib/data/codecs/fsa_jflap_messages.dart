import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the FSA JFLAP XML codec.
///
/// The codec keeps its legacy message and diagnostic-code fields for callers
/// that still consume them. Presentation code should resolve these payloads
/// from the active locale instead of displaying those compatibility fields.
abstract final class FsaJflapMessages {
  static const namespace = 'codec.fsa-jflap';

  static StructuredMessage invalidRoot() => _malformed('invalid-root');

  static StructuredMessage unsupportedDocumentType(String type) => _unsupported(
    'unsupported-document-type',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'document-type'),
    },
  );

  static StructuredMessage buildingBlocksUnsupported() =>
      _unsupported('building-blocks-unsupported');

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

  static StructuredMessage multipleInitialStates() =>
      _unsupported('multiple-initial-states');

  static StructuredMessage invalidDocument() => _malformed('invalid-document');

  static StructuredMessage unsupportedSchema(int version) => _unsupported(
    'unsupported-schema',
    arguments: {
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage requiresFsaDocument() =>
      _unsupported('requires-fsa-document');

  static StructuredMessage canonicalOrderImport() =>
      _information('canonical-order-import');

  static StructuredMessage canonicalOrderExport() =>
      _information('canonical-order-export');

  static StructuredMessage stateTypeDropped(String stateId) => _warning(
    'state-type-dropped',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage statePropertiesDropped(String stateId) => _warning(
    'state-properties-dropped',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage transitionControlPointDropped({
    required String transitionId,
    required num x,
    required num y,
  }) => _warning(
    'transition-control-point-dropped',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'control-point': StructuredMessageArgument.coordinate(x: x, y: y),
    },
  );

  static StructuredMessage transitionDisplayLabelDropped({
    required String transitionId,
    required String label,
  }) => _warning(
    'transition-display-label-dropped',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'label': StructuredMessageArgument.literal(
        label,
        role: 'transition-label',
      ),
    },
  );

  static StructuredMessage explicitEpsilonAliasInterpreted(String symbol) =>
      _warning(
        'explicit-epsilon-alias-interpreted',
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            symbol,
            role: 'input-symbol',
          ),
        },
      );

  static StructuredMessage explicitEpsilonAliasExported({
    required String transitionId,
    required String aliases,
  }) => _warning(
    'explicit-epsilon-alias-exported-empty',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'aliases': StructuredMessageArgument.literal(
        aliases,
        role: 'epsilon-aliases',
      ),
    },
  );

  static StructuredMessage multiSymbolTransitionExpanded({
    required String transitionId,
    required int symbolCount,
  }) => _information(
    'multi-symbol-transition-expanded',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'count': StructuredMessageArgument.count(
        symbolCount,
        role: 'symbol-count',
      ),
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

  static StructuredMessage unknownOptionalAttribute(String key) => _information(
    'unknown-optional-attribute',
    arguments: {
      'extension': StructuredMessageArgument.literal(
        key,
        role: 'extension-key',
      ),
    },
  );

  static StructuredMessage _malformed(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.interoperability,
    arguments: arguments,
  );

  static StructuredMessage _unsupported(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.interoperability,
    arguments: arguments,
  );

  static StructuredMessage _warning(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.interoperability,
    severity: StructuredMessageSeverity.warning,
    arguments: arguments,
  );

  static StructuredMessage _information(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.interoperability,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}

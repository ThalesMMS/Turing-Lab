import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the Mealy JFLAP XML codec.
///
/// The codec keeps its legacy message and diagnostic-code fields for callers
/// that still consume them. Presentation code should resolve these payloads
/// from the active locale instead of displaying those compatibility fields.
abstract final class MealyJflapMessages {
  static const namespace = 'codec.mealy-jflap';

  static StructuredMessage invalidRoot() => _error('invalid-root');

  static StructuredMessage unsupportedDocumentType(String type) => _error(
    'unsupported-document-type',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'document-type'),
    },
  );

  static StructuredMessage missingAutomaton() => _error('missing-automaton');

  static StructuredMessage missingStateId() => _error('missing-state-id');

  static StructuredMessage duplicateStateId(String stateId) => _error(
    'duplicate-state-id',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage invalidStateCoordinate(String stateId) => _error(
    'invalid-state-coordinate',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage emptyAutomaton() => _error('empty-automaton');

  static StructuredMessage invalidInitialStateCount(int count) => _error(
    'invalid-initial-state-count',
    arguments: {
      'count': StructuredMessageArgument.count(count, role: 'initial-count'),
    },
  );

  static StructuredMessage unknownTransitionEndpoints({
    required int index,
    String? from,
    String? to,
  }) => _error(
    'unknown-transition-endpoints',
    arguments: {
      'index': StructuredMessageArgument.index(index, role: 'transition-index'),
      if (from != null && from.isNotEmpty)
        'from': StructuredMessageArgument.identifier(
          from,
          role: 'source-state',
        ),
      if (to != null && to.isNotEmpty)
        'to': StructuredMessageArgument.identifier(to, role: 'target-state'),
    },
  );

  static StructuredMessage emptyInputSymbol(int index) => _error(
    'empty-input-symbol',
    arguments: {
      'index': StructuredMessageArgument.index(index, role: 'transition-index'),
    },
  );

  static StructuredMessage duplicateTransitionInput({
    required String input,
    required String state,
  }) => _error(
    'duplicate-transition-input',
    arguments: {
      'input': StructuredMessageArgument.symbol(input, role: 'input-symbol'),
      'state': StructuredMessageArgument.identifier(state, role: 'state-id'),
    },
  );

  static StructuredMessage stableTransitionIdCollision() =>
      _error('stable-transition-id-collision');

  static StructuredMessage invalidUtf8() => _error('invalid-utf8');

  static StructuredMessage malformedXml() => _error('malformed-xml');

  static StructuredMessage requiresMealyDocument() =>
      _error('requires-mealy-document');

  static StructuredMessage unsupportedSchema({
    required String schemaId,
    required int version,
  }) => _error(
    'unsupported-schema',
    arguments: {
      'schema': StructuredMessageArgument.literal(schemaId, role: 'schema-id'),
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage invalidDocument(String diagnostic) => _error(
    'invalid-document',
    arguments: {
      'diagnostic': StructuredMessageArgument.outcome(
        diagnostic,
        role: 'validation-code',
      ),
    },
  );

  static StructuredMessage transitionIdsDerived() =>
      _information('transition-ids-derived');

  static StructuredMessage canonicalOrder() => _information('canonical-order');

  static StructuredMessage machineIdentityNotPortable() =>
      _information('machine-identity-not-portable');

  static StructuredMessage transitionIdentitiesNotPortable() =>
      _information('transition-identities-not-portable');

  static StructuredMessage unusedAlphabetSymbolsDropped({
    required String inputSymbols,
    required String outputSymbols,
  }) => _warning(
    'unused-alphabet-symbols-dropped',
    arguments: {
      'input': StructuredMessageArgument.literal(
        inputSymbols,
        role: 'input-symbol-list',
      ),
      'output': StructuredMessageArgument.literal(
        outputSymbols,
        role: 'output-symbol-list',
      ),
    },
  );

  static StructuredMessage outputTokenBoundariesDropped({
    required String transitionId,
    required String tokens,
  }) => _warning(
    'output-token-boundaries-dropped',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'tokens': StructuredMessageArgument.literal(
        tokens,
        role: 'output-token-list',
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

  static StructuredMessage _error(
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

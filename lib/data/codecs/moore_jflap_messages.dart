import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the Moore JFLAP XML codec.
///
/// The codec keeps its legacy message and diagnostic-code fields for callers
/// that still consume them. Presentation code should resolve these payloads
/// from the active locale instead of displaying those compatibility fields.
abstract final class MooreJflapMessages {
  static const namespace = 'codec.moore-jflap';

  static StructuredMessage invalidRoot() => _error('invalid-root');

  static StructuredMessage unsupportedDocumentType(String type) => _error(
    'unsupported-document-type',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'document-type'),
    },
  );

  static StructuredMessage missingAutomaton() => _error('missing-automaton');

  static StructuredMessage finalStatesUnsupported() =>
      _error('final-states-unsupported');

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

  static StructuredMessage invalidOutputTokenMetadata(String stateId) => _error(
    'invalid-output-token-metadata',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage outputTokenVectorRestored({
    required String stateId,
    required String tokens,
  }) => _information(
    'output-token-vector-restored',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
      'tokens': StructuredMessageArgument.literal(
        tokens,
        role: 'output-token-list',
      ),
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

  static StructuredMessage duplicateTransition({
    required String from,
    required String input,
    required String to,
  }) => _error(
    'duplicate-transition',
    arguments: {
      'from': StructuredMessageArgument.identifier(from, role: 'source-state'),
      'input': StructuredMessageArgument.symbol(input, role: 'input-symbol'),
      'to': StructuredMessageArgument.identifier(to, role: 'target-state'),
    },
  );

  static StructuredMessage nondeterministicTransition({
    required String state,
    required String input,
  }) => _error(
    'nondeterministic-transition',
    arguments: {
      'state': StructuredMessageArgument.identifier(state, role: 'state-id'),
      'input': StructuredMessageArgument.symbol(input, role: 'input-symbol'),
    },
  );

  static StructuredMessage stableTransitionIdCollision() =>
      _error('stable-transition-id-collision');

  static StructuredMessage conflictingTransitionOutputPreserved({
    required String transitionId,
    required String actual,
    required String expected,
  }) => _warning(
    'conflicting-transition-output-preserved',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'actual': StructuredMessageArgument.literal(
        actual,
        role: 'transition-output',
      ),
      'expected': StructuredMessageArgument.literal(
        expected,
        role: 'state-output',
      ),
    },
  );

  static StructuredMessage invalidUtf8() => _error('invalid-utf8');

  static StructuredMessage malformedXml() => _error('malformed-xml');

  static StructuredMessage invalidDocument(String diagnostic) => _error(
    'invalid-document',
    arguments: {
      'diagnostic': StructuredMessageArgument.outcome(
        diagnostic,
        role: 'validation-code',
      ),
    },
  );

  static StructuredMessage requiresMooreDocument() =>
      _error('requires-moore-document');

  static StructuredMessage unsupportedSchema(int version) => _error(
    'unsupported-schema',
    arguments: {
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage outputTokenVectorPreserved({
    required String stateId,
    required String tokens,
  }) => _information(
    'output-token-vector-preserved',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
      'tokens': StructuredMessageArgument.literal(
        tokens,
        role: 'output-token-list',
      ),
    },
  );

  static StructuredMessage conflictingTransitionOutputNormalized({
    required String transitionId,
    required String output,
  }) => _warning(
    'conflicting-transition-output-normalized',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'output': StructuredMessageArgument.literal(
        output,
        role: 'transition-output',
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

import '../../core/messages/structured_message.dart';

/// Locale-neutral messages emitted by the TM JFLAP XML codec.
///
/// The codec keeps its legacy message and diagnostic-code fields for callers
/// that still consume them. Presentation code should resolve these payloads
/// from the active locale instead of displaying those compatibility fields.
abstract final class TmJflapMessages {
  static const namespace = 'codec.tm-jflap';

  static StructuredMessage invalidUtf8() => _malformed('invalid-utf8');

  static StructuredMessage malformedXml() => _malformed('malformed-xml');

  static StructuredMessage invalidRoot() => _malformed('invalid-root');

  static StructuredMessage unsupportedDocumentType(String type) => _unsupported(
    'unsupported-document-type',
    arguments: {
      'type': StructuredMessageArgument.literal(type, role: 'document-type'),
    },
  );

  static StructuredMessage unsupportedFeature() =>
      _unsupported('unsupported-feature');

  static StructuredMessage invalidTapeCount() =>
      _malformed('invalid-tape-count');

  static StructuredMessage missingAutomaton() =>
      _malformed('missing-automaton');

  static StructuredMessage malformedExtension() =>
      _malformed('malformed-extension');

  static StructuredMessage canonicalOrderImport() =>
      _information('canonical-order-import');

  static StructuredMessage canonicalOrderExport() =>
      _information('canonical-order-export');

  static StructuredMessage variantMismatch() => _malformed('variant-mismatch');

  static StructuredMessage tapeCountMismatch() =>
      _malformed('tape-count-mismatch');

  static StructuredMessage blankSymbolInvalid() =>
      _malformed('blank-symbol-invalid');

  static StructuredMessage acceptancePolicyInvalid() =>
      _malformed('acceptance-policy-invalid');

  static StructuredMessage incompleteExtension() =>
      _information('incomplete-extension');

  static StructuredMessage extensionSchemaInvalid() =>
      _malformed('extension-schema-invalid');

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

  static StructuredMessage invalidStateType(String stateId) => _malformed(
    'invalid-state-type',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage invalidStateProperties(String stateId) => _malformed(
    'invalid-state-properties',
    arguments: {
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage invalidInitialStateCount() =>
      _malformed('invalid-initial-state-count');

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

  static StructuredMessage invalidTapeIndex() =>
      _malformed('invalid-tape-index');

  static StructuredMessage duplicateTapeOperation(String operation) =>
      _malformed(
        'duplicate-tape-operation',
        arguments: {
          'operation': StructuredMessageArgument.literal(
            operation,
            role: 'operation-name',
          ),
        },
      );

  static StructuredMessage unsupportedReadPredicate() =>
      _unsupported('unsupported-read-predicate');

  static StructuredMessage invalidReadSymbol() =>
      _malformed('invalid-read-symbol');

  static StructuredMessage invalidWriteSymbol() =>
      _malformed('invalid-write-symbol');

  static StructuredMessage invalidMove() => _malformed('invalid-move');

  static StructuredMessage invalidTransitionExtension() =>
      _malformed('invalid-transition-extension');

  static StructuredMessage invalidTransitionId() =>
      _malformed('invalid-transition-id');

  static StructuredMessage duplicateTransitionId() =>
      _malformed('duplicate-transition-id');

  static StructuredMessage invalidTransitionLabel(String transitionId) =>
      _malformed(
        'invalid-transition-label',
        arguments: {
          'transition': StructuredMessageArgument.identifier(
            transitionId,
            role: 'transition-id',
          ),
        },
      );

  static StructuredMessage invalidTransitionType(String transitionId) =>
      _malformed(
        'invalid-transition-type',
        arguments: {
          'transition': StructuredMessageArgument.identifier(
            transitionId,
            role: 'transition-id',
          ),
        },
      );

  static StructuredMessage invalidControlPoint() =>
      _malformed('invalid-control-point');

  static StructuredMessage transitionIdentitiesReconstructed() =>
      _information('transition-identities-reconstructed');

  static StructuredMessage invalidMetadata() => _malformed('invalid-metadata');

  static StructuredMessage invalidDocument() => _malformed('invalid-document');

  static StructuredMessage requiresTmDocument() =>
      _unsupported('requires-tm-document');

  static StructuredMessage unsupportedSchema(int version) => _unsupported(
    'unsupported-schema',
    arguments: {
      'version': StructuredMessageArgument.integer(
        version,
        role: 'schema-version',
      ),
    },
  );

  static StructuredMessage unsupportedTapeCount() =>
      _unsupported('unsupported-tape-count');

  static StructuredMessage unsupportedOperation({
    required String transitionId,
    required String operation,
    required String symbol,
  }) => _unsupported(
    'unsupported-operation',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'operation': StructuredMessageArgument.literal(
        operation,
        role: 'operation-name',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'tape-symbol'),
    },
  );

  static StructuredMessage buildingBlockVariantMismatch() =>
      _malformed('building-block-variant-mismatch');

  static StructuredMessage recursiveDependency(String tag) => _malformed(
    'recursive-dependency',
    arguments: {
      'block': StructuredMessageArgument.identifier(tag, role: 'block-tag'),
    },
  );

  static StructuredMessage missingBlockDefinition(String tag) => _malformed(
    'missing-block-definition',
    arguments: {
      'block': StructuredMessageArgument.identifier(tag, role: 'block-tag'),
    },
  );

  static StructuredMessage ambiguousBlockDefinition(String tag) => _malformed(
    'ambiguous-block-definition',
    arguments: {
      'block': StructuredMessageArgument.identifier(tag, role: 'block-tag'),
    },
  );

  static StructuredMessage acceptancePolicyConflict() =>
      _malformed('acceptance-policy-conflict');

  static StructuredMessage machineSchemaInvalid() =>
      _malformed('machine-schema-invalid');

  static StructuredMessage machineVariantInvalid() =>
      _malformed('machine-variant-invalid');

  static StructuredMessage machineTapeCountMismatch() =>
      _malformed('machine-tape-count-mismatch');

  static StructuredMessage machineBlankSymbolMismatch() =>
      _malformed('machine-blank-symbol-mismatch');

  static StructuredMessage missingBlockTag(String blockId) => _malformed(
    'missing-block-tag',
    arguments: {
      'block': StructuredMessageArgument.identifier(blockId, role: 'block-id'),
    },
  );

  static StructuredMessage invalidNodeId() => _malformed('invalid-node-id');

  static StructuredMessage duplicateNodeId() => _malformed('duplicate-node-id');

  static StructuredMessage invalidNodeCoordinate(String nodeId) => _malformed(
    'invalid-node-coordinate',
    arguments: {
      'node': StructuredMessageArgument.identifier(nodeId, role: 'node-id'),
    },
  );

  static StructuredMessage invalidNodeStateType(String nodeId) => _malformed(
    'invalid-node-state-type',
    arguments: {
      'node': StructuredMessageArgument.identifier(nodeId, role: 'node-id'),
    },
  );

  static StructuredMessage invalidNodeProperties(String nodeId) => _malformed(
    'invalid-node-properties',
    arguments: {
      'node': StructuredMessageArgument.identifier(nodeId, role: 'node-id'),
    },
  );

  static StructuredMessage missingBlockTagReference(String blockId) =>
      _malformed(
        'missing-block-tag-reference',
        arguments: {
          'block': StructuredMessageArgument.identifier(
            blockId,
            role: 'block-id',
          ),
        },
      );

  static StructuredMessage invalidOrDuplicateTapeIndex() =>
      _malformed('invalid-or-duplicate-tape-index');

  static StructuredMessage transitionIdentityConflict() =>
      _malformed('transition-identity-conflict');

  static StructuredMessage buildingBlocksImported() =>
      _information('building-blocks-imported');

  static StructuredMessage sharedTapes() => _information('shared-tapes');

  static StructuredMessage unknownBuildingBlockExtensionDropped() =>
      _warning('unknown-building-block-extension-dropped');

  static StructuredMessage buildingBlocksExported() =>
      _information('building-blocks-exported');

  static StructuredMessage extensionIdentities() =>
      _warning('extension-identities');

  static StructuredMessage extensionPortability() =>
      _warning('extension-portability');

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

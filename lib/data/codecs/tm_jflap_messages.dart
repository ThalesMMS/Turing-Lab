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

  /// Maps the remaining validation exceptions raised by the XML helpers.
  ///
  /// The mapper is intentionally conservative. It only recognizes exact
  /// compatibility phrases and falls back to [invalidDocument] so a new
  /// message cannot accidentally become a translated string.
  static StructuredMessage malformedFromLegacy(String message) {
    if (message.contains('tape count must be between 1 and 5')) {
      return invalidTapeCount();
    }
    if (message.contains('TM is missing <automaton>')) {
      return missingAutomaton();
    }
    if (message.contains('variant does not match the building-block XML')) {
      return buildingBlockVariantMismatch();
    }
    if (message.contains('tape count does not match <tapes>')) {
      return tapeCountMismatch();
    }
    if (message.contains('root and machine acceptance policies conflict')) {
      return acceptancePolicyConflict();
    }
    if (message.contains(
      'building-block machine has an invalid Turing Lab schema',
    )) {
      return machineSchemaInvalid();
    }
    if (message.contains('building-block machine has an invalid TM variant')) {
      return machineVariantInvalid();
    }
    if (message.contains(
      'building-block machine has a mismatched tape count',
    )) {
      return machineTapeCountMismatch();
    }
    if (message.contains(
      'building-block machine has a mismatched blank symbol',
    )) {
      return machineBlankSymbolMismatch();
    }
    if (message.contains('state and block ids must be non-empty and unique')) {
      return invalidNodeId();
    }
    if (message.contains('node ') && message.contains('invalid coordinates')) {
      return invalidNodeCoordinate(_quotedValue(message, 'node'));
    }
    if (message.contains('node ') && message.contains('invalid state type')) {
      return invalidNodeStateType(_quotedValue(message, 'node'));
    }
    if (message.contains('node ') &&
        message.contains('invalid state properties')) {
      return invalidNodeProperties(_quotedValue(message, 'node'));
    }
    if (message.contains('has no <tag> reference')) {
      return missingBlockTagReference(_quotedValue(message, 'building block'));
    }
    if (message.contains('invalid or duplicate tape index')) {
      return invalidOrDuplicateTapeIndex();
    }
    if (message.contains('read symbols must contain')) {
      return invalidReadSymbol();
    }
    if (message.contains('write symbols must contain')) {
      return invalidWriteSymbol();
    }
    if (message.contains('movement must be L, R, or S')) {
      return invalidMove();
    }
    if (message.contains('transition identity extensions disagree')) {
      return transitionIdentityConflict();
    }
    if (message.contains('transition ids must be unique')) {
      return duplicateTransitionId();
    }
    if (message.contains('transition ') && message.contains('invalid label')) {
      return invalidTransitionLabel(_quotedValue(message, 'transition'));
    }
    if (message.contains('transition ') && message.contains('invalid type')) {
      return invalidTransitionType(_quotedValue(message, 'transition'));
    }
    if (message.contains('invalid Turing Lab id')) {
      return invalidTransitionId();
    }
    if (message.contains('requires states and one initial')) {
      return invalidInitialStateCount();
    }
    if (message.contains('state ids must be non-empty and unique')) {
      return missingStateId();
    }
    if (message.contains('state ') && message.contains('invalid coordinates')) {
      return invalidStateCoordinate(_quotedValue(message, 'state'));
    }
    if (message.contains('transition endpoints')) {
      return unknownTransitionEndpoints(from: null, to: null);
    }
    if (message.contains('transition ids must be non-empty and unique')) {
      return invalidTransitionId();
    }
    if (message.contains('acceptance mode is invalid')) {
      return invalidAcceptancePolicy();
    }
    if (message.contains('Malformed Turing Lab')) {
      return malformedExtension();
    }
    return invalidDocument();
  }

  static StructuredMessage unsupportedFromLegacy(String message) {
    if (message.contains('wildcard, negated, and variable')) {
      return unsupportedReadPredicate();
    }
    if (message.contains('supports Turing machines with 1 to 5 tapes')) {
      return unsupportedTapeCount();
    }
    return _unsupported('unsupported-feature');
  }

  static String _quotedValue(String message, String prefix) {
    final start = message.indexOf(prefix);
    if (start < 0) return 'unknown';
    final value = message.substring(start + prefix.length).trim();
    return value.split(' ').first;
  }

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

  static StructuredMessage invalidAcceptancePolicy() =>
      _malformed('acceptance-policy-invalid');
}

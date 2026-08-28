import 'dart:convert';

import 'package:collection/collection.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/algorithms/tm_block_dependency_analyzer.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_acceptance.dart';
import '../../core/models/tm_building_blocks.dart';
import '../../core/models/tm_transition.dart';
import 'codec_utils.dart';
import 'tm_json_messages.dart';
import 'versioned_json_document_codec.dart';

/// Versioned Turing Lab JSON codec for single- and multi-tape machines.
final class TmJsonDocumentCodec implements DocumentCodecCapability<Object> {
  TmJsonDocumentCodec()
    : _delegate = VersionedJsonDocumentCodec(
        systemKey: DefaultFormalSystemIds.tm,
        schema: schema,
        codecId: const DocumentCodecId('tm.turing-lab-json.v1'),
        namespace: const CapabilityNamespaceId('codec.tm.turing-lab-json'),
        fixture: 'test/fixtures/interoperability/tm_multi_canonical.json',
        encodePayload: _encodePayload,
        decodePayload: _decodePayload,
        isLegacyPayload: _isLegacyPayload,
        knownPayloadFields: const {
          'id',
          'name',
          'type',
          'states',
          'transitions',
          'alphabet',
          'initialState',
          'acceptingStates',
          'created',
          'modified',
          'bounds',
          'zoomLevel',
          'panOffset',
          'tapeAlphabet',
          'blankSymbol',
          'tapeCount',
          'acceptancePolicy',
          'tmVariant',
          'blockDefinitions',
          'blockInvocations',
        },
        semanticCapabilities: {
          CodecSemanticCapabilityId.stateIds,
          CodecSemanticCapabilityId.stateNames,
          CodecSemanticCapabilityId.statePositions,
          CodecSemanticCapabilityId.stateLabels,
          CodecSemanticCapabilityId.initialStates,
          CodecSemanticCapabilityId.acceptingStates,
          CodecSemanticCapabilityId.transitionLabels,
          CodecSemanticCapabilityId.tapeOperations,
          CodecSemanticCapabilityId.tokenVectors,
          CodecSemanticCapabilityId.buildingBlocks,
          CodecSemanticCapabilityId.extensions,
        },
      );

  static const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.tm'),
    version: DocumentSchemaVersion(1),
  );

  final VersionedJsonDocumentCodec _delegate;

  @override
  CodecDescriptor get descriptor => _delegate.descriptor;

  @override
  CodecSniffResult sniff(DocumentPayload payload) => _delegate.sniff(payload);

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final outcome = _delegate.decode(payload);
    if (outcome is! CodecSuccess<InteroperableDocument<Object>>) return outcome;
    final machine = outcome.value.document;
    if (machine is! TM) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.decode,
        message: 'TM JSON decoder returned an unexpected document type.',
        structuredMessage: TmJsonMessages.unexpectedDocumentType(),
      );
    }
    final error = _firstValidationError(machine);
    if (error != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error,
        location: const CodecSourceLocation(path: r'$.document.payload'),
        structuredMessage: TmJsonMessages.invalidDocument(),
      );
    }
    final rawPayload = _documentPayload(payload);
    if (rawPayload == null) return outcome;
    final declaredVariant = rawPayload['tmVariant'];
    if (declaredVariant != null &&
        (declaredVariant is! String ||
            declaredVariant != machine.documentVariant.name)) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message:
            'TM variant does not match the tape count and building-block structure.',
        location: CodecSourceLocation(path: r'$.document.payload.tmVariant'),
        structuredMessage: TmJsonMessages.variantMismatch(),
      );
    }
    final diagnostics = <CodecDiagnostic>[...outcome.diagnostics];
    var normalized = false;
    if (declaredVariant == null) {
      normalized = true;
      diagnostics.add(
        CodecDiagnostic(
          code: 'json.tm-variant-inferred',
          message: 'The TM variant was inferred from its semantic structure.',
          path: r'$.document.payload.tmVariant',
          sourceValue: machine.documentVariant.name,
          structuredMessage: TmJsonMessages.variantInferred(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
    }
    if (_hasLegacyOperationShape(rawPayload)) {
      normalized = true;
      diagnostics.add(
        CodecDiagnostic(
          code: 'json.tm-operation-vectors-migrated',
          message:
              'Legacy scalar or partial tape operations were expanded into complete vectors.',
          path: r'$.document.payload.transitions',
          structuredMessage: TmJsonMessages.operationVectorsMigrated(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
    }
    if (_hasEmbeddedTransitionEndpoints(rawPayload)) {
      normalized = true;
      diagnostics.add(
        CodecDiagnostic(
          code: 'json.tm-endpoints-migrated-to-ids',
          message:
              'Embedded transition endpoint states were resolved through the canonical state map.',
          path: r'$.document.payload.transitions',
          structuredMessage: TmJsonMessages.endpointsMigratedToIds(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
    }
    if (!normalized) return outcome;
    return CodecSuccess(
      value: outcome.value,
      fidelity: outcome.fidelity == DocumentFidelity.lossy
          ? DocumentFidelity.lossy
          : DocumentFidelity.normalized,
      diagnostics: diagnostics,
    );
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    final machine = document.document;
    if (machine is TM) {
      final error = _firstValidationError(machine);
      if (error != null) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: error,
          location: const CodecSourceLocation(path: r'$.document'),
          structuredMessage: TmJsonMessages.invalidDocument(),
        );
      }
    }
    return _delegate.encode(document, filename: filename);
  }

  static Map<String, Object?> _encodePayload(Object document) {
    if (document is! TM) throw const FormatException('Expected a TM.');
    return _encodeMachine(document);
  }

  static Map<String, Object?> _encodeMachine(TM document) {
    final payload = Map<String, Object?>.from(document.toJson());
    if (document.acceptancePolicy == TMAcceptancePolicy.finalState) {
      payload.remove('acceptancePolicy');
    }
    payload['tmVariant'] = document.documentVariant.name;
    payload['alphabet'] = document.alphabet.toList()..sort();
    payload['tapeAlphabet'] = document.tapeAlphabet.toList()..sort();
    payload['states'] = document.states.map((state) => state.toJson()).toList()
      ..sort(
        (left, right) =>
            (left['id'] as String).compareTo(right['id'] as String),
      );
    payload['acceptingStates'] =
        document.acceptingStates.map((state) => state.toJson()).toList()..sort(
          (left, right) =>
              (left['id'] as String).compareTo(right['id'] as String),
        );
    payload['transitions'] =
        document.tmTransitions.map((transition) => transition.toJson()).toList()
          ..sort(
            (left, right) =>
                (left['id'] as String).compareTo(right['id'] as String),
          );
    payload['blockInvocations'] =
        document.blockInvocations
            .map((invocation) => invocation.toJson())
            .toList()
          ..sort(
            (left, right) =>
                (left['id'] as String).compareTo(right['id'] as String),
          );
    payload['blockDefinitions'] =
        document.blockDefinitions.values
            .map(
              (definition) => {
                'id': definition.id,
                'name': definition.name,
                'revision': definition.revision,
                'machine': _encodeMachine(definition.machine),
                'invocations':
                    definition.invocations
                        .map((invocation) => invocation.toJson())
                        .toList()
                      ..sort(
                        (left, right) => (left['id'] as String).compareTo(
                          right['id'] as String,
                        ),
                      ),
              },
            )
            .toList()
          ..sort(
            (left, right) =>
                (left['id'] as String).compareTo(right['id'] as String),
          );
    return payload;
  }

  static Object _decodePayload(Map<String, dynamic> payload) {
    try {
      final normalized = _normalizeMachinePayload(payload);
      _validateRawIdentities(normalized);
      return TM.fromJson(normalized);
    } on FormatException {
      rethrow;
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? error.toString());
    } on TypeError catch (error) {
      throw FormatException(error.toString());
    }
  }

  static bool _isLegacyPayload(Map<String, dynamic> payload) =>
      payload['type'] == 'TM' &&
      payload['states'] is List &&
      payload['transitions'] is List;

  static void _validateRawIdentities(Map<String, dynamic> payload) {
    final acceptancePolicy = payload['acceptancePolicy'];
    if (acceptancePolicy != null &&
        (acceptancePolicy is! String ||
            !TMAcceptancePolicy.values.any(
              (policy) => policy.name == acceptancePolicy,
            ))) {
      throw const FormatException('TM acceptancePolicy is invalid.');
    }
    final states = payload['states'];
    final transitions = payload['transitions'];
    if (states is! List || transitions is! List) {
      throw const FormatException('TM states and transitions must be arrays.');
    }
    void requireUniqueIds(List<Object?> values, String subject) {
      final ids = <String>{};
      for (final value in values) {
        if (value is! Map || value['id'] is! String) {
          throw FormatException('$subject entries require string ids.');
        }
        final id = value['id'] as String;
        if (id.isEmpty) {
          throw FormatException('$subject ids must be non-empty.');
        }
        if (!ids.add(id)) {
          throw FormatException('$subject ids must be unique.');
        }
      }
    }

    requireUniqueIds(states.cast<Object?>(), 'TM state');
    requireUniqueIds(transitions.cast<Object?>(), 'TM transition');
    final stateIds = {
      for (final state in states.cast<Map>()) state['id'] as String,
    };
    String endpointId(Object? value, String field) {
      final id = value is String
          ? value
          : value is Map && value['id'] is String
          ? value['id'] as String
          : null;
      if (id == null || !stateIds.contains(id)) {
        throw FormatException(
          'TM transition $field must reference a canonical state id.',
        );
      }
      return id;
    }

    final tapeCount = payload['tapeCount'] as int? ?? 1;
    for (final raw in transitions.cast<Map>()) {
      endpointId(raw['fromState'], 'fromState');
      endpointId(raw['toState'], 'toState');
      final reads = raw['readSymbols'];
      final writes = raw['writeSymbols'];
      final directions = raw['directions'];
      if (reads is! List ||
          writes is! List ||
          directions is! List ||
          reads.length != tapeCount ||
          writes.length != tapeCount ||
          directions.length != tapeCount) {
        throw const FormatException(
          'TM transition operation vectors must match tapeCount.',
        );
      }
      if (directions.any(
        (value) =>
            value is! String ||
            !TapeDirection.values.any((direction) => direction.name == value),
      )) {
        throw const FormatException('TM transition movement is invalid.');
      }
    }
    final definitions = payload['blockDefinitions'];
    final invocations = payload['blockInvocations'];
    if (definitions != null && definitions is! List) {
      throw const FormatException('TM block definitions must be an array.');
    }
    if (invocations != null && invocations is! List) {
      throw const FormatException('TM block invocations must be an array.');
    }
    if (definitions is List) {
      requireUniqueIds(definitions.cast<Object?>(), 'TM block definition');
      for (final raw in definitions) {
        final definition = raw as Map;
        final machine = definition['machine'];
        if (machine is! Map) {
          throw const FormatException(
            'TM block definition requires a machine object.',
          );
        }
        _validateRawIdentities(machine.cast<String, dynamic>());
      }
    }
    if (invocations is List) {
      requireUniqueIds(invocations.cast<Object?>(), 'TM block invocation');
    }
  }

  static String? _firstValidationError(TM machine) {
    final validation = machine.validate();
    if (machine.states.isEmpty &&
        machine.transitions.isEmpty &&
        machine.initialState == null &&
        machine.acceptingStates.isEmpty) {
      validation.remove('Automaton must have at least one state');
    }
    final machineError = validation.firstOrNull;
    if (machineError != null) return machineError;
    if (machine.blockDefinitions.isEmpty && machine.blockInvocations.isEmpty) {
      return null;
    }
    final report = TMBlockDependencyAnalyzer.analyze(
      TMBlockProject(rootMachine: machine),
    );
    return report.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity == TMBlockDiagnosticSeverity.error,
        )
        .map((diagnostic) => diagnostic.message)
        .firstOrNull;
  }
}

Map<String, dynamic> _normalizeMachinePayload(Map<String, dynamic> payload) {
  final normalized = Map<String, dynamic>.from(payload);
  final tapeCount = payload['tapeCount'] as int? ?? 1;
  final blank = payload['blankSymbol'] as String? ?? 'B';
  normalized['tapeCount'] = tapeCount;
  normalized['blankSymbol'] = blank;
  normalized['tmVariant'] ??= _variantName(payload, tapeCount);
  final transitions = payload['transitions'];
  if (transitions is List) {
    normalized['transitions'] = [
      for (final value in transitions)
        if (value is Map)
          _normalizeTransition(
            Map<String, dynamic>.from(value),
            tapeCount,
            blank,
          )
        else
          value,
    ];
  }
  final definitions = payload['blockDefinitions'];
  if (definitions is List) {
    normalized['blockDefinitions'] = [
      for (final value in definitions)
        if (value is Map && value['machine'] is Map)
          {
            ...Map<String, dynamic>.from(value),
            'machine': _normalizeMachinePayload(
              Map<String, dynamic>.from(value['machine'] as Map),
            ),
          }
        else
          value,
    ];
  }
  return normalized;
}

Map<String, dynamic> _normalizeTransition(
  Map<String, dynamic> transition,
  int tapeCount,
  String blank,
) {
  final rawReads = transition['readSymbols'];
  final rawWrites = transition['writeSymbols'];
  final rawDirections = transition['directions'];
  final reads = rawReads is List
      ? rawReads.cast<String>().toList()
      : <String>[transition['readSymbol'] as String? ?? blank];
  final writes = rawWrites is List
      ? rawWrites.cast<String>().toList()
      : <String>[transition['writeSymbol'] as String? ?? blank];
  final directions = rawDirections is List
      ? rawDirections.cast<String>().toList()
      : <String>[
          transition['direction'] as String? ?? TapeDirection.right.name,
        ];
  final canExpand =
      tapeCount > 1 &&
      reads.length == 1 &&
      writes.length == 1 &&
      directions.length == 1;
  if (canExpand) {
    final tape = transition['tapeNumber'] as int? ?? 0;
    if (tape >= 0 && tape < tapeCount) {
      final expandedReads = List<String>.filled(tapeCount, blank);
      final expandedWrites = List<String>.filled(tapeCount, blank);
      final expandedDirections = List<String>.filled(
        tapeCount,
        TapeDirection.stay.name,
      );
      expandedReads[tape] = reads.single;
      expandedWrites[tape] = writes.single;
      expandedDirections[tape] = directions.single;
      transition
        ..['readSymbols'] = expandedReads
        ..['writeSymbols'] = expandedWrites
        ..['directions'] = expandedDirections;
    }
  } else {
    transition
      ..['readSymbols'] = reads
      ..['writeSymbols'] = writes
      ..['directions'] = directions;
  }
  transition['label'] ??= TMTransition.formatVectorLabel(
    readSymbols: (transition['readSymbols'] as List).cast<String>(),
    writeSymbols: (transition['writeSymbols'] as List).cast<String>(),
    directions: (transition['directions'] as List)
        .cast<String>()
        .map(
          (name) => TapeDirection.values.firstWhere(
            (direction) => direction.name == name,
            orElse: () => TapeDirection.right,
          ),
        )
        .toList(),
  );
  return transition;
}

String _variantName(Map<String, dynamic> payload, int tapeCount) {
  final definitions = payload['blockDefinitions'];
  final invocations = payload['blockInvocations'];
  if ((definitions is List && definitions.isNotEmpty) ||
      (invocations is List && invocations.isNotEmpty)) {
    return TMDocumentVariant.buildingBlocks.name;
  }
  return tapeCount > 1
      ? TMDocumentVariant.multiTape.name
      : TMDocumentVariant.singleTape.name;
}

Map<String, dynamic>? _documentPayload(DocumentPayload payload) {
  try {
    final root = jsonDecode(utf8Payload(payload));
    if (root is! Map) return null;
    final json = root.cast<String, dynamic>();
    if (json['format'] == VersionedJsonDocumentCodec.envelopeFormat) {
      final document = json['document'];
      if (document is! Map || document['payload'] is! Map) return null;
      return Map<String, dynamic>.from(document['payload'] as Map);
    }
    return json;
  } catch (_) {
    return null;
  }
}

bool _hasLegacyOperationShape(Map<String, dynamic> payload) {
  final tapeCount = payload['tapeCount'] as int? ?? 1;
  final transitions = payload['transitions'];
  if (transitions is List) {
    for (final value in transitions) {
      if (value is! Map) continue;
      final reads = value['readSymbols'];
      final writes = value['writeSymbols'];
      final directions = value['directions'];
      if (reads is! List ||
          writes is! List ||
          directions is! List ||
          reads.length != tapeCount ||
          writes.length != tapeCount ||
          directions.length != tapeCount) {
        return true;
      }
    }
  }
  final definitions = payload['blockDefinitions'];
  return definitions is List &&
      definitions.any(
        (value) =>
            value is Map &&
            value['machine'] is Map &&
            _hasLegacyOperationShape(
              Map<String, dynamic>.from(value['machine'] as Map),
            ),
      );
}

bool _hasEmbeddedTransitionEndpoints(Map<String, dynamic> payload) {
  final transitions = payload['transitions'];
  if (transitions is List &&
      transitions.any(
        (value) =>
            value is Map &&
            (value['fromState'] is Map || value['toState'] is Map),
      )) {
    return true;
  }
  final definitions = payload['blockDefinitions'];
  return definitions is List &&
      definitions.any(
        (value) =>
            value is Map &&
            value['machine'] is Map &&
            _hasEmbeddedTransitionEndpoints(
              Map<String, dynamic>.from(value['machine'] as Map),
            ),
      );
}

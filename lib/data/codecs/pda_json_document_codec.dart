import 'package:collection/collection.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/pda.dart';
import '../../core/models/pda_acceptance_mode.dart';
import '../../core/models/pda_transition.dart';
import 'pda_json_messages.dart';
import 'versioned_json_document_codec.dart';

/// Versioned canonical JSON codec for pushdown automata.
final class PdaJsonDocumentCodec implements DocumentCodecCapability<Object> {
  PdaJsonDocumentCodec()
    : _delegate = VersionedJsonDocumentCodec(
        systemKey: DefaultFormalSystemIds.pda,
        schema: schema,
        codecId: const DocumentCodecId('pda.turing-lab-json.v1'),
        namespace: const CapabilityNamespaceId('codec.pda.turing-lab-json'),
        fixture: 'test/fixtures/interoperability/pda_canonical.json',
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
          'stackAlphabet',
          'initialStackSymbol',
          'acceptanceMode',
        },
        semanticCapabilities: {
          CodecSemanticCapabilityId.stateIds,
          CodecSemanticCapabilityId.stateNames,
          CodecSemanticCapabilityId.statePositions,
          CodecSemanticCapabilityId.stateLabels,
          CodecSemanticCapabilityId.initialStates,
          CodecSemanticCapabilityId.acceptingStates,
          CodecSemanticCapabilityId.transitionLabels,
          CodecSemanticCapabilityId.stackOperations,
          CodecSemanticCapabilityId.tokenVectors,
          CodecSemanticCapabilityId.extensions,
        },
      );

  static const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.pda'),
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
    final pda = outcome.value.document;
    if (pda is! PDA) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.decode,
        message: 'PDA JSON decoder returned an unexpected document type.',
        structuredMessage: PdaJsonMessages.unexpectedDocumentType(),
      );
    }
    final error = pda.validate().firstOrNull;
    return error == null
        ? outcome
        : CodecMalformed(
            reason: CodecMalformedReason.invalidValue,
            message: error,
            location: const CodecSourceLocation(path: r'$.document.payload'),
            structuredMessage: PdaJsonMessages.invalidDocument(),
          );
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    final pda = document.document;
    if (pda is PDA) {
      final error = pda.validate().firstOrNull;
      if (error != null) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: error,
          location: const CodecSourceLocation(path: r'$.document'),
          structuredMessage: PdaJsonMessages.invalidDocument(),
        );
      }
    }
    return _delegate.encode(document, filename: filename);
  }

  static Map<String, Object?> _encodePayload(Object document) {
    if (document is! PDA) throw const FormatException('Expected a PDA.');
    final payload = Map<String, Object?>.from(document.toJson());
    payload['alphabet'] = document.alphabet.toList()..sort();
    payload['stackAlphabet'] = document.stackAlphabet.toList()..sort();
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
        document.pdaTransitions
            .map((transition) => transition.toJson())
            .toList()
          ..sort(
            (left, right) =>
                (left['id'] as String).compareTo(right['id'] as String),
          );
    return payload;
  }

  static Object _decodePayload(Map<String, dynamic> payload) {
    final normalized = _normalizeLegacyTransitions(payload);
    _validateRawIdentities(normalized);
    try {
      return PDA.fromJson(normalized);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? error.toString());
    } on TypeError catch (error) {
      throw FormatException(error.toString());
    }
  }

  static bool _isLegacyPayload(Map<String, dynamic> payload) =>
      payload['type'] == 'PDA' &&
      payload['states'] is List &&
      payload['transitions'] is List;

  static Map<String, dynamic> _normalizeLegacyTransitions(
    Map<String, dynamic> payload,
  ) {
    final normalized = Map<String, dynamic>.from(payload);
    final transitions = payload['transitions'];
    if (transitions is! List) return normalized;
    normalized['acceptanceMode'] ??= 'finalState';
    normalized['transitions'] = [
      for (final raw in transitions)
        if (raw is Map)
          () {
            final transition = Map<String, dynamic>.from(raw);
            final input = transition['inputSymbol'] as String? ?? '';
            final pop = transition['popSymbol'] as String? ?? '';
            final push = transition['pushSymbol'] as String? ?? '';
            transition['inputSymbol'] = input;
            transition['popSymbol'] = pop;
            transition['pushSymbol'] = push;
            transition['pushSymbols'] ??= push.runes
                .map(String.fromCharCode)
                .toList();
            transition['isLambdaInput'] ??= input.isEmpty;
            transition['isLambdaPop'] ??= pop.isEmpty;
            transition['isLambdaPush'] ??= push.isEmpty;
            transition['label'] ??= PDATransition.formatLabel(
              inputSymbol: input,
              popSymbol: pop,
              pushSymbol: push,
              isLambdaInput: transition['isLambdaInput'] as bool,
              isLambdaPop: transition['isLambdaPop'] as bool,
              isLambdaPush: transition['isLambdaPush'] as bool,
            );
            return transition;
          }()
        else
          raw,
    ];
    return normalized;
  }

  static void _validateRawIdentities(Map<String, dynamic> payload) {
    final states = payload['states'];
    final transitions = payload['transitions'];
    if (states is! List || transitions is! List) {
      throw const FormatException('PDA states and transitions must be arrays.');
    }
    final acceptanceMode = payload['acceptanceMode'];
    if (acceptanceMode is! String ||
        !PDAAcceptanceMode.values.any((mode) => mode.name == acceptanceMode)) {
      throw const FormatException('PDA acceptanceMode is invalid.');
    }
    final stateIds = <String>{};
    for (final value in states) {
      if (value is! Map || value['id'] is! String) {
        throw const FormatException('PDA state entries require string ids.');
      }
      if (!stateIds.add(value['id'] as String)) {
        throw const FormatException('PDA state ids must be unique.');
      }
    }
    final transitionIds = <String>{};
    for (final value in transitions) {
      if (value is! Map || value['id'] is! String) {
        throw const FormatException(
          'PDA transition entries require string ids.',
        );
      }
      if (!transitionIds.add(value['id'] as String)) {
        throw const FormatException('PDA transition ids must be unique.');
      }
      final from = value['fromState'];
      final to = value['toState'];
      if (from is! String || !stateIds.contains(from)) {
        throw const FormatException(
          'PDA transition fromState must reference a state id.',
        );
      }
      if (to is! String || !stateIds.contains(to)) {
        throw const FormatException(
          'PDA transition toState must reference a state id.',
        );
      }
    }
  }
}

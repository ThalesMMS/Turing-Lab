import 'dart:math' as math;
import 'dart:convert' as convert;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/algorithms/tm_block_dependency_analyzer.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_acceptance.dart';
import '../../core/models/tm_building_blocks.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/transition.dart';
import 'codec_utils.dart';
import 'hardened_xml.dart';
import 'jflap_annotations.dart';
import 'tm_jflap_messages.dart';
import 'tm_json_document_codec.dart';

/// Loss-aware JFLAP XML codec for Turing machines and building blocks.
final class TmJflapDocumentCodec implements DocumentCodecCapability<Object> {
  const TmJflapDocumentCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('tm.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.tm.jflap-xml'),
    systemKey: DefaultFormalSystemIds.tm,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 110,
    compatibilityOwner: 'Turing Lab interoperability / JFLAP TM XML',
    canonicalFixtures: const [
      'test/fixtures/interoperability/tm_multi_canonical.jff',
    ],
    semanticCapabilities: {
      CodecSemanticCapabilityId.stateIds,
      CodecSemanticCapabilityId.stateNames,
      CodecSemanticCapabilityId.statePositions,
      CodecSemanticCapabilityId.stateLabels,
      CodecSemanticCapabilityId.initialStates,
      CodecSemanticCapabilityId.acceptingStates,
      CodecSemanticCapabilityId.transitionLabels,
      CodecSemanticCapabilityId.tapeOperations,
      CodecSemanticCapabilityId.buildingBlocks,
      CodecSemanticCapabilityId.extensions,
      CodecSemanticCapabilityId.notes,
    },
    knownUnsupportedFields: const {
      'standard JFLAP document and transition IDs',
      'standard JFLAP declared alphabets and custom blank symbols',
      'standard JFLAP viewport and revision timestamps',
      'JFLAP wildcard, negated, and variable read predicates',
    },
  );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    try {
      final source = utf8Payload(payload);
      final prefix = source.substring(0, source.length.clamp(0, 8192));
      final recognized =
          RegExp(
            r'<type\s*>\s*turing\s*</type\s*>',
            caseSensitive: false,
          ).hasMatch(prefix) ||
          RegExp(
            r'''<structure\b[^>]*\btype\s*=\s*["']turing["']''',
            caseSensitive: false,
          ).hasMatch(prefix);
      return recognized
          ? CodecSniffResult(
              confidence: 100,
              detectedSystem: DefaultFormalSystemIds.tm,
              detectedSchemaVersion: 1,
            )
          : CodecSniffResult.none;
    } catch (_) {
      return CodecSniffResult.none;
    }
  }

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final parsed = parseHardenedXml(payload, descriptor.securityLimits);
    if (parsed is! CodecSuccess<XmlDocument>) return _copyTmXmlFailure(parsed);
    final root = parsed.value.rootElement;
    if (root.name.local != 'structure') {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'JFLAP XML root must be <structure>.',
        location: CodecSourceLocation(path: '/'),
        structuredMessage: TmJflapMessages.invalidRoot(),
      );
    }
    final type =
        root.getElement('type')?.innerText.trim() ??
        root.getAttribute('type')?.trim();
    if (type?.toLowerCase() != 'turing') {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'JFLAP document type ${type ?? '(missing)'} is not TM.',
        structuredMessage: TmJflapMessages.unsupportedDocumentType(
          type ?? '(missing)',
        ),
      );
    }
    final hasBuildingBlockExtensions = root.descendants
        .whereType<XmlElement>()
        .any((element) => element.getAttribute('turingLabBlockId') != null);
    if (root.findAllElements('block').isNotEmpty ||
        hasBuildingBlockExtensions) {
      return _decodeBuildingBlockDocument(root, descriptor);
    }
    final rawTapeCount = root.getElement('tapes')?.innerText.trim();
    final tapeCount = rawTapeCount == null || rawTapeCount.isEmpty
        ? 1
        : int.tryParse(rawTapeCount);
    if (tapeCount == null || tapeCount < 1 || tapeCount > 5) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'JFLAP tape count must be between 1 and 5.',
        location: CodecSourceLocation(path: '/structure/tapes'),
        structuredMessage: TmJflapMessages.invalidTapeCount(),
      );
    }
    final automaton = root.findElements('automaton').firstOrNull;
    if (automaton == null) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'JFLAP TM is missing <automaton>.',
        location: CodecSourceLocation(path: '/structure/automaton'),
        structuredMessage: TmJflapMessages.missingAutomaton(),
      );
    }
    final stateElements = automaton.findElements('state').toList();
    final transitionElements = automaton.findElements('transition').toList();
    final collectionEntries = stateElements.length + transitionElements.length;
    if (collectionEntries >
        descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: collectionEntries,
      );
    }

    final extensions = <String, Object?>{};
    final diagnostics = <CodecDiagnostic>[];
    final metadataElement = root.getElement('turingLabTm');
    late final Map<String, dynamic> metadata;
    try {
      metadata = metadataElement == null
          ? const <String, dynamic>{}
          : _jsonObject(metadataElement.innerText, '/structure/turingLabTm');
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        location: const CodecSourceLocation(path: '/structure/turingLabTm'),
        cause: error,
        structuredMessage: TmJflapMessages.malformedExtension(),
      );
    }
    if (metadataElement == null) {
      diagnostics.add(
        CodecDiagnostic(
          code: 'jflap.tm.canonical-order',
          message:
              'TM state and transition order is canonicalized; the absent JFLAP profile acceptance setting defaults to final-state acceptance.',
          structuredMessage: TmJflapMessages.canonicalOrderImport(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
    }
    final actualVariant = tapeCount > 1
        ? TMDocumentVariant.multiTape
        : TMDocumentVariant.singleTape;
    final declaredVariant = metadata['variant'];
    if (declaredVariant != null &&
        (declaredVariant is! String || declaredVariant != actualVariant.name)) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'The Turing Lab TM variant does not match the XML structure.',
        location: CodecSourceLocation(path: '/structure/turingLabTm/variant'),
        structuredMessage: TmJflapMessages.variantMismatch(),
      );
    }
    final declaredTapeCount = metadata['tapeCount'];
    if (declaredTapeCount != null &&
        (declaredTapeCount is! int || declaredTapeCount != tapeCount)) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'The Turing Lab tape count does not match <tapes>.',
        location: CodecSourceLocation(path: '/structure/turingLabTm/tapeCount'),
        structuredMessage: TmJflapMessages.tapeCountMismatch(),
      );
    }
    final rawBlank = metadata['blankSymbol'];
    if (rawBlank != null && (rawBlank is! String || rawBlank.isEmpty)) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'The Turing Lab blank symbol must be a non-empty string.',
        location: CodecSourceLocation(
          path: '/structure/turingLabTm/blankSymbol',
        ),
        structuredMessage: TmJflapMessages.blankSymbolInvalid(),
      );
    }
    final blankSymbol = rawBlank as String? ?? 'B';
    late final TMAcceptancePolicy acceptancePolicy;
    try {
      acceptancePolicy = _metadataAcceptancePolicy(metadata);
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        location: const CodecSourceLocation(
          path: '/structure/turingLabTm/acceptancePolicy',
        ),
        cause: error,
        structuredMessage: TmJflapMessages.acceptancePolicyInvalid(),
      );
    }
    const metadataKeys = {
      'schema',
      'variant',
      'id',
      'name',
      'alphabet',
      'tapeAlphabet',
      'blankSymbol',
      'tapeCount',
      'created',
      'modified',
      'bounds',
      'zoomLevel',
      'panOffset',
    };
    final completeMetadata =
        metadataElement != null && metadataKeys.every(metadata.containsKey);
    if (metadataElement != null && !completeMetadata) {
      diagnostics.add(
        CodecDiagnostic(
          code: 'jflap.tm-incomplete-turing-lab-extension',
          message:
              'Missing Turing Lab TM metadata, including any absent acceptance policy, was reconstructed.',
          path: '/structure/turingLabTm',
          structuredMessage: TmJflapMessages.incompleteExtension(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
    }
    if (metadata['schema'] != null && metadata['schema'] != 'turing-lab.tm@1') {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'The Turing Lab TM extension schema is invalid.',
        location: CodecSourceLocation(path: '/structure/turingLabTm/schema'),
        structuredMessage: TmJflapMessages.extensionSchemaInvalid(),
      );
    }
    final states = <State>[];
    final statesById = <String, State>{};
    var initialCount = 0;
    for (final element in stateElements) {
      final id = element.getAttribute('id')?.trim();
      if (id == null || id.isEmpty || statesById.containsKey(id)) {
        return CodecMalformed(
          reason: id == null || id.isEmpty
              ? CodecMalformedReason.missingField
              : CodecMalformedReason.duplicateIdentity,
          message: 'JFLAP TM state ids must be non-empty and unique.',
          location: const CodecSourceLocation(
            path: '/structure/automaton/state',
          ),
          structuredMessage: id == null || id.isEmpty
              ? TmJflapMessages.missingStateId()
              : TmJflapMessages.duplicateStateId(id),
        );
      }
      final x = double.tryParse(element.getElement('x')?.innerText ?? '');
      final y = double.tryParse(element.getElement('y')?.innerText ?? '');
      if (x == null || y == null) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'JFLAP TM state $id has invalid coordinates.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]',
          ),
          structuredMessage: TmJflapMessages.invalidStateCoordinate(id),
        );
      }
      final initial = element.findElements('initial').isNotEmpty;
      if (initial) initialCount++;
      final name = element.getAttribute('name') ?? 'q$id';
      final label = element.getElement('label')?.innerText ?? name;
      final custom = element.getElement('turingLabState');
      late final Map<String, dynamic> customData;
      try {
        customData = custom == null
            ? const <String, dynamic>{}
            : _jsonObject(
                custom.innerText,
                '/structure/automaton/state[@id="$id"]/turingLabState',
              );
      } on FormatException catch (error) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: error.message,
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]/turingLabState',
          ),
          cause: error,
          structuredMessage: TmJflapMessages.malformedExtension(),
        );
      }
      final stateTypeName = customData['type'];
      if (stateTypeName != null &&
          (stateTypeName is! String ||
              !StateType.values.any((value) => value.name == stateTypeName))) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'JFLAP TM state $id has an invalid Turing Lab state type.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]/turingLabState/type',
          ),
          structuredMessage: TmJflapMessages.invalidStateType(id),
        );
      }
      final stateProperties = customData['properties'];
      if (stateProperties != null && stateProperties is! Map) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'JFLAP TM state $id has invalid Turing Lab properties.',
          location: CodecSourceLocation(
            path:
                '/structure/automaton/state[@id="$id"]/turingLabState/properties',
          ),
          structuredMessage: TmJflapMessages.invalidStateProperties(id),
        );
      }
      final state = State(
        id: id,
        label: label,
        position: Vector2(x, y),
        isInitial: initial,
        isAccepting: element.findElements('final').isNotEmpty,
        type: StateType.values.firstWhere(
          (value) => value.name == stateTypeName,
          orElse: () => StateType.normal,
        ),
        properties: Map<String, dynamic>.from(stateProperties as Map? ?? {}),
      );
      states.add(state);
      statesById[id] = state;
      if (name != label) extensions['stateName.$id'] = name;
      preserveXmlAttributes(
        element,
        known: const {'id', 'name'},
        key: 'stateAttributes.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      preserveXmlChildren(
        element,
        known: const {'x', 'y', 'label', 'initial', 'final', 'turingLabState'},
        key: 'stateChildren.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
    }
    if ((states.isEmpty &&
            (transitionElements.isNotEmpty || initialCount != 0)) ||
        (states.isNotEmpty && initialCount != 1)) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'A non-empty JFLAP TM requires exactly one initial state.',
        location: CodecSourceLocation(path: '/structure/automaton/state'),
        structuredMessage: TmJflapMessages.invalidInitialStateCount(),
      );
    }

    final transitions = <TMTransition>[];
    final transitionIds = <String>{};
    var completeTransitionExtensions = true;
    final tapeAlphabet = <String>{blankSymbol};
    final inputAlphabet = <String>{};
    for (var index = 0; index < transitionElements.length; index++) {
      final element = transitionElements[index];
      final fromId = element.getElement('from')?.innerText.trim();
      final toId = element.getElement('to')?.innerText.trim();
      final from = statesById[fromId];
      final to = statesById[toId];
      if (from == null || to == null) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'JFLAP TM transition references an unknown state.',
          location: CodecSourceLocation(
            path: '/structure/automaton/transition[$index]',
          ),
          structuredMessage: TmJflapMessages.unknownTransitionEndpoints(
            from: fromId,
            to: toId,
          ),
        );
      }
      final reads = List<String>.filled(tapeCount, blankSymbol);
      final writes = List<String>.filled(tapeCount, blankSymbol);
      final moves = List<TapeDirection>.filled(tapeCount, TapeDirection.right);
      final seen = <String>{};
      for (final tag in const ['read', 'write', 'move']) {
        for (final child in element.findElements(tag)) {
          final rawTape = child.getAttribute('tape') ?? '1';
          final tape = int.tryParse(rawTape);
          if (tape == null || tape < 1 || tape > tapeCount) {
            return CodecMalformed(
              reason: CodecMalformedReason.invalidValue,
              message: 'JFLAP TM transition has an invalid tape index.',
              location: CodecSourceLocation(
                path: '/structure/automaton/transition[$index]/$tag/@tape',
              ),
              structuredMessage: TmJflapMessages.invalidTapeIndex(),
            );
          }
          if (!seen.add('$tag:$tape')) {
            return CodecMalformed(
              reason: CodecMalformedReason.duplicateIdentity,
              message: 'JFLAP TM transition repeats $tag for tape $tape.',
              location: CodecSourceLocation(
                path: '/structure/automaton/transition[$index]/$tag',
              ),
              structuredMessage: TmJflapMessages.duplicateTapeOperation(tag),
            );
          }
          final value = child.innerText;
          if (tag == 'read') {
            if (_usesJflapReadPredicate(value)) {
              return CodecUnsupported(
                reason: CodecUnsupportedReason.feature,
                message:
                    'JFLAP wildcard, negated, and variable TM reads are not supported.',
                structuredMessage: TmJflapMessages.unsupportedReadPredicate(),
              );
            }
            if (value.isNotEmpty && value.length != 1) {
              return CodecMalformed(
                reason: CodecMalformedReason.invalidValue,
                message:
                    'JFLAP TM read symbols must contain one UTF-16 code unit.',
                location: CodecSourceLocation(
                  path: '/structure/automaton/transition/read',
                ),
                structuredMessage: TmJflapMessages.invalidReadSymbol(),
              );
            }
            reads[tape - 1] = _jflapSymbol(value, blankSymbol);
          }
          if (tag == 'write') {
            if (value.isNotEmpty && value.length != 1) {
              return CodecMalformed(
                reason: CodecMalformedReason.invalidValue,
                message:
                    'JFLAP TM write symbols must contain one UTF-16 code unit.',
                location: CodecSourceLocation(
                  path: '/structure/automaton/transition/write',
                ),
                structuredMessage: TmJflapMessages.invalidWriteSymbol(),
              );
            }
            writes[tape - 1] = _jflapSymbol(value, blankSymbol);
          }
          if (tag == 'move') {
            final direction = _direction(value);
            if (direction == null) {
              return CodecMalformed(
                reason: CodecMalformedReason.invalidValue,
                message: 'JFLAP TM movement must be L, R, or S.',
                location: CodecSourceLocation(
                  path: '/structure/automaton/transition[$index]/move',
                ),
                structuredMessage: TmJflapMessages.invalidMove(),
              );
            }
            moves[tape - 1] = direction;
          }
        }
      }
      final signature = _signature(from.id, to.id, reads, writes, moves);
      final custom = element.getElement('turingLabTransition');
      late final Map<String, dynamic> customData;
      try {
        customData = custom == null
            ? const <String, dynamic>{}
            : _jsonObject(
                custom.innerText,
                '/structure/automaton/transition[$index]/turingLabTransition',
              );
      } on FormatException catch (error) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: error.message,
          location: CodecSourceLocation(
            path: '/structure/automaton/transition[$index]/turingLabTransition',
          ),
          cause: error,
          structuredMessage: TmJflapMessages.invalidTransitionExtension(),
        );
      }
      completeTransitionExtensions =
          completeTransitionExtensions &&
          custom != null &&
          const {
            'id',
            'label',
            'type',
            'controlPoint',
          }.every(customData.containsKey);
      final rawId = customData['id'];
      if (rawId != null && (rawId is! String || rawId.isEmpty)) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'JFLAP TM transition $index has an invalid Turing Lab id.',
          location: CodecSourceLocation(
            path:
                '/structure/automaton/transition[$index]/turingLabTransition/id',
          ),
          structuredMessage: TmJflapMessages.invalidTransitionId(),
        );
      }
      final id =
          rawId as String? ??
          deterministicContentId('tm_transition', signature);
      if (!transitionIds.add(id)) {
        return CodecMalformed(
          reason: CodecMalformedReason.duplicateIdentity,
          message: 'JFLAP TM transition ids must be unique.',
          location: CodecSourceLocation(
            path: '/structure/automaton/transition[$index]',
          ),
          structuredMessage: TmJflapMessages.duplicateTransitionId(),
        );
      }
      final rawLabel = customData['label'];
      if (rawLabel != null && rawLabel is! String) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'JFLAP TM transition $id has an invalid label.',
          location: CodecSourceLocation(
            path:
                '/structure/automaton/transition[$index]/turingLabTransition/label',
          ),
          structuredMessage: TmJflapMessages.invalidTransitionLabel(id),
        );
      }
      final transitionTypeName = customData['type'];
      if (transitionTypeName != null &&
          (transitionTypeName is! String ||
              !TransitionType.values.any(
                (value) => value.name == transitionTypeName,
              ))) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'JFLAP TM transition $id has an invalid type.',
          location: CodecSourceLocation(
            path:
                '/structure/automaton/transition[$index]/turingLabTransition/type',
          ),
          structuredMessage: TmJflapMessages.invalidTransitionType(id),
        );
      }
      late final Vector2 controlPoint;
      try {
        controlPoint = _controlPoint(customData);
      } on FormatException catch (error) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: error.message,
          location: CodecSourceLocation(
            path:
                '/structure/automaton/transition[$index]/turingLabTransition/controlPoint',
          ),
          cause: error,
          structuredMessage: TmJflapMessages.invalidControlPoint(),
        );
      }
      transitions.add(
        TMTransition(
          id: id,
          fromState: from,
          toState: to,
          label:
              rawLabel as String? ??
              TMTransition.formatVectorLabel(
                readSymbols: reads,
                writeSymbols: writes,
                directions: moves,
              ),
          controlPoint: controlPoint,
          type: TransitionType.values.firstWhere(
            (value) => value.name == transitionTypeName,
            orElse: () => TransitionType.deterministic,
          ),
          readSymbols: reads,
          writeSymbols: writes,
          directions: moves,
        ),
      );
      tapeAlphabet.addAll(reads);
      tapeAlphabet.addAll(writes);
      if (reads.first != blankSymbol) inputAlphabet.add(reads.first);
      preserveXmlAttributes(
        element,
        known: const {},
        key: 'transitionAttributes.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      preserveXmlChildren(
        element,
        known: const {
          'from',
          'to',
          'read',
          'write',
          'move',
          'turingLabTransition',
        },
        key: 'transitionChildren.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
    }
    if (!completeTransitionExtensions) {
      diagnostics.add(
        CodecDiagnostic(
          code: 'jflap.tm-transition-identities-reconstructed',
          message: 'Missing TM transition metadata was reconstructed.',
          path: '/structure/automaton/transition',
          structuredMessage:
              TmJflapMessages.transitionIdentitiesReconstructed(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
      );
    }
    preserveXmlAttributes(
      automaton,
      known: const {},
      key: 'automatonAttributes',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    preserveXmlAttributes(
      root,
      known: const {'type'},
      key: 'rootAttributes',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    preserveXmlChildren(
      root,
      known: const {'type', 'tapes', 'automaton', 'turingLabTm'},
      key: 'rootChildren',
      extensions: extensions,
      diagnostics: diagnostics,
    );

    states.sort((left, right) => left.id.compareTo(right.id));
    transitions.sort((left, right) => left.id.compareTo(right.id));
    final canonicalIdentity = canonicalIdentityJson({
      'tapes': tapeCount,
      'states': states
          .map(
            (state) => [
              state.id,
              state.label,
              state.isInitial,
              state.isAccepting,
            ],
          )
          .toList(),
      'transitions': transitions
          .map((transition) => transition.toJson())
          .toList(),
    });
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    late final Set<String>? declaredAlphabet;
    late final Set<String>? declaredTapeAlphabet;
    late final String? documentId;
    late final String? documentName;
    late final DateTime created;
    late final DateTime modified;
    late final math.Rectangle<double>? declaredBounds;
    late final double zoomLevel;
    late final Vector2 panOffset;
    try {
      declaredAlphabet = _metadataStringSet(metadata, 'alphabet');
      declaredTapeAlphabet = _metadataStringSet(metadata, 'tapeAlphabet');
      documentId = _metadataString(metadata, 'id');
      documentName = _metadataString(metadata, 'name');
      created = _metadataDate(metadata, 'created', epoch);
      modified = _metadataDate(metadata, 'modified', epoch);
      declaredBounds = _metadataBounds(metadata);
      zoomLevel = _metadataNumber(metadata, 'zoomLevel', 1);
      panOffset = _metadataPan(metadata);
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        location: const CodecSourceLocation(path: '/structure/turingLabTm'),
        cause: error,
        structuredMessage: TmJflapMessages.invalidMetadata(),
      );
    }
    final machine = TM(
      id:
          documentId ??
          deterministicContentId('imported_tm', canonicalIdentity),
      name: documentName ?? 'Imported Turing Machine',
      states: states.toSet(),
      transitions: transitions.toSet(),
      alphabet: declaredAlphabet ?? inputAlphabet,
      initialState: states.firstWhereOrNull((state) => state.isInitial),
      acceptingStates: states.where((state) => state.isAccepting).toSet(),
      created: created,
      modified: modified,
      bounds: declaredBounds ?? _bounds(states),
      zoomLevel: zoomLevel,
      panOffset: panOffset,
      tapeAlphabet: declaredTapeAlphabet ?? tapeAlphabet,
      blankSymbol: blankSymbol,
      tapeCount: tapeCount,
      acceptancePolicy: acceptancePolicy,
    );
    readJflapAnnotations(
      automaton,
      documentId: machine.id,
      documentRevision: 'jflap-import',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    preserveXmlChildren(
      automaton,
      known: const {'state', 'transition', 'note'},
      key: 'automatonChildren',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    final validation = _firstTmCodecValidationError(machine);
    if (validation != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: validation,
        location: const CodecSourceLocation(path: '/structure/automaton'),
        structuredMessage: TmJflapMessages.invalidDocument(),
      );
    }
    final resolvedDiagnostics = _withTmDiagnosticMessages(diagnostics);
    final hasDroppedDiagnostic = resolvedDiagnostics.any(
      (diagnostic) =>
          diagnostic.disposition == CodecDiagnosticDisposition.dropped,
    );
    final hasNormalizedDiagnostic = resolvedDiagnostics.any(
      (diagnostic) =>
          diagnostic.disposition == CodecDiagnosticDisposition.normalized,
    );
    return CodecSuccess(
      value: InteroperableDocument<Object>(
        document: machine,
        systemKey: DefaultFormalSystemIds.tm,
        schema: TmJsonDocumentCodec.schema,
        sourceMetadata: const DocumentSourceMetadata(
          application: 'JFLAP',
          sourceFormatVersion: '4+',
        ),
        extensions: DocumentExtensionBag(extensions),
      ),
      fidelity: hasDroppedDiagnostic
          ? DocumentFidelity.lossy
          : completeMetadata &&
                completeTransitionExtensions &&
                !hasNormalizedDiagnostic
          ? DocumentFidelity.exact
          : DocumentFidelity.normalized,
      diagnostics: resolvedDiagnostics,
    );
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != DefaultFormalSystemIds.tm ||
        document.document is! TM) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'TM JFLAP codec requires a TM document.',
        structuredMessage: TmJflapMessages.requiresTmDocument(),
      );
    }
    if (document.schema != TmJsonDocumentCodec.schema) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'TM JFLAP codec requires turing-lab.tm schema version 1.',
        structuredMessage: TmJflapMessages.unsupportedSchema(
          document.schema.version.value,
        ),
      );
    }
    final machine = document.document as TM;
    if (machine.blockDefinitions.isNotEmpty ||
        machine.blockInvocations.isNotEmpty) {
      return _encodeBuildingBlockDocument(
        document,
        machine,
        filename: filename,
      );
    }
    if (machine.tapeCount < 1 || machine.tapeCount > 5) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: 'JFLAP supports Turing machines with 1 to 5 tapes.',
        structuredMessage: TmJflapMessages.unsupportedTapeCount(),
      );
    }
    final validation = _firstTmCodecValidationError(machine);
    if (validation != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: validation,
        location: const CodecSourceLocation(path: r'$.document'),
        structuredMessage: TmJflapMessages.invalidDocument(),
      );
    }
    final states = machine.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final transitions = machine.tmTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final transition in transitions) {
      final operations = transition.operationsForTapeCount(
        machine.tapeCount,
        machine.blankSymbol,
      );
      for (var tape = 0; tape < machine.tapeCount; tape++) {
        final read = operations.readSymbols[tape];
        final write = operations.writeSymbols[tape];
        if (read != machine.blankSymbol &&
            (_usesJflapReadPredicate(read) || read.length != 1)) {
          return CodecUnsupported(
            reason: CodecUnsupportedReason.feature,
            message:
                'Transition ${transition.id} uses a read symbol that JFLAP cannot represent atomically.',
            structuredMessage: TmJflapMessages.unsupportedOperation(
              transitionId: transition.id,
              operation: 'read',
              symbol: read,
            ),
          );
        }
        if (write != machine.blankSymbol && write.length != 1) {
          return CodecUnsupported(
            reason: CodecUnsupportedReason.feature,
            message:
                'Transition ${transition.id} uses a write symbol that JFLAP cannot represent atomically.',
            structuredMessage: TmJflapMessages.unsupportedOperation(
              transitionId: transition.id,
              operation: 'write',
              symbol: write,
            ),
          );
        }
      }
    }
    final diagnostics = <CodecDiagnostic>[
      CodecDiagnostic(
        code: 'jflap.tm.canonical-order',
        message: 'TM state and transition order was canonicalized.',
        structuredMessage: TmJflapMessages.canonicalOrderExport(),
        disposition: CodecDiagnosticDisposition.normalized,
      ),
      CodecDiagnostic(
        code: 'jflap.tm-turing-lab-extension-portability',
        message:
            'JFLAP open/save discards Turing Lab identity, alphabet, blank-symbol, acceptance-policy, and viewport extensions.',
        path: '/structure/turingLabTm',
        structuredMessage: TmJflapMessages.extensionPortability(),
        disposition: CodecDiagnosticDisposition.dropped,
      ),
    ];
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        writeXmlAttributes(
          builder,
          document.extensions.values['rootAttributes'],
        );
        builder.element('type', nest: 'turing');
        if (machine.tapeCount > 1) {
          builder.element('tapes', nest: machine.tapeCount.toString());
        }
        builder.element(
          'turingLabTm',
          nest: convert.jsonEncode(_tmMetadata(machine)),
        );
        writeXmlExtensions(builder, document.extensions.values['rootChildren']);
        builder.element(
          'automaton',
          nest: () {
            writeXmlAttributes(
              builder,
              document.extensions.values['automatonAttributes'],
            );
            for (final state in states) {
              builder.element(
                'state',
                nest: () {
                  builder.attribute('id', state.id);
                  builder.attribute(
                    'name',
                    document.extensions.values['stateName.${state.id}']
                            as String? ??
                        state.label,
                  );
                  writeXmlAttributes(
                    builder,
                    document.extensions.values['stateAttributes.${state.id}'],
                  );
                  builder.element('x', nest: formatXmlNumber(state.position.x));
                  builder.element('y', nest: formatXmlNumber(state.position.y));
                  if (state.label != state.id) {
                    builder.element('label', nest: state.label);
                  }
                  if (state.isInitial) builder.element('initial');
                  if (state.isAccepting) builder.element('final');
                  if (state.type != StateType.normal ||
                      state.properties.isNotEmpty) {
                    builder.element(
                      'turingLabState',
                      nest: convert.jsonEncode({
                        'type': state.type.name,
                        'properties': state.properties,
                      }),
                    );
                  }
                  writeXmlExtensions(
                    builder,
                    document.extensions.values['stateChildren.${state.id}'],
                  );
                },
              );
            }
            for (final transition in transitions) {
              final operations = transition.operationsForTapeCount(
                machine.tapeCount,
                machine.blankSymbol,
              );
              builder.element(
                'transition',
                nest: () {
                  writeXmlAttributes(
                    builder,
                    document
                        .extensions
                        .values['transitionAttributes.${transition.id}'],
                  );
                  builder.element('from', nest: transition.fromState.id);
                  builder.element('to', nest: transition.toState.id);
                  for (var tape = 0; tape < machine.tapeCount; tape++) {
                    final attributes = machine.tapeCount > 1
                        ? <String, String>{'tape': '${tape + 1}'}
                        : const <String, String>{};
                    _element(
                      builder,
                      'read',
                      operations.readSymbols[tape],
                      machine.blankSymbol,
                      attributes,
                    );
                    _element(
                      builder,
                      'write',
                      operations.writeSymbols[tape],
                      machine.blankSymbol,
                      attributes,
                    );
                    builder.element(
                      'move',
                      attributes: attributes,
                      nest: operations.directions[tape].symbol,
                    );
                  }
                  builder.element(
                    'turingLabTransition',
                    nest: convert.jsonEncode({
                      'id': transition.id,
                      'label': transition.label,
                      'type': transition.type.name,
                      'controlPoint': {
                        'x': transition.controlPoint.x,
                        'y': transition.controlPoint.y,
                      },
                    }),
                  );
                  writeXmlExtensions(
                    builder,
                    document
                        .extensions
                        .values['transitionChildren.${transition.id}'],
                  );
                },
              );
            }
            writeJflapAnnotations(builder, document.extensions, diagnostics);
            writeXmlExtensions(
              builder,
              document.extensions.values['automatonChildren'],
            );
          },
        );
      },
    );
    final xml = builder.buildDocument().toXmlString(pretty: true);
    return CodecSuccess(
      value: EncodedDocument(
        bytes: utf8Bytes('$xml\n'),
        mimeType: 'application/xml',
        filename: filenameWithExtension(filename, 'machine', 'jff'),
        schema: TmJsonDocumentCodec.schema,
      ),
      fidelity: DocumentFidelity.lossy,
      diagnostics: diagnostics,
    );
  }
}

CodecOutcome<InteroperableDocument<Object>> _decodeBuildingBlockDocument(
  XmlElement root,
  CodecDescriptor descriptor,
) {
  try {
    final rawTapeCount = root.getElement('tapes')?.innerText.trim();
    final tapeCount = rawTapeCount == null || rawTapeCount.isEmpty
        ? 1
        : int.tryParse(rawTapeCount);
    if (tapeCount == null || tapeCount < 1 || tapeCount > 5) {
      throw const _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP tape count must be between 1 and 5.',
        '/structure/tapes',
      );
    }
    final automaton = root.findElements('automaton').firstOrNull;
    if (automaton == null) {
      throw const _BlockXmlException(
        CodecMalformedReason.missingField,
        'JFLAP TM is missing <automaton>.',
        '/structure/automaton',
      );
    }
    if (root.descendants.whereType<XmlElement>().length >
        descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: root.descendants.whereType<XmlElement>().length,
      );
    }

    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final metadataElement = root.getElement('turingLabTm');
    late final Map<String, dynamic> rootMetadata;
    try {
      rootMetadata = metadataElement == null
          ? const <String, dynamic>{}
          : _jsonObject(metadataElement.innerText, '/structure/turingLabTm');
    } on FormatException catch (error) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        error.message,
        '/structure/turingLabTm',
      );
    }
    if (rootMetadata['variant'] != null &&
        rootMetadata['variant'] != TMDocumentVariant.buildingBlocks.name) {
      throw const _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'The Turing Lab TM variant does not match the building-block XML.',
        '/structure/turingLabTm/variant',
      );
    }
    if (rootMetadata['tapeCount'] != null &&
        (rootMetadata['tapeCount'] is! int ||
            rootMetadata['tapeCount'] != tapeCount)) {
      throw const _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'The Turing Lab tape count does not match <tapes>.',
        '/structure/turingLabTm/tapeCount',
      );
    }
    late final String? metadataId;
    late final String? metadataName;
    late final String blankSymbol;
    try {
      metadataId = _metadataString(rootMetadata, 'id');
      metadataName = _metadataString(rootMetadata, 'name');
      blankSymbol = _metadataString(rootMetadata, 'blankSymbol') ?? 'B';
    } on FormatException catch (error) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        error.message,
        '/structure/turingLabTm',
      );
    }
    final rootId =
        metadataId ??
        automaton.getAttribute('turingLabMachineId') ??
        deterministicContentId('imported_tm_blocks', automaton.toXmlString());
    final parsedRoot = _parseBlockAutomaton(
      automaton,
      tapeCount: tapeCount,
      blankSymbol: blankSymbol,
      machineId: rootId,
      machineName: metadataName ?? 'Imported Turing Machine',
      epoch: epoch,
      metadata: rootMetadata,
    );
    final definitions = <String, TMBlockDefinition>{};
    final tagsInProgress = <String>{};
    final definitionIdByTag = <String, String>{};

    TMBlockDefinition resolve(_RawBlockInvocation reference) {
      final existingId = definitionIdByTag[reference.tag];
      if (existingId != null) return definitions[existingId]!;
      if (!tagsInProgress.add(reference.tag)) {
        throw _BlockXmlException(
          CodecMalformedReason.invalidValue,
          'JFLAP TM building blocks contain a recursive dependency.',
          '/structure/automaton/${reference.tag}',
        );
      }
      final candidates = root.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == reference.tag)
          .toList();
      if (candidates.length != 1) {
        throw _BlockXmlException(
          candidates.isEmpty
              ? CodecMalformedReason.missingField
              : CodecMalformedReason.duplicateIdentity,
          candidates.isEmpty
              ? 'JFLAP block ${reference.tag} has no submachine definition.'
              : 'JFLAP block ${reference.tag} has ambiguous definitions.',
          '/structure/automaton/${reference.tag}',
        );
      }
      final element = candidates.single;
      final definitionId =
          element.getAttribute('turingLabBlockId') ?? reference.blockId;
      final revision =
          int.tryParse(element.getAttribute('turingLabRevision') ?? '') ??
          reference.revision;
      final definitionName =
          element.getAttribute('turingLabBlockName') ?? reference.blockName;
      final parsed = _parseBlockAutomaton(
        element,
        tapeCount: tapeCount,
        blankSymbol: blankSymbol,
        machineId: definitionId,
        machineName: definitionName,
        epoch: epoch,
      );
      for (final child in parsed.rawInvocations) {
        resolve(child);
      }
      final definition = TMBlockDefinition(
        id: definitionId,
        name: definitionName,
        revision: revision,
        machine: parsed.machine,
        invocations: parsed.invocations,
      );
      definitionIdByTag[reference.tag] = definitionId;
      definitions[definitionId] = definition;
      tagsInProgress.remove(reference.tag);
      return definition;
    }

    for (final reference in parsedRoot.rawInvocations) {
      resolve(reference);
    }
    for (final element in automaton.childElements.where(
      (candidate) =>
          candidate.name.local != 'block' &&
          candidate.getAttribute('turingLabBlockId') != null,
    )) {
      resolve(
        _RawBlockInvocation(
          tag: element.name.local,
          blockId: element.getAttribute('turingLabBlockId')!,
          blockName:
              element.getAttribute('turingLabBlockName') ?? element.name.local,
          revision:
              int.tryParse(element.getAttribute('turingLabRevision') ?? '') ??
              1,
        ),
      );
    }

    List<TMBlockInvocationNode> bind(
      List<TMBlockInvocationNode> invocations,
      List<_RawBlockInvocation> raw,
    ) {
      return List<TMBlockInvocationNode>.generate(invocations.length, (index) {
        final definitionId = definitionIdByTag[raw[index].tag]!;
        final definition = definitions[definitionId]!;
        return invocations[index].copyWith(
          reference: TMBlockReference(
            blockId: definitionId,
            revision: definition.revision,
          ),
        );
      }, growable: false);
    }

    final reboundDefinitions = <String, TMBlockDefinition>{};
    for (final entry in definitions.entries) {
      final tag = definitionIdByTag.entries
          .firstWhere((candidate) => candidate.value == entry.key)
          .key;
      final element = root.descendants.whereType<XmlElement>().firstWhere(
        (candidate) => candidate.name.local == tag,
      );
      final parsed = _parseBlockAutomaton(
        element,
        tapeCount: tapeCount,
        blankSymbol: blankSymbol,
        machineId: entry.key,
        machineName: entry.value.name,
        epoch: epoch,
      );
      reboundDefinitions[entry.key] = entry.value.copyWith(
        invocations: bind(parsed.invocations, parsed.rawInvocations),
      );
    }
    final machine = parsedRoot.machine.copyWith(
      blockDefinitions: reboundDefinitions,
      blockInvocations: bind(parsedRoot.invocations, parsedRoot.rawInvocations),
    );
    final report = TMBlockDependencyAnalyzer.analyze(
      TMBlockProject(rootMachine: machine),
    );
    final firstError = report.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity == TMBlockDiagnosticSeverity.error,
        )
        .firstOrNull;
    if (firstError != null) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        firstError.message,
        '/structure/automaton',
      );
    }
    final droppedUnknownXml = _hasUnknownBuildingBlockXml(root);
    return CodecSuccess(
      value: InteroperableDocument<Object>(
        document: machine,
        systemKey: DefaultFormalSystemIds.tm,
        schema: TmJsonDocumentCodec.schema,
        sourceMetadata: const DocumentSourceMetadata(
          application: 'JFLAP',
          sourceFormatVersion: '4+ building blocks',
        ),
      ),
      fidelity: droppedUnknownXml
          ? DocumentFidelity.lossy
          : DocumentFidelity.normalized,
      diagnostics: [
        CodecDiagnostic(
          code: 'jflap.tm.building-blocks',
          message:
              'JFLAP building blocks were imported without flattening; absent profile acceptance settings use final-state acceptance.',
          structuredMessage: TmJflapMessages.buildingBlocksImported(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
        CodecDiagnostic(
          code: 'jflap.tm.shared-tapes',
          message: 'Nested machines share tapes and head positions.',
          structuredMessage: TmJflapMessages.sharedTapes(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
        if (droppedUnknownXml)
          CodecDiagnostic(
            code: 'jflap.tm-building-block-unknown-extension-dropped',
            message:
                'Unknown optional XML inside the building-block project was not retained.',
            path: '/structure/automaton',
            structuredMessage:
                TmJflapMessages.unknownBuildingBlockExtensionDropped(),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
      ],
    );
  } on _BlockUnsupportedException catch (error) {
    return CodecUnsupported(
      reason: CodecUnsupportedReason.feature,
      message: error.message,
      structuredMessage: TmJflapMessages.unsupportedFromLegacy(error.message),
    );
  } on _BlockXmlException catch (error) {
    return CodecMalformed(
      reason: error.reason,
      message: error.message,
      location: CodecSourceLocation(path: error.path),
      structuredMessage: TmJflapMessages.malformedFromLegacy(error.message),
    );
  } on FormatException catch (error) {
    return CodecMalformed(
      reason: CodecMalformedReason.invalidValue,
      message: error.message,
      location: const CodecSourceLocation(path: '/structure/turingLabTm'),
      cause: error,
      structuredMessage: TmJflapMessages.invalidMetadata(),
    );
  }
}

_ParsedBlockAutomaton _parseBlockAutomaton(
  XmlElement automaton, {
  required int tapeCount,
  required String blankSymbol,
  required String machineId,
  required String machineName,
  required DateTime epoch,
  Map<String, dynamic> metadata = const {},
}) {
  final customMachine = automaton.getElement('turingLabMachine');
  final customMetadata = customMachine == null
      ? const <String, dynamic>{}
      : _jsonObject(
          customMachine.innerText,
          '/structure/automaton/turingLabMachine',
        );
  if (customMetadata.containsKey('acceptancePolicy') &&
      metadata.containsKey('acceptancePolicy') &&
      customMetadata['acceptancePolicy'] != metadata['acceptancePolicy']) {
    throw const _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'The root and machine acceptance policies conflict.',
      '/structure/automaton/turingLabMachine/acceptancePolicy',
    );
  }
  final machineMetadata = <String, dynamic>{...customMetadata, ...metadata};
  final resolvedMachineId = _metadataString(machineMetadata, 'id') ?? machineId;
  final resolvedMachineName =
      _metadataString(machineMetadata, 'name') ?? machineName;
  if (machineMetadata['schema'] != null &&
      machineMetadata['schema'] != 'turing-lab.tm@1') {
    throw const _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has an invalid Turing Lab schema.',
      '/structure/automaton/turingLabMachine/schema',
    );
  }
  final declaredVariant = machineMetadata['variant'];
  if (declaredVariant != null &&
      (declaredVariant is! String ||
          !TMDocumentVariant.values.any(
            (variant) => variant.name == declaredVariant,
          ))) {
    throw const _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has an invalid TM variant.',
      '/structure/automaton/turingLabMachine/variant',
    );
  }
  final declaredTapeCount = machineMetadata['tapeCount'];
  if (declaredTapeCount != null &&
      (declaredTapeCount is! int || declaredTapeCount != tapeCount)) {
    throw const _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has a mismatched tape count.',
      '/structure/automaton/turingLabMachine/tapeCount',
    );
  }
  final declaredBlank = machineMetadata['blankSymbol'];
  if (declaredBlank != null && declaredBlank != blankSymbol) {
    throw const _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has a mismatched blank symbol.',
      '/structure/automaton/turingLabMachine/blankSymbol',
    );
  }
  late final TMAcceptancePolicy acceptancePolicy;
  try {
    acceptancePolicy = _metadataAcceptancePolicy(machineMetadata);
  } on FormatException catch (error) {
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      error.message,
      '/structure/automaton/turingLabMachine/acceptancePolicy',
    );
  }
  final stateElements = <XmlElement>[
    ...automaton.findElements('state'),
    ...automaton.findElements('block'),
  ];
  final states = <State>[];
  final statesById = <String, State>{};
  final invocations = <TMBlockInvocationNode>[];
  final rawInvocations = <_RawBlockInvocation>[];
  var initialCount = 0;
  for (final element in stateElements) {
    final id = element.getAttribute('id')?.trim();
    if (id == null || id.isEmpty || statesById.containsKey(id)) {
      throw _BlockXmlException(
        id == null || id.isEmpty
            ? CodecMalformedReason.missingField
            : CodecMalformedReason.duplicateIdentity,
        'JFLAP TM state and block ids must be non-empty and unique.',
        '/structure/automaton/${element.name.local}',
      );
    }
    final x = double.tryParse(element.getElement('x')?.innerText ?? '');
    final y = double.tryParse(element.getElement('y')?.innerText ?? '');
    if (x == null || y == null) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM node $id has invalid coordinates.',
        '/structure/automaton/${element.name.local}[@id="$id"]',
      );
    }
    final initial = element.findElements('initial').isNotEmpty;
    if (initial) initialCount++;
    final name = element.getAttribute('name') ?? 'q$id';
    final custom = element.getElement('turingLabState');
    final customData = custom == null
        ? const <String, dynamic>{}
        : _jsonObject(
            custom.innerText,
            '/structure/automaton/${element.name.local}[@id="$id"]/turingLabState',
          );
    final stateTypeName = customData['type'];
    if (stateTypeName != null &&
        (stateTypeName is! String ||
            !StateType.values.any((value) => value.name == stateTypeName))) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM node $id has an invalid state type.',
        '/structure/automaton/${element.name.local}[@id="$id"]/turingLabState/type',
      );
    }
    final stateProperties = customData['properties'];
    if (stateProperties != null && stateProperties is! Map) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM node $id has invalid state properties.',
        '/structure/automaton/${element.name.local}[@id="$id"]/turingLabState/properties',
      );
    }
    final state = State(
      id: id,
      label: element.getElement('label')?.innerText ?? name,
      position: Vector2(x, y),
      isInitial: initial,
      isAccepting: element.findElements('final').isNotEmpty,
      type: StateType.values.firstWhere(
        (value) => value.name == stateTypeName,
        orElse: () => StateType.normal,
      ),
      properties: Map<String, dynamic>.from(stateProperties as Map? ?? {}),
    );
    states.add(state);
    statesById[id] = state;
    if (element.name.local == 'block') {
      final tag = element.getElement('tag')?.innerText.trim();
      if (tag == null || tag.isEmpty) {
        throw _BlockXmlException(
          CodecMalformedReason.missingField,
          'JFLAP building block $id has no <tag> reference.',
          '/structure/automaton/block[@id="$id"]/tag',
        );
      }
      final blockId =
          element.getAttribute('turingLabBlockId') ??
          deterministicContentId('tm_block', tag);
      final revision =
          int.tryParse(element.getAttribute('turingLabRevision') ?? '') ?? 1;
      final invocationId =
          element.getAttribute('turingLabInvocationId') ??
          deterministicContentId(
            'tm_block_invocation',
            '$resolvedMachineId:$id:$tag',
          );
      invocations.add(
        TMBlockInvocationNode(
          id: invocationId,
          stateId: id,
          reference: TMBlockReference(blockId: blockId, revision: revision),
        ),
      );
      rawInvocations.add(
        _RawBlockInvocation(
          tag: tag,
          blockId: blockId,
          blockName: name,
          revision: revision,
        ),
      );
    }
  }
  if (states.isEmpty || initialCount != 1) {
    throw const _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'Every JFLAP TM block definition requires states and one initial state.',
      '/structure/automaton',
    );
  }

  final transitions = <TMTransition>[];
  final transitionIds = <String>{};
  final tapeAlphabet = <String>{blankSymbol};
  final inputAlphabet = <String>{};
  final transitionElements = automaton.findElements('transition').toList();
  for (var index = 0; index < transitionElements.length; index++) {
    final element = transitionElements[index];
    final fromId = element.getElement('from')?.innerText.trim();
    final toId = element.getElement('to')?.innerText.trim();
    final from = statesById[fromId];
    final to = statesById[toId];
    if (from == null || to == null) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM transition references an unknown state.',
        '/structure/automaton/transition[$index]',
      );
    }
    final isBlockTransition = element.getAttribute('block') == 'true';
    final reads = List<String>.filled(tapeCount, blankSymbol);
    final writes = List<String>.filled(tapeCount, blankSymbol);
    final moves = List<TapeDirection>.filled(
      tapeCount,
      isBlockTransition ? TapeDirection.stay : TapeDirection.right,
    );
    for (final tag in const ['read', 'write', 'move']) {
      final seenTapes = <int>{};
      for (final child in element.findElements(tag)) {
        final tape = int.tryParse(child.getAttribute('tape') ?? '1');
        if (tape == null ||
            tape < 1 ||
            tape > tapeCount ||
            !seenTapes.add(tape)) {
          throw _BlockXmlException(
            CodecMalformedReason.invalidValue,
            'JFLAP TM transition has an invalid or duplicate tape index.',
            '/structure/automaton/transition[$index]/$tag',
          );
        }
        final value = child.innerText;
        if (tag == 'read') {
          if (_usesJflapReadPredicate(value)) {
            throw const _BlockUnsupportedException(
              'JFLAP wildcard, negated, and variable TM reads are not supported.',
            );
          }
          if (value.isNotEmpty && value.length != 1) {
            throw _BlockXmlException(
              CodecMalformedReason.invalidValue,
              'JFLAP TM read symbols must contain one UTF-16 code unit.',
              '/structure/automaton/transition[$index]/read',
            );
          }
          reads[tape - 1] = _jflapSymbol(value, blankSymbol);
        }
        if (tag == 'write') {
          if (value.isNotEmpty && value.length != 1) {
            throw _BlockXmlException(
              CodecMalformedReason.invalidValue,
              'JFLAP TM write symbols must contain one UTF-16 code unit.',
              '/structure/automaton/transition[$index]/write',
            );
          }
          writes[tape - 1] = _jflapSymbol(value, blankSymbol);
        }
        if (tag == 'move') {
          final direction = _direction(value);
          if (direction == null) {
            throw _BlockXmlException(
              CodecMalformedReason.invalidValue,
              'JFLAP TM movement must be L, R, or S.',
              '/structure/automaton/transition[$index]/move',
            );
          }
          moves[tape - 1] = direction;
        }
      }
    }
    if (isBlockTransition) {
      for (var tape = 0; tape < tapeCount; tape++) {
        writes[tape] = reads[tape];
        moves[tape] = TapeDirection.stay;
      }
    }
    final signature = _signature(from.id, to.id, reads, writes, moves);
    final custom = element.getElement('turingLabTransition');
    final customData = custom == null
        ? const <String, dynamic>{}
        : _jsonObject(
            custom.innerText,
            '/structure/automaton/transition[$index]/turingLabTransition',
          );
    final customId = customData['id'];
    final attributeId = element.getAttribute('turingLabTransitionId');
    if (customId != null && (customId is! String || customId.isEmpty)) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM transition $index has an invalid Turing Lab id.',
        '/structure/automaton/transition[$index]/turingLabTransition/id',
      );
    }
    if (customId != null && attributeId != null && customId != attributeId) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM transition identity extensions disagree.',
        '/structure/automaton/transition[$index]',
      );
    }
    final id =
        customId as String? ??
        attributeId ??
        deterministicContentId(
          'tm_transition',
          '$resolvedMachineId:$signature',
        );
    if (!transitionIds.add(id)) {
      throw _BlockXmlException(
        CodecMalformedReason.duplicateIdentity,
        'JFLAP TM transition ids must be unique.',
        '/structure/automaton/transition[$index]',
      );
    }
    final rawLabel = customData['label'];
    if (rawLabel != null && rawLabel is! String) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM transition $id has an invalid label.',
        '/structure/automaton/transition[$index]/turingLabTransition/label',
      );
    }
    final transitionTypeName = customData['type'];
    if (transitionTypeName != null &&
        (transitionTypeName is! String ||
            !TransitionType.values.any(
              (value) => value.name == transitionTypeName,
            ))) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM transition $id has an invalid type.',
        '/structure/automaton/transition[$index]/turingLabTransition/type',
      );
    }
    transitions.add(
      TMTransition(
        id: id,
        fromState: from,
        toState: to,
        label:
            rawLabel as String? ??
            TMTransition.formatVectorLabel(
              readSymbols: reads,
              writeSymbols: writes,
              directions: moves,
            ),
        controlPoint: _controlPoint(customData),
        type: TransitionType.values.firstWhere(
          (value) => value.name == transitionTypeName,
          orElse: () => TransitionType.deterministic,
        ),
        readSymbols: reads,
        writeSymbols: writes,
        directions: moves,
      ),
    );
    tapeAlphabet
      ..addAll(reads)
      ..addAll(writes);
    if (reads.first != blankSymbol) inputAlphabet.add(reads.first);
  }
  states.sort((left, right) => left.id.compareTo(right.id));
  final machine = TM(
    id: resolvedMachineId,
    name: resolvedMachineName,
    states: states.toSet(),
    transitions: transitions.toSet(),
    alphabet: _metadataStringSet(machineMetadata, 'alphabet') ?? inputAlphabet,
    initialState: states.firstWhere((state) => state.isInitial),
    acceptingStates: states.where((state) => state.isAccepting).toSet(),
    created: _metadataDate(machineMetadata, 'created', epoch),
    modified: _metadataDate(machineMetadata, 'modified', epoch),
    bounds: _metadataBounds(machineMetadata) ?? _bounds(states),
    zoomLevel: _metadataNumber(machineMetadata, 'zoomLevel', 1),
    panOffset: _metadataPan(machineMetadata),
    tapeAlphabet:
        _metadataStringSet(machineMetadata, 'tapeAlphabet') ?? tapeAlphabet,
    blankSymbol: blankSymbol,
    tapeCount: tapeCount,
    acceptancePolicy: acceptancePolicy,
  );
  return _ParsedBlockAutomaton(
    machine: machine,
    invocations: invocations,
    rawInvocations: rawInvocations,
  );
}

CodecOutcome<EncodedDocument> _encodeBuildingBlockDocument(
  InteroperableDocument<Object> document,
  TM machine, {
  String? filename,
}) {
  if (machine.tapeCount < 1 || machine.tapeCount > 5) {
    return CodecUnsupported(
      reason: CodecUnsupportedReason.feature,
      message: 'JFLAP supports Turing machines with 1 to 5 tapes.',
      structuredMessage: TmJflapMessages.unsupportedTapeCount(),
    );
  }
  final report = TMBlockDependencyAnalyzer.analyze(
    TMBlockProject(rootMachine: machine),
  );
  final firstError = report.diagnostics
      .where(
        (diagnostic) => diagnostic.severity == TMBlockDiagnosticSeverity.error,
      )
      .firstOrNull;
  if (firstError != null) {
    return CodecMalformed(
      reason: CodecMalformedReason.invalidValue,
      message: firstError.message,
      location: const CodecSourceLocation(path: r'$.document.blockDefinitions'),
      structuredMessage: TmJflapMessages.invalidDocument(),
    );
  }
  for (final current in [
    machine,
    ...machine.blockDefinitions.values.map((definition) => definition.machine),
  ]) {
    final validation = _firstTmCodecValidationError(current);
    if (validation != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: validation,
        location: const CodecSourceLocation(path: r'$.document'),
        structuredMessage: TmJflapMessages.invalidDocument(),
      );
    }
    final unsupported = _jflapUnsupportedOperation(current);
    if (unsupported != null) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: unsupported,
        structuredMessage: TmJflapMessages.unsupportedFromLegacy(unsupported),
      );
    }
  }
  final tags = {
    for (final id in machine.blockDefinitions.keys) id: _blockTag(id),
  };
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element(
    'structure',
    nest: () {
      builder.element('type', nest: 'turing');
      if (machine.tapeCount > 1) {
        builder.element('tapes', nest: machine.tapeCount.toString());
      }
      builder.element(
        'turingLabTm',
        nest: convert.jsonEncode(_tmMetadata(machine)),
      );
      builder.element(
        'automaton',
        nest: () {
          builder.attribute('turingLabMachineId', machine.id);
          _writeBlockMachine(
            builder,
            machine,
            machine.blockInvocations,
            machine.blockDefinitions,
            tags,
          );
          final definitions = machine.blockDefinitions.values.toList()
            ..sort((a, b) => a.id.compareTo(b.id));
          for (final definition in definitions) {
            builder.element(
              tags[definition.id]!,
              nest: () {
                builder.attribute('turingLabBlockId', definition.id);
                builder.attribute('turingLabBlockName', definition.name);
                builder.attribute(
                  'turingLabRevision',
                  '${definition.revision}',
                );
                builder.attribute('turingLabMachineId', definition.machine.id);
                _writeBlockMachine(
                  builder,
                  definition.machine,
                  definition.invocations,
                  machine.blockDefinitions,
                  tags,
                );
              },
            );
          }
        },
      );
    },
  );
  final xml = builder.buildDocument().toXmlString(pretty: true);
  return CodecSuccess(
    value: EncodedDocument(
      bytes: utf8Bytes('$xml\n'),
      mimeType: 'application/xml',
      filename: filenameWithExtension(filename, 'machine', 'jff'),
      schema: TmJsonDocumentCodec.schema,
    ),
    fidelity: DocumentFidelity.lossy,
    diagnostics: [
      CodecDiagnostic(
        code: 'jflap.tm.building-blocks',
        message: 'TM building blocks were exported without flattening.',
        structuredMessage: TmJflapMessages.buildingBlocksExported(),
        disposition: CodecDiagnosticDisposition.normalized,
      ),
      CodecDiagnostic(
        code: 'jflap.tm.extension-identities',
        message:
            'Stable block revisions and invocation IDs use ignored XML attributes.',
        structuredMessage: TmJflapMessages.extensionIdentities(),
        disposition: CodecDiagnosticDisposition.dropped,
      ),
      CodecDiagnostic(
        code: 'jflap.tm-turing-lab-extension-portability',
        message:
            'JFLAP open/save discards Turing Lab acceptance policy, machine metadata, state properties, transition identities, and block revisions.',
        path: '/structure/turingLabTm',
        structuredMessage: TmJflapMessages.extensionPortability(),
        disposition: CodecDiagnosticDisposition.dropped,
      ),
    ],
  );
}

void _writeBlockMachine(
  XmlBuilder builder,
  TM machine,
  List<TMBlockInvocationNode> invocations,
  Map<String, TMBlockDefinition> definitions,
  Map<String, String> tags,
) {
  builder.element(
    'turingLabMachine',
    nest: convert.jsonEncode(_tmMetadata(machine)),
  );
  final invocationByState = {
    for (final invocation in invocations) invocation.stateId: invocation,
  };
  final states = machine.states.toList()..sort((a, b) => a.id.compareTo(b.id));
  for (final state in states) {
    final invocation = invocationByState[state.id];
    builder.element(
      invocation == null ? 'state' : 'block',
      nest: () {
        builder.attribute('id', state.id);
        builder.attribute('name', state.label);
        if (invocation != null) {
          final definition = definitions[invocation.reference.blockId]!;
          builder.attribute('turingLabInvocationId', invocation.id);
          builder.attribute('turingLabBlockId', definition.id);
          builder.attribute('turingLabRevision', '${definition.revision}');
          builder.element('tag', nest: tags[definition.id]);
        }
        builder.element('x', nest: formatXmlNumber(state.position.x));
        builder.element('y', nest: formatXmlNumber(state.position.y));
        if (state.label != state.id)
          builder.element('label', nest: state.label);
        if (state.isInitial) builder.element('initial');
        if (state.isAccepting) builder.element('final');
        if (state.type != StateType.normal || state.properties.isNotEmpty) {
          builder.element(
            'turingLabState',
            nest: convert.jsonEncode({
              'type': state.type.name,
              'properties': state.properties,
            }),
          );
        }
      },
    );
  }
  final transitions = machine.tmTransitions.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  for (final transition in transitions) {
    final operations = transition.operationsForTapeCount(
      machine.tapeCount,
      machine.blankSymbol,
    );
    builder.element(
      'transition',
      nest: () {
        builder.attribute('turingLabTransitionId', transition.id);
        builder.element('from', nest: transition.fromState.id);
        builder.element('to', nest: transition.toState.id);
        for (var tape = 0; tape < machine.tapeCount; tape++) {
          final attributes = machine.tapeCount > 1
              ? <String, String>{'tape': '${tape + 1}'}
              : const <String, String>{};
          _element(
            builder,
            'read',
            operations.readSymbols[tape],
            machine.blankSymbol,
            attributes,
          );
          _element(
            builder,
            'write',
            operations.writeSymbols[tape],
            machine.blankSymbol,
            attributes,
          );
          builder.element(
            'move',
            attributes: attributes,
            nest: operations.directions[tape].symbol,
          );
        }
        builder.element(
          'turingLabTransition',
          nest: convert.jsonEncode({
            'id': transition.id,
            'label': transition.label,
            'type': transition.type.name,
            'controlPoint': {
              'x': transition.controlPoint.x,
              'y': transition.controlPoint.y,
            },
          }),
        );
      },
    );
  }
}

String _blockTag(String blockId) {
  final encoded = convert.base64Url.encode(convert.utf8.encode(blockId));
  return 'turing_lab_block_${encoded.replaceAll('=', '')}';
}

bool _hasUnknownBuildingBlockXml(XmlElement root) {
  bool hasUnknownAttributes(XmlElement element, Set<String> known) => element
      .attributes
      .any((attribute) => !known.contains(attribute.name.local));

  bool hasUnknownChildren(XmlElement element, Set<String> known) =>
      element.childElements.any((child) => !known.contains(child.name.local));

  if (hasUnknownAttributes(root, const {'type'}) ||
      hasUnknownChildren(root, const {
        'type',
        'tapes',
        'turingLabTm',
        'automaton',
      })) {
    return true;
  }
  final automaton = root.findElements('automaton').firstOrNull;
  if (automaton == null ||
      hasUnknownAttributes(automaton, const {'turingLabMachineId'})) {
    return true;
  }

  bool inspectNode(XmlElement element) {
    final isBlock = element.name.local == 'block';
    final knownAttributes = isBlock
        ? const {
            'id',
            'name',
            'turingLabInvocationId',
            'turingLabBlockId',
            'turingLabRevision',
          }
        : const {'id', 'name'};
    final knownChildren = isBlock
        ? const {'tag', 'x', 'y', 'label', 'initial', 'final', 'turingLabState'}
        : const {'x', 'y', 'label', 'initial', 'final', 'turingLabState'};
    return hasUnknownAttributes(element, knownAttributes) ||
        hasUnknownChildren(element, knownChildren);
  }

  bool inspectTransition(XmlElement element) {
    if (hasUnknownAttributes(element, const {
          'block',
          'turingLabTransitionId',
        }) ||
        hasUnknownChildren(element, const {
          'from',
          'to',
          'read',
          'write',
          'move',
          'turingLabTransition',
        })) {
      return true;
    }
    return element.childElements
        .where(
          (child) => const {'read', 'write', 'move'}.contains(child.name.local),
        )
        .any((child) => hasUnknownAttributes(child, const {'tape'}));
  }

  bool inspectMachine(XmlElement machine) {
    for (final child in machine.childElements) {
      if (child.name.local == 'turingLabMachine') {
        if (child.attributes.isNotEmpty || child.childElements.isNotEmpty) {
          return true;
        }
        continue;
      }
      if (child.name.local == 'state' || child.name.local == 'block') {
        if (inspectNode(child)) return true;
        continue;
      }
      if (child.name.local == 'transition') {
        if (inspectTransition(child)) return true;
        continue;
      }
      if (child.getAttribute('turingLabBlockId') == null) return true;
      if (hasUnknownAttributes(child, const {
        'turingLabBlockId',
        'turingLabBlockName',
        'turingLabRevision',
        'turingLabMachineId',
      })) {
        return true;
      }
      if (inspectMachine(child)) return true;
    }
    return false;
  }

  return inspectMachine(automaton);
}

class _ParsedBlockAutomaton {
  const _ParsedBlockAutomaton({
    required this.machine,
    required this.invocations,
    required this.rawInvocations,
  });

  final TM machine;
  final List<TMBlockInvocationNode> invocations;
  final List<_RawBlockInvocation> rawInvocations;
}

class _RawBlockInvocation {
  const _RawBlockInvocation({
    required this.tag,
    required this.blockId,
    required this.blockName,
    required this.revision,
  });

  final String tag;
  final String blockId;
  final String blockName;
  final int revision;
}

class _BlockXmlException implements Exception {
  const _BlockXmlException(this.reason, this.message, this.path);

  final CodecMalformedReason reason;
  final String message;
  final String path;
}

class _BlockUnsupportedException implements Exception {
  const _BlockUnsupportedException(this.message);

  final String message;
}

TapeDirection? _direction(String raw) => switch (raw.trim().toUpperCase()) {
  'L' => TapeDirection.left,
  'R' => TapeDirection.right,
  'S' => TapeDirection.stay,
  _ => null,
};

bool _usesJflapReadPredicate(String symbol) =>
    symbol == '~' || symbol.startsWith('!') || symbol.contains('}');

String _jflapSymbol(String value, String blankSymbol) =>
    value.isEmpty || value == '□' ? blankSymbol : value;

Map<String, Object?> _tmMetadata(TM machine) => {
  'schema': 'turing-lab.tm@1',
  'variant': machine.documentVariant.name,
  'id': machine.id,
  'name': machine.name,
  'alphabet': machine.alphabet.toList()..sort(),
  'tapeAlphabet': machine.tapeAlphabet.toList()..sort(),
  'blankSymbol': machine.blankSymbol,
  'tapeCount': machine.tapeCount,
  if (machine.acceptancePolicy != TMAcceptancePolicy.finalState)
    'acceptancePolicy': machine.acceptancePolicy.name,
  'created': machine.created.toIso8601String(),
  'modified': machine.modified.toIso8601String(),
  'bounds': {
    'x': machine.bounds.left,
    'y': machine.bounds.top,
    'width': machine.bounds.width,
    'height': machine.bounds.height,
  },
  'zoomLevel': machine.zoomLevel,
  'panOffset': {'x': machine.panOffset.x, 'y': machine.panOffset.y},
};

Map<String, dynamic> _jsonObject(String source, String path) {
  final value = convert.jsonDecode(source);
  if (value is! Map) throw FormatException('Expected a JSON object at $path.');
  return Map<String, dynamic>.from(value);
}

Set<String>? _metadataStringSet(Map<String, dynamic> metadata, String key) {
  final raw = metadata[key];
  if (raw == null) return null;
  if (raw is! List || raw.any((value) => value is! String)) {
    throw FormatException('Turing Lab TM $key must be a string array.');
  }
  return raw.cast<String>().toSet();
}

String? _metadataString(Map<String, dynamic> metadata, String key) {
  final raw = metadata[key];
  if (raw == null) return null;
  if (raw is! String || raw.isEmpty) {
    throw FormatException('Turing Lab TM $key must be a non-empty string.');
  }
  return raw;
}

TMAcceptancePolicy _metadataAcceptancePolicy(Map<String, dynamic> metadata) {
  final raw = metadata['acceptancePolicy'];
  if (raw == null) return TMAcceptancePolicy.finalState;
  if (raw is! String ||
      !TMAcceptancePolicy.values.any((policy) => policy.name == raw)) {
    throw const FormatException('Turing Lab TM acceptancePolicy is invalid.');
  }
  return TMAcceptancePolicy.parse(raw);
}

DateTime _metadataDate(
  Map<String, dynamic> metadata,
  String key,
  DateTime fallback,
) {
  final raw = metadata[key];
  if (raw == null) return fallback;
  if (raw is! String) {
    throw FormatException('Turing Lab TM $key must be an ISO-8601 string.');
  }
  final value = DateTime.tryParse(raw);
  if (value == null) {
    throw FormatException('Turing Lab TM $key is not a valid date.');
  }
  return value;
}

double _metadataNumber(
  Map<String, dynamic> metadata,
  String key,
  double fallback,
) {
  final raw = metadata[key];
  if (raw == null) return fallback;
  if (raw is! num || !raw.toDouble().isFinite) {
    throw FormatException('Turing Lab TM $key must be a finite number.');
  }
  return raw.toDouble();
}

math.Rectangle<double>? _metadataBounds(Map<String, dynamic> metadata) {
  final raw = metadata['bounds'];
  if (raw == null) return null;
  if (raw is! Map) {
    throw const FormatException('Turing Lab TM bounds must be an object.');
  }
  final values = [raw['x'], raw['y'], raw['width'], raw['height']];
  if (values.any((value) => value is! num)) {
    throw const FormatException('Turing Lab TM bounds must be numeric.');
  }
  final numbers = values.cast<num>().map((value) => value.toDouble()).toList();
  if (numbers.any((value) => !value.isFinite) ||
      numbers[2] < 0 ||
      numbers[3] < 0) {
    throw const FormatException('Turing Lab TM bounds are invalid.');
  }
  return math.Rectangle<double>(numbers[0], numbers[1], numbers[2], numbers[3]);
}

Vector2 _metadataPan(Map<String, dynamic> metadata) {
  final raw = metadata['panOffset'];
  if (raw == null) return Vector2.zero();
  if (raw is! Map || raw['x'] is! num || raw['y'] is! num) {
    throw const FormatException('Turing Lab TM panOffset must be numeric.');
  }
  final x = (raw['x'] as num).toDouble();
  final y = (raw['y'] as num).toDouble();
  if (!x.isFinite || !y.isFinite) {
    throw const FormatException('Turing Lab TM panOffset must be finite.');
  }
  return Vector2(x, y);
}

Vector2 _controlPoint(Map<String, dynamic> data) {
  final raw = data['controlPoint'];
  if (raw == null) return Vector2.zero();
  if (raw is! Map || raw['x'] is! num || raw['y'] is! num) {
    throw const FormatException('TM transition controlPoint must be numeric.');
  }
  final x = (raw['x'] as num).toDouble();
  final y = (raw['y'] as num).toDouble();
  if (!x.isFinite || !y.isFinite) {
    throw const FormatException('TM transition controlPoint must be finite.');
  }
  return Vector2(x, y);
}

String? _firstTmCodecValidationError(TM machine) {
  final errors = machine.validate();
  if (machine.states.isEmpty &&
      machine.transitions.isEmpty &&
      machine.initialState == null &&
      machine.acceptingStates.isEmpty) {
    errors.remove('Automaton must have at least one state');
  }
  return errors.firstOrNull;
}

String? _jflapUnsupportedOperation(TM machine) {
  for (final transition in machine.tmTransitions) {
    final operations = transition.operationsForTapeCount(
      machine.tapeCount,
      machine.blankSymbol,
    );
    for (var tape = 0; tape < machine.tapeCount; tape++) {
      final read = operations.readSymbols[tape];
      final write = operations.writeSymbols[tape];
      if (read != machine.blankSymbol &&
          (_usesJflapReadPredicate(read) || read.length != 1)) {
        return 'Transition ${transition.id} uses a read symbol that JFLAP '
            'cannot represent atomically.';
      }
      if (write != machine.blankSymbol && write.length != 1) {
        return 'Transition ${transition.id} uses a write symbol that JFLAP '
            'cannot represent atomically.';
      }
    }
  }
  return null;
}

String _signature(
  String from,
  String to,
  List<String> reads,
  List<String> writes,
  List<TapeDirection> moves,
) => canonicalJson({
  'from': from,
  'to': to,
  'read': reads,
  'write': writes,
  'move': moves.map((move) => move.symbol).toList(),
});

math.Rectangle<double> _bounds(List<State> states) {
  if (states.isEmpty) return const math.Rectangle<double>(0, 0, 800, 600);
  final xs = states.map((state) => state.position.x);
  final ys = states.map((state) => state.position.y);
  final minX = xs.reduce(math.min);
  final maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min);
  final maxY = ys.reduce(math.max);
  return math.Rectangle<double>(minX, minY, maxX - minX + 96, maxY - minY + 96);
}

List<CodecDiagnostic> _withTmDiagnosticMessages(
  List<CodecDiagnostic> diagnostics,
) => [
  for (final diagnostic in diagnostics)
    diagnostic.structuredMessage != null
        ? diagnostic
        : CodecDiagnostic(
            code: diagnostic.code,
            message: diagnostic.message,
            path: diagnostic.path,
            location: diagnostic.location,
            sourceValue: diagnostic.sourceValue,
            disposition: diagnostic.disposition,
            structuredMessage: switch (diagnostic.code) {
              'jflap.unknown-optional-element' =>
                TmJflapMessages.unknownOptionalElement(
                  diagnostic.path ?? 'unknown',
                ),
              'jflap.unknown-optional-attribute' =>
                TmJflapMessages.unknownOptionalAttribute(
                  diagnostic.path ?? 'unknown',
                ),
              'jflap.note-invalid-position-preserved' =>
                TmJflapMessages.invalidNotePosition(),
              'jflap.notes-normalized' => TmJflapMessages.notesNormalized(),
              'jflap.note-presentation-dropped' =>
                TmJflapMessages.notePresentationDropped(),
              _ => TmJflapMessages.unknownDiagnostic(),
            },
          ),
];

CodecOutcome<InteroperableDocument<Object>> _copyTmXmlFailure(
  CodecOutcome<XmlDocument> outcome,
) {
  return switch (outcome) {
    CodecMalformed(
      :final reason,
      :final message,
      :final location,
      :final cause,
      :final structuredMessage,
    ) =>
      CodecMalformed(
        reason: reason,
        message: message,
        location: location,
        cause: cause,
        structuredMessage:
            structuredMessage ??
            (message == 'XML is not valid UTF-8.'
                ? TmJflapMessages.invalidUtf8()
                : TmJflapMessages.malformedXml()),
      ),
    CodecResourceLimit(:final limit, :final maximum, :final actual) =>
      CodecResourceLimit(limit: limit, maximum: maximum, actual: actual),
    CodecInternalFailure(
      :final stage,
      :final message,
      :final cause,
      :final structuredMessage,
    ) =>
      CodecInternalFailure(
        stage: stage,
        message: message,
        cause: cause,
        structuredMessage: structuredMessage,
      ),
    CodecUnsupported(
      :final reason,
      :final message,
      :final roadmapIssue,
      :final structuredMessage,
    ) =>
      CodecUnsupported(
        reason: reason,
        message: message,
        roadmapIssue: roadmapIssue,
        structuredMessage: structuredMessage,
      ),
    CodecAmbiguous(:final codecIds) => CodecAmbiguous(codecIds: codecIds),
    CodecSuccess() => throw StateError('Cannot copy successful XML result'),
  };
}

void _element(
  XmlBuilder builder,
  String name,
  String symbol,
  String blankSymbol,
  Map<String, String> attributes,
) {
  if (symbol == blankSymbol) {
    builder.element(name, attributes: attributes, isSelfClosing: true);
  } else {
    builder.element(name, attributes: attributes, nest: symbol);
  }
}

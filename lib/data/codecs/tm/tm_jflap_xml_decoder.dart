//
//  tm_jflap_xml_decoder.dart
//  Turing Lab
//
//  Decoder for classic JFLAP Turing-machine XML (single tape and the
//  1-5 tape vector form): states, transitions, Turing Lab extensions, sticky
//  notes and fidelity diagnostics. Building-block documents are handled by
//  TmBuildingBlockXmlCodec; the facade decides which one to use.
//

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../../../core/formal_systems/formal_systems.dart';
import '../../../core/interoperability/interoperability.dart';
import '../../../core/models/state.dart';
import '../../../core/models/tm.dart';
import '../../../core/models/tm_acceptance.dart';
import '../../../core/models/tm_transition.dart';
import '../../../core/models/transition.dart';
import '../codec_utils.dart';
import '../jflap_annotations.dart';
import '../tm_jflap_messages.dart';
import '../tm_json_document_codec.dart';
import 'tm_jflap_metadata.dart';
import 'tm_tape_vector_codec.dart';

abstract final class TmJflapXmlDecoder {
  /// Decodes a `<structure>` root already known to be a classic TM document.
  static CodecOutcome<InteroperableDocument<Object>> decode(
    XmlElement root,
    CodecDescriptor descriptor,
  ) {
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
          : TmJflapMetadata.jsonObject(
              metadataElement.innerText,
              '/structure/turingLabTm',
            );
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
      acceptancePolicy = TmJflapMetadata.acceptancePolicy(metadata);
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
            : TmJflapMetadata.jsonObject(
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
      final tapeVector = TmTapeVectorCodec.read(
        element,
        index: index,
        tapeCount: tapeCount,
        blankSymbol: blankSymbol,
        dialect: TmTapeVectorDialect.classic,
      );
      final tapeFailure = _tapeVectorFailure(tapeVector);
      if (tapeFailure != null) return tapeFailure;
      final TmTapeVector(:reads, :writes, :moves) = tapeVector as TmTapeVector;
      final signature = TmTapeVectorCodec.signature(
        from.id,
        to.id,
        reads,
        writes,
        moves,
      );
      final custom = element.getElement('turingLabTransition');
      late final Map<String, dynamic> customData;
      try {
        customData = custom == null
            ? const <String, dynamic>{}
            : TmJflapMetadata.jsonObject(
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
        controlPoint = TmJflapMetadata.controlPoint(customData);
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
      declaredAlphabet = TmJflapMetadata.stringSet(metadata, 'alphabet');
      declaredTapeAlphabet = TmJflapMetadata.stringSet(
        metadata,
        'tapeAlphabet',
      );
      documentId = TmJflapMetadata.string(metadata, 'id');
      documentName = TmJflapMetadata.string(metadata, 'name');
      created = TmJflapMetadata.date(metadata, 'created', epoch);
      modified = TmJflapMetadata.date(metadata, 'modified', epoch);
      declaredBounds = TmJflapMetadata.bounds(metadata);
      zoomLevel = TmJflapMetadata.number(metadata, 'zoomLevel', 1);
      panOffset = TmJflapMetadata.panOffset(metadata);
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
      bounds: declaredBounds ?? TmJflapMetadata.boundsForStates(states),
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
    final validation = TmJflapMetadata.firstValidationError(machine);
    if (validation != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: validation,
        location: const CodecSourceLocation(path: '/structure/automaton'),
        structuredMessage: TmJflapMessages.invalidDocument(),
      );
    }
    final resolvedDiagnostics = TmJflapMetadata.withDiagnosticMessages(
      diagnostics,
    );
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

  static CodecOutcome<InteroperableDocument<Object>>? _tapeVectorFailure(
    TmTapeVectorOutcome outcome,
  ) => switch (outcome) {
    TmTapeVector() => null,
    TmTapeVectorMalformed(
      :final reason,
      :final message,
      :final path,
      :final structuredMessage,
    ) =>
      CodecMalformed(
        reason: reason,
        message: message,
        location: CodecSourceLocation(path: path),
        structuredMessage: structuredMessage,
      ),
    TmTapeVectorUnsupported(:final message, :final structuredMessage) =>
      CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: message,
        structuredMessage: structuredMessage,
      ),
  };
}

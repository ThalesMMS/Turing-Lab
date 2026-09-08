//
//  tm_building_block_xml_codec.dart
//  Turing Lab
//
//  JFLAP building-block Turing-machine XML: nested submachine definitions
//  referenced by `<block>` tags, hierarchical binding of invocations to
//  definitions, dependency validation and the loss-aware round trip of the
//  Turing Lab identity attributes.
//

import 'dart:convert' as convert;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../../../core/algorithms/tm/tm_block_dependency_analyzer.dart';
import '../../../core/messages/structured_message.dart';
import '../../../core/models/tm_building_blocks.dart';
import '../../../core/formal_systems/formal_systems.dart';
import '../../../core/interoperability/interoperability.dart';
import '../../../core/models/state.dart';
import '../../../core/models/tm.dart';
import '../../../core/models/tm_acceptance.dart';
import '../../../core/models/tm_transition.dart';
import '../../../core/models/transition.dart';
import '../codec_utils.dart';
import '../tm_jflap_messages.dart';
import '../tm_json_document_codec.dart';
import 'tm_jflap_metadata.dart';
import 'tm_tape_vector_codec.dart';

abstract final class TmBuildingBlockXmlCodec {
  /// Decodes a `<structure>` root that contains `<block>` elements or Turing
  /// Lab building-block attributes.
  static CodecOutcome<InteroperableDocument<Object>> decode(
    XmlElement root,
    CodecDescriptor descriptor,
  ) => _decodeBuildingBlockDocument(root, descriptor);

  static CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document,
    TM machine, {
    String? filename,
  }) => _encodeBuildingBlockDocument(document, machine, filename: filename);
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
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP tape count must be between 1 and 5.',
        '/structure/tapes',
        structuredMessage: TmJflapMessages.invalidTapeCount(),
      );
    }
    final automaton = root.findElements('automaton').firstOrNull;
    if (automaton == null) {
      throw _BlockXmlException(
        CodecMalformedReason.missingField,
        'JFLAP TM is missing <automaton>.',
        '/structure/automaton',
        structuredMessage: TmJflapMessages.missingAutomaton(),
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
          : TmJflapMetadata.jsonObject(
              metadataElement.innerText,
              '/structure/turingLabTm',
            );
    } on FormatException catch (error) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        error.message,
        '/structure/turingLabTm',
        structuredMessage: TmJflapMessages.invalidMetadata(),
      );
    }
    if (rootMetadata['variant'] != null &&
        rootMetadata['variant'] != TMDocumentVariant.buildingBlocks.name) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'The Turing Lab TM variant does not match the building-block XML.',
        '/structure/turingLabTm/variant',
        structuredMessage: TmJflapMessages.buildingBlockVariantMismatch(),
      );
    }
    if (rootMetadata['tapeCount'] != null &&
        (rootMetadata['tapeCount'] is! int ||
            rootMetadata['tapeCount'] != tapeCount)) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'The Turing Lab tape count does not match <tapes>.',
        '/structure/turingLabTm/tapeCount',
        structuredMessage: TmJflapMessages.tapeCountMismatch(),
      );
    }
    late final String? metadataId;
    late final String? metadataName;
    late final String blankSymbol;
    try {
      metadataId = TmJflapMetadata.string(rootMetadata, 'id');
      metadataName = TmJflapMetadata.string(rootMetadata, 'name');
      blankSymbol = TmJflapMetadata.string(rootMetadata, 'blankSymbol') ?? 'B';
    } on FormatException catch (error) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        error.message,
        '/structure/turingLabTm',
        structuredMessage: TmJflapMessages.invalidMetadata(),
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
    final definitionTagById = <String, String>{};

    TMBlockDefinition resolve(_RawBlockInvocation reference) {
      final existingId = definitionIdByTag[reference.tag];
      if (existingId != null) return definitions[existingId]!;
      if (!tagsInProgress.add(reference.tag)) {
        throw _BlockXmlException(
          CodecMalformedReason.invalidValue,
          'JFLAP TM building blocks contain a recursive dependency.',
          '/structure/automaton/${reference.tag}',
          structuredMessage: TmJflapMessages.recursiveDependency(reference.tag),
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
          structuredMessage: candidates.isEmpty
              ? TmJflapMessages.missingBlockDefinition(reference.tag)
              : TmJflapMessages.ambiguousBlockDefinition(reference.tag),
        );
      }
      final element = candidates.single;
      final definitionId =
          element.getAttribute('turingLabBlockId') ?? reference.blockId;
      // Reserve identities before descending into dependencies, so differently
      // named definitions cannot overwrite one another, even while resolving.
      final previousTag = definitionTagById.putIfAbsent(
        definitionId,
        () => reference.tag,
      );
      if (previousTag != reference.tag ||
          definitions.containsKey(definitionId)) {
        throw _BlockXmlException(
          CodecMalformedReason.duplicateIdentity,
          'JFLAP blocks $previousTag and ${reference.tag} reuse block id $definitionId.',
          '/structure/automaton/${reference.tag}',
          structuredMessage: TmJflapMessages.duplicateBlockIdentity(
            definitionId,
            previousTag,
            reference.tag,
          ),
        );
      }
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
        structuredMessage:
            firstError.structuredMessage ?? TmJflapMessages.invalidDocument(),
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
      structuredMessage: error.structuredMessage,
    );
  } on _BlockXmlException catch (error) {
    return CodecMalformed(
      reason: error.reason,
      message: error.message,
      location: CodecSourceLocation(path: error.path),
      structuredMessage: error.structuredMessage,
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
      : TmJflapMetadata.jsonObject(
          customMachine.innerText,
          '/structure/automaton/turingLabMachine',
        );
  if (customMetadata.containsKey('acceptancePolicy') &&
      metadata.containsKey('acceptancePolicy') &&
      customMetadata['acceptancePolicy'] != metadata['acceptancePolicy']) {
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'The root and machine acceptance policies conflict.',
      '/structure/automaton/turingLabMachine/acceptancePolicy',
      structuredMessage: TmJflapMessages.acceptancePolicyConflict(),
    );
  }
  final machineMetadata = <String, dynamic>{...customMetadata, ...metadata};
  final resolvedMachineId =
      TmJflapMetadata.string(machineMetadata, 'id') ?? machineId;
  final resolvedMachineName =
      TmJflapMetadata.string(machineMetadata, 'name') ?? machineName;
  if (machineMetadata['schema'] != null &&
      machineMetadata['schema'] != 'turing-lab.tm@1') {
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has an invalid Turing Lab schema.',
      '/structure/automaton/turingLabMachine/schema',
      structuredMessage: TmJflapMessages.machineSchemaInvalid(),
    );
  }
  final declaredVariant = machineMetadata['variant'];
  if (declaredVariant != null &&
      (declaredVariant is! String ||
          !TMDocumentVariant.values.any(
            (variant) => variant.name == declaredVariant,
          ))) {
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has an invalid TM variant.',
      '/structure/automaton/turingLabMachine/variant',
      structuredMessage: TmJflapMessages.machineVariantInvalid(),
    );
  }
  final declaredTapeCount = machineMetadata['tapeCount'];
  if (declaredTapeCount != null &&
      (declaredTapeCount is! int || declaredTapeCount != tapeCount)) {
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has a mismatched tape count.',
      '/structure/automaton/turingLabMachine/tapeCount',
      structuredMessage: TmJflapMessages.machineTapeCountMismatch(),
    );
  }
  final declaredBlank = machineMetadata['blankSymbol'];
  if (declaredBlank != null && declaredBlank != blankSymbol) {
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'A building-block machine has a mismatched blank symbol.',
      '/structure/automaton/turingLabMachine/blankSymbol',
      structuredMessage: TmJflapMessages.machineBlankSymbolMismatch(),
    );
  }
  late final TMAcceptancePolicy acceptancePolicy;
  try {
    acceptancePolicy = TmJflapMetadata.acceptancePolicy(machineMetadata);
  } on FormatException catch (error) {
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      error.message,
      '/structure/automaton/turingLabMachine/acceptancePolicy',
      structuredMessage: TmJflapMessages.acceptancePolicyInvalid(),
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
        structuredMessage: id == null || id.isEmpty
            ? TmJflapMessages.invalidNodeId()
            : TmJflapMessages.duplicateNodeId(),
      );
    }
    final x = double.tryParse(element.getElement('x')?.innerText ?? '');
    final y = double.tryParse(element.getElement('y')?.innerText ?? '');
    if (x == null || y == null) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM node $id has invalid coordinates.',
        '/structure/automaton/${element.name.local}[@id="$id"]',
        structuredMessage: TmJflapMessages.invalidNodeCoordinate(id),
      );
    }
    final initial = element.findElements('initial').isNotEmpty;
    if (initial) initialCount++;
    final name = element.getAttribute('name') ?? 'q$id';
    final custom = element.getElement('turingLabState');
    final customData = custom == null
        ? const <String, dynamic>{}
        : TmJflapMetadata.jsonObject(
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
        structuredMessage: TmJflapMessages.invalidNodeStateType(id),
      );
    }
    final stateProperties = customData['properties'];
    if (stateProperties != null && stateProperties is! Map) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM node $id has invalid state properties.',
        '/structure/automaton/${element.name.local}[@id="$id"]/turingLabState/properties',
        structuredMessage: TmJflapMessages.invalidNodeProperties(id),
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
          structuredMessage: TmJflapMessages.missingBlockTagReference(id),
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
    throw _BlockXmlException(
      CodecMalformedReason.invalidValue,
      'Every JFLAP TM block definition requires states and one initial state.',
      '/structure/automaton',
      structuredMessage: TmJflapMessages.invalidInitialStateCount(),
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
        structuredMessage: TmJflapMessages.unknownTransitionEndpoints(
          from: fromId,
          to: toId,
        ),
      );
    }
    final isBlockTransition = element.getAttribute('block') == 'true';
    final tapeVector = TmTapeVectorCodec.read(
      element,
      index: index,
      tapeCount: tapeCount,
      blankSymbol: blankSymbol,
      dialect: TmTapeVectorDialect.buildingBlock,
      defaultMove: isBlockTransition ? TapeDirection.stay : TapeDirection.right,
    );
    final TmTapeVector(:reads, :writes, :moves) = switch (tapeVector) {
      TmTapeVector() => tapeVector,
      TmTapeVectorMalformed(
        :final reason,
        :final message,
        :final path,
        :final structuredMessage,
      ) =>
        throw _BlockXmlException(
          reason,
          message,
          path,
          structuredMessage: structuredMessage,
        ),
      TmTapeVectorUnsupported(:final message, :final structuredMessage) =>
        throw _BlockUnsupportedException(
          message,
          structuredMessage: structuredMessage,
        ),
    };
    if (isBlockTransition) {
      for (var tape = 0; tape < tapeCount; tape++) {
        writes[tape] = reads[tape];
        moves[tape] = TapeDirection.stay;
      }
    }
    final signature = TmTapeVectorCodec.signature(
      from.id,
      to.id,
      reads,
      writes,
      moves,
    );
    final custom = element.getElement('turingLabTransition');
    final customData = custom == null
        ? const <String, dynamic>{}
        : TmJflapMetadata.jsonObject(
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
        structuredMessage: TmJflapMessages.invalidTransitionId(),
      );
    }
    if (customId != null && attributeId != null && customId != attributeId) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM transition identity extensions disagree.',
        '/structure/automaton/transition[$index]',
        structuredMessage: TmJflapMessages.transitionIdentityConflict(),
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
        structuredMessage: TmJflapMessages.duplicateTransitionId(),
      );
    }
    final rawLabel = customData['label'];
    if (rawLabel != null && rawLabel is! String) {
      throw _BlockXmlException(
        CodecMalformedReason.invalidValue,
        'JFLAP TM transition $id has an invalid label.',
        '/structure/automaton/transition[$index]/turingLabTransition/label',
        structuredMessage: TmJflapMessages.invalidTransitionLabel(id),
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
        structuredMessage: TmJflapMessages.invalidTransitionType(id),
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
        controlPoint: TmJflapMetadata.controlPoint(customData),
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
    alphabet:
        TmJflapMetadata.stringSet(machineMetadata, 'alphabet') ?? inputAlphabet,
    initialState: states.firstWhere((state) => state.isInitial),
    acceptingStates: states.where((state) => state.isAccepting).toSet(),
    created: TmJflapMetadata.date(machineMetadata, 'created', epoch),
    modified: TmJflapMetadata.date(machineMetadata, 'modified', epoch),
    bounds:
        TmJflapMetadata.bounds(machineMetadata) ??
        TmJflapMetadata.boundsForStates(states),
    zoomLevel: TmJflapMetadata.number(machineMetadata, 'zoomLevel', 1),
    panOffset: TmJflapMetadata.panOffset(machineMetadata),
    tapeAlphabet:
        TmJflapMetadata.stringSet(machineMetadata, 'tapeAlphabet') ??
        tapeAlphabet,
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
    final validation = TmJflapMetadata.firstValidationError(current);
    if (validation != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: validation,
        location: const CodecSourceLocation(path: r'$.document'),
        structuredMessage: TmJflapMessages.invalidDocument(),
      );
    }
    final unsupported = TmTapeVectorCodec.unsupportedOperation(current);
    if (unsupported != null) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: unsupported.message,
        structuredMessage: unsupported.structuredMessage,
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
        nest: convert.jsonEncode(TmJflapMetadata.encode(machine)),
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
    nest: convert.jsonEncode(TmJflapMetadata.encode(machine)),
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
    builder.element(
      'transition',
      nest: () {
        builder.attribute('turingLabTransitionId', transition.id);
        builder.element('from', nest: transition.fromState.id);
        builder.element('to', nest: transition.toState.id);
        TmTapeVectorCodec.writeOperations(
          builder,
          transition,
          tapeCount: machine.tapeCount,
          blankSymbol: machine.blankSymbol,
        );
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
  const _BlockXmlException(
    this.reason,
    this.message,
    this.path, {
    required this.structuredMessage,
  });

  final CodecMalformedReason reason;
  final String message;
  final String path;
  final StructuredMessage structuredMessage;
}

class _BlockUnsupportedException implements Exception {
  const _BlockUnsupportedException(
    this.message, {
    required this.structuredMessage,
  });

  final String message;
  final StructuredMessage structuredMessage;
}

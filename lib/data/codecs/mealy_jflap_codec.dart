import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/transducers/transducers.dart';
import 'codec_utils.dart';
import 'hardened_xml.dart';
import 'jflap_annotations.dart';
import 'mealy_jflap_messages.dart';

/// Reads and writes the JFLAP Mealy XML shape without adding FSA semantics.
final class MealyJflapDocumentCodec implements DocumentCodecCapability<Object> {
  const MealyJflapDocumentCodec();

  static const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.mealy'),
    version: DocumentSchemaVersion(1),
  );

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('mealy.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.transducer.mealy.jflap-xml'),
    systemKey: TransducerFormalSystemIds.mealy,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 110,
    compatibilityOwner: 'Turing Lab Mealy / JFLAP XML',
    canonicalFixtures: const [
      'test/fixtures/interoperability/mealy_canonical.jff',
    ],
    semanticCapabilities: {
      CodecSemanticCapabilityId.stateIds,
      CodecSemanticCapabilityId.stateNames,
      CodecSemanticCapabilityId.statePositions,
      CodecSemanticCapabilityId.stateLabels,
      CodecSemanticCapabilityId.initialStates,
      CodecSemanticCapabilityId.transitionLabels,
      CodecSemanticCapabilityId.transitionOutputs,
      CodecSemanticCapabilityId.extensions,
      CodecSemanticCapabilityId.notes,
    },
    knownUnsupportedFields: const {
      'transition IDs',
      'token boundaries inside multi-token output words',
      'declared alphabets',
      'source revision',
    },
  );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    try {
      final prefix = utf8Payload(payload);
      final bounded = prefix.substring(0, prefix.length.clamp(0, 8192));
      final matches = RegExp(
        r'<type\s*>\s*mealy\s*</type\s*>',
        caseSensitive: false,
      ).hasMatch(bounded);
      return matches
          ? CodecSniffResult(
              confidence: 100,
              detectedSystem: TransducerFormalSystemIds.mealy,
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
    if (parsed is! CodecSuccess<XmlDocument>) return _forward(parsed);
    final root = parsed.value.rootElement;
    if (root.name.local != 'structure') {
      return CodecMalformed(
        message: 'JFLAP XML root must be <structure>.',
        location: CodecSourceLocation(path: '/'),
        structuredMessage: MealyJflapMessages.invalidRoot(),
      );
    }
    final type =
        root.getElement('type')?.innerText.trim() ??
        root.getAttribute('type')?.trim();
    if (type?.toLowerCase() != 'mealy') {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'JFLAP document type ${type ?? '(missing)'} is not Mealy.',
        structuredMessage: MealyJflapMessages.unsupportedDocumentType(
          type ?? '(missing)',
        ),
      );
    }
    final automaton = root.findElements('automaton').firstOrNull;
    if (automaton == null) {
      return CodecMalformed(
        message: 'JFLAP Mealy document is missing <automaton>.',
        location: CodecSourceLocation(path: '/structure/automaton'),
        structuredMessage: MealyJflapMessages.missingAutomaton(),
      );
    }

    final extensions = <String, Object?>{};
    final diagnostics = <CodecDiagnostic>[];
    final states = <MealyState>[];
    final statesById = <String, MealyState>{};
    final statesByName = <String, MealyState?>{};
    var initialCount = 0;
    for (final element in automaton.findElements('state')) {
      final id = element.getAttribute('id')?.trim();
      if (id == null || id.isEmpty) {
        return CodecMalformed(
          reason: CodecMalformedReason.missingField,
          message: 'JFLAP Mealy state requires a non-empty id.',
          location: CodecSourceLocation(path: '/structure/automaton/state/@id'),
          structuredMessage: MealyJflapMessages.missingStateId(),
        );
      }
      if (statesById.containsKey(id)) {
        return CodecMalformed(
          reason: CodecMalformedReason.duplicateIdentity,
          message: 'Duplicate JFLAP Mealy state id: $id.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]',
          ),
          structuredMessage: MealyJflapMessages.duplicateStateId(id),
        );
      }
      final x = _coordinate(element, 'x');
      final y = _coordinate(element, 'y');
      if (x == null || y == null) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'State $id has an invalid coordinate.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]',
          ),
          structuredMessage: MealyJflapMessages.invalidStateCoordinate(id),
        );
      }
      final name = element.getAttribute('name')?.trim();
      final label =
          element.findElements('label').firstOrNull?.innerText ??
          (name?.isNotEmpty == true ? name! : 'q$id');
      final initial = element.findElements('initial').isNotEmpty;
      if (initial) initialCount++;
      final state = MealyState(
        id: TransducerStateId(id),
        label: label,
        position: TransducerPoint(x, y),
        isInitial: initial,
      );
      states.add(state);
      statesById[id] = state;
      if (name != null && name.isNotEmpty) {
        statesByName[name] = statesByName.containsKey(name) ? null : state;
        if (name != label) extensions['stateName.$id'] = name;
      }
      _preserveAttributes(
        element,
        known: const {'id', 'name'},
        key: 'stateAttributes.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      _preserveUnknown(
        element,
        known: const {'x', 'y', 'label', 'initial'},
        key: 'stateChildren.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
    }
    if (states.isEmpty) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'JFLAP Mealy document must contain at least one state.',
        location: CodecSourceLocation(path: '/structure/automaton/state'),
        structuredMessage: MealyJflapMessages.emptyAutomaton(),
      );
    }
    if (initialCount != 1) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'JFLAP Mealy document must contain exactly one initial state.',
        location: CodecSourceLocation(
          path: '/structure/automaton/state/initial',
        ),
        structuredMessage: MealyJflapMessages.invalidInitialStateCount(
          initialCount,
        ),
      );
    }

    final transitionElements = automaton.findElements('transition').toList();
    if (states.length + transitionElements.length >
        descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: states.length + transitionElements.length,
      );
    }
    final records = <_MealyTransitionRecord>[];
    final deterministicKeys = <String>{};
    for (var index = 0; index < transitionElements.length; index++) {
      final element = transitionElements[index];
      final fromRaw = element.getElement('from')?.innerText.trim();
      final toRaw = element.getElement('to')?.innerText.trim();
      final from = fromRaw == null
          ? null
          : statesById[fromRaw] ?? statesByName[fromRaw];
      final to = toRaw == null
          ? null
          : statesById[toRaw] ?? statesByName[toRaw];
      if (from == null || to == null) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Transition $index references an unknown state.',
          location: CodecSourceLocation(
            path: '/structure/automaton/transition[$index]',
          ),
          structuredMessage: MealyJflapMessages.unknownTransitionEndpoints(
            index: index,
            from: fromRaw,
            to: toRaw,
          ),
        );
      }
      final input = element.getElement('read')?.innerText ?? '';
      if (input.isEmpty) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Mealy transitions cannot consume an empty input symbol.',
          location: CodecSourceLocation(
            path: '/structure/automaton/transition[$index]/read',
          ),
          structuredMessage: MealyJflapMessages.emptyInputSymbol(index),
        );
      }
      final output = element.getElement('transout')?.innerText ?? '';
      final deterministicKey = jsonEncode([from.id.value, input]);
      if (!deterministicKeys.add(deterministicKey)) {
        return CodecMalformed(
          reason: CodecMalformedReason.duplicateIdentity,
          message:
              'More than one Mealy transition consumes $input from ${from.id.value}.',
          location: CodecSourceLocation(
            path: '/structure/automaton/transition[$index]',
          ),
          structuredMessage: MealyJflapMessages.duplicateTransitionInput(
            input: input,
            state: from.id.value,
          ),
        );
      }
      records.add(
        _MealyTransitionRecord(
          from: from,
          to: to,
          input: input,
          output: output,
          element: element,
        ),
      );
    }
    records.sort((left, right) => left.signature.compareTo(right.signature));
    final transitions = <MealyTransition>[];
    final transitionSignaturesById = <String, String>{};
    final inputAlphabet = <TransducerInputSymbol>{};
    final outputAlphabet = <TransducerOutputSymbol>{};
    for (final record in records) {
      final id = _stableTransitionId(record.signature);
      final collidingSignature = transitionSignaturesById[id];
      if (collidingSignature != null &&
          collidingSignature != record.signature) {
        return CodecInternalFailure(
          stage: CodecInternalFailureStage.decode,
          message: 'Stable Mealy transition ID collision.',
          structuredMessage: MealyJflapMessages.stableTransitionIdCollision(),
        );
      }
      transitionSignaturesById[id] = record.signature;
      final input = TransducerInputSymbol(record.input);
      final output = record.output.isEmpty
          ? TransducerOutputWord.empty
          : TransducerOutputWord.fromValues([record.output]);
      inputAlphabet.add(input);
      outputAlphabet.addAll(output.symbols);
      transitions.add(
        MealyTransition(
          id: TransducerTransitionId(id),
          from: record.from.id,
          to: record.to.id,
          input: input,
          output: output,
        ),
      );
      _preserveAttributes(
        record.element,
        known: const {},
        key: 'transitionAttributes.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      _preserveUnknown(
        record.element,
        known: const {'from', 'to', 'read', 'transout'},
        key: 'transitionChildren.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
    }
    _preserveAttributes(
      root,
      known: const {'type'},
      key: 'rootAttributes',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    _preserveUnknown(
      root,
      known: const {'type', 'automaton'},
      key: 'rootChildren',
      extensions: extensions,
      diagnostics: diagnostics,
    );

    final canonicalStates = states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final canonicalIdentity = canonicalIdentityJson({
      'states': canonicalStates.map((state) => state.toJson()).toList(),
      'transitions': transitions
          .map((transition) => transition.toJson())
          .toList(),
      'inputAlphabet': (inputAlphabet.map((symbol) => symbol.value).toList()
        ..sort()),
      'outputAlphabet': (outputAlphabet.map((symbol) => symbol.value).toList()
        ..sort()),
    });
    final machine = MealyMachine(
      id: TransducerMachineId(
        deterministicContentId('imported_mealy', canonicalIdentity),
      ),
      name: 'Imported Mealy machine',
      revision: const TransducerRevision(1),
      inputAlphabet: inputAlphabet,
      outputAlphabet: outputAlphabet,
      states: states,
      transitions: transitions,
    );
    _preserveAttributes(
      automaton,
      known: const {},
      key: 'automatonAttributes',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    readJflapAnnotations(
      automaton,
      documentId: machine.id.value,
      documentRevision: 'jflap-import',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    _preserveUnknown(
      automaton,
      known: const {'state', 'transition', 'note'},
      key: 'automatonChildren',
      extensions: extensions,
      diagnostics: diagnostics,
    );
    return CodecSuccess(
      value: InteroperableDocument<Object>(
        document: machine,
        systemKey: TransducerFormalSystemIds.mealy,
        schema: schema,
        sourceMetadata: const DocumentSourceMetadata(
          application: 'JFLAP',
          sourceFormatVersion: '7.1',
        ),
        extensions: DocumentExtensionBag(extensions),
      ),
      fidelity: DocumentFidelity.normalized,
      diagnostics: [
        CodecDiagnostic(
          code: 'jflap.mealy.transition-ids-derived',
          message:
              'Stable transition IDs were derived from transition content.',
          structuredMessage: MealyJflapMessages.transitionIdsDerived(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
        ...diagnostics,
      ],
    );
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != TransducerFormalSystemIds.mealy ||
        document.document is! MealyMachine) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Mealy JFLAP codec requires a Mealy machine.',
        structuredMessage: MealyJflapMessages.requiresMealyDocument(),
      );
    }
    if (document.schema.id != schema.id ||
        document.schema.version != schema.version) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message:
            'Unsupported Mealy schema ${document.schema.id.value}@${document.schema.version.value}.',
        structuredMessage: MealyJflapMessages.unsupportedSchema(
          schemaId: document.schema.id.value,
          version: document.schema.version.value,
        ),
      );
    }
    final machine = document.document as MealyMachine;
    final analysis = TransducerAnalyzer.analyze(machine);
    final error = analysis.diagnostics.firstWhereOrNull(
      (item) => item.severity == TransducerDiagnosticSeverity.error,
    );
    if (error != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Invalid Mealy machine: ${error.code.name}.',
        location: CodecSourceLocation(
          path: '${r'$.document.'}${error.subject}',
        ),
        structuredMessage: MealyJflapMessages.invalidDocument(error.code.name),
      );
    }
    final states = machine.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final transitions = machine.transitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final diagnostics = <CodecDiagnostic>[
      CodecDiagnostic(
        code: 'jflap.mealy.canonical-order',
        message: 'State and transition ordering was canonicalized.',
        structuredMessage: MealyJflapMessages.canonicalOrder(),
        disposition: CodecDiagnosticDisposition.normalized,
      ),
      CodecDiagnostic(
        code: 'jflap.mealy.machine-identity-not-portable',
        message: 'JFLAP does not store the native machine ID or revision.',
        path: r'$.document',
        sourceValue: {
          'id': machine.id.value,
          'revision': machine.revision.value,
        },
        structuredMessage: MealyJflapMessages.machineIdentityNotPortable(),
        disposition: CodecDiagnosticDisposition.normalized,
      ),
      CodecDiagnostic(
        code: 'jflap.mealy.transition-identities-not-portable',
        message: 'JFLAP does not store native transition IDs.',
        path: r'$.document.transitions',
        sourceValue: transitions
            .map((transition) => transition.id.value)
            .toList(),
        structuredMessage: MealyJflapMessages.transitionIdentitiesNotPortable(),
        disposition: CodecDiagnosticDisposition.normalized,
      ),
    ];
    final usedInputs = transitions
        .map((transition) => transition.input)
        .toSet();
    final usedOutputs = transitions
        .expand((transition) => transition.output.symbols)
        .toSet();
    final unusedInputs = machine.inputAlphabet.difference(usedInputs);
    final unusedOutputs = machine.outputAlphabet.difference(usedOutputs);
    if (unusedInputs.isNotEmpty || unusedOutputs.isNotEmpty) {
      diagnostics.add(
        CodecDiagnostic(
          code: 'jflap.mealy.unused-alphabet-symbols-dropped',
          message: 'JFLAP does not store declared alphabets.',
          path: r'$.document',
          sourceValue: {
            'input': unusedInputs.map((symbol) => symbol.value).toList(),
            'output': unusedOutputs.map((symbol) => symbol.value).toList(),
          },
          structuredMessage: MealyJflapMessages.unusedAlphabetSymbolsDropped(
            inputSymbols:
                (unusedInputs.map((symbol) => symbol.value).toList()..sort())
                    .join(', '),
            outputSymbols:
                (unusedOutputs.map((symbol) => symbol.value).toList()..sort())
                    .join(', '),
          ),
          disposition: CodecDiagnosticDisposition.dropped,
        ),
      );
    }
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        writeXmlAttributes(
          builder,
          document.extensions.values['rootAttributes'],
        );
        builder.element('type', nest: 'mealy');
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
                  builder.attribute('id', state.id.value);
                  builder.attribute(
                    'name',
                    document.extensions.values['stateName.${state.id.value}']
                            as String? ??
                        state.label,
                  );
                  writeXmlAttributes(
                    builder,
                    document
                        .extensions
                        .values['stateAttributes.${state.id.value}'],
                  );
                  builder.element('x', nest: formatXmlNumber(state.position.x));
                  builder.element('y', nest: formatXmlNumber(state.position.y));
                  if (state.label.isNotEmpty) {
                    builder.element('label', nest: state.label);
                  }
                  if (state.isInitial) builder.element('initial');
                  writeXmlExtensions(
                    builder,
                    document
                        .extensions
                        .values['stateChildren.${state.id.value}'],
                  );
                },
              );
            }
            for (final transition in transitions) {
              final output = transition.output.values.join();
              if (transition.output.symbols.length > 1) {
                diagnostics.add(
                  CodecDiagnostic(
                    code: 'jflap.mealy.output-token-boundaries-dropped',
                    message: 'JFLAP stores a Mealy output as one string.',
                    path: '\$.transitions.${transition.id.value}.output',
                    sourceValue: transition.output.values,
                    structuredMessage:
                        MealyJflapMessages.outputTokenBoundariesDropped(
                          transitionId: transition.id.value,
                          tokens: transition.output.values.join(', '),
                        ),
                    disposition: CodecDiagnosticDisposition.dropped,
                  ),
                );
              }
              builder.element(
                'transition',
                nest: () {
                  writeXmlAttributes(
                    builder,
                    document
                        .extensions
                        .values['transitionAttributes.${transition.id.value}'],
                  );
                  builder.element('from', nest: transition.from.value);
                  builder.element('to', nest: transition.to.value);
                  builder.element('read', nest: transition.input.value);
                  if (output.isEmpty) {
                    builder.element('transout', isSelfClosing: true);
                  } else {
                    builder.element('transout', nest: output);
                  }
                  writeXmlExtensions(
                    builder,
                    document
                        .extensions
                        .values['transitionChildren.${transition.id.value}'],
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
    final xml = '${builder.buildDocument().toXmlString(pretty: true)}\n';
    return CodecSuccess(
      value: EncodedDocument(
        bytes: utf8Bytes(xml),
        mimeType: 'application/xml',
        filename: filenameWithExtension(filename, 'mealy-machine', 'jff'),
        schema: schema,
      ),
      fidelity:
          diagnostics.any(
            (item) => item.disposition == CodecDiagnosticDisposition.dropped,
          )
          ? DocumentFidelity.lossy
          : DocumentFidelity.normalized,
      diagnostics: diagnostics,
    );
  }
}

void _preserveUnknown(
  XmlElement parent, {
  required Set<String> known,
  required String key,
  required Map<String, Object?> extensions,
  required List<CodecDiagnostic> diagnostics,
}) {
  final unknown = parent.childElements
      .where((element) => !known.contains(element.name.local))
      .map((element) => element.toXmlString())
      .toList(growable: false);
  if (unknown.isEmpty) return;
  extensions[key] = unknown;
  diagnostics.add(
    CodecDiagnostic(
      code: 'jflap.unknown-optional-element',
      message: 'Unknown optional XML data was preserved.',
      path: key,
      structuredMessage: MealyJflapMessages.unknownOptionalElement(key),
    ),
  );
}

void _preserveAttributes(
  XmlElement element, {
  required Set<String> known,
  required String key,
  required Map<String, Object?> extensions,
  required List<CodecDiagnostic> diagnostics,
}) {
  final unknown = <String, String>{};
  for (final attribute in element.attributes) {
    if (!known.contains(attribute.name.local)) {
      unknown[attribute.name.qualified] = attribute.value;
    }
  }
  if (unknown.isEmpty) return;
  extensions[key] = unknown;
  diagnostics.add(
    CodecDiagnostic(
      code: 'jflap.unknown-optional-attribute',
      message: 'Unknown optional XML attributes were preserved.',
      path: key,
      structuredMessage: MealyJflapMessages.unknownOptionalAttribute(key),
    ),
  );
}

final class _MealyTransitionRecord {
  const _MealyTransitionRecord({
    required this.from,
    required this.to,
    required this.input,
    required this.output,
    required this.element,
  });

  final MealyState from;
  final MealyState to;
  final String input;
  final String output;
  final XmlElement element;

  String get signature => jsonEncode([from.id.value, input, to.id.value]);
}

String _stableTransitionId(String signature) =>
    'transition_${fnv1a32Hex(signature)}'
    '${fnv1a32Hex(signature, 0x9e3779b9)}'
    '${fnv1a32Hex(signature, 0x85ebca6b)}';

double? _coordinate(XmlElement state, String name) {
  final raw =
      state.getAttribute(name) ?? state.getElement(name)?.innerText.trim();
  return raw == null ? 0 : double.tryParse(raw);
}

CodecOutcome<T> _forward<T>(
  CodecOutcome<XmlDocument> outcome,
) => switch (outcome) {
  CodecMalformed<XmlDocument>() => CodecMalformed(
    reason: outcome.reason,
    message: outcome.message,
    location: outcome.location,
    cause: outcome.cause,
    structuredMessage:
        outcome.structuredMessage ??
        switch (outcome.reason) {
          CodecMalformedReason.invalidUtf8 => MealyJflapMessages.invalidUtf8(),
          _ => MealyJflapMessages.malformedXml(),
        },
  ),
  CodecResourceLimit<XmlDocument>() => CodecResourceLimit(
    limit: outcome.limit,
    maximum: outcome.maximum,
    actual: outcome.actual,
  ),
  CodecUnsupported<XmlDocument>() => CodecUnsupported(
    reason: outcome.reason,
    message: outcome.message,
    roadmapIssue: outcome.roadmapIssue,
    structuredMessage: outcome.structuredMessage,
  ),
  CodecAmbiguous<XmlDocument>() => CodecAmbiguous(codecIds: outcome.codecIds),
  CodecInternalFailure<XmlDocument>() => CodecInternalFailure(
    stage: outcome.stage,
    message: outcome.message,
    cause: outcome.cause,
    structuredMessage:
        outcome.structuredMessage ?? MealyJflapMessages.malformedXml(),
  ),
  CodecSuccess<XmlDocument>() => throw StateError('Unexpected success.'),
};

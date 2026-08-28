import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/transducers/transducers.dart';
import 'codec_utils.dart';
import 'hardened_xml.dart';
import 'jflap_annotations.dart';
import 'moore_jflap_messages.dart';

/// JFLAP 7 Moore XML interoperability.
///
/// JFLAP stores Moore emissions in state `<output>` elements. A transition's
/// `<transout>` is redundant and never overrides its destination state output.
final class MooreJflapDocumentCodec implements DocumentCodecCapability<Object> {
  const MooreJflapDocumentCodec();

  static const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.moore'),
    version: DocumentSchemaVersion(1),
  );

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('moore.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.transducer.moore.jflap-xml'),
    systemKey: TransducerFormalSystemIds.moore,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 110,
    compatibilityOwner: 'Turing Lab interoperability / JFLAP Moore XML',
    canonicalFixtures: const [
      'test/fixtures/interoperability/moore_canonical.jff',
    ],
    semanticCapabilities: {
      CodecSemanticCapabilityId.stateIds,
      CodecSemanticCapabilityId.stateNames,
      CodecSemanticCapabilityId.statePositions,
      CodecSemanticCapabilityId.stateLabels,
      CodecSemanticCapabilityId.initialStates,
      CodecSemanticCapabilityId.transitionLabels,
      CodecSemanticCapabilityId.stateOutputs,
      CodecSemanticCapabilityId.tokenVectors,
      CodecSemanticCapabilityId.extensions,
      CodecSemanticCapabilityId.notes,
    },
    knownUnsupportedFields: const {
      'document/machine ID',
      'transition IDs',
      'declared input/output alphabets',
      'source revision',
      'portable multi-token output boundaries after JFLAP 7.1 open/save',
      'accepting/final states',
      'epsilon transitions',
      'transition-owned outputs',
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
      final isMoore =
          RegExp(
            r'<type\s*>\s*moore\s*</type\s*>',
            caseSensitive: false,
          ).hasMatch(prefix) ||
          RegExp(
            r'''<structure\b[^>]*\btype\s*=\s*["']moore["']''',
            caseSensitive: false,
          ).hasMatch(prefix);
      return isMoore
          ? CodecSniffResult(
              confidence: 100,
              detectedSystem: TransducerFormalSystemIds.moore,
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
        reason: CodecMalformedReason.invalidValue,
        message: 'JFLAP XML root must be <structure>.',
        location: CodecSourceLocation(path: '/'),
        structuredMessage: MooreJflapMessages.invalidRoot(),
      );
    }
    final type =
        root.getElement('type')?.innerText.trim() ??
        root.getAttribute('type')?.trim();
    if (type?.toLowerCase() != 'moore') {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'JFLAP document type ${type ?? '(missing)'} is not Moore.',
        structuredMessage: MooreJflapMessages.unsupportedDocumentType(
          type ?? '(missing)',
        ),
      );
    }
    final automaton = root.findElements('automaton').firstOrNull;
    if (automaton == null) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'JFLAP Moore document is missing <automaton>.',
        location: CodecSourceLocation(path: '/structure/automaton'),
        structuredMessage: MooreJflapMessages.missingAutomaton(),
      );
    }
    if (automaton
        .findElements('state')
        .any((state) => state.findElements('final').isNotEmpty)) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: 'Moore machines do not have accepting or final states.',
        structuredMessage: MooreJflapMessages.finalStatesUnsupported(),
      );
    }

    final extensions = <String, Object?>{};
    final diagnostics = <CodecDiagnostic>[];
    final states = <MooreState>[];
    final stateIds = <String>{};
    var initialCount = 0;
    for (final element in automaton.findElements('state')) {
      final id = element.getAttribute('id')?.trim();
      if (id == null || id.isEmpty) {
        return CodecMalformed(
          reason: CodecMalformedReason.missingField,
          message: 'JFLAP state is missing a non-empty id.',
          location: CodecSourceLocation(path: '/structure/automaton/state/@id'),
          structuredMessage: MooreJflapMessages.missingStateId(),
        );
      }
      if (!stateIds.add(id)) {
        return CodecMalformed(
          reason: CodecMalformedReason.duplicateIdentity,
          message: 'Duplicate JFLAP state id: $id.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]',
          ),
          structuredMessage: MooreJflapMessages.duplicateStateId(id),
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
          structuredMessage: MooreJflapMessages.invalidStateCoordinate(id),
        );
      }
      final initial = element.findElements('initial').isNotEmpty;
      if (initial) initialCount++;
      final rawOutput =
          element.findElements('output').firstOrNull?.innerText ?? '';
      final tokenExtension = element
          .findElements('turingLabOutputTokens')
          .firstOrNull;
      final output = _decodeOutputWord(tokenExtension, rawOutput);
      if (output == null) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'State $id has invalid Turing Lab output token metadata.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]/turingLabOutputTokens',
          ),
          structuredMessage: MooreJflapMessages.invalidOutputTokenMetadata(id),
        );
      }
      if (tokenExtension != null) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.moore.output-token-vector-restored',
            message: 'Moore output token boundaries were restored.',
            path: '/structure/automaton/state[@id="$id"]/turingLabOutputTokens',
            structuredMessage: MooreJflapMessages.outputTokenVectorRestored(
              stateId: id,
              tokens: tokenExtension.innerText,
            ),
            disposition: CodecDiagnosticDisposition.preserved,
          ),
        );
      }
      final name = element.getAttribute('name') ?? 'q$id';
      final label =
          element.findElements('label').firstOrNull?.innerText ?? name;
      states.add(
        MooreState(
          id: TransducerStateId(id),
          label: label,
          position: TransducerPoint(x, y),
          isInitial: initial,
          output: output,
        ),
      );
      if (name != label) extensions['stateName.$id'] = name;
      _preserveAttributes(
        element,
        known: const {'id', 'name'},
        key: 'stateAttributes.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      _preserveUnknown(
        element,
        known: const {
          'x',
          'y',
          'label',
          'initial',
          'output',
          'turingLabOutputTokens',
        },
        key: 'stateChildren.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
    }
    if (states.isEmpty) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'JFLAP Moore document does not contain any states.',
        location: CodecSourceLocation(path: '/structure/automaton/state'),
        structuredMessage: MooreJflapMessages.emptyAutomaton(),
      );
    }
    if (initialCount != 1) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'A Moore machine must contain exactly one initial state.',
        location: CodecSourceLocation(
          path: '/structure/automaton/state/initial',
        ),
        structuredMessage: MooreJflapMessages.invalidInitialStateCount(
          initialCount,
        ),
      );
    }

    final stateById = {for (final state in states) state.id.value: state};
    final transitions = <MooreTransition>[];
    final transitionSignatures = <String>{};
    final signaturesByDerivedId = <String, String>{};
    final inputAlphabet = <TransducerInputSymbol>{};
    final transitionElements = automaton.findElements('transition').toList();
    final collectionEntries = states.length + transitionElements.length;
    if (collectionEntries >
        descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: collectionEntries,
      );
    }
    for (var index = 0; index < transitionElements.length; index++) {
      final element = transitionElements[index];
      final from = element.findElements('from').firstOrNull?.innerText.trim();
      final to = element.findElements('to').firstOrNull?.innerText.trim();
      final rawRead = element.findElements('read').firstOrNull?.innerText;
      final path = '/structure/automaton/transition[$index]';
      if (from == null ||
          to == null ||
          !stateById.containsKey(from) ||
          !stateById.containsKey(to)) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Transition references an unknown state.',
          location: CodecSourceLocation(path: path),
          structuredMessage: MooreJflapMessages.unknownTransitionEndpoints(
            index: index,
            from: from,
            to: to,
          ),
        );
      }
      if (rawRead == null || rawRead.isEmpty) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Moore transitions require a non-empty input symbol.',
          location: CodecSourceLocation(path: '$path/read'),
          structuredMessage: MooreJflapMessages.emptyInputSymbol(index),
        );
      }
      final signature = '$from\u0000$rawRead\u0000$to';
      if (!transitionSignatures.add(signature)) {
        return CodecMalformed(
          reason: CodecMalformedReason.duplicateIdentity,
          message: 'Duplicate Moore transition ($from, $rawRead, $to).',
          location: CodecSourceLocation(path: path),
          structuredMessage: MooreJflapMessages.duplicateTransition(
            from: from,
            input: rawRead,
            to: to,
          ),
        );
      }
      if (transitions.any(
        (transition) =>
            transition.from.value == from && transition.input.value == rawRead,
      )) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Moore transitions must be deterministic.',
          location: CodecSourceLocation(path: path),
          structuredMessage: MooreJflapMessages.nondeterministicTransition(
            state: from,
            input: rawRead,
          ),
        );
      }
      final transitionId = deterministicContentId('mt', signature);
      final collidingSignature = signaturesByDerivedId[transitionId];
      if (collidingSignature != null && collidingSignature != signature) {
        return CodecMalformed(
          reason: CodecMalformedReason.duplicateIdentity,
          message: 'Two Moore transitions produced the same stable identity.',
          location: CodecSourceLocation(path: path),
          structuredMessage: MooreJflapMessages.stableTransitionIdCollision(),
        );
      }
      signaturesByDerivedId[transitionId] = signature;
      final destinationOutput = stateById[to]!.output.render();
      final rawTransitionOutput = element
          .findElements('transout')
          .firstOrNull
          ?.innerText;
      if (rawTransitionOutput != null &&
          rawTransitionOutput != destinationOutput) {
        extensions['transitionOutput.$transitionId'] = rawTransitionOutput;
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.moore.conflicting-transition-output-preserved',
            message:
                'A redundant transition output disagreed with the destination state output.',
            path: '$path/transout',
            sourceValue: rawTransitionOutput,
            structuredMessage:
                MooreJflapMessages.conflictingTransitionOutputPreserved(
                  transitionId: transitionId,
                  actual: rawTransitionOutput,
                  expected: destinationOutput,
                ),
            disposition: CodecDiagnosticDisposition.preserved,
          ),
        );
      }
      final input = TransducerInputSymbol(rawRead);
      inputAlphabet.add(input);
      transitions.add(
        MooreTransition(
          id: TransducerTransitionId(transitionId),
          from: TransducerStateId(from),
          to: TransducerStateId(to),
          input: input,
        ),
      );
      _preserveAttributes(
        element,
        known: const {},
        key: 'transitionAttributes.$transitionId',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      _preserveUnknown(
        element,
        known: const {'from', 'to', 'read', 'transout'},
        key: 'transitionChildren.$transitionId',
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
    final outputAlphabet = states
        .expand((state) => state.output.symbols)
        .toSet();
    final canonicalIdentity = [
      ...states.map(
        (state) =>
            's:${state.id.value}:${jsonEncode(state.output.values)}:${state.isInitial}',
      ),
      ...transitions.map(
        (transition) =>
            't:${transition.from.value}:${jsonEncode(transition.input.value)}:${transition.to.value}',
      ),
    ]..sort();
    final machine = MooreMachine(
      id: TransducerMachineId(
        deterministicContentId('moore', canonicalIdentity.join('|')),
      ),
      name: _documentName(payload.filename),
      revision: const TransducerRevision(0),
      inputAlphabet: inputAlphabet,
      outputAlphabet: outputAlphabet,
      states: states,
      transitions: transitions,
    );
    final analysis = TransducerAnalyzer.analyze(machine);
    final error = analysis.diagnostics.firstWhereOrNull(
      (diagnostic) => diagnostic.severity == TransducerDiagnosticSeverity.error,
    );
    if (error != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Invalid Moore machine: ${error.code.name}.',
        location: CodecSourceLocation(path: r'$.moore.' + error.subject),
        structuredMessage: MooreJflapMessages.invalidDocument(error.code.name),
      );
    }
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
        systemKey: TransducerFormalSystemIds.moore,
        schema: schema,
        sourceMetadata: const DocumentSourceMetadata(
          application: 'JFLAP',
          sourceFormatVersion: '7.1',
        ),
        extensions: DocumentExtensionBag(extensions),
      ),
      fidelity: DocumentFidelity.normalized,
      diagnostics: diagnostics,
    );
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != TransducerFormalSystemIds.moore ||
        document.document is! MooreMachine) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'This codec can encode only Moore machines.',
        structuredMessage: MooreJflapMessages.requiresMooreDocument(),
      );
    }
    if (document.schema.id != schema.id ||
        document.schema.version != schema.version) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'Unsupported Moore schema version.',
        structuredMessage: MooreJflapMessages.unsupportedSchema(
          document.schema.version.value,
        ),
      );
    }
    final machine = document.document as MooreMachine;
    final analysis = TransducerAnalyzer.analyze(machine);
    final error = analysis.diagnostics.firstWhereOrNull(
      (diagnostic) => diagnostic.severity == TransducerDiagnosticSeverity.error,
    );
    if (error != null) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Invalid Moore machine: ${error.code.name}.',
        location: CodecSourceLocation(path: r'$.moore.' + error.subject),
        structuredMessage: MooreJflapMessages.invalidDocument(error.code.name),
      );
    }
    final diagnostics = <CodecDiagnostic>[];
    final states = machine.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final transitions = machine.transitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final stateById = {for (final state in states) state.id: state};
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        _writeAttributes(builder, document.extensions.values['rootAttributes']);
        builder.element('type', nest: 'moore');
        _writeExtensions(builder, document.extensions.values['rootChildren']);
        builder.element(
          'automaton',
          nest: () {
            _writeAttributes(
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
                  _writeAttributes(
                    builder,
                    document
                        .extensions
                        .values['stateAttributes.${state.id.value}'],
                  );
                  builder.element('x', nest: _number(state.position.x));
                  builder.element('y', nest: _number(state.position.y));
                  if (state.label != state.id.value) {
                    builder.element('label', nest: state.label);
                  }
                  if (state.isInitial) builder.element('initial');
                  builder.element('output', nest: state.output.render());
                  if (state.output.symbols.length > 1) {
                    builder.element(
                      'turingLabOutputTokens',
                      nest: jsonEncode(state.output.values),
                    );
                    diagnostics.add(
                      CodecDiagnostic(
                        code: 'jflap.moore.output-token-vector-preserved',
                        message:
                            'Moore output token boundaries were preserved in a Turing Lab extension.',
                        path:
                            r'$.states.'
                            '${state.id.value}.output',
                        sourceValue: state.output.values,
                        structuredMessage:
                            MooreJflapMessages.outputTokenVectorPreserved(
                              stateId: state.id.value,
                              tokens: state.output.values.join(', '),
                            ),
                        disposition: CodecDiagnosticDisposition.normalized,
                      ),
                    );
                  }
                  _writeExtensions(
                    builder,
                    document
                        .extensions
                        .values['stateChildren.${state.id.value}'],
                  );
                },
              );
            }
            for (final transition in transitions) {
              builder.element(
                'transition',
                nest: () {
                  _writeAttributes(
                    builder,
                    document
                        .extensions
                        .values['transitionAttributes.${transition.id.value}'],
                  );
                  builder.element('from', nest: transition.from.value);
                  builder.element('to', nest: transition.to.value);
                  builder.element('read', nest: transition.input.value);
                  builder.element(
                    'transout',
                    nest: stateById[transition.to]!.output.render(),
                  );
                  _writeExtensions(
                    builder,
                    document
                        .extensions
                        .values['transitionChildren.${transition.id.value}'],
                  );
                },
              );
              final conflicting = document
                  .extensions
                  .values['transitionOutput.${transition.id.value}'];
              if (conflicting != null) {
                diagnostics.add(
                  CodecDiagnostic(
                    code:
                        'jflap.moore.conflicting-transition-output-normalized',
                    message:
                        'A conflicting transition output was replaced by the destination state output.',
                    path: r'$.transitions.' + transition.id.value,
                    sourceValue: conflicting,
                    structuredMessage:
                        MooreJflapMessages.conflictingTransitionOutputNormalized(
                          transitionId: transition.id.value,
                          output: conflicting.toString(),
                        ),
                    disposition: CodecDiagnosticDisposition.normalized,
                  ),
                );
              }
            }
            writeJflapAnnotations(builder, document.extensions, diagnostics);
            _writeExtensions(
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
        filename: filenameWithExtension(filename, 'moore-machine', 'jff'),
        schema: schema,
      ),
      fidelity:
          diagnostics.any(
            (diagnostic) =>
                diagnostic.disposition == CodecDiagnosticDisposition.dropped,
          )
          ? DocumentFidelity.lossy
          : diagnostics.isEmpty
          ? DocumentFidelity.exact
          : DocumentFidelity.normalized,
      diagnostics: diagnostics,
    );
  }
}

TransducerOutputWord? _decodeOutputWord(
  XmlElement? tokenExtension,
  String rawOutput,
) {
  if (tokenExtension == null) {
    return rawOutput.isEmpty
        ? TransducerOutputWord.empty
        : TransducerOutputWord.fromValues([rawOutput]);
  }
  try {
    final decoded = jsonDecode(tokenExtension.innerText);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      return null;
    }
    final values = decoded.cast<String>();
    if (values.any((value) => value.isEmpty) || values.join() != rawOutput) {
      return null;
    }
    return TransducerOutputWord.fromValues(values);
  } catch (_) {
    return null;
  }
}

double? _coordinate(XmlElement state, String name) {
  final raw =
      state.getAttribute(name) ??
      state.findElements(name).firstOrNull?.innerText.trim();
  return raw == null ? 0 : double.tryParse(raw);
}

String _documentName(String? filename) {
  final value = filename?.trim();
  if (value == null || value.isEmpty) return 'Moore machine';
  final separator = value.lastIndexOf('.');
  return separator > 0 ? value.substring(0, separator) : value;
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
      structuredMessage: MooreJflapMessages.unknownOptionalElement(key),
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
      structuredMessage: MooreJflapMessages.unknownOptionalAttribute(key),
    ),
  );
}

void _writeExtensions(XmlBuilder builder, Object? raw) {
  if (raw is! List) return;
  for (final value in raw.whereType<String>()) {
    builder.xml(value);
  }
}

void _writeAttributes(XmlBuilder builder, Object? raw) {
  if (raw is! Map) return;
  final entries = raw.entries.toList()
    ..sort(
      (left, right) => left.key.toString().compareTo(right.key.toString()),
    );
  for (final entry in entries) {
    builder.attribute(entry.key.toString(), entry.value.toString());
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

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
          CodecMalformedReason.invalidUtf8 => MooreJflapMessages.invalidUtf8(),
          _ => MooreJflapMessages.malformedXml(),
        },
  ),
  CodecResourceLimit<XmlDocument>() => CodecResourceLimit(
    limit: outcome.limit,
    maximum: outcome.maximum,
    actual: outcome.actual,
  ),
  CodecInternalFailure<XmlDocument>() => CodecInternalFailure(
    stage: outcome.stage,
    message: outcome.message,
    cause: outcome.cause,
    structuredMessage:
        outcome.structuredMessage ?? MooreJflapMessages.malformedXml(),
  ),
  CodecUnsupported<XmlDocument>() => CodecUnsupported(
    reason: outcome.reason,
    message: outcome.message,
    roadmapIssue: outcome.roadmapIssue,
    structuredMessage: outcome.structuredMessage,
  ),
  CodecAmbiguous<XmlDocument>() => CodecAmbiguous(codecIds: outcome.codecIds),
  CodecSuccess<XmlDocument>() => throw StateError('Unexpected success.'),
};

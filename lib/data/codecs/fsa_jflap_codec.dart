import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/utils/epsilon_utils.dart';
import 'codec_utils.dart';
import 'fsa_jflap_messages.dart';
import 'hardened_xml.dart';
import 'jflap_annotations.dart';

final class FsaJflapDocumentCodec implements DocumentCodecCapability<Object> {
  const FsaJflapDocumentCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('fsa.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.fsa.jflap-xml'),
    systemKey: DefaultFormalSystemIds.fsa,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 100,
    compatibilityOwner: 'Turing Lab interoperability / JFLAP XML',
    canonicalFixtures: const [
      'test/fixtures/interoperability/fsa_canonical.jff',
    ],
    semanticCapabilities: {
      CodecSemanticCapabilityId.stateIds,
      CodecSemanticCapabilityId.stateNames,
      CodecSemanticCapabilityId.statePositions,
      CodecSemanticCapabilityId.stateLabels,
      CodecSemanticCapabilityId.initialStates,
      CodecSemanticCapabilityId.acceptingStates,
      CodecSemanticCapabilityId.transitionLabels,
      CodecSemanticCapabilityId.extensions,
      CodecSemanticCapabilityId.notes,
    },
    knownUnsupportedFields: const {
      'building-block references',
      'Mealy/Moore outputs',
      'multiple initial states',
    },
  );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    late final String source;
    try {
      source = utf8Payload(payload);
    } catch (_) {
      return CodecSniffResult.none;
    }
    final prefix = source.substring(0, source.length.clamp(0, 8192));
    final isFsa =
        RegExp(
          r'<type\s*>\s*fa\s*</type\s*>',
          caseSensitive: false,
        ).hasMatch(prefix) ||
        RegExp(
          r'''<structure\b[^>]*\btype\s*=\s*["']fa["']''',
          caseSensitive: false,
        ).hasMatch(prefix);
    return isFsa
        ? CodecSniffResult(
            confidence: 100,
            detectedSystem: DefaultFormalSystemIds.fsa,
            detectedSchemaVersion: 1,
          )
        : CodecSniffResult.none;
  }

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final parsed = parseHardenedXml(payload, descriptor.securityLimits);
    if (parsed is! CodecSuccess<XmlDocument>) return _copyXmlFailure(parsed);
    final document = parsed.value;
    final root = document.rootElement;
    if (root.name.local != 'structure') {
      // The structured payload is created at runtime for the presentation
      // boundary, so this constructor cannot be const.
      // ignore: prefer_const_constructors
      return CodecMalformed(
        message: 'JFLAP XML root must be <structure>.',
        location: const CodecSourceLocation(path: '/'),
        structuredMessage: FsaJflapMessages.invalidRoot(),
      );
    }
    final sourceType =
        root.getElement('type')?.innerText.trim() ??
        root.getAttribute('type')?.trim();
    if (sourceType?.toLowerCase() != 'fa') {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'JFLAP document type ${sourceType ?? '(missing)'} is not FSA.',
        structuredMessage: FsaJflapMessages.unsupportedDocumentType(
          sourceType ?? '(missing)',
        ),
      );
    }
    if (root.findAllElements('block').isNotEmpty) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: 'JFLAP building blocks require the dedicated TM codec.',
        roadmapIssue: 325,
        structuredMessage: FsaJflapMessages.buildingBlocksUnsupported(),
      );
    }
    final automaton = root.findElements('automaton').firstOrNull;
    if (automaton == null) {
      // The structured payload is created at runtime for the presentation
      // boundary, so this constructor cannot be const.
      // ignore: prefer_const_constructors
      return CodecMalformed(
        message: 'JFLAP FSA is missing <automaton>.',
        location: const CodecSourceLocation(path: '/structure/automaton'),
        structuredMessage: FsaJflapMessages.missingAutomaton(),
      );
    }

    final states = <automaton_state.State>[];
    final stateIds = <String>{};
    final statesById = <String, automaton_state.State>{};
    final statesByName = <String, automaton_state.State?>{};
    final extensions = <String, Object?>{};
    final diagnostics = <CodecDiagnostic>[];
    var initialCount = 0;
    for (final element in automaton.findElements('state')) {
      final id = element.getAttribute('id')?.trim();
      if (id == null || id.isEmpty) {
        // The structured payload is created at runtime for the presentation
        // boundary, so this constructor cannot be const.
        // ignore: prefer_const_constructors
        return CodecMalformed(
          message: 'JFLAP state is missing a non-empty id.',
          location: const CodecSourceLocation(
            path: '/structure/automaton/state/@id',
          ),
          structuredMessage: FsaJflapMessages.missingStateId(),
        );
      }
      if (!stateIds.add(id)) {
        return CodecMalformed(
          message: 'Duplicate JFLAP state id: $id.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]',
          ),
          structuredMessage: FsaJflapMessages.duplicateStateId(id),
        );
      }
      final x = _coordinate(element, 'x');
      final y = _coordinate(element, 'y');
      if (x == null || y == null) {
        return CodecMalformed(
          message: 'State $id has an invalid coordinate.',
          location: CodecSourceLocation(
            path: '/structure/automaton/state[@id="$id"]',
          ),
          structuredMessage: FsaJflapMessages.invalidStateCoordinate(id),
        );
      }
      final name = element.getAttribute('name') ?? id;
      final label =
          element.findElements('label').firstOrNull?.innerText ?? name;
      final isInitial = element.findElements('initial').isNotEmpty;
      if (isInitial) initialCount++;
      final state = automaton_state.State(
        id: id,
        label: label,
        position: Vector2(x, y),
        isInitial: isInitial,
        isAccepting: element.findElements('final').isNotEmpty,
      );
      states.add(state);
      statesById[id] = state;
      if (statesByName.containsKey(name) && statesByName[name] != state) {
        statesByName[name] = null;
      } else {
        statesByName[name] = state;
      }
      if (name != label) extensions['stateName.$id'] = name;
      _preserveAttributes(
        element,
        known: const {'id', 'name', 'x', 'y'},
        key: 'stateAttributes.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      _preserveUnknown(
        element,
        known: const {'x', 'y', 'label', 'initial', 'final'},
        key: 'stateChildren.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
    }
    if (states.isEmpty) {
      return CodecMalformed(
        message: 'JFLAP automaton does not contain any states.',
        location: const CodecSourceLocation(path: '/structure/automaton/state'),
        structuredMessage: _jflapParserMessage('empty-automaton'),
      );
    }
    final collectionEntries =
        states.length + automaton.findElements('transition').length;
    if (collectionEntries >
        descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: collectionEntries,
      );
    }
    if (initialCount > 1) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: 'Turing Lab FSA supports only one initial state.',
        structuredMessage: FsaJflapMessages.multipleInitialStates(),
      );
    }

    final transitions = <FSATransition>[];
    final alphabet = <String>{};
    var interpretedExplicitEpsilonAlias = false;
    var transitionIndex = 0;
    for (final element in automaton.findElements('transition')) {
      final from = element.findElements('from').firstOrNull?.innerText.trim();
      final to = element.findElements('to').firstOrNull?.innerText.trim();
      final fromState = from == null
          ? null
          : statesById[from] ?? statesByName[from];
      final toState = to == null ? null : statesById[to] ?? statesByName[to];
      final transitionLocation = CodecSourceLocation(
        path: '/structure/automaton/transition[$transitionIndex]',
      );
      if (from == null || from.isEmpty || to == null || to.isEmpty) {
        return CodecMalformed(
          message: 'parser.jflap-xml.incomplete-transition',
          location: transitionLocation,
          structuredMessage: _jflapParserMessage(
            'incomplete-transition',
            arguments: {
              'index': StructuredMessageArgument.index(
                transitionIndex,
                role: 'transition-index',
              ),
            },
          ),
        );
      }
      if (fromState == null || toState == null) {
        return CodecMalformed(
          message: 'Transition $transitionIndex references an unknown state.',
          location: transitionLocation,
          structuredMessage: _jflapParserMessage(
            'unknown-transition-endpoints',
            arguments: {
              'from': StructuredMessageArgument.identifier(
                from,
                role: 'source-state',
              ),
              'to': StructuredMessageArgument.identifier(
                to,
                role: 'target-state',
              ),
            },
          ),
        );
      }
      final rawRead = element.findElements('read').firstOrNull?.innerText;
      final symbol = normalizeToEpsilon(rawRead);
      final epsilon = isEpsilonSymbol(symbol);
      if (rawRead != null &&
          rawRead.trim().isNotEmpty &&
          isEpsilonSymbol(rawRead)) {
        interpretedExplicitEpsilonAlias = true;
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.explicit-epsilon-alias-interpreted',
            message:
                'An explicit epsilon alias was interpreted as an empty read.',
            path: '/structure/automaton/transition[$transitionIndex]/read',
            sourceValue: rawRead,
            structuredMessage: FsaJflapMessages.explicitEpsilonAliasInterpreted(
              rawRead.trim(),
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        );
      }
      if (!epsilon) alphabet.add(symbol);
      final id = 't$transitionIndex';
      transitions.add(
        FSATransition(
          id: id,
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: epsilon ? const {} : {symbol},
          lambdaSymbol: epsilon ? kEpsilonSymbol : null,
        ),
      );
      _preserveAttributes(
        element,
        known: const {},
        key: 'transitionAttributes.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      _preserveUnknown(
        element,
        known: const {'from', 'to', 'read'},
        key: 'transitionChildren.$id',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      transitionIndex++;
    }
    final source = utf8Payload(payload);
    final importedDocumentId = deterministicContentId('imported_fsa', source);
    readJflapAnnotations(
      automaton,
      documentId: importedDocumentId,
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
    _preserveAttributes(
      automaton,
      known: const {},
      key: 'automatonAttributes',
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
    _preserveAttributes(
      root,
      known: const {'type'},
      key: 'rootAttributes',
      extensions: extensions,
      diagnostics: diagnostics,
    );

    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final fsa = FSA(
      id: importedDocumentId,
      name: 'Imported Automaton',
      states: states.toSet(),
      transitions: transitions.toSet(),
      alphabet: alphabet,
      initialState: states.firstWhereOrNull((state) => state.isInitial),
      acceptingStates: states.where((state) => state.isAccepting).toSet(),
      created: epoch,
      modified: epoch,
      bounds: _bounds(states),
    );
    return CodecSuccess(
      value: InteroperableDocument<Object>(
        document: fsa,
        systemKey: DefaultFormalSystemIds.fsa,
        schema: descriptorSchema,
        sourceMetadata: const DocumentSourceMetadata(
          application: 'JFLAP',
          sourceFormatVersion: '4+',
        ),
        extensions: DocumentExtensionBag(extensions),
      ),
      fidelity: interpretedExplicitEpsilonAlias
          ? DocumentFidelity.lossy
          : DocumentFidelity.normalized,
      diagnostics: [
        CodecDiagnostic(
          code: 'jflap.canonical-order',
          message: 'State and transition ordering is canonicalized on export.',
          structuredMessage: FsaJflapMessages.canonicalOrderImport(),
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
    if (document.systemKey != DefaultFormalSystemIds.fsa ||
        document.document is! FSA) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'FSA JFLAP codec requires an FSA document.',
        structuredMessage: FsaJflapMessages.requiresFsaDocument(),
      );
    }
    if (document.schema.id != descriptorSchema.id ||
        !descriptor.schemas.contains(document.schema.version.value)) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'Unsupported FSA schema ${document.schema.version.value}.',
        structuredMessage: FsaJflapMessages.unsupportedSchema(
          document.schema.version.value,
        ),
      );
    }
    final fsa = document.document as FSA;
    final validation = fsa.validate();
    if (validation.isNotEmpty) {
      return CodecMalformed(
        message: validation.first,
        location: const CodecSourceLocation(path: r'$.document'),
        structuredMessage: FsaJflapMessages.invalidDocument(),
      );
    }
    final states = fsa.states.toList()..sort((a, b) => a.id.compareTo(b.id));
    final transitions = fsa.transitions.whereType<FSATransition>().toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final diagnostics = <CodecDiagnostic>[
      CodecDiagnostic(
        code: 'jflap.canonical-order',
        message: 'State and transition ordering was canonicalized.',
        structuredMessage: FsaJflapMessages.canonicalOrderExport(),
        disposition: CodecDiagnosticDisposition.normalized,
      ),
    ];
    for (final state in states) {
      if (state.type != automaton_state.StateType.normal) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.state-type-dropped',
            message: 'JFLAP FSA cannot store the Turing Lab state type.',
            path: '\$.states.${state.id}.type',
            sourceValue: state.type.name,
            structuredMessage: FsaJflapMessages.stateTypeDropped(state.id),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        );
      }
      if (state.properties.isNotEmpty) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.state-properties-dropped',
            message: 'JFLAP FSA cannot store Turing Lab state properties.',
            path: '\$.states.${state.id}.properties',
            sourceValue: state.properties,
            structuredMessage: FsaJflapMessages.statePropertiesDropped(
              state.id,
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        );
      }
    }
    for (final transition in transitions) {
      if (transition.controlPoint.x != 0 || transition.controlPoint.y != 0) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.transition-control-point-dropped',
            message: 'JFLAP FSA cannot store transition control points.',
            path: '\$.transitions.${transition.id}.controlPoint',
            sourceValue: {
              'x': transition.controlPoint.x,
              'y': transition.controlPoint.y,
            },
            structuredMessage: FsaJflapMessages.transitionControlPointDropped(
              transitionId: transition.id,
              x: transition.controlPoint.x,
              y: transition.controlPoint.y,
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        );
      }
      final canonicalLabel = transition.lambdaSymbol != null
          ? transition.lambdaSymbol!
          : ((transition.inputSymbols.toList()..sort()).join(','));
      if (transition.label != canonicalLabel) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.transition-display-label-dropped',
            message: 'JFLAP FSA cannot store a separate transition label.',
            path: '\$.transitions.${transition.id}.label',
            sourceValue: transition.label,
            structuredMessage: FsaJflapMessages.transitionDisplayLabelDropped(
              transitionId: transition.id,
              label: transition.label,
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        );
      }
      final aliases = transition.inputSymbols.where(isEpsilonSymbol).toList()
        ..sort();
      if (aliases.isNotEmpty) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.explicit-epsilon-alias-exported-empty',
            message: 'Explicit epsilon aliases are exported as empty reads.',
            path: '\$.transitions.${transition.id}.inputSymbols',
            sourceValue: aliases,
            structuredMessage: FsaJflapMessages.explicitEpsilonAliasExported(
              transitionId: transition.id,
              aliases: aliases.join(','),
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        );
      }
    }
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', 'fa');
        _writeAttributes(builder, document.extensions.values['rootAttributes']);
        builder.element('type', nest: 'fa');
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
                  builder.attribute('id', state.id);
                  builder.attribute(
                    'name',
                    document.extensions.values['stateName.${state.id}']
                            as String? ??
                        state.label,
                  );
                  _writeAttributes(
                    builder,
                    document.extensions.values['stateAttributes.${state.id}'],
                  );
                  builder.element('x', nest: _number(state.position.x));
                  builder.element('y', nest: _number(state.position.y));
                  if (state.label != state.id) {
                    builder.element('label', nest: state.label);
                  }
                  if (state.isInitial) builder.element('initial');
                  if (state.isAccepting) builder.element('final');
                  _writeExtensions(
                    builder,
                    document.extensions.values['stateChildren.${state.id}'],
                  );
                },
              );
            }
            for (final transition in transitions) {
              final symbols =
                  transition.inputSymbols.isEmpty
                        ? <String>[transition.symbol]
                        : transition.inputSymbols.toList()
                    ..sort();
              for (
                var symbolIndex = 0;
                symbolIndex < symbols.length;
                symbolIndex++
              ) {
                final symbol = symbols[symbolIndex];
                builder.element(
                  'transition',
                  nest: () {
                    if (symbolIndex == 0) {
                      _writeAttributes(
                        builder,
                        document
                            .extensions
                            .values['transitionAttributes.${transition.id}'],
                      );
                    }
                    builder.element('from', nest: transition.fromState.id);
                    builder.element('to', nest: transition.toState.id);
                    if (isEpsilonSymbol(symbol)) {
                      builder.element('read', isSelfClosing: true);
                    } else {
                      builder.element('read', nest: symbol);
                    }
                    if (symbolIndex == 0) {
                      _writeExtensions(
                        builder,
                        document
                            .extensions
                            .values['transitionChildren.${transition.id}'],
                      );
                    }
                  },
                );
              }
              if (symbols.length > 1) {
                diagnostics.add(
                  CodecDiagnostic(
                    code: 'jflap.multi-symbol-transition-expanded',
                    message:
                        'A grouped transition was expanded into one JFLAP transition per symbol.',
                    path: r'$.transitions',
                    sourceValue: {
                      'transitionId': transition.id,
                      'symbols': symbols,
                    },
                    structuredMessage:
                        FsaJflapMessages.multiSymbolTransitionExpanded(
                          transitionId: transition.id,
                          symbolCount: symbols.length,
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
        filename: filenameWithExtension(filename, 'automaton', 'jff'),
        schema: descriptorSchema,
      ),
      fidelity:
          diagnostics.any(
            (diagnostic) =>
                diagnostic.disposition == CodecDiagnosticDisposition.dropped,
          )
          ? DocumentFidelity.lossy
          : DocumentFidelity.normalized,
      diagnostics: diagnostics,
    );
  }

  static const descriptorSchema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.fsa'),
    version: DocumentSchemaVersion(1),
  );
}

StructuredMessage _jflapParserMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'parser.jflap-xml',
  code: code,
  category: StructuredMessageCategory.interoperability,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

double? _coordinate(XmlElement state, String name) {
  final raw =
      state.getAttribute(name) ??
      state.findElements(name).firstOrNull?.innerText.trim();
  return raw == null ? 0 : double.tryParse(raw);
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
      structuredMessage: FsaJflapMessages.unknownOptionalElement(key),
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
      structuredMessage: FsaJflapMessages.unknownOptionalAttribute(key),
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

math.Rectangle<double> _bounds(List<automaton_state.State> states) {
  final xs = states.map((state) => state.position.x);
  final ys = states.map((state) => state.position.y);
  final minX = xs.reduce((a, b) => a < b ? a : b);
  final maxX = xs.reduce((a, b) => a > b ? a : b);
  final minY = ys.reduce((a, b) => a < b ? a : b);
  final maxY = ys.reduce((a, b) => a > b ? a : b);
  return math.Rectangle<double>(
    minX,
    minY,
    (maxX - minX) + 80,
    (maxY - minY) + 80,
  );
}

CodecOutcome<InteroperableDocument<Object>> _copyXmlFailure(
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
        structuredMessage: structuredMessage,
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

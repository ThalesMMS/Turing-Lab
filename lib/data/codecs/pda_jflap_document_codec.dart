import 'dart:convert';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/pda.dart';
import '../../core/models/pda_acceptance_mode.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart';
import '../../core/models/transition.dart';
import '../../core/utils/epsilon_utils.dart';
import 'codec_utils.dart';
import 'hardened_xml.dart';
import 'jflap_annotations.dart';
import 'pda_jflap_messages.dart';
import 'pda_json_document_codec.dart';

/// Loss-aware JFLAP XML codec for pushdown automata.
final class PdaJflapDocumentCodec implements DocumentCodecCapability<Object> {
  const PdaJflapDocumentCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('pda.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.pda.jflap-xml'),
    systemKey: DefaultFormalSystemIds.pda,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 115,
    compatibilityOwner: 'JFLAP 7.1 PDATransducer',
    canonicalFixtures: const [
      'test/fixtures/interoperability/pda_canonical.jff',
    ],
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
      CodecSemanticCapabilityId.notes,
    },
    knownUnsupportedFields: const {
      'standard JFLAP transition IDs and tokenized push words',
      'standard JFLAP initial stack symbols other than Z',
      'standard JFLAP persisted acceptance mode',
      'standard JFLAP document metadata and viewport',
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
            r'<type\s*>\s*pda\s*</type\s*>',
            caseSensitive: false,
          ).hasMatch(prefix) ||
          RegExp(
            r'''<structure\b[^>]*\btype\s*=\s*["']pda["']''',
            caseSensitive: false,
          ).hasMatch(prefix);
      return recognized
          ? CodecSniffResult(
              confidence: 100,
              detectedSystem: DefaultFormalSystemIds.pda,
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
    if (parsed is! CodecSuccess<XmlDocument>) return _copyPdaXmlFailure(parsed);
    final root = parsed.value.rootElement;
    final type =
        root.getElement('type')?.innerText.trim() ??
        root.getAttribute('type')?.trim();
    if (root.name.local != 'structure') {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'JFLAP XML root must be <structure>.',
        location: const CodecSourceLocation(path: '/'),
        structuredMessage: PdaJflapMessages.invalidRoot(),
      );
    }
    if (type?.toLowerCase() != 'pda') {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected a JFLAP PDA document.',
        structuredMessage: PdaJflapMessages.unsupportedDocumentType(
          type ?? '(missing)',
        ),
      );
    }
    final automaton = root.findElements('automaton').firstOrNull;
    if (automaton == null) {
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'JFLAP PDA is missing <automaton>.',
        location: CodecSourceLocation(path: '/structure/automaton'),
        structuredMessage: PdaJflapMessages.missingAutomaton(),
      );
    }
    final stateElements = automaton.findElements('state').toList();
    final transitionElements = automaton.findElements('transition').toList();
    final count = stateElements.length + transitionElements.length;
    if (count > descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: count,
      );
    }

    try {
      final extensions = <String, Object?>{};
      final diagnostics = <CodecDiagnostic>[];
      final metadataElement = root.getElement('turingLabPda');
      final metadata = metadataElement == null
          ? const <String, dynamic>{}
          : _jsonObject(metadataElement.innerText, '/structure/turingLabPda');
      if (metadataElement == null) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.pda.canonical-order',
            message: 'PDA state and transition order is canonicalized.',
            structuredMessage: PdaJflapMessages.canonicalOrderImport(),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
      final states = <State>[];
      final statesById = <String, State>{};
      var initialCount = 0;
      for (var index = 0; index < stateElements.length; index++) {
        final element = stateElements[index];
        final id = element.getAttribute('id')?.trim();
        if (id == null || id.isEmpty || statesById.containsKey(id)) {
          throw _PdaXmlException(
            id == null || id.isEmpty
                ? CodecMalformedReason.missingField
                : CodecMalformedReason.duplicateIdentity,
            'JFLAP PDA state ids must be non-empty and unique.',
            '/structure/automaton/state[$index]/@id',
            id == null || id.isEmpty
                ? PdaJflapMessages.missingStateId()
                : PdaJflapMessages.duplicateStateId(id),
          );
        }
        final x = double.tryParse(element.getElement('x')?.innerText ?? '');
        final y = double.tryParse(element.getElement('y')?.innerText ?? '');
        if (x == null || y == null) {
          throw _PdaXmlException(
            CodecMalformedReason.invalidValue,
            'JFLAP PDA state $id has invalid coordinates.',
            '/structure/automaton/state[$index]',
            PdaJflapMessages.invalidStateCoordinate(id),
          );
        }
        final initial = element.findElements('initial').isNotEmpty;
        if (initial) initialCount++;
        final custom = element.getElement('turingLabState');
        final customData = custom == null
            ? const <String, dynamic>{}
            : _jsonObject(
                custom.innerText,
                '/structure/automaton/state[$index]/turingLabState',
              );
        final state = State(
          id: id,
          label:
              element.getElement('label')?.innerText ??
              element.getAttribute('name') ??
              'q$id',
          position: Vector2(x, y),
          isInitial: initial,
          isAccepting: element.findElements('final').isNotEmpty,
          type: StateType.values.firstWhere(
            (value) => value.name == customData['type'],
            orElse: () => StateType.normal,
          ),
          properties: Map<String, dynamic>.from(
            customData['properties'] as Map? ?? const {},
          ),
        );
        states.add(state);
        statesById[id] = state;
        preserveXmlAttributes(
          element,
          known: const {'id', 'name'},
          key: 'stateAttributes.$id',
          extensions: extensions,
          diagnostics: diagnostics,
        );
        preserveXmlChildren(
          element,
          known: const {
            'x',
            'y',
            'label',
            'initial',
            'final',
            'turingLabState',
          },
          key: 'stateChildren.$id',
          extensions: extensions,
          diagnostics: diagnostics,
        );
      }
      if (states.isEmpty || initialCount != 1) {
        throw _PdaXmlException(
          CodecMalformedReason.invalidValue,
          'A JFLAP PDA requires states and exactly one initial state.',
          '/structure/automaton/state',
          PdaJflapMessages.invalidDocument(),
        );
      }

      final transitions = <PDATransition>[];
      final transitionIds = <String>{};
      final alphabet = <String>{};
      final stackAlphabet = <String>{};
      for (var index = 0; index < transitionElements.length; index++) {
        final element = transitionElements[index];
        final fromId = element.getElement('from')?.innerText.trim();
        final toId = element.getElement('to')?.innerText.trim();
        final from = statesById[fromId];
        final to = statesById[toId];
        if (from == null || to == null) {
          throw _PdaXmlException(
            CodecMalformedReason.invalidValue,
            'JFLAP PDA transition endpoints must reference state ids.',
            '/structure/automaton/transition[$index]',
            PdaJflapMessages.unknownTransitionEndpoints(from: fromId, to: toId),
          );
        }
        final readRaw = element.getElement('read')?.innerText ?? '';
        final popRaw = element.getElement('pop')?.innerText ?? '';
        final pushRaw = element.getElement('push')?.innerText ?? '';
        final custom = element.getElement('turingLabTransition');
        final customData = custom == null
            ? const <String, dynamic>{}
            : _jsonObject(
                custom.innerText,
                '/structure/automaton/transition[$index]/turingLabTransition',
              );
        final lambdaInput = readRaw.isEmpty || isEpsilonSymbol(readRaw);
        final lambdaPop = popRaw.isEmpty || isEpsilonSymbol(popRaw);
        final lambdaPush = pushRaw.isEmpty || isEpsilonSymbol(pushRaw);
        final input = lambdaInput ? '' : readRaw;
        final pop = lambdaPop ? '' : popRaw;
        final push = lambdaPush ? '' : pushRaw;
        final customTokens = (customData['pushSymbols'] as List?)
            ?.map((value) => value as String)
            .toList(growable: false);
        final pushTokens = customTokens != null && customTokens.join() == push
            ? customTokens
            : push.runes.map(String.fromCharCode).toList(growable: false);
        if (customTokens != null && customTokens.join() != push) {
          diagnostics.add(
            CodecDiagnostic(
              code: 'jflap.pda-stale-token-extension',
              message:
                  'A stale token extension was ignored after the JFLAP push text changed.',
              path:
                  '/structure/automaton/transition[$index]/turingLabTransition',
              structuredMessage: PdaJflapMessages.staleTokenExtension(),
              disposition: CodecDiagnosticDisposition.normalized,
            ),
          );
        }
        if ((readRaw.isNotEmpty && isEpsilonSymbol(readRaw)) ||
            (popRaw.isNotEmpty && isEpsilonSymbol(popRaw)) ||
            (pushRaw.isNotEmpty && isEpsilonSymbol(pushRaw))) {
          diagnostics.add(
            CodecDiagnostic(
              code: 'jflap.explicit-epsilon-alias-interpreted',
              message: 'An explicit epsilon alias was normalized to emptiness.',
              path: '/structure/automaton/transition[$index]',
              structuredMessage:
                  PdaJflapMessages.explicitEpsilonAliasInterpreted(),
              disposition: CodecDiagnosticDisposition.dropped,
            ),
          );
        }
        if (metadataElement == null && !lambdaPop && popRaw.runes.length > 1) {
          diagnostics.add(
            CodecDiagnostic(
              code: 'jflap.pda-pop-word-treated-as-atomic-token',
              message:
                  'JFLAP pops this text as a character word; Turing Lab imported it as one atomic stack token.',
              path: '/structure/automaton/transition[$index]/pop',
              structuredMessage: PdaJflapMessages.popWordTreatedAsAtomicToken(),
              disposition: CodecDiagnosticDisposition.dropped,
            ),
          );
        }
        final signature = canonicalJson({
          'from': from.id,
          'to': to.id,
          'read': input,
          'pop': pop,
          'push': pushTokens,
        });
        final id =
            customData['id'] as String? ??
            deterministicContentId('pda_transition', signature);
        if (id.isEmpty) {
          throw _PdaXmlException(
            CodecMalformedReason.invalidValue,
            'JFLAP PDA transition ids must be non-empty.',
            '/structure/automaton/transition[$index]/turingLabTransition',
            PdaJflapMessages.invalidTransitionId(),
          );
        }
        if (!transitionIds.add(id)) {
          throw _PdaXmlException(
            CodecMalformedReason.duplicateIdentity,
            'JFLAP PDA transition ids must be unique.',
            '/structure/automaton/transition[$index]/turingLabTransition',
            PdaJflapMessages.duplicateTransitionId(),
          );
        }
        final transition = PDATransition(
          id: id,
          fromState: from,
          toState: to,
          label:
              customData['label'] as String? ??
              PDATransition.formatLabel(
                inputSymbol: input,
                popSymbol: pop,
                pushSymbol: push,
                isLambdaInput: lambdaInput,
                isLambdaPop: lambdaPop,
                isLambdaPush: lambdaPush,
              ),
          controlPoint: _controlPoint(customData),
          type: TransitionType.values.firstWhere(
            (value) => value.name == customData['type'],
            orElse: () => TransitionType.deterministic,
          ),
          inputSymbol: input,
          popSymbol: pop,
          pushSymbol: push,
          pushSymbols: pushTokens,
          isLambdaInput: lambdaInput,
          isLambdaPop: lambdaPop,
          isLambdaPush: lambdaPush,
        );
        transitions.add(transition);
        if (!lambdaInput) alphabet.add(input);
        if (!lambdaPop) stackAlphabet.add(pop);
        if (!lambdaPush) stackAlphabet.addAll(pushTokens);
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
            'pop',
            'push',
            'turingLabTransition',
          },
          key: 'transitionChildren.$id',
          extensions: extensions,
          diagnostics: diagnostics,
        );
      }

      final initialStack = metadata['initialStackSymbol'] as String? ?? 'Z';
      stackAlphabet.add(initialStack);
      final declaredInput = (metadata['alphabet'] as List?)
          ?.map((value) => value as String)
          .toSet();
      final declaredStack = (metadata['stackAlphabet'] as List?)
          ?.map((value) => value as String)
          .toSet();
      final acceptanceModeName = metadata['acceptanceMode'];
      if (acceptanceModeName != null &&
          (acceptanceModeName is! String ||
              !PDAAcceptanceMode.values.any(
                (value) => value.name == acceptanceModeName,
              ))) {
        throw _PdaXmlException(
          CodecMalformedReason.invalidValue,
          'The Turing Lab PDA acceptance mode is invalid.',
          '/structure/turingLabPda/acceptanceMode',
          PdaJflapMessages.invalidAcceptanceMode(),
        );
      }
      final acceptanceMode = acceptanceModeName == null
          ? PDAAcceptanceMode.finalState
          : PDAAcceptanceMode.values.firstWhere(
              (value) => value.name == acceptanceModeName,
            );
      if (metadataElement == null) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.pda-acceptance-mode-assumed-final-state',
            message:
                'JFLAP XML does not store the selected PDA acceptance mode; final-state acceptance was assumed.',
            path: '/structure',
            structuredMessage:
                PdaJflapMessages.acceptanceModeAssumedFinalState(),
            disposition: CodecDiagnosticDisposition.normalized,
          ),
        );
      }
      states.sort((left, right) => left.id.compareTo(right.id));
      transitions.sort((left, right) => left.id.compareTo(right.id));
      final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final pda = PDA(
        id:
            metadata['id'] as String? ??
            deterministicContentId(
              'imported_pda',
              canonicalIdentityJson({
                'states': states.map((state) => state.toJson()).toList(),
                'transitions': transitions
                    .map((transition) => transition.toJson())
                    .toList(),
              }),
            ),
        name: metadata['name'] as String? ?? 'Imported Pushdown Automaton',
        states: states.toSet(),
        transitions: transitions.toSet(),
        alphabet: declaredInput ?? alphabet,
        initialState: states.firstWhere((state) => state.isInitial),
        acceptingStates: states.where((state) => state.isAccepting).toSet(),
        created:
            DateTime.tryParse(metadata['created'] as String? ?? '') ?? epoch,
        modified:
            DateTime.tryParse(metadata['modified'] as String? ?? '') ?? epoch,
        bounds: _metadataBounds(metadata) ?? _bounds(states),
        zoomLevel: (metadata['zoomLevel'] as num?)?.toDouble() ?? 1,
        panOffset: _metadataPan(metadata),
        stackAlphabet: declaredStack ?? stackAlphabet,
        initialStackSymbol: initialStack,
        acceptanceMode: acceptanceMode,
      );
      final validation = pda.validate();
      if (validation.isNotEmpty) {
        throw _PdaXmlException(
          CodecMalformedReason.invalidValue,
          validation.first,
          '/structure/automaton',
          PdaJflapMessages.invalidDocument(),
        );
      }
      preserveXmlAttributes(
        automaton,
        known: const {},
        key: 'automatonAttributes',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      readJflapAnnotations(
        automaton,
        documentId: pda.id,
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
      preserveXmlAttributes(
        root,
        known: const {'type'},
        key: 'rootAttributes',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      preserveXmlChildren(
        root,
        known: const {'type', 'automaton', 'turingLabPda'},
        key: 'rootChildren',
        extensions: extensions,
        diagnostics: diagnostics,
      );
      final resolvedDiagnostics = _withPdaDiagnosticMessages(diagnostics);
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
          document: pda,
          systemKey: DefaultFormalSystemIds.pda,
          schema: PdaJsonDocumentCodec.schema,
          sourceMetadata: const DocumentSourceMetadata(
            application: 'JFLAP',
            sourceFormatVersion: '4+',
          ),
          extensions: DocumentExtensionBag(extensions),
        ),
        fidelity: hasDroppedDiagnostic
            ? DocumentFidelity.lossy
            : metadataElement == null || hasNormalizedDiagnostic
            ? DocumentFidelity.normalized
            : DocumentFidelity.exact,
        diagnostics: resolvedDiagnostics,
      );
    } on _PdaXmlException catch (error) {
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
        location: const CodecSourceLocation(path: '/structure'),
        cause: error,
        structuredMessage: PdaJflapMessages.invalidDocument(),
      );
    } on TypeError catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Malformed Turing Lab PDA extension.',
        location: const CodecSourceLocation(path: '/structure'),
        cause: error,
        structuredMessage: PdaJflapMessages.malformedExtension(),
      );
    }
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != DefaultFormalSystemIds.pda ||
        document.document is! PDA) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'PDA JFLAP codec requires a PDA document.',
        structuredMessage: PdaJflapMessages.requiresPdaDocument(),
      );
    }
    if (document.schema != PdaJsonDocumentCodec.schema) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'PDA JFLAP codec requires turing-lab.pda schema version 1.',
        structuredMessage: PdaJflapMessages.unsupportedSchema(
          document.schema.version.value,
        ),
      );
    }
    final pda = document.document as PDA;
    final validation = pda.validate();
    if (validation.isNotEmpty) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: validation.first,
        location: const CodecSourceLocation(path: r'$.document'),
        structuredMessage: PdaJflapMessages.invalidDocument(),
      );
    }
    final states = pda.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final transitions = pda.pdaTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final diagnostics = <CodecDiagnostic>[];
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        writeXmlAttributes(
          builder,
          document.extensions.values['rootAttributes'],
        );
        builder.element('type', nest: 'pda');
        builder.element(
          'turingLabPda',
          nest: jsonEncode({
            'schema': 'turing-lab.pda@1',
            'id': pda.id,
            'name': pda.name,
            'alphabet': pda.alphabet.toList()..sort(),
            'stackAlphabet': pda.stackAlphabet.toList()..sort(),
            'initialStackSymbol': pda.initialStackSymbol,
            'acceptanceMode': pda.acceptanceMode.name,
            'created': pda.created.toIso8601String(),
            'modified': pda.modified.toIso8601String(),
            'bounds': {
              'x': pda.bounds.left,
              'y': pda.bounds.top,
              'width': pda.bounds.width,
              'height': pda.bounds.height,
            },
            'zoomLevel': pda.zoomLevel,
            'panOffset': {'x': pda.panOffset.x, 'y': pda.panOffset.y},
          }),
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
                  builder.attribute('name', state.label);
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
                      nest: jsonEncode({
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
                  _nullableElement(
                    builder,
                    'read',
                    transition.inputSymbol,
                    transition.isLambdaInput,
                  );
                  _nullableElement(
                    builder,
                    'pop',
                    transition.popSymbol,
                    transition.isLambdaPop,
                  );
                  _nullableElement(
                    builder,
                    'push',
                    transition.pushSymbol,
                    transition.isLambdaPush,
                  );
                  builder.element(
                    'turingLabTransition',
                    nest: jsonEncode({
                      'id': transition.id,
                      'label': transition.label,
                      'type': transition.type.name,
                      'controlPoint': {
                        'x': transition.controlPoint.x,
                        'y': transition.controlPoint.y,
                      },
                      'pushSymbols': transition.pushSymbols,
                      'isLambdaInput': transition.isLambdaInput,
                      'isLambdaPop': transition.isLambdaPop,
                      'isLambdaPush': transition.isLambdaPush,
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
    final xml = '${builder.buildDocument().toXmlString(pretty: true)}\n';
    diagnostics.addAll([
      CodecDiagnostic(
        code: 'jflap.pda-turing-lab-extension-portability',
        message:
            'JFLAP open/save discards Turing Lab token, identity, initial-stack, and acceptance-mode extensions.',
        path: '/structure/turingLabPda',
        structuredMessage: PdaJflapMessages.extensionPortability(),
        disposition: CodecDiagnosticDisposition.dropped,
      ),
      if (pda.initialStackSymbol != 'Z')
        CodecDiagnostic(
          code: 'jflap.pda-initial-stack-symbol-not-portable',
          message: 'JFLAP simulation initializes the PDA stack with Z.',
          path: '/structure/turingLabPda/initialStackSymbol',
          structuredMessage: PdaJflapMessages.initialStackSymbolNotPortable(),
          disposition: CodecDiagnosticDisposition.dropped,
        ),
      if (pda.acceptanceMode != PDAAcceptanceMode.finalState)
        CodecDiagnostic(
          code: 'jflap.pda-acceptance-mode-not-portable',
          message:
              'JFLAP asks for an acceptance mode when simulation starts instead of storing it in the document.',
          path: '/structure/turingLabPda/acceptanceMode',
          structuredMessage: PdaJflapMessages.acceptanceModeNotPortable(),
          disposition: CodecDiagnosticDisposition.dropped,
        ),
      for (var index = 0; index < transitions.length; index++)
        if (!transitions[index].isLambdaPop &&
            transitions[index].popSymbol.runes.length > 1)
          CodecDiagnostic(
            code: 'jflap.pda-atomic-pop-token-not-portable',
            message:
                'JFLAP will pop the serialized text as a character word instead of one atomic token.',
            path: '/structure/automaton/transition[$index]/pop',
            structuredMessage: PdaJflapMessages.atomicPopTokenNotPortable(),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
      for (var index = 0; index < transitions.length; index++)
        if (!transitions[index].isLambdaPush &&
            transitions[index].pushSymbols.any(
              (symbol) => symbol.runes.length > 1,
            ))
          CodecDiagnostic(
            code: 'jflap.pda-atomic-push-token-not-portable',
            message:
                'JFLAP will split at least one serialized push token into characters.',
            path: '/structure/automaton/transition[$index]/push',
            structuredMessage: PdaJflapMessages.atomicPushTokenNotPortable(),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
    ]);
    return CodecSuccess(
      value: EncodedDocument(
        bytes: utf8Bytes(xml),
        mimeType: 'application/xml',
        filename: filenameWithExtension(filename, 'pushdown-automaton', 'jff'),
        schema: PdaJsonDocumentCodec.schema,
      ),
      fidelity: DocumentFidelity.lossy,
      diagnostics: _withPdaDiagnosticMessages(diagnostics),
    );
  }
}

Map<String, dynamic> _jsonObject(String source, String path) {
  final value = jsonDecode(source);
  if (value is! Map) throw FormatException('Expected a JSON object at $path.');
  return Map<String, dynamic>.from(value);
}

Vector2 _controlPoint(Map<String, dynamic> data) {
  final raw = data['controlPoint'];
  if (raw is! Map) return Vector2.zero();
  return Vector2(
    (raw['x'] as num?)?.toDouble() ?? 0,
    (raw['y'] as num?)?.toDouble() ?? 0,
  );
}

math.Rectangle<double>? _metadataBounds(Map<String, dynamic> metadata) {
  final raw = metadata['bounds'];
  if (raw is! Map) return null;
  return math.Rectangle<double>(
    (raw['x'] as num?)?.toDouble() ?? 0,
    (raw['y'] as num?)?.toDouble() ?? 0,
    (raw['width'] as num?)?.toDouble() ?? 0,
    (raw['height'] as num?)?.toDouble() ?? 0,
  );
}

Vector2 _metadataPan(Map<String, dynamic> metadata) {
  final raw = metadata['panOffset'];
  if (raw is! Map) return Vector2.zero();
  return Vector2(
    (raw['x'] as num?)?.toDouble() ?? 0,
    (raw['y'] as num?)?.toDouble() ?? 0,
  );
}

math.Rectangle<double> _bounds(List<State> states) {
  final minX = states.map((state) => state.position.x).reduce(math.min);
  final minY = states.map((state) => state.position.y).reduce(math.min);
  final maxX = states.map((state) => state.position.x).reduce(math.max);
  final maxY = states.map((state) => state.position.y).reduce(math.max);
  return math.Rectangle<double>(minX, minY, maxX - minX, maxY - minY);
}

void _nullableElement(
  XmlBuilder builder,
  String name,
  String value,
  bool lambda,
) {
  if (lambda) {
    builder.element(name, isSelfClosing: true);
  } else {
    builder.element(name, nest: value);
  }
}

List<CodecDiagnostic> _withPdaDiagnosticMessages(
  List<CodecDiagnostic> diagnostics,
) {
  return diagnostics
      .map((diagnostic) {
        if (diagnostic.structuredMessage != null) return diagnostic;
        final structuredMessage = switch (diagnostic.code) {
          'jflap.unknown-optional-element' =>
            PdaJflapMessages.unknownOptionalElement(
              diagnostic.path ?? 'unknown',
            ),
          'jflap.unknown-optional-attribute' =>
            PdaJflapMessages.unknownOptionalAttribute(
              diagnostic.path ?? 'unknown',
            ),
          'jflap.note-invalid-position-preserved' =>
            PdaJflapMessages.invalidNotePosition(),
          'jflap.notes-normalized' => PdaJflapMessages.notesNormalized(),
          'jflap.note-presentation-dropped' =>
            PdaJflapMessages.notePresentationDropped(),
          _ => null,
        };
        if (structuredMessage == null) return diagnostic;
        return CodecDiagnostic(
          code: diagnostic.code,
          message: diagnostic.message,
          path: diagnostic.path,
          location: diagnostic.location,
          sourceValue: diagnostic.sourceValue,
          disposition: diagnostic.disposition,
          structuredMessage: structuredMessage,
        );
      })
      .toList(growable: false);
}

CodecOutcome<InteroperableDocument<Object>> _copyPdaXmlFailure(
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
            (reason == CodecMalformedReason.invalidUtf8
                ? PdaJflapMessages.invalidUtf8()
                : PdaJflapMessages.malformedXml()),
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

final class _PdaXmlException implements Exception {
  const _PdaXmlException(
    this.reason,
    this.message,
    this.path, [
    this.structuredMessage,
  ]);

  final CodecMalformedReason reason;
  final String message;
  final String path;
  final StructuredMessage? structuredMessage;
}

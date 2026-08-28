import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/data/codecs/fsa_jflap_codec.dart';
import 'package:turing_lab/data/codecs/fsa_jflap_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const codec = FsaJflapDocumentCodec();

  group('FSA JFLAP codec structured outcomes', () {
    test(
      'malformed XML root retains legacy detail and adds a typed message',
      () {
        final outcome = codec.decode(_payload('<not-structure/>'));

        expect(outcome, isA<CodecMalformed<InteroperableDocument<Object>>>());
        final malformed =
            outcome as CodecMalformed<InteroperableDocument<Object>>;
        expect(malformed.message, 'JFLAP XML root must be <structure>.');
        expect(malformed.location?.path, '/');
        _expectRoundTrip(
          malformed.structuredMessage!,
          'codec.fsa-jflap.invalid-root',
        );
      },
    );

    test(
      'unsupported document type carries the source type as a typed value',
      () {
        final outcome = codec.decode(
          _payload('<structure><type>pda</type></structure>'),
        );

        expect(outcome, isA<CodecUnsupported<InteroperableDocument<Object>>>());
        final unsupported =
            outcome as CodecUnsupported<InteroperableDocument<Object>>;
        expect(unsupported.message, 'JFLAP document type pda is not FSA.');
        expect(
          unsupported.structuredMessage?.stableCode,
          'codec.fsa-jflap.unsupported-document-type',
        );
        expect(
          unsupported.structuredMessage?.arguments['type'],
          StructuredMessageArgument.literal('pda', role: 'document-type'),
        );
        _expectRoundTrip(
          unsupported.structuredMessage!,
          'codec.fsa-jflap.unsupported-document-type',
        );
      },
    );

    test('malformed state and transition paths expose stable arguments', () {
      final missingId =
          codec.decode(
                _payload('''
<structure><type>fa</type><automaton>
  <state><x>0</x><y>0</y></state>
</automaton></structure>'''),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(missingId.message, 'JFLAP state is missing a non-empty id.');
      expect(
        missingId.structuredMessage?.stableCode,
        'codec.fsa-jflap.missing-state-id',
      );

      final duplicate =
          codec.decode(
                _payload('''
<structure><type>fa</type><automaton>
  <state id="q0"><x>0</x><y>0</y></state>
  <state id="q0"><x>1</x><y>0</y></state>
</automaton></structure>'''),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(
        duplicate.structuredMessage?.arguments['state'],
        StructuredMessageArgument.identifier('q0', role: 'state-id'),
      );

      final unknownEndpoint =
          codec.decode(
                _payload('''
<structure><type>fa</type><automaton>
  <state id="q0"><x>0</x><y>0</y></state>
  <transition><from>q0</from><to>q9</to><read>a</read></transition>
</automaton></structure>'''),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(
        unknownEndpoint.structuredMessage?.stableCode,
        'parser.jflap-xml.unknown-transition-endpoints',
      );
      expect(
        unknownEndpoint.structuredMessage?.arguments['to'],
        StructuredMessageArgument.identifier('q9', role: 'target-state'),
      );
      _expectRoundTrip(
        unknownEndpoint.structuredMessage!,
        'parser.jflap-xml.unknown-transition-endpoints',
      );
    });
  });

  group('FSA JFLAP import diagnostics', () {
    test(
      'normalization and preservation diagnostics carry structured data',
      () {
        const source = '''
<structure vendor="root">
  <type>fa</type>
  <automaton vendor="automaton">
    <state id="q0" name="q0" vendor="state">
      <x>0</x><y>0</y><initial/><custom/>
    </state>
    <state id="q1"><x>100</x><y>0</y><final/></state>
    <transition vendor="transition">
      <from>q0</from><to>q1</to><read>eps</read><custom/>
    </transition>
    <metadata/>
  </automaton>
  <metadata/>
</structure>''';

        final outcome = codec.decode(_payload(source));
        final success = outcome as CodecSuccess<InteroperableDocument<Object>>;

        final alias = success.diagnostics.firstWhere(
          (diagnostic) =>
              diagnostic.code == 'jflap.explicit-epsilon-alias-interpreted',
        );
        expect(
          alias.structuredMessage?.stableCode,
          'codec.fsa-jflap.explicit-epsilon-alias-interpreted',
        );
        expect(
          alias.structuredMessage?.arguments['symbol'],
          StructuredMessageArgument.symbol('eps', role: 'input-symbol'),
        );

        final unknownElement = success.diagnostics.firstWhere(
          (diagnostic) => diagnostic.code == 'jflap.unknown-optional-element',
        );
        expect(
          unknownElement.structuredMessage?.arguments['extension'],
          StructuredMessageArgument.literal(
            'stateChildren.q0',
            role: 'extension-key',
          ),
        );

        final unknownAttribute = success.diagnostics.firstWhere(
          (diagnostic) => diagnostic.code == 'jflap.unknown-optional-attribute',
        );
        expect(
          unknownAttribute.structuredMessage?.stableCode,
          'codec.fsa-jflap.unknown-optional-attribute',
        );
        expect(
          success.diagnostics
              .where((diagnostic) => diagnostic.structuredMessage != null)
              .map((diagnostic) => diagnostic.structuredMessage!.stableCode),
          contains('codec.fsa-jflap.canonical-order-import'),
        );

        for (final diagnostic in success.diagnostics) {
          if (diagnostic.structuredMessage case final message?) {
            _expectRoundTrip(message, message.stableCode);
          }
        }
      },
    );
  });

  group('FSA JFLAP export diagnostics', () {
    test(
      'loss reports retain legacy fields and typed structured arguments',
      () {
        final outcome = codec.encode(_lossyFsaDocument());
        final success = outcome as CodecSuccess<EncodedDocument>;

        expect(success.fidelity, DocumentFidelity.lossy);
        expect(
          success.diagnostics.map((diagnostic) => diagnostic.code),
          containsAll({
            'jflap.canonical-order',
            'jflap.state-type-dropped',
            'jflap.state-properties-dropped',
            'jflap.transition-control-point-dropped',
            'jflap.transition-display-label-dropped',
            'jflap.explicit-epsilon-alias-exported-empty',
            'jflap.multi-symbol-transition-expanded',
          }),
        );

        final controlPoint = success.diagnostics.firstWhere(
          (diagnostic) =>
              diagnostic.code == 'jflap.transition-control-point-dropped',
        );
        expect(
          controlPoint.structuredMessage?.arguments['transition'],
          StructuredMessageArgument.identifier('t0', role: 'transition-id'),
        );
        expect(
          controlPoint.structuredMessage?.arguments['control-point'],
          StructuredMessageArgument.coordinate(x: 2, y: 3),
        );

        final multiSymbol = success.diagnostics.firstWhere(
          (diagnostic) =>
              diagnostic.code == 'jflap.multi-symbol-transition-expanded',
        );
        expect(
          multiSymbol.structuredMessage?.arguments['count'],
          StructuredMessageArgument.count(2, role: 'symbol-count'),
        );
        final label = success.diagnostics.firstWhere(
          (diagnostic) =>
              diagnostic.code == 'jflap.transition-display-label-dropped',
        );
        expect(
          label.structuredMessage?.arguments['label'],
          StructuredMessageArgument.literal(
            'custom label',
            role: 'transition-label',
          ),
        );

        for (final diagnostic in success.diagnostics) {
          expect(diagnostic.structuredMessage, isNotNull);
          _expectRoundTrip(
            diagnostic.structuredMessage!,
            diagnostic.structuredMessage!.stableCode,
          );
        }
      },
    );

    test('unsupported and invalid encode outcomes are structured', () {
      final foreign =
          codec.encode(
                InteroperableDocument<Object>(
                  document: Object(),
                  systemKey: DefaultFormalSystemIds.grammar,
                  schema: const DocumentSchemaDescriptor(
                    id: DocumentSchemaId('turing-lab.grammar'),
                    version: DocumentSchemaVersion(1),
                  ),
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(foreign.message, 'FSA JFLAP codec requires an FSA document.');
      expect(
        foreign.structuredMessage?.stableCode,
        'codec.fsa-jflap.requires-fsa-document',
      );

      final wrongSchema =
          codec.encode(
                InteroperableDocument<Object>(
                  document: _validFsa(),
                  systemKey: DefaultFormalSystemIds.fsa,
                  schema: const DocumentSchemaDescriptor(
                    id: DocumentSchemaId('turing-lab.fsa'),
                    version: DocumentSchemaVersion(2),
                  ),
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(
        wrongSchema.structuredMessage?.arguments['version'],
        StructuredMessageArgument.integer(2, role: 'schema-version'),
      );

      final invalid =
          codec.encode(_invalidFsaDocument())
              as CodecMalformed<EncodedDocument>;
      expect(invalid.message, 'Automaton must have at least one state');
      expect(
        invalid.structuredMessage?.stableCode,
        'codec.fsa-jflap.invalid-document',
      );
      _expectRoundTrip(
        invalid.structuredMessage!,
        'codec.fsa-jflap.invalid-document',
      );
    });
  });

  test('companion exposes stable namespace and round-trippable contracts', () {
    final messages = <StructuredMessage>[
      FsaJflapMessages.invalidRoot(),
      FsaJflapMessages.unsupportedDocumentType('pda'),
      FsaJflapMessages.buildingBlocksUnsupported(),
      FsaJflapMessages.missingAutomaton(),
      FsaJflapMessages.missingStateId(),
      FsaJflapMessages.duplicateStateId('q0'),
      FsaJflapMessages.invalidStateCoordinate('q0'),
      FsaJflapMessages.multipleInitialStates(),
      FsaJflapMessages.invalidDocument(),
      FsaJflapMessages.unsupportedSchema(2),
      FsaJflapMessages.requiresFsaDocument(),
      FsaJflapMessages.canonicalOrderImport(),
      FsaJflapMessages.canonicalOrderExport(),
      FsaJflapMessages.stateTypeDropped('q0'),
      FsaJflapMessages.statePropertiesDropped('q0'),
      FsaJflapMessages.transitionControlPointDropped(
        transitionId: 't0',
        x: 2,
        y: 3,
      ),
      FsaJflapMessages.transitionDisplayLabelDropped(
        transitionId: 't0',
        label: 'custom',
      ),
      FsaJflapMessages.explicitEpsilonAliasInterpreted('eps'),
      FsaJflapMessages.explicitEpsilonAliasExported(
        transitionId: 't1',
        aliases: 'eps',
      ),
      FsaJflapMessages.multiSymbolTransitionExpanded(
        transitionId: 't0',
        symbolCount: 2,
      ),
      FsaJflapMessages.unknownOptionalElement('rootChildren'),
      FsaJflapMessages.unknownOptionalAttribute('rootAttributes'),
    ];

    expect(messages, everyElement(isA<StructuredMessage>()));
    expect(
      messages.map((message) => message.namespace),
      everyElement(FsaJflapMessages.namespace),
    );
    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });
}

DocumentPayload _payload(String source) => DocumentPayload(
  bytes: Uint8List.fromList(utf8.encode(source)),
  filename: 'machine.jff',
);

void _expectRoundTrip(StructuredMessage message, String stableCode) {
  expect(message.stableCode, stableCode);
  expect(StructuredMessage.fromJson(message.toJson()), message);
}

InteroperableDocument<Object> _lossyFsaDocument() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    type: StateType.trap,
    properties: const {'color': 'blue'},
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final grouped = FSATransition.nondeterministic(
    id: 't0',
    fromState: q0,
    toState: q1,
    symbols: const {'a', 'b'},
    label: 'custom label',
    controlPoint: Vector2(2, 3),
  );
  final epsilonAlias = FSATransition(
    id: 't1',
    fromState: q0,
    toState: q1,
    inputSymbols: const {'eps'},
    label: 'eps',
  );
  return InteroperableDocument<Object>(
    document: FSA(
      id: 'fsa',
      name: 'FSA',
      states: {q0, q1},
      transitions: {grouped, epsilonAlias},
      alphabet: const {'a', 'b'},
      initialState: q0,
      acceptingStates: {q1},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle<double>(0, 0, 100, 100),
    ),
    systemKey: DefaultFormalSystemIds.fsa,
    schema: FsaJflapDocumentCodec.descriptorSchema,
  );
}

FSA _validFsa() => (_lossyFsaDocument().document as FSA).copyWith(
  states: {
    State(id: 'q0', label: 'q0', position: Vector2.zero(), isInitial: true),
    State(id: 'q1', label: 'q1', position: Vector2(100, 0), isAccepting: true),
  },
  transitions: const {},
  acceptingStates: {
    State(id: 'q1', label: 'q1', position: Vector2(100, 0), isAccepting: true),
  },
  initialState: State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  ),
);

InteroperableDocument<Object> _invalidFsaDocument() =>
    InteroperableDocument<Object>(
      document: FSA(
        id: 'fsa',
        name: 'FSA',
        states: const {},
        transitions: const {},
        alphabet: const {},
        acceptingStates: const {},
        created: DateTime.utc(2026),
        modified: DateTime.utc(2026),
        bounds: const math.Rectangle<double>(0, 0, 0, 0),
      ),
      systemKey: DefaultFormalSystemIds.fsa,
      schema: FsaJflapDocumentCodec.descriptorSchema,
    );

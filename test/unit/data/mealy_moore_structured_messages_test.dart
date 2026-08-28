import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/codecs/mealy_jflap_codec.dart';
import 'package:turing_lab/data/codecs/mealy_jflap_messages.dart';
import 'package:turing_lab/data/codecs/mealy_json_document_codec.dart';
import 'package:turing_lab/data/codecs/mealy_json_messages.dart';
import 'package:turing_lab/data/codecs/moore_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/moore_jflap_messages.dart';
import 'package:turing_lab/data/codecs/moore_json_document_codec.dart';
import 'package:turing_lab/data/codecs/moore_json_messages.dart';

void main() {
  const mealyJflap = MealyJflapDocumentCodec();
  const mooreJflap = MooreJflapDocumentCodec();

  group('Mealy JFLAP structured outcomes', () {
    test('malformed and unsupported outcomes retain legacy details', () {
      final root =
          mealyJflap.decode(_payload('<not-structure/>'))
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(root.message, 'JFLAP XML root must be <structure>.');
      expect(root.location?.path, '/');
      _expectMessage(root.structuredMessage!, 'codec.mealy-jflap.invalid-root');

      final type =
          mealyJflap.decode(
                _payload('<structure><type>moore</type></structure>'),
              )
              as CodecUnsupported<InteroperableDocument<Object>>;
      expect(type.message, 'JFLAP document type moore is not Mealy.');
      expect(
        type.structuredMessage?.arguments['type'],
        StructuredMessageArgument.literal('moore', role: 'document-type'),
      );
      _expectMessage(
        type.structuredMessage!,
        'codec.mealy-jflap.unsupported-document-type',
      );

      final missing =
          mealyJflap.decode(
                _payload('<structure><type>mealy</type></structure>'),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(missing.message, 'JFLAP Mealy document is missing <automaton>.');
      _expectMessage(
        missing.structuredMessage!,
        'codec.mealy-jflap.missing-automaton',
      );
    });

    test('state and transition failures carry typed source values', () {
      final duplicate =
          mealyJflap.decode(
                _payload('''
<structure><type>mealy</type><automaton>
  <state id="q0"><x>0</x><y>0</y><initial/></state>
  <state id="q0"><x>1</x><y>0</y></state>
</automaton></structure>'''),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(duplicate.message, 'Duplicate JFLAP Mealy state id: q0.');
      expect(
        duplicate.structuredMessage?.arguments['state'],
        StructuredMessageArgument.identifier('q0', role: 'state-id'),
      );

      final unknown =
          mealyJflap.decode(
                _payload('''
<structure><type>mealy</type><automaton>
  <state id="q0"><x>0</x><y>0</y><initial/></state>
  <transition><from>q0</from><to>q9</to><read>a</read></transition>
</automaton></structure>'''),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(unknown.message, 'Transition 0 references an unknown state.');
      expect(
        unknown.structuredMessage?.arguments['index'],
        StructuredMessageArgument.index(0, role: 'transition-index'),
      );
      expect(
        unknown.structuredMessage?.arguments['to'],
        StructuredMessageArgument.identifier('q9', role: 'target-state'),
      );
      _expectMessage(
        unknown.structuredMessage!,
        'codec.mealy-jflap.unknown-transition-endpoints',
      );
    });

    test('import and export diagnostics carry structured payloads', () {
      final imported =
          mealyJflap.decode(
                _payload('''
<structure vendor="root"><type>mealy</type><automaton>
  <state id="q0" custom="yes"><x>0</x><y>0</y><initial/><extra/></state>
  <transition><from>q0</from><to>q0</to><read>a</read><transout>x</transout></transition>
  <metadata/>
</automaton></structure>'''),
              )
              as CodecSuccess<InteroperableDocument<Object>>;
      final unknownElement = imported.diagnostics.firstWhere(
        (diagnostic) => diagnostic.code == 'jflap.unknown-optional-element',
      );
      expect(
        unknownElement.structuredMessage?.stableCode,
        'codec.mealy-jflap.unknown-optional-element',
      );
      final unknownAttribute = imported.diagnostics.firstWhere(
        (diagnostic) => diagnostic.code == 'jflap.unknown-optional-attribute',
      );
      expect(
        unknownAttribute.structuredMessage?.stableCode,
        'codec.mealy-jflap.unknown-optional-attribute',
      );
      expect(
        imported.diagnostics
            .firstWhere(
              (diagnostic) =>
                  diagnostic.code == 'jflap.mealy.transition-ids-derived',
            )
            .structuredMessage
            ?.stableCode,
        'codec.mealy-jflap.transition-ids-derived',
      );

      final encoded =
          mealyJflap.encode(
                InteroperableDocument<Object>(
                  document: _mealyMachine(output: const ['left', 'right']),
                  systemKey: TransducerFormalSystemIds.mealy,
                  schema: MealyJflapDocumentCodec.schema,
                ),
              )
              as CodecSuccess<EncodedDocument>;
      expect(encoded.fidelity, DocumentFidelity.lossy);
      final outputLoss = encoded.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.code == 'jflap.mealy.output-token-boundaries-dropped',
      );
      expect(
        outputLoss.structuredMessage?.arguments['transition'],
        StructuredMessageArgument.identifier('t0', role: 'transition-id'),
      );
      expect(
        outputLoss.structuredMessage?.stableCode,
        'codec.mealy-jflap.output-token-boundaries-dropped',
      );
      for (final diagnostic in encoded.diagnostics) {
        expect(diagnostic.structuredMessage, isNotNull);
        _expectMessage(
          diagnostic.structuredMessage!,
          diagnostic.structuredMessage!.stableCode,
        );
      }
    });

    test('unsupported and invalid encode outcomes are structured', () {
      final foreign =
          mealyJflap.encode(
                InteroperableDocument<Object>(
                  document: Object(),
                  systemKey: DefaultFormalSystemIds.grammar,
                  schema: MealyJflapDocumentCodec.schema,
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(foreign.message, 'Mealy JFLAP codec requires a Mealy machine.');
      _expectMessage(
        foreign.structuredMessage!,
        'codec.mealy-jflap.requires-mealy-document',
      );

      final wrongSchema =
          mealyJflap.encode(
                InteroperableDocument<Object>(
                  document: _mealyMachine(),
                  systemKey: TransducerFormalSystemIds.mealy,
                  schema: const DocumentSchemaDescriptor(
                    id: DocumentSchemaId('turing-lab.mealy'),
                    version: DocumentSchemaVersion(2),
                  ),
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(
        wrongSchema.structuredMessage?.arguments['version'],
        StructuredMessageArgument.integer(2, role: 'schema-version'),
      );
      _expectMessage(
        wrongSchema.structuredMessage!,
        'codec.mealy-jflap.unsupported-schema',
      );
    });
  });

  group('Mealy JSON structured outcomes', () {
    test('custom validation outcomes retain the codec-specific payload', () {
      final machine = _mealyMachine();
      final payload =
          jsonDecode(jsonEncode(machine.toJson())) as Map<String, dynamic>;
      final states = payload['states'] as List<dynamic>;
      states.add(Map<String, dynamic>.from(states.single as Map));
      final json = jsonEncode(payload);
      final outcome =
          MealyJsonDocumentCodec().decode(_payload(json))
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(outcome.message, startsWith('Invalid Mealy machine:'));
      _expectMessage(
        outcome.structuredMessage!,
        'codec.mealy-json.invalid-document',
      );
      expect(
        outcome.structuredMessage?.arguments['diagnostic']?.kind,
        StructuredMessageArgumentKind.outcome,
      );

      final companion = MealyJsonMessages.unexpectedDocumentType();
      _expectMessage(companion, 'codec.mealy-json.unexpected-document-type');
    });
  });

  group('Moore JFLAP structured outcomes', () {
    test('malformed and unsupported outcomes retain legacy details', () {
      final root =
          mooreJflap.decode(_payload('<not-structure/>'))
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(root.message, 'JFLAP XML root must be <structure>.');
      _expectMessage(root.structuredMessage!, 'codec.moore-jflap.invalid-root');

      final type =
          mooreJflap.decode(
                _payload('<structure><type>mealy</type></structure>'),
              )
              as CodecUnsupported<InteroperableDocument<Object>>;
      expect(type.message, 'JFLAP document type mealy is not Moore.');
      expect(
        type.structuredMessage?.arguments['type'],
        StructuredMessageArgument.literal('mealy', role: 'document-type'),
      );
      _expectMessage(
        type.structuredMessage!,
        'codec.moore-jflap.unsupported-document-type',
      );

      final finalState =
          mooreJflap.decode(
                _payload('''
<structure><type>moore</type><automaton>
  <state id="q0"><x>0</x><y>0</y><initial/><final/><output>x</output></state>
</automaton></structure>'''),
              )
              as CodecUnsupported<InteroperableDocument<Object>>;
      expect(
        finalState.message,
        'Moore machines do not have accepting or final states.',
      );
      _expectMessage(
        finalState.structuredMessage!,
        'codec.moore-jflap.final-states-unsupported',
      );
    });

    test('state and transition failures carry typed source values', () {
      final duplicate =
          mooreJflap.decode(
                _payload('''
<structure><type>moore</type><automaton>
  <state id="q0"><x>0</x><y>0</y><initial/><output>x</output></state>
  <state id="q0"><x>1</x><y>0</y><output>y</output></state>
</automaton></structure>'''),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(duplicate.message, 'Duplicate JFLAP state id: q0.');
      expect(
        duplicate.structuredMessage?.arguments['state'],
        StructuredMessageArgument.identifier('q0', role: 'state-id'),
      );

      final unknown =
          mooreJflap.decode(
                _payload('''
<structure><type>moore</type><automaton>
  <state id="q0"><x>0</x><y>0</y><initial/><output>x</output></state>
  <transition><from>q0</from><to>q9</to><read>a</read></transition>
</automaton></structure>'''),
              )
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(unknown.message, 'Transition references an unknown state.');
      expect(
        unknown.structuredMessage?.arguments['to'],
        StructuredMessageArgument.identifier('q9', role: 'target-state'),
      );
      _expectMessage(
        unknown.structuredMessage!,
        'codec.moore-jflap.unknown-transition-endpoints',
      );
    });

    test('import and export diagnostics carry structured payloads', () {
      const xml = '''
<structure vendor="root"><type>moore</type><automaton>
  <state id="q0" custom="yes"><x>0</x><y>0</y><initial/><output>ab</output>
    <turingLabOutputTokens>["a","b"]</turingLabOutputTokens></state>
  <state id="q1"><x>100</x><y>0</y><output>x</output></state>
  <transition><from>q0</from><to>q1</to><read>a</read><transout>wrong</transout></transition>
  <metadata/>
</automaton></structure>''';
      final imported =
          mooreJflap.decode(_payload(xml))
              as CodecSuccess<InteroperableDocument<Object>>;
      expect(
        imported.diagnostics
            .firstWhere(
              (diagnostic) =>
                  diagnostic.code == 'jflap.moore.output-token-vector-restored',
            )
            .structuredMessage
            ?.stableCode,
        'codec.moore-jflap.output-token-vector-restored',
      );
      final conflict = imported.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.code ==
            'jflap.moore.conflicting-transition-output-preserved',
      );
      expect(
        conflict.structuredMessage?.arguments['actual'],
        StructuredMessageArgument.literal('wrong', role: 'transition-output'),
      );
      expect(
        conflict.structuredMessage?.stableCode,
        'codec.moore-jflap.conflicting-transition-output-preserved',
      );
      for (final diagnostic in imported.diagnostics) {
        if (diagnostic.structuredMessage case final message?) {
          _expectMessage(message, message.stableCode);
        }
      }

      final encoded =
          mooreJflap.encode(
                InteroperableDocument<Object>(
                  document: _mooreMachine(),
                  systemKey: TransducerFormalSystemIds.moore,
                  schema: MooreJflapDocumentCodec.schema,
                ),
              )
              as CodecSuccess<EncodedDocument>;
      for (final diagnostic in encoded.diagnostics) {
        expect(diagnostic.structuredMessage, isNotNull);
        _expectMessage(
          diagnostic.structuredMessage!,
          diagnostic.structuredMessage!.stableCode,
        );
      }
    });

    test('unsupported and invalid encode outcomes are structured', () {
      final foreign =
          mooreJflap.encode(
                InteroperableDocument<Object>(
                  document: Object(),
                  systemKey: DefaultFormalSystemIds.grammar,
                  schema: MooreJflapDocumentCodec.schema,
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(foreign.message, 'This codec can encode only Moore machines.');
      _expectMessage(
        foreign.structuredMessage!,
        'codec.moore-jflap.requires-moore-document',
      );

      final wrongSchema =
          mooreJflap.encode(
                InteroperableDocument<Object>(
                  document: _mooreMachine(),
                  systemKey: TransducerFormalSystemIds.moore,
                  schema: const DocumentSchemaDescriptor(
                    id: DocumentSchemaId('turing-lab.moore'),
                    version: DocumentSchemaVersion(2),
                  ),
                ),
              )
              as CodecUnsupported<EncodedDocument>;
      expect(
        wrongSchema.structuredMessage?.arguments['version'],
        StructuredMessageArgument.integer(2, role: 'schema-version'),
      );
      _expectMessage(
        wrongSchema.structuredMessage!,
        'codec.moore-jflap.unsupported-schema',
      );
    });
  });

  group('Moore JSON structured outcomes', () {
    test('custom validation outcomes retain the codec-specific payload', () {
      final machine = _mooreMachine();
      final payload =
          jsonDecode(jsonEncode(machine.toJson())) as Map<String, dynamic>;
      final states = payload['states'] as List<dynamic>;
      states.add(Map<String, dynamic>.from(states.single as Map));
      final outcome =
          MooreJsonDocumentCodec().decode(_payload(jsonEncode(payload)))
              as CodecMalformed<InteroperableDocument<Object>>;
      expect(outcome.message, startsWith('Invalid Moore machine:'));
      _expectMessage(
        outcome.structuredMessage!,
        'codec.moore-json.invalid-document',
      );
      _expectMessage(
        MooreJsonMessages.unexpectedDocumentType(),
        'codec.moore-json.unexpected-document-type',
      );
    });
  });

  test('all companion messages are stable and round-trip through JSON', () {
    final messages = <StructuredMessage>[
      MealyJflapMessages.invalidRoot(),
      MealyJflapMessages.unsupportedDocumentType('moore'),
      MealyJflapMessages.missingAutomaton(),
      MealyJflapMessages.missingStateId(),
      MealyJflapMessages.duplicateStateId('q0'),
      MealyJflapMessages.invalidStateCoordinate('q0'),
      MealyJflapMessages.emptyAutomaton(),
      MealyJflapMessages.invalidInitialStateCount(2),
      MealyJflapMessages.unknownTransitionEndpoints(
        index: 0,
        from: 'q0',
        to: 'q1',
      ),
      MealyJflapMessages.emptyInputSymbol(0),
      MealyJflapMessages.duplicateTransitionInput(input: 'a', state: 'q0'),
      MealyJflapMessages.stableTransitionIdCollision(),
      MealyJflapMessages.invalidUtf8(),
      MealyJflapMessages.malformedXml(),
      MealyJflapMessages.requiresMealyDocument(),
      MealyJflapMessages.unsupportedSchema(schemaId: 'schema', version: 2),
      MealyJflapMessages.invalidDocument('invalid-value'),
      MealyJflapMessages.transitionIdsDerived(),
      MealyJflapMessages.canonicalOrder(),
      MealyJflapMessages.machineIdentityNotPortable(),
      MealyJflapMessages.transitionIdentitiesNotPortable(),
      MealyJflapMessages.unusedAlphabetSymbolsDropped(
        inputSymbols: 'a',
        outputSymbols: 'x',
      ),
      MealyJflapMessages.outputTokenBoundariesDropped(
        transitionId: 't0',
        tokens: 'left, right',
      ),
      MealyJflapMessages.unknownOptionalElement('rootChildren'),
      MealyJflapMessages.unknownOptionalAttribute('rootAttributes'),
      MealyJsonMessages.unexpectedDocumentType(),
      MealyJsonMessages.invalidDocument('invalid-value'),
      MooreJflapMessages.invalidRoot(),
      MooreJflapMessages.unsupportedDocumentType('mealy'),
      MooreJflapMessages.missingAutomaton(),
      MooreJflapMessages.finalStatesUnsupported(),
      MooreJflapMessages.missingStateId(),
      MooreJflapMessages.duplicateStateId('q0'),
      MooreJflapMessages.invalidStateCoordinate('q0'),
      MooreJflapMessages.invalidOutputTokenMetadata('q0'),
      MooreJflapMessages.outputTokenVectorRestored(
        stateId: 'q0',
        tokens: '["a"]',
      ),
      MooreJflapMessages.emptyAutomaton(),
      MooreJflapMessages.invalidInitialStateCount(0),
      MooreJflapMessages.unknownTransitionEndpoints(
        index: 0,
        from: 'q0',
        to: 'q1',
      ),
      MooreJflapMessages.emptyInputSymbol(0),
      MooreJflapMessages.duplicateTransition(from: 'q0', input: 'a', to: 'q1'),
      MooreJflapMessages.nondeterministicTransition(state: 'q0', input: 'a'),
      MooreJflapMessages.stableTransitionIdCollision(),
      MooreJflapMessages.conflictingTransitionOutputPreserved(
        transitionId: 't0',
        actual: 'x',
        expected: 'y',
      ),
      MooreJflapMessages.invalidUtf8(),
      MooreJflapMessages.malformedXml(),
      MooreJflapMessages.invalidDocument('invalid-value'),
      MooreJflapMessages.requiresMooreDocument(),
      MooreJflapMessages.unsupportedSchema(2),
      MooreJflapMessages.outputTokenVectorPreserved(
        stateId: 'q0',
        tokens: 'a, b',
      ),
      MooreJflapMessages.conflictingTransitionOutputNormalized(
        transitionId: 't0',
        output: 'x',
      ),
      MooreJflapMessages.unknownOptionalElement('rootChildren'),
      MooreJflapMessages.unknownOptionalAttribute('rootAttributes'),
      MooreJsonMessages.unexpectedDocumentType(),
      MooreJsonMessages.invalidDocument('invalid-value'),
    ];

    for (final message in messages) {
      expect(StructuredMessage.fromJson(message.toJson()), message);
    }
  });
}

DocumentPayload _payload(String source) => DocumentPayload(
  bytes: Uint8List.fromList(utf8.encode(source)),
  filename: 'machine.jff',
);

void _expectMessage(StructuredMessage message, String stableCode) {
  expect(message.stableCode, stableCode);
  expect(StructuredMessage.fromJson(message.toJson()), message);
}

MealyMachine _mealyMachine({List<String> output = const ['x']}) => MealyMachine(
  id: const TransducerMachineId('machine'),
  name: 'Machine',
  revision: const TransducerRevision(1),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: output.map(TransducerOutputSymbol.new),
  states: const [
    MealyState(
      id: TransducerStateId('q0'),
      label: 'q0',
      position: TransducerPoint(0, 0),
      isInitial: true,
    ),
  ],
  transitions: [
    MealyTransition(
      id: const TransducerTransitionId('t0'),
      from: const TransducerStateId('q0'),
      to: const TransducerStateId('q0'),
      input: const TransducerInputSymbol('a'),
      output: TransducerOutputWord.fromValues(output),
    ),
  ],
);

MooreMachine _mooreMachine() => MooreMachine(
  id: const TransducerMachineId('machine'),
  name: 'Machine',
  revision: const TransducerRevision(1),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {const TransducerOutputSymbol('x')},
  states: [
    MooreState(
      id: const TransducerStateId('q0'),
      label: 'q0',
      position: const TransducerPoint(0, 0),
      isInitial: true,
      output: TransducerOutputWord.fromValues(const ['x']),
    ),
  ],
  transitions: const [
    MooreTransition(
      id: TransducerTransitionId('t0'),
      from: TransducerStateId('q0'),
      to: TransducerStateId('q0'),
      input: TransducerInputSymbol('a'),
    ),
  ],
);

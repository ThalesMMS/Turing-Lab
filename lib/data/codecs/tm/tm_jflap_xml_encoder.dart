//
//  tm_jflap_xml_encoder.dart
//  Turing Lab
//
//  Encoder for classic JFLAP Turing-machine XML. The facade has already
//  checked the document type and schema; this module validates the machine,
//  reports what JFLAP cannot represent and writes the tape vectors, Turing
//  Lab extensions and sticky notes.
//

import 'dart:convert' as convert;

import 'package:xml/xml.dart';

import '../../../core/interoperability/interoperability.dart';
import '../../../core/models/state.dart';
import '../../../core/models/tm.dart';
import '../codec_utils.dart';
import '../jflap_annotations.dart';
import '../tm_jflap_messages.dart';
import '../tm_json_document_codec.dart';
import 'tm_jflap_metadata.dart';
import 'tm_tape_vector_codec.dart';

abstract final class TmJflapXmlEncoder {
  static CodecOutcome<EncodedDocument> encode(
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
    final validation = TmJflapMetadata.firstValidationError(machine);
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
    final unsupported = TmTapeVectorCodec.unsupportedOperation(machine);
    if (unsupported != null) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.feature,
        message: unsupported.message,
        structuredMessage: unsupported.structuredMessage,
      );
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
          nest: convert.jsonEncode(TmJflapMetadata.encode(machine)),
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

//
//  tm_jflap_metadata.dart
//  Turing Lab
//
//  Turing Lab metadata carried inside JFLAP TM XML (`<turingLabTm>`,
//  `<turingLabMachine>`, `<turingLabTransition>`): JSON encoding of a
//  machine, typed readers with FormatException on invalid values, and the
//  codec-level helpers shared by the classic and building-block modules.
//

import 'dart:convert' as convert;
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

import '../../../core/interoperability/interoperability.dart';
import '../../../core/models/state.dart';
import '../../../core/models/tm.dart';
import '../../../core/models/tm_acceptance.dart';
import '../tm_jflap_messages.dart';

abstract final class TmJflapMetadata {
  static Map<String, Object?> encode(TM machine) => {
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

  static Map<String, dynamic> jsonObject(String source, String path) {
    final value = convert.jsonDecode(source);
    if (value is! Map)
      throw FormatException('Expected a JSON object at $path.');
    return Map<String, dynamic>.from(value);
  }

  static Set<String>? stringSet(Map<String, dynamic> metadata, String key) {
    final raw = metadata[key];
    if (raw == null) return null;
    if (raw is! List || raw.any((value) => value is! String)) {
      throw FormatException('Turing Lab TM $key must be a string array.');
    }
    return raw.cast<String>().toSet();
  }

  static String? string(Map<String, dynamic> metadata, String key) {
    final raw = metadata[key];
    if (raw == null) return null;
    if (raw is! String || raw.isEmpty) {
      throw FormatException('Turing Lab TM $key must be a non-empty string.');
    }
    return raw;
  }

  static TMAcceptancePolicy acceptancePolicy(Map<String, dynamic> metadata) {
    final raw = metadata['acceptancePolicy'];
    if (raw == null) return TMAcceptancePolicy.finalState;
    if (raw is! String ||
        !TMAcceptancePolicy.values.any((policy) => policy.name == raw)) {
      throw const FormatException('Turing Lab TM acceptancePolicy is invalid.');
    }
    return TMAcceptancePolicy.parse(raw);
  }

  static DateTime date(
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

  static double number(
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

  static math.Rectangle<double>? bounds(Map<String, dynamic> metadata) {
    final raw = metadata['bounds'];
    if (raw == null) return null;
    if (raw is! Map) {
      throw const FormatException('Turing Lab TM bounds must be an object.');
    }
    final values = [raw['x'], raw['y'], raw['width'], raw['height']];
    if (values.any((value) => value is! num)) {
      throw const FormatException('Turing Lab TM bounds must be numeric.');
    }
    final numbers = values
        .cast<num>()
        .map((value) => value.toDouble())
        .toList();
    if (numbers.any((value) => !value.isFinite) ||
        numbers[2] < 0 ||
        numbers[3] < 0) {
      throw const FormatException('Turing Lab TM bounds are invalid.');
    }
    return math.Rectangle<double>(
      numbers[0],
      numbers[1],
      numbers[2],
      numbers[3],
    );
  }

  static Vector2 panOffset(Map<String, dynamic> metadata) {
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

  static Vector2 controlPoint(Map<String, dynamic> data) {
    final raw = data['controlPoint'];
    if (raw == null) return Vector2.zero();
    if (raw is! Map || raw['x'] is! num || raw['y'] is! num) {
      throw const FormatException(
        'TM transition controlPoint must be numeric.',
      );
    }
    final x = (raw['x'] as num).toDouble();
    final y = (raw['y'] as num).toDouble();
    if (!x.isFinite || !y.isFinite) {
      throw const FormatException('TM transition controlPoint must be finite.');
    }
    return Vector2(x, y);
  }

  static String? firstValidationError(TM machine) {
    final errors = machine.validate();
    if (machine.states.isEmpty &&
        machine.transitions.isEmpty &&
        machine.initialState == null &&
        machine.acceptingStates.isEmpty) {
      errors.remove('Automaton must have at least one state');
    }
    return errors.firstOrNull;
  }

  static math.Rectangle<double> boundsForStates(List<State> states) {
    if (states.isEmpty) return const math.Rectangle<double>(0, 0, 800, 600);
    final xs = states.map((state) => state.position.x);
    final ys = states.map((state) => state.position.y);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    return math.Rectangle<double>(
      minX,
      minY,
      maxX - minX + 96,
      maxY - minY + 96,
    );
  }

  static List<CodecDiagnostic> withDiagnosticMessages(
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

  static CodecOutcome<InteroperableDocument<Object>> copyXmlFailure(
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
}

//
//  interoperability_roundtrip_test.dart
//  Turing Lab
//
//  Examines interoperability among JFLAP, JSON, and SVG formats, ensuring
//  round-trips without structural loss. Checks conversions, serialization, and
//  exports to keep the editor compatible with external tools.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:turing_lab/core/entities/turing_machine_entity.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automata;
import 'package:turing_lab/core/parsers/jflap_xml_codec.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';
import 'package:vector_math/vector_math_64.dart';

part 'interoperability_roundtrip_fixtures.dart';
part 'interoperability_roundtrip/jff_format_tests.dart';
part 'interoperability_roundtrip/json_format_tests.dart';
part 'interoperability_roundtrip/svg_export_tests.dart';
part 'interoperability_roundtrip/cross_format_tests.dart';
part 'interoperability_roundtrip/data_integrity_tests.dart';
part 'interoperability_roundtrip/performance_tests.dart';

RegExp _viewBoxPattern(num width, num height) => RegExp(
      'viewBox="0 0 ${width.toInt()}(?:\\.0+)? ${height.toInt()}(?:\\.0+)?"',
    );

String _serializeAutomatonToJflap(Map<String, dynamic> automatonData) {
  return const JflapXmlCodec().encodeSerializableAutomaton(automatonData);
}

Result<Map<String, dynamic>> _deserializeAutomatonFromJflap(String xmlString) {
  return const JflapXmlCodec().decodeSerializableAutomaton(xmlString);
}

String _serializeAutomatonToJson(Map<String, dynamic> automatonData) {
  return jsonEncode(_normalizeAutomatonJson(automatonData));
}

Result<Map<String, dynamic>> _deserializeAutomatonFromJson(String jsonString) {
  try {
    final json = jsonDecode(jsonString);
    if (json is! Map<String, dynamic>) {
      return const Failure(
          'Failed to deserialize JSON automaton: root is not an object');
    }

    return Success(_normalizeAutomatonJson(json));
  } catch (e) {
    return Failure('Failed to deserialize JSON automaton: $e');
  }
}

Map<String, dynamic> _normalizeAutomatonJson(Map<String, dynamic> data) {
  final statesRaw = data['states'];
  final transitionsRaw = data['transitions'];
  final alphabetRaw = data['alphabet'];

  if (statesRaw is! List) {
    throw const FormatException('states must be a list');
  }
  if (transitionsRaw is! Map) {
    throw const FormatException('transitions must be an object');
  }
  if (alphabetRaw is! List) {
    throw const FormatException('alphabet must be a list');
  }

  final states = statesRaw.map((rawState) {
    if (rawState is! Map) {
      throw const FormatException('state must be an object');
    }
    final state = Map<String, dynamic>.from(rawState);
    final id = state['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('state id must be a non-empty string');
    }
    return <String, dynamic>{
      'id': id,
      'name': state['name'] as String? ?? id,
      'x': (state['x'] as num?)?.toDouble() ?? 0.0,
      'y': (state['y'] as num?)?.toDouble() ?? 0.0,
      'isInitial': state['isInitial'] as bool? ?? false,
      'isFinal': state['isFinal'] as bool? ?? false,
    };
  }).toList();

  final transitions = <String, List<String>>{};
  for (final entry in Map<dynamic, dynamic>.from(transitionsRaw).entries) {
    final value = entry.value;
    transitions[entry.key.toString()] = value is List
        ? value.map((item) => item.toString()).toList()
        : <String>[value.toString()];
  }

  return <String, dynamic>{
    'id': data['id'] as String? ??
        'automaton_${DateTime.now().millisecondsSinceEpoch}',
    'name': data['name'] as String? ?? 'Automaton',
    'type': data['type'] as String? ?? 'dfa',
    'alphabet': alphabetRaw.map((item) => item.toString()).toList(),
    'states': states,
    'transitions': transitions,
    'initialId': data['initialId'] as String?,
    'nextId': data['nextId'] as int? ?? states.length,
  };
}

/// 3. SVG export/import testing
/// 4. Cross-format conversion testing
/// 5. Data integrity validation
void main() {
  group('Interoperability and Round-trip Tests', () {
    _runJffFormatTests();
    _runJsonFormatTests();
    _runSvgExportTests();
    _runCrossFormatTests();
    _runDataIntegrityTests();
    _runPerformanceTests();
  });
}

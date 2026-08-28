import 'dart:collection';

import 'tm.dart';
import 'tm_building_blocks.dart';

/// Original project element represented by one expanded graph element.
class TMInlineSource {
  TMInlineSource({
    required this.machineId,
    required this.elementId,
    required Iterable<String> invocationPath,
  }) : invocationPath = List<String>.unmodifiable(invocationPath);

  final String machineId;
  final String elementId;
  final List<String> invocationPath;
}

/// Deterministic inline expansion with a source map back to block definitions.
class TMInlineExpansionResult {
  TMInlineExpansionResult.success({
    required this.machine,
    required Map<String, TMInlineSource> stateSources,
    required Map<String, TMInlineSource> transitionSources,
  })  : stateSources = UnmodifiableMapView(stateSources),
        transitionSources = UnmodifiableMapView(transitionSources),
        diagnostics = const [];

  TMInlineExpansionResult.failure({
    required Iterable<TMBlockDiagnostic> diagnostics,
  })  : machine = null,
        stateSources = const {},
        transitionSources = const {},
        diagnostics = List<TMBlockDiagnostic>.unmodifiable(diagnostics);

  final TM? machine;
  final Map<String, TMInlineSource> stateSources;
  final Map<String, TMInlineSource> transitionSources;
  final List<TMBlockDiagnostic> diagnostics;

  bool get isSuccess => machine != null;
}

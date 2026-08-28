import 'dart:collection';

import '../messages/structured_message.dart';
import 'tm.dart';

/// Tape ownership used by every compositional TM invocation.
enum TMBlockTapeSemantics { shared }

/// Recursion policy for compositional TM projects.
enum TMBlockRecursionPolicy { rejectCycles }

/// Stable reference to one revision of a reusable TM definition.
class TMBlockReference {
  const TMBlockReference({required this.blockId, required this.revision});

  final String blockId;
  final int revision;

  Map<String, Object?> toJson() => {'blockId': blockId, 'revision': revision};

  factory TMBlockReference.fromJson(Map<String, dynamic> json) {
    return TMBlockReference(
      blockId: json['blockId'] as String,
      revision: json['revision'] as int,
    );
  }
}

/// First-class graph node that invokes a reusable TM definition.
///
/// [stateId] anchors the node in the existing graph topology without encoding
/// its behavior in a label or in untyped state properties.
class TMBlockInvocationNode {
  const TMBlockInvocationNode({
    required this.id,
    required this.stateId,
    required this.reference,
  });

  final String id;
  final String stateId;
  final TMBlockReference reference;

  Map<String, Object?> toJson() => {
    'id': id,
    'stateId': stateId,
    'reference': reference.toJson(),
  };

  factory TMBlockInvocationNode.fromJson(Map<String, dynamic> json) {
    return TMBlockInvocationNode(
      id: json['id'] as String,
      stateId: json['stateId'] as String,
      reference: TMBlockReference.fromJson(
        (json['reference'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  TMBlockInvocationNode copyWith({
    String? id,
    String? stateId,
    TMBlockReference? reference,
  }) {
    return TMBlockInvocationNode(
      id: id ?? this.id,
      stateId: stateId ?? this.stateId,
      reference: reference ?? this.reference,
    );
  }
}

/// One reusable, revisioned submachine in a TM project library.
class TMBlockDefinition {
  TMBlockDefinition({
    required this.id,
    required this.name,
    required this.revision,
    required this.machine,
    Iterable<TMBlockInvocationNode> invocations = const [],
  }) : invocations = List<TMBlockInvocationNode>.unmodifiable(invocations);

  final String id;
  final String name;
  final int revision;
  final TM machine;
  final List<TMBlockInvocationNode> invocations;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'revision': revision,
    'machine': machine.toJson(),
    'invocations': invocations.map((node) => node.toJson()).toList(),
  };

  factory TMBlockDefinition.fromJson(Map<String, dynamic> json) {
    return TMBlockDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      revision: json['revision'] as int,
      machine: TM.fromJson((json['machine'] as Map).cast<String, dynamic>()),
      invocations: (json['invocations'] as List? ?? const [])
          .map(
            (value) => TMBlockInvocationNode.fromJson(
              (value as Map).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    );
  }

  TMBlockDefinition copyWith({
    String? id,
    String? name,
    int? revision,
    TM? machine,
    Iterable<TMBlockInvocationNode>? invocations,
  }) {
    return TMBlockDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      revision: revision ?? this.revision,
      machine: machine ?? this.machine,
      invocations: invocations ?? this.invocations,
    );
  }
}

/// Versioned multi-document view over a root TM and its block library.
class TMBlockProject {
  TMBlockProject({
    required this.rootMachine,
    this.schemaVersion = currentSchemaVersion,
    this.tapeSemantics = TMBlockTapeSemantics.shared,
    this.recursionPolicy = TMBlockRecursionPolicy.rejectCycles,
    this.maximumCallDepth = 32,
  }) {
    if (maximumCallDepth < 1) {
      throw ArgumentError.value(maximumCallDepth, 'maximumCallDepth');
    }
  }

  static const currentSchemaVersion = 1;

  final TM rootMachine;
  final int schemaVersion;
  final TMBlockTapeSemantics tapeSemantics;
  final TMBlockRecursionPolicy recursionPolicy;
  final int maximumCallDepth;

  Map<String, TMBlockDefinition> get definitions =>
      rootMachine.blockDefinitions;
  List<TMBlockInvocationNode> get rootInvocations =>
      rootMachine.blockInvocations;

  TM? machineFor(String machineId) {
    if (machineId == rootMachine.id) return rootMachine;
    return definitions[machineId]?.machine;
  }

  List<TMBlockInvocationNode> invocationsFor(String machineId) {
    if (machineId == rootMachine.id) return rootInvocations;
    return definitions[machineId]?.invocations ?? const [];
  }

  TMBlockInvocationNode? invocationForState(String machineId, String stateId) {
    for (final invocation in invocationsFor(machineId)) {
      if (invocation.stateId == stateId) return invocation;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'schema': 'turing-lab/tm-building-block-project',
    'version': schemaVersion,
    'tapeSemantics': tapeSemantics.name,
    'recursionPolicy': recursionPolicy.name,
    'maximumCallDepth': maximumCallDepth,
    'rootMachine': rootMachine.toJson(),
  };

  factory TMBlockProject.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 0;
    if (version < 0 || version > currentSchemaVersion) {
      throw FormatException(
        'Unsupported TM building-block project version: $version',
      );
    }
    final rootJson = json['rootMachine'];
    if (rootJson is! Map) {
      throw const FormatException(
        'TM building-block project requires a root machine',
      );
    }
    return TMBlockProject(
      rootMachine: TM.fromJson(rootJson.cast<String, dynamic>()),
      schemaVersion: currentSchemaVersion,
      tapeSemantics: TMBlockTapeSemantics.values.firstWhere(
        (value) => value.name == json['tapeSemantics'],
        orElse: () => TMBlockTapeSemantics.shared,
      ),
      recursionPolicy: TMBlockRecursionPolicy.values.firstWhere(
        (value) => value.name == json['recursionPolicy'],
        orElse: () => TMBlockRecursionPolicy.rejectCycles,
      ),
      maximumCallDepth: json['maximumCallDepth'] as int? ?? 32,
    );
  }

  factory TMBlockProject.fromFlatMachine(TM machine) {
    return TMBlockProject(rootMachine: machine);
  }
}

enum TMBlockDiagnosticSeverity { warning, error }

enum TMBlockDiagnosticCode {
  duplicateMachineId,
  duplicateBlockName,
  duplicateInvocationId,
  duplicateInvocationState,
  missingReference,
  revisionMismatch,
  missingAnchorState,
  missingInitialState,
  tapeCountMismatch,
  blankSymbolMismatch,
  nestedLibrary,
  recursiveDependency,
}

/// Typed validation evidence for a compositional TM project.
class TMBlockDiagnostic {
  const TMBlockDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.machineId,
    this.invocationId,
    this.blockId,
    this.structuredMessage,
  });

  final TMBlockDiagnosticCode code;
  final TMBlockDiagnosticSeverity severity;
  final String message;
  final String? machineId;
  final String? invocationId;
  final String? blockId;

  /// Locale-neutral semantic payload for [message], when available.
  final StructuredMessage? structuredMessage;
}

/// Deterministic dependency and validation result.
class TMBlockDependencyReport {
  TMBlockDependencyReport({
    required Map<String, Set<String>> dependencies,
    required Iterable<String> topologicalOrder,
    required Iterable<List<String>> cycles,
    required Iterable<TMBlockDiagnostic> diagnostics,
  }) : dependencies = UnmodifiableMapView(
         dependencies.map(
           (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
         ),
       ),
       topologicalOrder = List<String>.unmodifiable(topologicalOrder),
       cycles = List<List<String>>.unmodifiable(
         cycles.map((cycle) => List<String>.unmodifiable(cycle)),
       ),
       diagnostics = List<TMBlockDiagnostic>.unmodifiable(diagnostics);

  final Map<String, Set<String>> dependencies;
  final List<String> topologicalOrder;
  final List<List<String>> cycles;
  final List<TMBlockDiagnostic> diagnostics;

  bool get isValid => diagnostics.every(
    (diagnostic) => diagnostic.severity != TMBlockDiagnosticSeverity.error,
  );
}

/// One suspended parent invocation in an active execution.
class TMBlockCallFrame {
  const TMBlockCallFrame({
    required this.parentMachineId,
    required this.invocationNodeId,
    required this.returnStateId,
  });

  final String parentMachineId;
  final String invocationNodeId;
  final String returnStateId;

  Map<String, Object?> toJson() => {
    'parentMachineId': parentMachineId,
    'invocationNodeId': invocationNodeId,
    'returnStateId': returnStateId,
  };
}

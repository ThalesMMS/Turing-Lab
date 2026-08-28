import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:turing_lab/core/graph_layout/graph_layout.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_automaton_mapper.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_snapshot_codec.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../catalog.dart';
import '../mutation.dart';
import '../runner.dart';
import '../shrinking.dart';

const graphFamilyId = 'graph';
const graphGeneratorVersion = 'graph-fixture-v2';
const graphOracleVersion = 'graph-invariants-v2';

final class GraphHardEdgeDescriptor {
  const GraphHardEdgeDescriptor({
    required this.id,
    required this.algorithm,
    required this.property,
    required this.requiredTool,
  });

  final String id;
  final String algorithm;
  final String property;
  final String? requiredTool;

  String get reproductionCommand =>
      'dart run tool/hard_edge_graph.dart --property $property';
}

final class GraphBoundaryInventoryEntry {
  const GraphBoundaryInventoryEntry({
    required this.id,
    required this.sourcePath,
    required this.entryPoints,
    required this.properties,
  });

  final String id;
  final String sourcePath;
  final List<String> entryPoints;
  final List<String> properties;
}

const graphLayoutPropertyByAlgorithm = <GraphLayoutAlgorithmId, String>{
  GraphLayoutAlgorithmId.circle: 'graph.layout-circle',
  GraphLayoutAlgorithmId.twoCircle: 'graph.layout-two-circle',
  GraphLayoutAlgorithmId.spiral: 'graph.layout-spiral',
  GraphLayoutAlgorithmId.hierarchical: 'graph.layout-hierarchical',
  GraphLayoutAlgorithmId.sugiyama: 'graph.layout-sugiyama',
  GraphLayoutAlgorithmId.componentPacking: 'graph.layout-component-packing',
  GraphLayoutAlgorithmId.seededForce: 'graph.layout-seeded-force',
  GraphLayoutAlgorithmId.seededRandom: 'graph.layout-seeded-random',
  GraphLayoutAlgorithmId.reflectHorizontal: 'graph.reflect-horizontal',
  GraphLayoutAlgorithmId.reflectVertical: 'graph.reflect-vertical',
  GraphLayoutAlgorithmId.rotate90: 'graph.rotate-90',
  GraphLayoutAlgorithmId.rotate180: 'graph.rotate-180',
  GraphLayoutAlgorithmId.rotate270: 'graph.rotate-270',
  GraphLayoutAlgorithmId.fit: 'graph.fit',
  GraphLayoutAlgorithmId.fill: 'graph.fill',
  GraphLayoutAlgorithmId.restore: 'graph.restore',
};

final graphHardEdgeDescriptors = <GraphHardEdgeDescriptor>[
  for (final entry in graphLayoutPropertyByAlgorithm.entries)
    GraphHardEdgeDescriptor(
      id: 'graph-${entry.value.substring('graph.'.length)}',
      algorithm: entry.value.substring('graph.'.length),
      property: entry.value,
      requiredTool: null,
    ),
  const GraphHardEdgeDescriptor(
    id: 'graph-invalid-topology',
    algorithm: 'topology-validator',
    property: 'graph.invalid-topology',
    requiredTool: null,
  ),
  const GraphHardEdgeDescriptor(
    id: 'graph-scope-and-pins',
    algorithm: 'layout-scope',
    property: 'graph.scope-and-pins',
    requiredTool: null,
  ),
  const GraphHardEdgeDescriptor(
    id: 'graph-document-adapter',
    algorithm: 'document-adapter',
    property: 'graph.document-adapter',
    requiredTool: 'flutter',
  ),
  const GraphHardEdgeDescriptor(
    id: 'graph-canvas-contracts',
    algorithm: 'canvas-contracts',
    property: 'graph.canvas-contracts',
    requiredTool: 'flutter',
  ),
  const GraphHardEdgeDescriptor(
    id: 'graph-viewport-invalid-matrix',
    algorithm: 'viewport-transform',
    property: 'graph.viewport-invalid-matrix',
    requiredTool: 'flutter',
  ),
  const GraphHardEdgeDescriptor(
    id: 'graph-event-history-replay',
    algorithm: 'event-history-replay',
    property: 'graph.event-history-replay',
    requiredTool: null,
  ),
  const GraphHardEdgeDescriptor(
    id: 'graph-performance-benchmark',
    algorithm: 'canvas-performance',
    property: 'graph.performance-benchmark',
    requiredTool: 'flutter',
  ),
];

const graphFlutterEvidenceByProperty = <String, List<String>>{
  'graph.document-adapter': [
    'test/unit/core/graph_layout/graph_layout_engine_test.dart',
  ],
  'graph.canvas-contracts': [
    'test/features/canvas/graphview',
    'test/unit/presentation/graphview_transducer_canvas_controller_test.dart',
    'test/widget/presentation/automaton_graphview_canvas_test.dart',
    'test/widget/presentation/automaton_graphview_canvas_coordinators_test.dart',
    'test/widget/presentation/automaton_graphview_canvas_drag_preview_test.dart',
    'test/widget/presentation/read_only_fsa_graphview_canvas_test.dart',
    'test/widget/presentation/document_annotations_test.dart',
    'test/widget/presentation/scoped_canvas_highlight_pages_test.dart',
    'test/unit/presentation/moore_workspace_definition_test.dart',
    'test/widget/presentation/moore_workspace_test.dart',
  ],
  'graph.viewport-invalid-matrix': [
    'test/unit/tool/hard_edge_graph_viewport_matrix_test.dart',
  ],
  'graph.performance-benchmark': [
    'test/widget/presentation/automaton_graphview_canvas_performance_test.dart',
  ],
};

const graphBoundaryDiscoveryRoots = <String>[
  'lib/core/graph_layout',
  'lib/features/canvas/graphview',
  'lib/presentation/widgets/automaton_graphview',
];

/// Files below the discovery roots that contain private implementation parts,
/// barrels, or leaf widgets rather than independently callable boundaries.
/// Any new Dart file must be classified here or in [graphBoundaryInventory].
const graphBoundarySupportSourceAllowlist = <String>{
  'lib/core/graph_layout/graph_layout.dart',
  'lib/features/canvas/graphview/graphview_label_field_editor.dart',
  'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer_cache.dart',
  'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer_grouped_geometry.dart',
  'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer_grouped_rendering.dart',
  'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer_label_layout.dart',
  'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer_models.dart',
  'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer_route_layout.dart',
  'lib/presentation/widgets/automaton_graphview/canvas_surface.dart',
};

const graphBoundaryInventory = <GraphBoundaryInventoryEntry>[
  GraphBoundaryInventoryEntry(
    id: 'layout-engine',
    sourcePath: 'lib/core/graph_layout/graph_layout_engine.dart',
    entryPoints: ['GraphLayoutEngine.compute'],
    properties: ['graph.layout-circle', 'graph.invalid-topology'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'layout-task',
    sourcePath: 'lib/core/graph_layout/graph_layout_task.dart',
    entryPoints: ['graph_layout_task_io.dart', 'graph_layout_task_web.dart'],
    properties: ['graph.document-adapter'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'layout-task-io',
    sourcePath: 'lib/core/graph_layout/graph_layout_task_io.dart',
    entryPoints: ['GraphLayoutTask.start', 'GraphLayoutTask.cancel'],
    properties: ['graph.document-adapter'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'layout-task-web',
    sourcePath: 'lib/core/graph_layout/graph_layout_task_web.dart',
    entryPoints: ['GraphLayoutTask.start', 'GraphLayoutTask.cancel'],
    properties: ['graph.document-adapter'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'layout-models',
    sourcePath: 'lib/core/graph_layout/graph_layout_models.dart',
    entryPoints: ['GraphLayoutRequest', 'GraphLayoutResult'],
    properties: ['graph.layout-circle', 'graph.invalid-topology'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'layout-document-adapter',
    sourcePath: 'lib/core/graph_layout/graph_layout_document_adapter.dart',
    entryPoints: ['GraphLayoutDocumentAdapter.applyPositions'],
    properties: ['graph.document-adapter'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'fsa-mapper',
    sourcePath: 'lib/features/canvas/graphview/graphview_automaton_mapper.dart',
    entryPoints: ['toSnapshot', 'mergeIntoTemplate'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'pda-mapper',
    sourcePath: 'lib/features/canvas/graphview/graphview_pda_mapper.dart',
    entryPoints: ['toSnapshot', 'mergeIntoTemplate'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'tm-mapper',
    sourcePath: 'lib/features/canvas/graphview/graphview_tm_mapper.dart',
    entryPoints: ['toSnapshot', 'mergeIntoTemplate'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'snapshot-codec',
    sourcePath: 'lib/features/canvas/graphview/graphview_snapshot_codec.dart',
    entryPoints: ['graphview_snapshot_codec_stub.dart'],
    properties: ['graph.canvas-contracts', 'graph.event-history-replay'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'snapshot-codec-io',
    sourcePath:
        'lib/features/canvas/graphview/graphview_snapshot_codec_io.dart',
    entryPoints: ['createGraphHistoryCodec'],
    properties: ['graph.canvas-contracts', 'graph.event-history-replay'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'snapshot-codec-web',
    sourcePath:
        'lib/features/canvas/graphview/graphview_snapshot_codec_stub.dart',
    entryPoints: ['createGraphHistoryCodec'],
    properties: ['graph.canvas-contracts', 'graph.event-history-replay'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'snapshot-models',
    sourcePath: 'lib/features/canvas/graphview/graphview_canvas_models.dart',
    entryPoints: ['GraphViewAutomatonSnapshot.toJson', 'fromJson'],
    properties: ['graph.canvas-contracts', 'graph.event-history-replay'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'mapper-helpers',
    sourcePath: 'lib/features/canvas/graphview/graphview_mapper_helpers.dart',
    entryPoints: ['nodesToGraphViewNodes', 'resolveEdgeEndpoints'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'state-notifier-adapter',
    sourcePath:
        'lib/features/canvas/graphview/graphview_state_notifier_adapter.dart',
    entryPoints: ['GraphViewStateNotifierAdapter', 'currentData'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'canvas-history-controller',
    sourcePath:
        'lib/features/canvas/graphview/base_graphview_canvas_controller.dart',
    entryPoints: ['undo', 'redo', 'performMutation', 'dispose'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'fsa-canvas-controller',
    sourcePath:
        'lib/features/canvas/graphview/graphview_canvas_controller.dart',
    entryPoints: ['toSnapshot', 'synchronize', 'applySnapshotToDomain'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'pda-canvas-controller',
    sourcePath:
        'lib/features/canvas/graphview/graphview_pda_canvas_controller.dart',
    entryPoints: ['toSnapshot', 'synchronize', 'applySnapshotToDomain'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'tm-canvas-controller',
    sourcePath:
        'lib/features/canvas/graphview/graphview_tm_canvas_controller.dart',
    entryPoints: ['toSnapshot', 'synchronize', 'applySnapshotToDomain'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'transducer-controller',
    sourcePath:
        'lib/presentation/transducers/graphview_transducer_canvas_controller.dart',
    entryPoints: ['toSnapshot', 'applySnapshotToDomain', 'putTransition'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'viewport-transform',
    sourcePath:
        'lib/presentation/widgets/automaton_graphview/canvas_viewport_adapter.dart',
    entryPoints: ['screenToWorld', 'worldToScreen', 'updateViewport'],
    properties: ['graph.viewport-invalid-matrix', 'graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'controller-lifecycle',
    sourcePath:
        'lib/presentation/widgets/automaton_graphview/canvas_controller_lifecycle.dart',
    entryPoints: ['replaceController', 'replaceToolController', 'dispose'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'domain-sync-coordinator',
    sourcePath:
        'lib/presentation/widgets/automaton_graphview/canvas_domain_sync_coordinator.dart',
    entryPoints: ['schedule', 'replaceTarget', 'contentChanged', 'dispose'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'interaction-coordinator',
    sourcePath:
        'lib/presentation/widgets/automaton_graphview/canvas_interaction_coordinator.dart',
    entryPoints: ['activateTool', 'deleteSelection', 'undo', 'redo'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'transition-routing',
    sourcePath:
        'lib/features/canvas/graphview/automatic_transition_route_planner.dart',
    entryPoints: ['plan'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'link-overlay-geometry',
    sourcePath:
        'lib/features/canvas/graphview/graphview_link_overlay_utils.dart',
    entryPoints: ['resolveLinkAnchorWorld', 'resolveNodeCenter'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'viewport-highlight',
    sourcePath:
        'lib/features/canvas/graphview/graphview_viewport_highlight_mixin.dart',
    entryPoints: ['zoomIn', 'fitToContent', 'applyHighlight'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'edge-render-cache',
    sourcePath:
        'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart',
    entryPoints: ['renderEdge', 'invalidateEdgeCaches'],
    properties: ['graph.canvas-contracts', 'graph.performance-benchmark'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'edge-renderer-compatibility',
    sourcePath:
        'lib/features/canvas/graphview/turing_lab_adaptive_edge_renderer_compat.dart',
    entryPoints: ['invalidatePathGeometryCache', 'EdgeLabelGeometry'],
    properties: ['graph.canvas-contracts', 'graph.performance-benchmark'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'highlight-controller',
    sourcePath:
        'lib/features/canvas/graphview/graphview_highlight_controller.dart',
    entryPoints: ['applyHighlight', 'clearHighlight'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'simulation-highlight-channel',
    sourcePath:
        'lib/features/canvas/graphview/graphview_highlight_channel.dart',
    entryPoints: ['send', 'clear'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'algorithm-highlight-channel',
    sourcePath:
        'lib/features/canvas/graphview/graphview_algorithm_step_highlight_channel.dart',
    entryPoints: ['send', 'clear'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'grouped-fsa-geometry',
    sourcePath: 'lib/features/canvas/graphview/grouped_fsa_geometry.dart',
    entryPoints: [
      'resolveGroupedFsaControlPoint',
      'resolveGroupedFsaLabelNormal'
    ],
    properties: ['graph.canvas-contracts', 'graph.performance-benchmark'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'edge-presentation',
    sourcePath:
        'lib/presentation/widgets/automaton_graphview/canvas_edge_presentation.dart',
    entryPoints: ['synchronizeStructure', 'updateHighlight'],
    properties: ['graph.canvas-contracts', 'graph.performance-benchmark'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'canvas-semantics',
    sourcePath:
        'lib/presentation/widgets/automaton_graphview/canvas_semantics_adapter.dart',
    entryPoints: ['viewportLabel', 'nodeLabel', 'transitionLayer'],
    properties: ['graph.canvas-contracts'],
  ),
  GraphBoundaryInventoryEntry(
    id: 'read-only-canvas',
    sourcePath: 'lib/presentation/widgets/read_only_fsa_graphview_canvas.dart',
    entryPoints: ['build'],
    properties: ['graph.canvas-contracts'],
  ),
];

Object graphHardEdgeFixture({
  required String property,
  int seed = 341,
}) =>
    <String, Object?>{
      'family': graphFamilyId,
      'generatorVersion': graphGeneratorVersion,
      'oracleVersion': graphOracleVersion,
      'property': property,
      'seed': seed,
      'nodes': const [
        {'id': 'n0', 'label': 'start', 'x': -100000.0, 'y': -40.0},
        {'id': 'n1', 'label': 'duplicate', 'x': 0.0, 'y': 0.0},
        {'id': 'n2', 'label': 'duplicate', 'x': 120.0, 'y': 80.0},
        {'id': 'n3', 'label': 'loop', 'x': 240.0, 'y': -20.0},
        {'id': 'n4', 'label': 'island', 'x': 100000.0, 'y': 300.0},
      ],
      'edges': const [
        {'id': 'e0', 'from': 'n0', 'to': 'n1'},
        {'id': 'e1', 'from': 'n0', 'to': 'n1'},
        {'id': 'e2', 'from': 'n1', 'to': 'n0'},
        {'id': 'e3', 'from': 'n1', 'to': 'n2'},
        {'id': 'e4', 'from': 'n2', 'to': 'n3'},
        {'id': 'e5', 'from': 'n3', 'to': 'n3'},
      ],
      if (property == 'graph.event-history-replay')
        'events': const [
          {'type': 'rename', 'nodeId': 'n1', 'label': 'generated-341'},
          {'type': 'move', 'nodeId': 'n2', 'x': 180.0, 'y': 140.0},
          {'type': 'undo'},
          {'type': 'redo'},
          {
            'type': 'assertLabel',
            'nodeId': 'n1',
            'label': 'generated-341',
          },
          {
            'type': 'assertPosition',
            'nodeId': 'n2',
            'x': 180.0,
            'y': 140.0,
          },
        ],
      'restorePositions': const {
        'n0': {'x': 10.0, 'y': 20.0},
        'n1': {'x': 30.0, 'y': 40.0},
        'n2': {'x': 50.0, 'y': 60.0},
        'n3': {'x': 70.0, 'y': 80.0},
        'n4': {'x': 90.0, 'y': 100.0},
      },
    };

typedef GraphFlutterEvidenceRunner = Future<int> Function(
  List<String> paths,
  Duration timeout,
);

const graphEvidenceTimeout = Duration(seconds: 50);
const _generatedEvidenceNotApplicable = 'generatedEvidenceNotApplicable';

final class GraphHardEdgePropertyExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  GraphHardEdgePropertyExecutor({GraphFlutterEvidenceRunner? evidenceRunner})
      : _evidenceRunner = evidenceRunner ?? _runFlutterEvidence;

  final GraphFlutterEvidenceRunner _evidenceRunner;
  Future<void> _evidenceQueue = Future<void>.value();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    if (testCase.family != graphFamilyId) {
      throw HardEdgeConfigurationException(
        'Graph executor cannot run family "${testCase.family}".',
      );
    }
    final source = _fixtureMap(fixture);
    _validateFixture(source, testCase.property);
    final evidencePaths = graphFlutterEvidenceByProperty[testCase.property];
    if (evidencePaths != null) {
      if (source[_generatedEvidenceNotApplicable] == true) {
        return HardEdgeExecutionOutcome.notApplicable;
      }
      if (testCase.requiredTool != 'flutter') {
        throw HardEdgeConfigurationException(
          'Graph evidence "${testCase.property}" requires Flutter.',
        );
      }
      final exitCode = await _serializedEvidence(
        evidencePaths,
        graphEvidenceTimeout,
      );
      return exitCode == 0
          ? HardEdgeExecutionOutcome.pass
          : HardEdgeExecutionOutcome.violation;
    }
    if (testCase.property == 'graph.invalid-topology') {
      return _invalidTopologyIsRejected(source)
          ? HardEdgeExecutionOutcome.pass
          : HardEdgeExecutionOutcome.violation;
    }
    if (testCase.property == 'graph.scope-and-pins') {
      return _scopeAndPinsHold(source)
          ? HardEdgeExecutionOutcome.pass
          : HardEdgeExecutionOutcome.violation;
    }
    if (testCase.property == 'graph.event-history-replay') {
      final first = graphEventHistoryReplay(source);
      final second = graphEventHistoryReplay(source);
      return first.failureSignature == null &&
              jsonEncode(first.toJson()) == jsonEncode(second.toJson())
          ? HardEdgeExecutionOutcome.pass
          : HardEdgeExecutionOutcome.violation;
    }
    final algorithm = _algorithmForProperty(testCase.property);
    return _layoutPropertiesHold(source, algorithm)
        ? HardEdgeExecutionOutcome.pass
        : HardEdgeExecutionOutcome.violation;
  }

  Future<int> _serializedEvidence(List<String> paths, Duration timeout) {
    final result = _evidenceQueue.then((_) => _evidenceRunner(paths, timeout));
    _evidenceQueue = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    final source = _fixtureMap(templateFixture);
    _validateFixture(source, template.property);
    return <String, Object?>{
      ...source,
      'seed': seed,
      if (template.property == 'graph.event-history-replay')
        'events': _generatedEventHistory(seed),
      if (graphFlutterEvidenceByProperty.containsKey(template.property))
        _generatedEvidenceNotApplicable: true,
    };
  }
}

bool _layoutPropertiesHold(
    Map<String, Object?> source, GraphLayoutAlgorithmId algorithm,
    [_GraphCertificationAdapter adapter = const _GraphCertificationAdapter()]) {
  final graph = _graphFromFixture(source);
  final settings = _settingsFromFixture(source);
  final request = GraphLayoutRequest(
    algorithmId: algorithm,
    graph: graph,
    settings: settings,
  );
  final first = adapter.compute(request);
  final second = adapter.compute(request);
  if (!first.canApply || first.positions.length != graph.nodes.length) {
    return false;
  }
  if (!_samePositions(first.positions, second.positions) ||
      first.positions.values.any((point) => !point.isFinite) ||
      first.positions.keys
          .toSet()
          .difference(
            graph.nodes.map((node) => node.id).toSet(),
          )
          .isNotEmpty) {
    return false;
  }
  if (first.metrics.nodeCount != graph.nodes.length ||
      first.metrics.edgeCount != graph.edges.length) {
    return false;
  }
  if (_isConstructive(algorithm)) {
    final bounds = settings.targetBounds;
    return first.positions.values.every(
      (point) =>
          point.x >= bounds.left - 1e-8 &&
          point.x <= bounds.right + 1e-8 &&
          point.y >= bounds.top - 1e-8 &&
          point.y <= bounds.bottom + 1e-8,
    );
  }
  if (algorithm == GraphLayoutAlgorithmId.restore) {
    return first.positions.entries.every(
      (entry) => entry.value == settings.restorePositions[entry.key],
    );
  }
  if (algorithm == GraphLayoutAlgorithmId.seededForce) return true;
  return first.transform != null;
}

bool _invalidTopologyIsRejected(Map<String, Object?> source) {
  final graph = _graphFromFixture(source);
  final invalid = GraphLayoutGraph(
    nodes: graph.nodes,
    edges: [
      ...graph.edges,
      const GraphLayoutEdge(
        id: 'dangling',
        fromNodeId: 'n0',
        toNodeId: 'missing',
      ),
    ],
  );
  final result = GraphLayoutEngine.compute(
    GraphLayoutRequest(
      algorithmId: GraphLayoutAlgorithmId.circle,
      graph: invalid,
      settings: _settingsFromFixture(source),
    ),
  );
  return !result.canApply &&
      result.diagnostics.any(
        (item) => item.code == GraphLayoutDiagnosticCode.invalidTopology,
      ) &&
      result.positions.values.every((point) => point.isFinite);
}

bool _scopeAndPinsHold(
  Map<String, Object?> source, [
  _GraphCertificationAdapter adapter = const _GraphCertificationAdapter(),
]) {
  final graph = _graphFromFixture(source);
  final result = adapter.compute(
    GraphLayoutRequest(
      algorithmId: GraphLayoutAlgorithmId.circle,
      graph: graph,
      settings: _settingsFromFixture(source).copyWith(
        scope: GraphLayoutScope.selectedNodes,
        selectedNodeIds: const {'n0', 'n1', 'n2'},
        pinnedNodeIds: const {'n0'},
      ),
    ),
  );
  final originals = {for (final node in graph.nodes) node.id: node.position};
  return result.canApply &&
      result.affectedNodeIds.length == 3 &&
      result.affectedNodeIds.containsAll(const {'n0', 'n1', 'n2'}) &&
      result.positions['n0'] == originals['n0'] &&
      result.positions['n3'] == originals['n3'] &&
      result.positions['n4'] == originals['n4'] &&
      result.transform == null;
}

GraphLayoutAlgorithmId _algorithmForProperty(String property) {
  for (final entry in graphLayoutPropertyByAlgorithm.entries) {
    if (entry.value == property) return entry.key;
  }
  throw HardEdgeConfigurationException(
    'Unknown graph property "$property".',
  );
}

bool _isConstructive(GraphLayoutAlgorithmId algorithm) => switch (algorithm) {
      GraphLayoutAlgorithmId.circle ||
      GraphLayoutAlgorithmId.twoCircle ||
      GraphLayoutAlgorithmId.spiral ||
      GraphLayoutAlgorithmId.hierarchical ||
      GraphLayoutAlgorithmId.sugiyama ||
      GraphLayoutAlgorithmId.componentPacking ||
      GraphLayoutAlgorithmId.seededRandom =>
        true,
      _ => false,
    };

bool _samePositions(
  Map<String, GraphLayoutPoint> left,
  Map<String, GraphLayoutPoint> right,
) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

GraphLayoutGraph _graphFromFixture(Map<String, Object?> source) {
  final rawNodes = source['nodes'];
  final rawEdges = source['edges'];
  if (rawNodes is! List || rawEdges is! List) {
    throw const FormatException('Graph fixture requires nodes and edges.');
  }
  return GraphLayoutGraph(
    nodes: rawNodes.map((value) {
      final node = _fixtureMap(value);
      return GraphLayoutNode(
        id: _string(node, 'id'),
        label: _string(node, 'label'),
        position: GraphLayoutPoint(_number(node, 'x'), _number(node, 'y')),
        isInitial: node['id'] == 'n0',
      );
    }),
    edges: rawEdges.map((value) {
      final edge = _fixtureMap(value);
      return GraphLayoutEdge(
        id: _string(edge, 'id'),
        fromNodeId: _string(edge, 'from'),
        toNodeId: _string(edge, 'to'),
      );
    }),
    revision: 'fixture-${source['seed']}',
  );
}

GraphLayoutSettings _settingsFromFixture(Map<String, Object?> source) {
  final rawRestore = _fixtureMap(source['restorePositions']);
  return GraphLayoutSettings(
    seed: source['seed'] as int,
    maximumIterations: 32,
    targetBounds: const GraphLayoutBounds(
      left: 40,
      top: 40,
      width: 720,
      height: 520,
    ),
    restorePositions: {
      for (final entry in rawRestore.entries)
        entry.key: GraphLayoutPoint(
          _number(_fixtureMap(entry.value), 'x'),
          _number(_fixtureMap(entry.value), 'y'),
        ),
    },
  );
}

void _validateFixture(Map<String, Object?> source, String property) {
  if (source['family'] != graphFamilyId || source['property'] != property) {
    throw FormatException(
      'Graph fixture must declare family "$graphFamilyId" and property '
      '"$property".',
    );
  }
  final seed = source['seed'];
  if (seed is! int || seed < 0 || seed > 0xffffffff) {
    throw const FormatException('Graph fixture seed must be a uint32 integer.');
  }
  _graphFromFixture(source);
  _settingsFromFixture(source);
  if (property == 'graph.event-history-replay') {
    _validateEventHistory(source);
  }
}

List<Object?> _generatedEventHistory(int seed) {
  final label = 'seed-$seed';
  final x = 120.0 + (seed % 211);
  final y = 80.0 + ((seed >> 8) % 173);
  return [
    {'type': 'rename', 'nodeId': 'n1', 'label': label},
    {'type': 'move', 'nodeId': 'n2', 'x': x, 'y': y},
    const {'type': 'undo'},
    const {'type': 'redo'},
    {'type': 'assertLabel', 'nodeId': 'n1', 'label': label},
    {'type': 'assertPosition', 'nodeId': 'n2', 'x': x, 'y': y},
  ];
}

void _validateEventHistory(Map<String, Object?> source) {
  final rawEvents = source['events'];
  if (rawEvents is! List) {
    throw const FormatException('Graph event fixture requires events.');
  }
  final nodeIds =
      _graphFromFixture(source).nodes.map((node) => node.id).toSet();
  for (final rawEvent in rawEvents) {
    final event = _fixtureMap(rawEvent);
    final type = _string(event, 'type');
    switch (type) {
      case 'rename':
      case 'assertLabel':
        final nodeId = _string(event, 'nodeId');
        _string(event, 'label');
        if (!nodeIds.contains(nodeId)) {
          throw FormatException('Graph event references missing node $nodeId.');
        }
      case 'move':
      case 'assertPosition':
        final nodeId = _string(event, 'nodeId');
        _number(event, 'x');
        _number(event, 'y');
        if (!nodeIds.contains(nodeId)) {
          throw FormatException('Graph event references missing node $nodeId.');
        }
      case 'undo':
      case 'redo':
        break;
      default:
        throw FormatException('Unknown graph event type "$type".');
    }
  }
}

final class GraphEventHistoryReplayResult {
  const GraphEventHistoryReplayResult({
    required this.finalSnapshot,
    required this.failureSignature,
    required this.undoDepth,
    required this.redoDepth,
  });

  final GraphViewAutomatonSnapshot finalSnapshot;
  final String? failureSignature;
  final int undoDepth;
  final int redoDepth;

  Map<String, Object?> toJson() => {
        'failureSignature': failureSignature,
        'finalSnapshot': finalSnapshot.toJson(),
        'redoDepth': redoDepth,
        'undoDepth': undoDepth,
      };
}

GraphEventHistoryReplayResult graphEventHistoryReplay(Object? fixture) {
  final source = _fixtureMap(fixture);
  _validateFixture(source, 'graph.event-history-replay');
  const historyAdapter = _GraphHistoryCertificationAdapter();
  var current = _snapshotFromFixture(source);
  final undo = <List<int>>[];
  final redo = <List<int>>[];
  String? failureSignature;

  void commit(GraphViewAutomatonSnapshot next) {
    undo.add(historyAdapter.encode(current));
    redo.clear();
    current = next;
  }

  for (final rawEvent in source['events'] as List) {
    final event = _fixtureMap(rawEvent);
    final type = _string(event, 'type');
    final nodeId = event['nodeId'] as String?;
    switch (type) {
      case 'rename':
        commit(
          current.copyWith(
            nodes: [
              for (final node in current.nodes)
                if (node.id == nodeId)
                  node.copyWith(label: _string(event, 'label'))
                else
                  node,
            ],
          ),
        );
      case 'move':
        commit(
          current.copyWith(
            nodes: [
              for (final node in current.nodes)
                if (node.id == nodeId)
                  node.copyWith(
                    x: _number(event, 'x'),
                    y: _number(event, 'y'),
                  )
                else
                  node,
            ],
          ),
        );
      case 'undo':
        if (undo.isEmpty) {
          failureSignature = 'history-underflow:undo';
          break;
        }
        redo.add(historyAdapter.encode(current));
        current = historyAdapter.decode(undo.removeLast());
      case 'redo':
        if (redo.isEmpty) {
          failureSignature = 'history-underflow:redo';
          break;
        }
        undo.add(historyAdapter.encode(current));
        current = historyAdapter.decode(redo.removeLast());
      case 'assertLabel':
        final node = current.nodes.singleWhere((item) => item.id == nodeId);
        final expected = _string(event, 'label');
        if (node.label != expected) {
          failureSignature = 'assert-label:$nodeId:$expected';
        }
      case 'assertPosition':
        final node = current.nodes.singleWhere((item) => item.id == nodeId);
        final expectedX = _number(event, 'x');
        final expectedY = _number(event, 'y');
        if (node.x != expectedX || node.y != expectedY) {
          failureSignature =
              'assert-position:$nodeId:${event['x']}:${event['y']}';
        }
    }
    if (failureSignature != null) break;
  }

  if (failureSignature == null &&
      historyAdapter.roundTrip(current) != current) {
    failureSignature = 'history-round-trip';
  }
  return GraphEventHistoryReplayResult(
    finalSnapshot: current,
    failureSignature: failureSignature,
    undoDepth: undo.length,
    redoDepth: redo.length,
  );
}

GraphViewAutomatonSnapshot _snapshotFromFixture(Map<String, Object?> source) {
  final graph = _graphFromFixture(source);
  return GraphViewAutomatonSnapshot(
    nodes: [
      for (final node in graph.nodes)
        GraphViewCanvasNode(
          id: node.id,
          label: node.label,
          x: node.position.x,
          y: node.position.y,
          isInitial: node.isInitial,
          isAccepting: false,
        ),
    ],
    edges: [
      for (final edge in graph.edges)
        GraphViewCanvasEdge(
          id: edge.id,
          fromStateId: edge.fromNodeId,
          toStateId: edge.toNodeId,
          symbols: [edge.id],
        ),
    ],
    metadata: GraphViewAutomatonMetadata(
      id: 'graph-event-${source['seed']}',
      name: 'Generated graph event history',
      alphabet: [for (final edge in graph.edges) edge.id],
    ),
  );
}

Future<int> _runFlutterEvidence(
  List<String> paths,
  Duration timeout,
) async {
  try {
    return await runGraphEvidenceProcessForCertification(
      executable: Platform.isWindows ? 'cmd.exe' : 'flutter',
      arguments: Platform.isWindows
          ? ['/d', '/s', '/c', 'flutter', 'test', ...paths]
          : ['test', ...paths],
      timeout: timeout,
    );
  } on ProcessException {
    throw const HardEdgeMissingToolException('flutter');
  }
}

@visibleForTesting
Future<int> runGraphEvidenceProcessForCertification({
  required String executable,
  required List<String> arguments,
  required Duration timeout,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    runInShell: false,
  );
  final output =
      process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
  final errors =
      process.stderr.transform(const Utf8Decoder(allowMalformed: true)).join();
  try {
    final exitCode = await process.exitCode.timeout(timeout);
    await Future.wait([output, errors]);
    return exitCode;
  } on TimeoutException {
    await _terminateProcessTree(process);
    try {
      await Future.wait([output, errors]).timeout(const Duration(seconds: 2));
    } on TimeoutException {
      throw StateError(
        'Graph evidence descendants retained output pipes after termination.',
      );
    }
    throw TimeoutException(
      'Flutter graph evidence exceeded ${timeout.inSeconds} seconds and was '
      'terminated.',
      timeout,
    );
  }
}

Future<void> _terminateProcessTree(Process process) async {
  if (Platform.isWindows) {
    final result = await Process.run(
      'taskkill.exe',
      ['/pid', '${process.pid}', '/t', '/f'],
      runInShell: false,
    ).timeout(const Duration(seconds: 3));
    if (result.exitCode != 0 &&
        await graphEvidenceProcessIsRunningForCertification(process.pid)) {
      process.kill();
      throw StateError(
        'taskkill could not terminate graph evidence tree ${process.pid}: '
        '${result.stderr}',
      );
    }
  } else {
    await _terminatePosixProcessTree(process.pid);
  }
  try {
    await process.exitCode.timeout(const Duration(seconds: 3));
  } on TimeoutException {
    throw StateError(
      'Graph evidence process ${process.pid} did not terminate safely.',
    );
  }
}

Future<void> _terminatePosixProcessTree(int rootPid) async {
  final frozen = <int>[];
  try {
    for (var pass = 0; pass < 4; pass++) {
      final current = await _posixProcessTree(rootPid);
      final additions = current.where((pid) => !frozen.contains(pid)).toList();
      for (final pid in additions) {
        Process.killPid(pid, ProcessSignal.sigstop);
        frozen.add(pid);
      }
      if (additions.isEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  } on Object catch (error) {
    Process.killPid(rootPid, ProcessSignal.sigkill);
    throw StateError(
      'Could not enumerate graph evidence descendants for $rootPid: $error',
    );
  }
  for (final pid in frozen.reversed) {
    Process.killPid(pid, ProcessSignal.sigkill);
  }
  final remaining = await _waitForGraphProcessIds(
    frozen,
    const Duration(seconds: 3),
  );
  if (remaining.isNotEmpty) {
    throw StateError(
      'Graph evidence descendants did not exit: ${remaining.join(', ')}.',
    );
  }
}

Future<List<int>> _posixProcessTree(int rootPid) async {
  final result = await Process.run(
    'ps',
    const ['-eo', 'pid=,ppid='],
    runInShell: false,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
        'ps', const ['-eo', 'pid=,ppid='], '${result.stderr}');
  }
  final children = <int, List<int>>{};
  for (final line in '${result.stdout}'.split('\n')) {
    final fields = line.trim().split(RegExp(r'\s+'));
    if (fields.length != 2) continue;
    final pid = int.tryParse(fields[0]);
    final parent = int.tryParse(fields[1]);
    if (pid == null || parent == null) continue;
    children.putIfAbsent(parent, () => <int>[]).add(pid);
  }
  final ordered = <int>[rootPid];
  for (var index = 0; index < ordered.length; index++) {
    ordered.addAll(children[ordered[index]] ?? const <int>[]);
  }
  return ordered;
}

Future<List<int>> _waitForGraphProcessIds(
  Iterable<int> processIds,
  Duration timeout,
) async {
  final pending = processIds.toSet();
  final stopwatch = Stopwatch()..start();
  while (pending.isNotEmpty && stopwatch.elapsed < timeout) {
    final running = <int>{};
    for (final pid in pending) {
      if (await graphEvidenceProcessIsRunningForCertification(pid)) {
        running.add(pid);
      }
    }
    pending
      ..clear()
      ..addAll(running);
    if (pending.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }
  return pending.toList()..sort();
}

@visibleForTesting
Future<bool> graphEvidenceProcessIsRunningForCertification(int pid) async {
  if (Platform.isWindows) {
    final result = await Process.run(
      'tasklist.exe',
      ['/fi', 'PID eq $pid', '/fo', 'csv', '/nh'],
      runInShell: false,
    );
    return result.exitCode == 0 && '${result.stdout}'.contains('"$pid"');
  }
  final result = await Process.run(
    '/bin/kill',
    ['-0', '$pid'],
    runInShell: false,
  );
  return result.exitCode == 0;
}

const graphMutationOperatorIds = <String>{
  'drop-node-position',
  'ignore-layout-seed',
  'move-pinned-node',
  'drop-mapped-edge',
  'truncate-history-payload',
};

enum _GraphCertificationMutation {
  dropNodePosition,
  ignoreLayoutSeed,
  movePinnedNode,
  dropMappedEdge,
  truncateHistoryPayload,
}

final class _GraphCertificationAdapter {
  const _GraphCertificationAdapter([this.mutation]);

  final _GraphCertificationMutation? mutation;

  GraphLayoutResult compute(GraphLayoutRequest request) {
    final effectiveRequest = switch (mutation) {
      _GraphCertificationMutation.ignoreLayoutSeed => GraphLayoutRequest(
          algorithmId: request.algorithmId,
          algorithmVersion: request.algorithmVersion,
          graph: request.graph,
          settings: request.settings.copyWith(seed: 0),
        ),
      _GraphCertificationMutation.movePinnedNode => GraphLayoutRequest(
          algorithmId: request.algorithmId,
          algorithmVersion: request.algorithmVersion,
          graph: request.graph,
          settings: request.settings.copyWith(pinnedNodeIds: const []),
        ),
      _ => request,
    };
    final result = GraphLayoutEngine.compute(effectiveRequest);
    if (mutation != _GraphCertificationMutation.dropNodePosition ||
        result.positions.isEmpty) {
      return result;
    }
    final positions = Map<String, GraphLayoutPoint>.of(result.positions);
    final removedId = positions.keys.toList()..sort();
    positions.remove(removedId.last);
    return GraphLayoutResult(
      algorithmId: result.algorithmId,
      algorithmVersion: result.algorithmVersion,
      positions: positions,
      diagnostics: result.diagnostics,
      metrics: result.metrics,
      affectedNodeIds: result.affectedNodeIds,
      transform: result.transform,
    );
  }
}

final class _GraphMappingCertificationAdapter {
  const _GraphMappingCertificationAdapter([this.mutation]);

  final _GraphCertificationMutation? mutation;

  GraphViewAutomatonSnapshot toSnapshot(FSA automaton) {
    final snapshot = GraphViewAutomatonMapper.toSnapshot(automaton);
    if (mutation != _GraphCertificationMutation.dropMappedEdge ||
        snapshot.edges.isEmpty) {
      return snapshot;
    }
    return snapshot.copyWith(edges: snapshot.edges.sublist(1));
  }
}

final class _GraphHistoryCertificationAdapter {
  const _GraphHistoryCertificationAdapter([this.mutation]);

  final _GraphCertificationMutation? mutation;

  List<int> encode(GraphViewAutomatonSnapshot snapshot) {
    final encoded = createGraphHistoryCodec().encode(
      utf8.encode(jsonEncode(snapshot.toJson())),
    );
    if (mutation != _GraphCertificationMutation.truncateHistoryPayload ||
        encoded.isEmpty) {
      return List<int>.unmodifiable(encoded);
    }
    return List<int>.unmodifiable(encoded.take(encoded.length ~/ 2));
  }

  GraphViewAutomatonSnapshot decode(List<int> payload) {
    final decoded = createGraphHistoryCodec().decode(payload);
    final json = jsonDecode(utf8.decode(decoded));
    if (json is! Map) {
      throw const FormatException('Graph history snapshot must be an object.');
    }
    return GraphViewAutomatonSnapshot.fromJson(
      json.cast<String, dynamic>(),
    );
  }

  GraphViewAutomatonSnapshot roundTrip(GraphViewAutomatonSnapshot snapshot) =>
      decode(encode(snapshot));
}

final class GraphHardEdgeMutationExecutor implements HardEdgeMutationExecutor {
  const GraphHardEdgeMutationExecutor();

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (mutation.family != graphFamilyId ||
        mutation.property != 'graph.mutations' ||
        !graphMutationOperatorIds.contains(mutation.operatorId)) {
      throw HardEdgeConfigurationException(
        'Unknown graph mutation "${mutation.operatorId}".',
      );
    }
    final source = _fixtureMap(fixture);
    _validateFixture(source, 'graph.mutations');
    final killed = switch (mutation.operatorId) {
      'drop-node-position' => _dropNodePositionMutantKilled(source),
      'ignore-layout-seed' => _ignoreSeedMutantKilled(source),
      'move-pinned-node' => _movePinnedNodeMutantKilled(source),
      'drop-mapped-edge' => _dropMappedEdgeMutantKilled(source),
      'truncate-history-payload' => _truncateHistoryPayloadMutantKilled(source),
      _ => false,
    };
    return killed
        ? HardEdgeMutationStatus.killed
        : HardEdgeMutationStatus.survived;
  }
}

bool _dropNodePositionMutantKilled(Map<String, Object?> source) {
  final canonical = _layoutPropertiesHold(
    source,
    GraphLayoutAlgorithmId.circle,
  );
  final mutant = _layoutPropertiesHold(
    source,
    GraphLayoutAlgorithmId.circle,
    const _GraphCertificationAdapter(
      _GraphCertificationMutation.dropNodePosition,
    ),
  );
  return canonical && !mutant;
}

bool _ignoreSeedMutantKilled(Map<String, Object?> source) {
  bool property(_GraphCertificationAdapter adapter) {
    final graph = _graphFromFixture(source);
    GraphLayoutResult run(int seed) => adapter.compute(
          GraphLayoutRequest(
            algorithmId: GraphLayoutAlgorithmId.seededRandom,
            graph: graph,
            settings: _settingsFromFixture(source).copyWith(seed: seed),
          ),
        );
    final seed = source['seed'] as int;
    final first = run(seed);
    final second = run(seed == 0xffffffff ? seed - 1 : seed + 1);
    return first.canApply &&
        second.canApply &&
        !_samePositions(first.positions, second.positions);
  }

  return property(const _GraphCertificationAdapter()) &&
      !property(
        const _GraphCertificationAdapter(
          _GraphCertificationMutation.ignoreLayoutSeed,
        ),
      );
}

bool _movePinnedNodeMutantKilled(Map<String, Object?> source) {
  final canonical = _scopeAndPinsHold(source);
  final mutant = _scopeAndPinsHold(
    source,
    const _GraphCertificationAdapter(
      _GraphCertificationMutation.movePinnedNode,
    ),
  );
  return canonical && !mutant;
}

bool _dropMappedEdgeMutantKilled(Map<String, Object?> source) =>
    _mappingRoundTripHolds(source, const _GraphMappingCertificationAdapter()) &&
    !_mappingRoundTripHolds(
      source,
      const _GraphMappingCertificationAdapter(
        _GraphCertificationMutation.dropMappedEdge,
      ),
    );

bool _truncateHistoryPayloadMutantKilled(Map<String, Object?> source) =>
    _historyRoundTripHolds(source, const _GraphHistoryCertificationAdapter()) &&
    !_historyRoundTripHolds(
      source,
      const _GraphHistoryCertificationAdapter(
        _GraphCertificationMutation.truncateHistoryPayload,
      ),
    );

bool _mappingRoundTripHolds(
  Map<String, Object?> source,
  _GraphMappingCertificationAdapter adapter,
) {
  final automaton = _fsaFromFixture(source);
  final snapshot = adapter.toSnapshot(automaton);
  final restored = GraphViewAutomatonMapper.mergeIntoTemplate(
    snapshot,
    automaton,
  );
  final stateIds = automaton.states.map((state) => state.id).toSet();
  final transitionIds =
      automaton.fsaTransitions.map((transition) => transition.id).toSet();
  return snapshot.nodes.map((node) => node.id).toSet().containsAll(stateIds) &&
      snapshot.nodes.length == stateIds.length &&
      snapshot.edges
          .map((edge) => edge.id)
          .toSet()
          .containsAll(transitionIds) &&
      snapshot.edges.length == transitionIds.length &&
      restored.states.map((state) => state.id).toSet().containsAll(stateIds) &&
      restored.fsaTransitions
          .map((transition) => transition.id)
          .toSet()
          .containsAll(transitionIds) &&
      restored.initialState?.id == automaton.initialState?.id;
}

bool _historyRoundTripHolds(
  Map<String, Object?> source,
  _GraphHistoryCertificationAdapter adapter,
) {
  try {
    final snapshot = _snapshotFromFixture(source);
    return adapter.roundTrip(snapshot) == snapshot;
  } on Object {
    return false;
  }
}

FSA _fsaFromFixture(Map<String, Object?> source) {
  final graph = _graphFromFixture(source);
  final states = <String, State>{
    for (final node in graph.nodes)
      node.id: State(
        id: node.id,
        label: node.label,
        position: vmath.Vector2(node.position.x, node.position.y),
        isInitial: node.isInitial,
        isAccepting: node.id == 'n3',
      ),
  };
  final transitions = {
    for (final edge in graph.edges)
      FSATransition(
        id: edge.id,
        fromState: states[edge.fromNodeId]!,
        toState: states[edge.toNodeId]!,
        inputSymbols: {edge.id},
        controlPoint: vmath.Vector2.zero(),
      ),
  };
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return FSA(
    id: 'graph-mapping-${source['seed']}',
    name: 'Graph mapping mutation fixture',
    states: states.values.toSet(),
    transitions: transitions,
    alphabet:
        transitions.expand((transition) => transition.inputSymbols).toSet(),
    initialState: states['n0'],
    acceptingStates: {if (states['n3'] case final accepting?) accepting},
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}

final class GraphFailureFixtureShrinker implements DomainShrinker<Object?> {
  const GraphFailureFixtureShrinker();

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    final source = _fixtureMap(value);
    final nodes = source['nodes'];
    final edges = source['edges'];
    if (nodes is! List || edges is! List) return;
    final events = source['events'];
    if (events is List && events.isNotEmpty) {
      yield <String, Object?>{...source, 'events': const <Object?>[]};
      if (events.length > 1) {
        yield <String, Object?>{
          ...source,
          'events': events.take(events.length ~/ 2).toList(),
        };
      }
      for (var index = events.length - 1; index >= 0; index--) {
        yield <String, Object?>{
          ...source,
          'events': [...events]..removeAt(index),
        };
      }
    }
    for (var index = edges.length - 1; index >= 0; index--) {
      yield <String, Object?>{
        ...source,
        'edges': [...edges]..removeAt(index),
      };
    }
    for (var index = nodes.length - 1; index > 0; index--) {
      final node = _fixtureMap(nodes[index]);
      final id = node['id'];
      yield <String, Object?>{
        ...source,
        'nodes': [...nodes]..removeAt(index),
        'edges': [
          for (final edgeValue in edges)
            if (_fixtureMap(edgeValue)['from'] != id &&
                _fixtureMap(edgeValue)['to'] != id)
              edgeValue,
        ],
      };
    }
  }
}

bool graphFailureFixtureIsValid(Object? value) {
  try {
    final source = _fixtureMap(value);
    final property = source['property'];
    if (property is! String) return false;
    _validateFixture(source, property);
    final graph = _graphFromFixture(source);
    final ids = graph.nodes.map((node) => node.id).toSet();
    return ids.length == graph.nodes.length &&
        graph.edges.every(
          (edge) =>
              ids.contains(edge.fromNodeId) && ids.contains(edge.toNodeId),
        );
  } on Object {
    return false;
  }
}

bool graphFailureFixtureIsApplicable(Object? value) {
  if (!graphFailureFixtureIsValid(value)) return false;
  final source = _fixtureMap(value);
  final property = source['property'];
  if (graphFlutterEvidenceByProperty.containsKey(property) ||
      (source['nodes'] as List).isEmpty) {
    return false;
  }
  return property != 'graph.event-history-replay' ||
      (source['events'] as List).isNotEmpty;
}

Map<String, Object?> _fixtureMap(Object? value) => value is Map
    ? <String, Object?>{
        for (final entry in value.entries) entry.key.toString(): entry.value,
      }
    : const {};

String _string(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! String) throw FormatException('Graph fixture $key is invalid.');
  return value;
}

double _number(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('Graph fixture $key must be finite.');
  }
  return value.toDouble();
}

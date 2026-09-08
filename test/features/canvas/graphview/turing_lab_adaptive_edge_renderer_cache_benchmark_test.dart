//
//  turing_lab_adaptive_edge_renderer_cache_benchmark_test.dart
//  Turing Lab
//
//  Measures automatic route cache behaviour on a 500-state DFA (1 000
//  transitions: a ring on `a` plus one self-loop per state on `b`) across
//  the interactions #434 asks about: viewport-only rebuilds (pan/zoom),
//  dragging one state, and editing one transition. Counters come from the
//  renderer itself; timings are printed and only loosely bounded because they
//  are load-sensitive.
//

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:vector_math/vector_math_64.dart';

FSA _ringDfa(int stateCount) {
  final columns = math.sqrt(stateCount).ceil();
  final states = [
    for (var index = 0; index < stateCount; index++)
      automaton_state.State(
        id: 'q$index',
        label: 'q$index',
        position: Vector2(
          120.0 + (index % columns) * 140.0,
          120.0 + (index ~/ columns) * 140.0,
        ),
        isInitial: index == 0,
        isAccepting: index == stateCount - 1,
      ),
  ];
  final transitions = <FSATransition>{
    for (var index = 0; index < states.length; index++) ...[
      FSATransition(
        id: 't${index}_primary',
        fromState: states[index],
        toState: states[(index + 1) % states.length],
        symbol: 'a',
      ),
      FSATransition(
        id: 't${index}_self',
        fromState: states[index],
        toState: states[index],
        symbol: 'b',
      ),
    ],
  };
  return FSA(
    id: 'ring-$stateCount',
    name: 'Ring $stateCount',
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: math.Rectangle(0, 0, columns * 140.0 + 240, columns * 140.0 + 240),
  );
}

Graph _equivalentContainer(Graph graph) {
  final rebuilt = Graph();
  for (final node in graph.nodes) {
    rebuilt.addNode(node);
  }
  for (final edge in graph.edges) {
    rebuilt.addEdgeS(edge);
  }
  return rebuilt;
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

void main() {
  test('500-state DFA: pan/zoom reuses geometry, drag and edit stay local', () {
    const stateCount = 500;
    final notifier = AutomatonStateNotifier();
    final controller = GraphViewCanvasController(
      automatonStateNotifier: notifier,
    );
    addTearDown(controller.dispose);
    notifier.replaceAutomaton(_ringDfa(stateCount));
    controller.synchronize(notifier.state.currentAutomaton!);

    // Same routing configuration the app uses for the grouped FSA canvas
    // (see AutomatonGraphViewEdgePresentation): the grouped planner never
    // reads the base repulsion offsets, so repulsion is off in this mode.
    final renderer = TuringLabAdaptiveEdgeRenderer(
      config: EdgeRoutingConfig(
        anchorMode: AnchorMode.dynamic,
        routingMode: RoutingMode.bezier,
        enableRepulsion: false,
      ),
      renderMode: TuringLabEdgeRenderMode.groupedFsa,
    )..setGraph(controller.graph);
    final edgeCount = controller.graph.edges.length;
    final report = StringBuffer(
      '\n#434 route cache benchmark ($stateCount states, $edgeCount edges)\n',
    );

    // Phase 1: first layout plans every group once.
    final firstLayout = Stopwatch()..start();
    renderer.prepareForRenderCycle();
    firstLayout.stop();
    final groupsInFirstLayout = renderer.debugRouteGroupsPlanned;
    report.writeln(
      'first layout: ${firstLayout.elapsedMilliseconds}ms, '
      'groups planned=$groupsInFirstLayout, full replans='
      '${renderer.debugRouteFullReplans}',
    );
    expect(renderer.debugRouteLayoutRuns, 1);
    expect(renderer.debugRouteFullReplans, 1);
    expect(groupsInFirstLayout, greaterThanOrEqualTo(edgeCount ~/ 2));

    // Phase 2: pan/zoom. The viewport transform never reaches the renderer;
    // GraphView only hands it an equivalent container on every rebuild.
    renderer.debugResetRouteCounters();
    const viewportRebuilds = 60;
    final panSamples = <double>[];
    final containerSamples = <double>[];
    final setGraphSamples = <double>[];
    for (var index = 0; index < viewportRebuilds; index++) {
      final build = Stopwatch()..start();
      final container = _equivalentContainer(controller.graph);
      build.stop();
      containerSamples.add(build.elapsedMicroseconds / 1000.0);
      final cycle = Stopwatch()..start();
      renderer.setGraph(container);
      setGraphSamples.add(cycle.elapsedMicroseconds / 1000.0);
      renderer.prepareForRenderCycle();
      cycle.stop();
      panSamples.add(cycle.elapsedMicroseconds / 1000.0);
    }
    report.writeln(
      'pan/zoom harness: median container build='
      '${_median(containerSamples).toStringAsFixed(3)}ms, median setGraph='
      '${_median(setGraphSamples).toStringAsFixed(3)}ms',
    );
    report.writeln(
      'pan/zoom x$viewportRebuilds: cache hits=${renderer.debugRouteCacheHits}, '
      'layout runs=${renderer.debugRouteLayoutRuns}, groups planned='
      '${renderer.debugRouteGroupsPlanned}, median cycle='
      '${_median(panSamples).toStringAsFixed(3)}ms, last cycle phases (µs)='
      '${renderer.debugLastCyclePhaseMicros}',
    );
    expect(renderer.debugRouteCacheHits, viewportRebuilds);
    expect(renderer.debugRouteLayoutRuns, 0);
    expect(renderer.debugRouteGroupsPlanned, 0);

    // Phase 3: drag one state through 30 preview positions.
    renderer.debugResetRouteCounters();
    const dragFrames = 30;
    final dragSamples = <double>[];
    for (var index = 1; index <= dragFrames; index++) {
      final cycle = Stopwatch()..start();
      controller.previewStatePosition('q7', Offset(120.0 + index * 3.0, 120.0));
      renderer.prepareForRenderCycle();
      cycle.stop();
      dragSamples.add(cycle.elapsedMicroseconds / 1000.0);
    }
    final groupsPerDragFrame =
        renderer.debugRouteGroupsPlanned / renderer.debugRouteLayoutRuns;
    report.writeln(
      'drag q7 x$dragFrames: layout runs=${renderer.debugRouteLayoutRuns}, '
      'groups planned per frame=${groupsPerDragFrame.toStringAsFixed(1)}, '
      'full replans=${renderer.debugRouteFullReplans}, median cycle='
      '${_median(dragSamples).toStringAsFixed(3)}ms, last cycle phases (µs)='
      '${renderer.debugLastCyclePhaseMicros}, route sub-phases (µs)='
      '${renderer.debugLastRoutePhaseMicros}',
    );
    expect(renderer.debugRouteLayoutRuns, dragFrames);
    expect(renderer.debugRouteFullReplans, 0);
    // q7 touches three groups (incoming ring edge, outgoing ring edge and its
    // own loop); the planner may add neighbours whose paths it now obstructs,
    // but never approaches a full replan.
    expect(groupsPerDragFrame, greaterThanOrEqualTo(3));
    expect(groupsPerDragFrame, lessThan(groupsInFirstLayout / 10));

    // Phase 4: editing one transition label rebuilds the graph structure,
    // which is a full replan by design (edge identities change).
    renderer.debugResetRouteCounters();
    final edit = Stopwatch()..start();
    notifier.updateTransitionLabel(id: 't3_primary', label: 'a,b');
    controller.synchronize(notifier.state.currentAutomaton!);
    renderer.setGraph(controller.graph);
    renderer.prepareForRenderCycle();
    edit.stop();
    report.writeln(
      'edit one transition: layout runs=${renderer.debugRouteLayoutRuns}, '
      'groups planned=${renderer.debugRouteGroupsPlanned}, full replans='
      '${renderer.debugRouteFullReplans}, cycle=${edit.elapsedMilliseconds}ms',
    );
    expect(renderer.debugRouteLayoutRuns, 1);
    expect(renderer.debugRouteFullReplans, 1);

    // ignore: avoid_print
    print(report);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

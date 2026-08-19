import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:turing_lab/features/canvas/graphview/automatic_transition_route_planner.dart';

void main() {
  test('plans separated deterministic controls around an obstacle', () {
    const planner = AutomaticTransitionRoutePlanner();
    final requests = [
      const AutomaticTransitionRouteRequest(
        stableId: 'a',
        sourceId: 'q0',
        destinationId: 'q1',
        sourceCenter: Offset(48, 48),
        destinationCenter: Offset(348, 48),
        sourceRadius: 48,
        destinationRadius: 48,
        laneOffset: -17,
        repulsionOffset: Offset(0, -12),
      ),
      const AutomaticTransitionRouteRequest(
        stableId: 'b',
        sourceId: 'q0',
        destinationId: 'q1',
        sourceCenter: Offset(48, 48),
        destinationCenter: Offset(348, 48),
        sourceRadius: 48,
        destinationRadius: 48,
        laneOffset: 17,
        repulsionOffset: Offset(0, 12),
      ),
    ];
    const obstacles = [
      AutomaticTransitionObstacle(
        id: 'blocking',
        center: Offset(198, 48),
        radius: 48,
      ),
    ];

    final result = planner.plan(requests: requests, obstacles: obstacles);
    final reversed = planner.plan(
      requests: requests.reversed.toList(),
      obstacles: obstacles,
    );

    expect(result['a']!.controlPoint.dy, lessThan(0));
    expect(result['b']!.controlPoint.dy, greaterThan(96));
    expect(result['a']!.controlPoint, reversed['a']!.controlPoint);
    expect(result['b']!.controlPoint, reversed['b']!.controlPoint);
  });

  test('loop selects a free heading and changes when it is occupied', () {
    const planner = AutomaticTransitionRoutePlanner();
    const loop = AutomaticTransitionRouteRequest(
      stableId: 'loop-a',
      sourceId: 'q0',
      destinationId: 'q0',
      sourceCenter: Offset(200, 200),
      destinationCenter: Offset(200, 200),
      sourceRadius: 48,
      destinationRadius: 48,
      laneOffset: 0,
      repulsionOffset: Offset.zero,
    );

    final open = planner.plan(requests: [loop], obstacles: const []);
    final blocked = planner.plan(
      requests: [loop],
      obstacles: const [
        AutomaticTransitionObstacle(
          id: 'north-blocker',
          center: Offset(200, 80),
          radius: 48,
        ),
      ],
    );

    expect(open['loop-a']!.loopHeading, LoopHeading.north);
    expect(blocked['loop-a']!.loopHeading, isNot(LoopHeading.north));
  });
}

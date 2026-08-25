import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
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

  test('loop points up when the border around the state is free', () {
    const planner = AutomaticTransitionRoutePlanner();

    final plan = planner.plan(requests: [_loopRequest()], obstacles: const []);

    expect(plan['loop-a']!.loopAngle, closeTo(-math.pi / 2, 0.01));
  });

  test('loop turns away from a state blocking its heading', () {
    const planner = AutomaticTransitionRoutePlanner();

    final blocked = planner.plan(
      requests: [_loopRequest()],
      obstacles: const [
        AutomaticTransitionObstacle(
          id: 'north-blocker',
          center: Offset(200, 80),
          radius: 48,
        ),
      ],
    );

    expect(
      _angularGap(blocked['loop-a']!.loopAngle!, -math.pi / 2),
      greaterThan(math.pi / 6),
    );
  });

  test('loop keeps clear of the initial-state marker and of transitions', () {
    const planner = AutomaticTransitionRoutePlanner();

    // The marker enters from the west and a transition leaves to the north,
    // so the loop has to settle on one of the free sides.
    final plan = planner.plan(
      requests: [
        _loopRequest(
          repulsors: const [
            AutomaticTransitionLoopRepulsor(
              direction: math.pi,
              halfWidth: 5 * math.pi / 18,
              weight: 2.5,
            ),
            AutomaticTransitionLoopRepulsor(
              direction: -math.pi / 2,
              halfWidth: 7 * math.pi / 36,
              weight: 2.0,
            ),
          ],
        ),
      ],
      obstacles: const [],
    );

    final angle = plan['loop-a']!.loopAngle!;
    expect(_angularGap(angle, math.pi), greaterThan(math.pi / 2));
    expect(_angularGap(angle, -math.pi / 2), greaterThan(math.pi / 6));
  });

  test('loop slides with a moving neighbour instead of jumping sides', () {
    const planner = AutomaticTransitionRoutePlanner();
    var previous = -math.pi / 2;
    final travelled = <double>[];

    // Walks a neighbouring state across the top of the looping state, one
    // replan per step, exactly as a drag would.
    for (var step = 0; step <= 20; step++) {
      final plan = planner.plan(
        requests: [_loopRequest(previousLoopAngle: previous)],
        obstacles: [
          AutomaticTransitionObstacle(
            id: 'walker',
            center: Offset(120 + (step * 8), 90),
            radius: 48,
          ),
        ],
      );
      final angle = plan['loop-a']!.loopAngle!;
      travelled.add(_angularGap(angle, previous));
      previous = angle;
    }

    expect(travelled.reduce(math.max), lessThan(math.pi / 6));
  });

  test('loop stays on the side it was already on when sides tie', () {
    const planner = AutomaticTransitionRoutePlanner();
    // A state due north leaves two mirror-image placements. Whichever one the
    // loop already had must survive the replan.
    const blocker = [
      AutomaticTransitionObstacle(
        id: 'north-blocker',
        center: Offset(200, 80),
        radius: 48,
      ),
    ];

    final fromEast = planner.plan(
      requests: [_loopRequest(previousLoopAngle: 0)],
      obstacles: blocker,
    );
    final fromWest = planner.plan(
      requests: [_loopRequest(previousLoopAngle: math.pi)],
      obstacles: blocker,
    );

    expect(math.cos(fromEast['loop-a']!.loopAngle!), greaterThan(0));
    expect(math.cos(fromWest['loop-a']!.loopAngle!), lessThan(0));
  });

  test('loop abandons its previous angle when a state moves onto it', () {
    const planner = AutomaticTransitionRoutePlanner();

    final blocked = planner.plan(
      requests: [_loopRequest(previousLoopAngle: 0)],
      obstacles: const [
        AutomaticTransitionObstacle(
          id: 'east-blocker',
          center: Offset(320, 200),
          radius: 48,
        ),
      ],
    );

    expect(
      _angularGap(blocked['loop-a']!.loopAngle!, 0),
      greaterThan(math.pi / 6),
    );
  });

  test('loop planning ignores the order requests arrive in', () {
    const planner = AutomaticTransitionRoutePlanner();
    final requests = [
      _loopRequest(stableId: 'loop-a'),
      _loopRequest(
          stableId: 'loop-b', sourceId: 'q1', center: const Offset(500, 200)),
    ];
    const obstacles = [
      AutomaticTransitionObstacle(
        id: 'q0',
        center: Offset(200, 200),
        radius: 48,
      ),
      AutomaticTransitionObstacle(
        id: 'q1',
        center: Offset(500, 200),
        radius: 48,
      ),
      AutomaticTransitionObstacle(
        id: 'blocker',
        center: Offset(350, 130),
        radius: 48,
      ),
    ];

    final plan = planner.plan(requests: requests, obstacles: obstacles);
    final reversed = planner.plan(
      requests: requests.reversed.toList(),
      obstacles: obstacles,
    );

    expect(plan['loop-a']!.loopAngle, reversed['loop-a']!.loopAngle);
    expect(plan['loop-b']!.loopAngle, reversed['loop-b']!.loopAngle);
  });
}

AutomaticTransitionRouteRequest _loopRequest({
  String stableId = 'loop-a',
  String sourceId = 'q0',
  Offset center = const Offset(200, 200),
  double? previousLoopAngle,
  List<AutomaticTransitionLoopRepulsor> repulsors =
      const <AutomaticTransitionLoopRepulsor>[],
}) {
  return AutomaticTransitionRouteRequest(
    stableId: stableId,
    sourceId: sourceId,
    destinationId: sourceId,
    sourceCenter: center,
    destinationCenter: center,
    sourceRadius: 48,
    destinationRadius: 48,
    laneOffset: 0,
    repulsionOffset: Offset.zero,
    previousLoopAngle: previousLoopAngle,
    loopRepulsors: repulsors,
  );
}

double _angularGap(double left, double right) {
  final delta = (left - right) % (2 * math.pi);
  return delta > math.pi ? (2 * math.pi) - delta : delta;
}

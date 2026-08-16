import 'package:graphview/GraphView.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdgeRoutingConfig', () {
    test('Default configuration uses correct values', () {
      final config = EdgeRoutingConfig();

      expect(config.anchorMode, AnchorMode.center);
      expect(config.routingMode, RoutingMode.direct);
      expect(config.enableRepulsion, false);
      expect(config.repulsionStrength, 0.5);
      expect(config.minEdgeDistance, 10.0);
      expect(config.maxRepulsionIterations, 10);
      expect(config.movementThreshold, 1.0);
    });

    test('Configuration can be created with custom values', () {
      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.cardinal,
        routingMode: RoutingMode.orthogonal,
        enableRepulsion: true,
        repulsionStrength: 0.8,
        minEdgeDistance: 15.0,
        maxRepulsionIterations: 20,
        movementThreshold: 0.5,
      );

      expect(config.anchorMode, AnchorMode.cardinal);
      expect(config.routingMode, RoutingMode.orthogonal);
      expect(config.enableRepulsion, true);
      expect(config.repulsionStrength, 0.8);
      expect(config.minEdgeDistance, 15.0);
      expect(config.maxRepulsionIterations, 20);
      expect(config.movementThreshold, 0.5);
    });

    test('Getter methods return correct values', () {
      final config = EdgeRoutingConfig(
        anchorMode: AnchorMode.octagonal,
        routingMode: RoutingMode.bezier,
        enableRepulsion: true,
        repulsionStrength: 0.6,
        minEdgeDistance: 12.0,
        maxRepulsionIterations: 15,
        movementThreshold: 2.0,
      );

      expect(config.getAnchorMode(), AnchorMode.octagonal);
      expect(config.getRoutingMode(), RoutingMode.bezier);
      expect(config.getEnableRepulsion(), true);
      expect(config.getRepulsionStrength(), 0.6);
      expect(config.getMinEdgeDistance(), 12.0);
      expect(config.getMaxRepulsionIterations(), 15);
      expect(config.getMovementThreshold(), 2.0);
    });

    test('AnchorMode enum has all expected values', () {
      expect(AnchorMode.values.length, 4);
      expect(AnchorMode.values, contains(AnchorMode.center));
      expect(AnchorMode.values, contains(AnchorMode.cardinal));
      expect(AnchorMode.values, contains(AnchorMode.octagonal));
      expect(AnchorMode.values, contains(AnchorMode.dynamic));
    });

    test('RoutingMode enum has all expected values', () {
      expect(RoutingMode.values.length, 4);
      expect(RoutingMode.values, contains(RoutingMode.direct));
      expect(RoutingMode.values, contains(RoutingMode.orthogonal));
      expect(RoutingMode.values, contains(RoutingMode.bezier));
      expect(RoutingMode.values, contains(RoutingMode.bundling));
    });

    test('Static constants match default values', () {
      expect(EdgeRoutingConfig.DEFAULT_ANCHOR_MODE, AnchorMode.center);
      expect(EdgeRoutingConfig.DEFAULT_ROUTING_MODE, RoutingMode.direct);
      expect(EdgeRoutingConfig.DEFAULT_ENABLE_REPULSION, false);
      expect(EdgeRoutingConfig.DEFAULT_REPULSION_STRENGTH, 0.5);
      expect(EdgeRoutingConfig.DEFAULT_MIN_EDGE_DISTANCE, 10.0);
      expect(EdgeRoutingConfig.DEFAULT_MAX_REPULSION_ITERATIONS, 10);
      expect(EdgeRoutingConfig.DEFAULT_MOVEMENT_THRESHOLD, 1.0);
    });

    test('Configuration supports all anchor modes', () {
      final centerConfig = EdgeRoutingConfig(anchorMode: AnchorMode.center);
      expect(centerConfig.anchorMode, AnchorMode.center);

      final cardinalConfig = EdgeRoutingConfig(anchorMode: AnchorMode.cardinal);
      expect(cardinalConfig.anchorMode, AnchorMode.cardinal);

      final octagonalConfig =
          EdgeRoutingConfig(anchorMode: AnchorMode.octagonal);
      expect(octagonalConfig.anchorMode, AnchorMode.octagonal);

      final dynamicConfig = EdgeRoutingConfig(anchorMode: AnchorMode.dynamic);
      expect(dynamicConfig.anchorMode, AnchorMode.dynamic);
    });

    test('Configuration supports all routing modes', () {
      final directConfig = EdgeRoutingConfig(routingMode: RoutingMode.direct);
      expect(directConfig.routingMode, RoutingMode.direct);

      final orthogonalConfig =
          EdgeRoutingConfig(routingMode: RoutingMode.orthogonal);
      expect(orthogonalConfig.routingMode, RoutingMode.orthogonal);

      final bezierConfig = EdgeRoutingConfig(routingMode: RoutingMode.bezier);
      expect(bezierConfig.routingMode, RoutingMode.bezier);

      final bundlingConfig =
          EdgeRoutingConfig(routingMode: RoutingMode.bundling);
      expect(bundlingConfig.routingMode, RoutingMode.bundling);
    });

    test('Repulsion strength can be set to boundary values', () {
      final minConfig = EdgeRoutingConfig(repulsionStrength: 0.0);
      expect(minConfig.repulsionStrength, 0.0);

      final maxConfig = EdgeRoutingConfig(repulsionStrength: 1.0);
      expect(maxConfig.repulsionStrength, 1.0);
    });

    test('Fields can be modified after construction', () {
      final config = EdgeRoutingConfig();

      // Modify fields
      config.anchorMode = AnchorMode.dynamic;
      config.routingMode = RoutingMode.bezier;
      config.enableRepulsion = true;
      config.repulsionStrength = 0.75;
      config.minEdgeDistance = 20.0;
      config.maxRepulsionIterations = 25;
      config.movementThreshold = 3.0;

      // Verify modifications
      expect(config.anchorMode, AnchorMode.dynamic);
      expect(config.routingMode, RoutingMode.bezier);
      expect(config.enableRepulsion, true);
      expect(config.repulsionStrength, 0.75);
      expect(config.minEdgeDistance, 20.0);
      expect(config.maxRepulsionIterations, 25);
      expect(config.movementThreshold, 3.0);
    });
  });
}

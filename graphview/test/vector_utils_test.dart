import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

void main() {
  group('VectorUtils - Perpendicular Vectors', () {
    test('perpendicular of horizontal vector', () {
      final vec = Offset(3, 0);
      final perp = VectorUtils.perpendicular(vec);
      expect(perp.dx, closeTo(0, VectorUtils.epsilon));
      expect(perp.dy, closeTo(3, VectorUtils.epsilon));
    });

    test('perpendicular of vertical vector', () {
      final vec = Offset(0, 4);
      final perp = VectorUtils.perpendicular(vec);
      expect(perp.dx, closeTo(-4, VectorUtils.epsilon));
      expect(perp.dy, closeTo(0, VectorUtils.epsilon));
    });

    test('perpendicular of diagonal vector', () {
      final vec = Offset(3, 4);
      final perp = VectorUtils.perpendicular(vec);
      expect(perp.dx, closeTo(-4, VectorUtils.epsilon));
      expect(perp.dy, closeTo(3, VectorUtils.epsilon));

      // Verify perpendicularity using dot product
      final dot = VectorUtils.dotProduct(vec, perp);
      expect(dot, closeTo(0, VectorUtils.epsilon));
    });

    test('perpendicular of zero vector', () {
      final vec = Offset.zero;
      final perp = VectorUtils.perpendicular(vec);
      expect(perp, equals(Offset.zero));
    });
  });

  group('VectorUtils - Cross Product', () {
    test('cross product of perpendicular vectors', () {
      final a = Offset(1, 0);
      final b = Offset(0, 1);
      final cross = VectorUtils.crossProduct(a, b);
      expect(cross, closeTo(1.0, VectorUtils.epsilon));
    });

    test('cross product of parallel vectors is zero', () {
      final a = Offset(2, 4);
      final b = Offset(1, 2); // Parallel to a
      final cross = VectorUtils.crossProduct(a, b);
      expect(cross, closeTo(0.0, VectorUtils.epsilon));
    });

    test('cross product changes sign with order', () {
      final a = Offset(3, 1);
      final b = Offset(1, 2);
      final cross1 = VectorUtils.crossProduct(a, b);
      final cross2 = VectorUtils.crossProduct(b, a);
      expect(cross1, closeTo(-cross2, VectorUtils.epsilon));
    });

    test('cross product for counter-clockwise rotation is positive', () {
      final a = Offset(1, 0);
      final b = Offset(1, 1); // Counter-clockwise from a
      final cross = VectorUtils.crossProduct(a, b);
      expect(cross, greaterThan(0));
    });

    test('cross product for clockwise rotation is negative', () {
      final a = Offset(1, 0);
      final b = Offset(1, -1); // Clockwise from a
      final cross = VectorUtils.crossProduct(a, b);
      expect(cross, lessThan(0));
    });
  });

  group('VectorUtils - Line Intersection', () {
    test('intersecting lines at right angles', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(2, 2);
      final p3 = Offset(0, 2);
      final p4 = Offset(2, 0);
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);

      expect(intersection, isNotNull);
      expect(intersection!.dx, closeTo(1.0, VectorUtils.epsilon));
      expect(intersection.dy, closeTo(1.0, VectorUtils.epsilon));
    });

    test('parallel lines do not intersect', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(2, 0);
      final p3 = Offset(0, 1);
      final p4 = Offset(2, 1);
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);

      expect(intersection, isNull);
    });

    test('collinear segments do not intersect', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(2, 0);
      final p3 = Offset(3, 0);
      final p4 = Offset(5, 0);
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);

      expect(intersection, isNull);
    });

    test(
        'non-intersecting segments (lines would intersect but segments don\'t)',
        () {
      final p1 = Offset(0, 0);
      final p2 = Offset(1, 1);
      final p3 = Offset(2, 0);
      final p4 = Offset(3, 1);
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);

      expect(intersection, isNull);
    });

    test('T-intersection (endpoint touching)', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(2, 0);
      final p3 = Offset(1, -1);
      final p4 = Offset(1, 0);
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);

      expect(intersection, isNotNull);
      expect(intersection!.dx, closeTo(1.0, VectorUtils.epsilon));
      expect(intersection.dy, closeTo(0.0, VectorUtils.epsilon));
    });

    test('intersection at segment endpoints', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(1, 1);
      final p3 = Offset(1, 1);
      final p4 = Offset(2, 0);
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);

      expect(intersection, isNotNull);
      expect(intersection!.dx, closeTo(1.0, VectorUtils.epsilon));
      expect(intersection.dy, closeTo(1.0, VectorUtils.epsilon));
    });

    test('vertical and horizontal lines intersection', () {
      final p1 = Offset(5, 0);
      final p2 = Offset(5, 10);
      final p3 = Offset(0, 5);
      final p4 = Offset(10, 5);
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);

      expect(intersection, isNotNull);
      expect(intersection!.dx, closeTo(5.0, VectorUtils.epsilon));
      expect(intersection.dy, closeTo(5.0, VectorUtils.epsilon));
    });
  });

  group('VectorUtils - Normalize', () {
    test('normalize horizontal vector', () {
      final vec = Offset(5, 0);
      final normalized = VectorUtils.normalize(vec);
      expect(normalized.dx, closeTo(1.0, VectorUtils.epsilon));
      expect(normalized.dy, closeTo(0.0, VectorUtils.epsilon));
      expect(normalized.distance, closeTo(1.0, VectorUtils.epsilon));
    });

    test('normalize diagonal vector', () {
      final vec = Offset(3, 4);
      final normalized = VectorUtils.normalize(vec);
      expect(normalized.dx, closeTo(0.6, VectorUtils.epsilon));
      expect(normalized.dy, closeTo(0.8, VectorUtils.epsilon));
      expect(normalized.distance, closeTo(1.0, VectorUtils.epsilon));
    });

    test('normalize zero vector returns zero', () {
      final vec = Offset.zero;
      final normalized = VectorUtils.normalize(vec);
      expect(normalized, equals(Offset.zero));
    });

    test('normalize very small vector returns zero', () {
      final vec = Offset(1e-10, 1e-10);
      final normalized = VectorUtils.normalize(vec);
      expect(normalized, equals(Offset.zero));
    });
  });

  group('VectorUtils - Dot Product', () {
    test('dot product of perpendicular vectors is zero', () {
      final a = Offset(1, 0);
      final b = Offset(0, 1);
      final dot = VectorUtils.dotProduct(a, b);
      expect(dot, closeTo(0.0, VectorUtils.epsilon));
    });

    test('dot product of parallel vectors', () {
      final a = Offset(2, 3);
      final b = Offset(4, 6);
      final dot = VectorUtils.dotProduct(a, b);
      expect(dot, closeTo(26.0, VectorUtils.epsilon)); // 2*4 + 3*6 = 26
    });

    test('dot product is commutative', () {
      final a = Offset(3, 4);
      final b = Offset(5, 6);
      final dot1 = VectorUtils.dotProduct(a, b);
      final dot2 = VectorUtils.dotProduct(b, a);
      expect(dot1, closeTo(dot2, VectorUtils.epsilon));
    });
  });

  group('VectorUtils - Distance to Line Segment', () {
    test('distance to horizontal line segment', () {
      final p = Offset(1, 1);
      final lineStart = Offset(0, 0);
      final lineEnd = Offset(2, 0);
      final distance = VectorUtils.distanceToLineSegment(p, lineStart, lineEnd);
      expect(distance, closeTo(1.0, VectorUtils.epsilon));
    });

    test('distance to point on line segment is zero', () {
      final p = Offset(1, 0);
      final lineStart = Offset(0, 0);
      final lineEnd = Offset(2, 0);
      final distance = VectorUtils.distanceToLineSegment(p, lineStart, lineEnd);
      expect(distance, closeTo(0.0, VectorUtils.epsilon));
    });

    test('distance to line segment endpoint', () {
      final p = Offset(3, 1);
      final lineStart = Offset(0, 0);
      final lineEnd = Offset(2, 0);
      final distance = VectorUtils.distanceToLineSegment(p, lineStart, lineEnd);
      final expectedDistance = sqrt(2); // Distance from (3,1) to (2,0)
      expect(distance, closeTo(expectedDistance, VectorUtils.epsilon));
    });

    test('distance to zero-length line segment', () {
      final p = Offset(3, 4);
      final lineStart = Offset(0, 0);
      final lineEnd = Offset(0, 0);
      final distance = VectorUtils.distanceToLineSegment(p, lineStart, lineEnd);
      expect(distance, closeTo(5.0, VectorUtils.epsilon)); // Distance to point
    });
  });

  group('VectorUtils - Are Parallel', () {
    test('horizontal lines are parallel', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(2, 0);
      final p3 = Offset(0, 1);
      final p4 = Offset(3, 1);
      expect(VectorUtils.areParallel(p1, p2, p3, p4), isTrue);
    });

    test('perpendicular lines are not parallel', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(1, 0);
      final p3 = Offset(0, 0);
      final p4 = Offset(0, 1);
      expect(VectorUtils.areParallel(p1, p2, p3, p4), isFalse);
    });

    test('diagonal parallel lines', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(1, 1);
      final p3 = Offset(0, 1);
      final p4 = Offset(1, 2);
      expect(VectorUtils.areParallel(p1, p2, p3, p4), isTrue);
    });
  });

  group('VectorUtils - Angle', () {
    test('angle of horizontal vector is zero', () {
      final vec = Offset(1, 0);
      final angle = VectorUtils.angle(vec);
      expect(angle, closeTo(0.0, VectorUtils.epsilon));
    });

    test('angle of vertical vector is pi/2', () {
      final vec = Offset(0, 1);
      final angle = VectorUtils.angle(vec);
      expect(angle, closeTo(pi / 2, VectorUtils.epsilon));
    });

    test('angle of 45-degree vector', () {
      final vec = Offset(1, 1);
      final angle = VectorUtils.angle(vec);
      expect(angle, closeTo(pi / 4, VectorUtils.epsilon));
    });

    test('angle of negative x vector is pi', () {
      final vec = Offset(-1, 0);
      final angle = VectorUtils.angle(vec);
      expect(angle.abs(), closeTo(pi, VectorUtils.epsilon));
    });
  });

  group('VectorUtils - Rotate', () {
    test('rotate horizontal vector by 90 degrees', () {
      final vec = Offset(1, 0);
      final rotated = VectorUtils.rotate(vec, pi / 2);
      expect(rotated.dx, closeTo(0.0, VectorUtils.epsilon));
      expect(rotated.dy, closeTo(1.0, VectorUtils.epsilon));
    });

    test('rotate by 180 degrees', () {
      final vec = Offset(1, 2);
      final rotated = VectorUtils.rotate(vec, pi);
      expect(rotated.dx, closeTo(-1.0, VectorUtils.epsilon));
      expect(rotated.dy, closeTo(-2.0, VectorUtils.epsilon));
    });

    test('rotate by 360 degrees returns original', () {
      final vec = Offset(3, 4);
      final rotated = VectorUtils.rotate(vec, 2 * pi);
      expect(rotated.dx, closeTo(3.0, VectorUtils.epsilon));
      expect(rotated.dy, closeTo(4.0, VectorUtils.epsilon));
    });

    test('rotate maintains length', () {
      final vec = Offset(3, 4);
      final originalLength = vec.distance;
      final rotated = VectorUtils.rotate(vec, pi / 3);
      final rotatedLength = rotated.distance;
      expect(rotatedLength, closeTo(originalLength, VectorUtils.epsilon));
    });
  });

  group('VectorUtils - Lerp', () {
    test('lerp at t=0 returns start', () {
      final start = Offset(0, 0);
      final end = Offset(10, 10);
      final result = VectorUtils.lerp(start, end, 0.0);
      expect(result, equals(start));
    });

    test('lerp at t=1 returns end', () {
      final start = Offset(0, 0);
      final end = Offset(10, 10);
      final result = VectorUtils.lerp(start, end, 1.0);
      expect(result, equals(end));
    });

    test('lerp at t=0.5 returns midpoint', () {
      final start = Offset(0, 0);
      final end = Offset(10, 10);
      final result = VectorUtils.lerp(start, end, 0.5);
      expect(result.dx, closeTo(5.0, VectorUtils.epsilon));
      expect(result.dy, closeTo(5.0, VectorUtils.epsilon));
    });

    test('lerp at arbitrary t', () {
      final start = Offset(0, 0);
      final end = Offset(10, 20);
      final result = VectorUtils.lerp(start, end, 0.3);
      expect(result.dx, closeTo(3.0, VectorUtils.epsilon));
      expect(result.dy, closeTo(6.0, VectorUtils.epsilon));
    });
  });

  group('VectorUtils - Edge Cases', () {
    test('operations with very large values', () {
      final large = Offset(1e9, 1e9);
      final perp = VectorUtils.perpendicular(large);
      expect(perp.dx, closeTo(-1e9, 1e-3)); // Relaxed epsilon for large values
      expect(perp.dy, closeTo(1e9, 1e-3));
    });

    test('operations with very small values', () {
      final small = Offset(1e-5, 1e-5);
      final perp = VectorUtils.perpendicular(small);
      expect(perp.dx, closeTo(-1e-5, VectorUtils.epsilon));
      expect(perp.dy, closeTo(1e-5, VectorUtils.epsilon));
    });

    test('intersection with nearly parallel lines', () {
      final p1 = Offset(0, 0);
      final p2 = Offset(10, 0);
      final p3 = Offset(0, 0.0000001);
      final p4 = Offset(10, 0.0000001);

      // These are nearly parallel and should be treated as parallel
      final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4);
      expect(intersection, isNull);
    });
  });
}

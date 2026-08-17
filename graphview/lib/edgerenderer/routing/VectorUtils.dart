part of graphview;

/// Utility class for vector mathematics operations used in edge routing.
///
/// This class provides static methods for common vector operations including
/// perpendicular vector calculation, cross products, and line intersection detection.
class VectorUtils {
  /// Epsilon value for floating-point comparisons to handle precision issues.
  static const double epsilon = 1e-6;

  /// Returns a perpendicular vector (90-degree counter-clockwise rotation).
  ///
  /// Given a vector (dx, dy), returns (-dy, dx) which is perpendicular.
  /// This is useful for calculating edge repulsion forces and offsetting paths.
  ///
  /// Example:
  /// ```dart
  /// final vec = Offset(3, 4);
  /// final perp = VectorUtils.perpendicular(vec); // Offset(-4, 3)
  /// ```
  static Offset perpendicular(Offset offset) {
    return Offset(-offset.dy, offset.dx);
  }

  /// Calculates the 2D cross product of two vectors.
  ///
  /// The cross product is defined as: a.dx * b.dy - a.dy * b.dx
  /// This is useful for determining if two vectors point in similar directions
  /// and for calculating the signed area of triangles.
  ///
  /// Returns:
  /// - Positive value if b is counter-clockwise from a
  /// - Negative value if b is clockwise from a
  /// - Zero if vectors are parallel (collinear)
  ///
  /// Example:
  /// ```dart
  /// final a = Offset(1, 0);
  /// final b = Offset(0, 1);
  /// final cross = VectorUtils.crossProduct(a, b); // 1.0 (counter-clockwise)
  /// ```
  static double crossProduct(Offset a, Offset b) {
    return a.dx * b.dy - a.dy * b.dx;
  }

  /// Normalizes a vector to unit length.
  ///
  /// Returns a vector with the same direction but length 1.0.
  /// If the input vector has zero length, returns Offset.zero.
  ///
  /// Example:
  /// ```dart
  /// final vec = Offset(3, 4);
  /// final normalized = VectorUtils.normalize(vec); // Offset(0.6, 0.8)
  /// ```
  static Offset normalize(Offset offset) {
    final length = offset.distance;
    if (length < epsilon) {
      return Offset.zero;
    }
    return Offset(offset.dx / length, offset.dy / length);
  }

  /// Calculates the dot product of two vectors.
  ///
  /// The dot product is defined as: a.dx * b.dx + a.dy * b.dy
  /// This is useful for determining the angle between vectors and
  /// for projecting one vector onto another.
  ///
  /// Example:
  /// ```dart
  /// final a = Offset(1, 0);
  /// final b = Offset(0, 1);
  /// final dot = VectorUtils.dotProduct(a, b); // 0.0 (perpendicular)
  /// ```
  static double dotProduct(Offset a, Offset b) {
    return a.dx * b.dx + a.dy * b.dy;
  }

  /// Finds the intersection point of two line segments.
  ///
  /// Uses parametric line equations to find if and where two line segments intersect.
  /// Line 1 is defined by points p1 and p2.
  /// Line 2 is defined by points p3 and p4.
  ///
  /// Returns:
  /// - The intersection point if the segments intersect
  /// - null if the segments are parallel, collinear, or don't intersect
  ///
  /// The algorithm uses parametric equations:
  /// - Line 1: P = p1 + t * (p2 - p1), where t ∈ [0, 1]
  /// - Line 2: Q = p3 + u * (p4 - p3), where u ∈ [0, 1]
  ///
  /// Example:
  /// ```dart
  /// final p1 = Offset(0, 0);
  /// final p2 = Offset(2, 2);
  /// final p3 = Offset(0, 2);
  /// final p4 = Offset(2, 0);
  /// final intersection = VectorUtils.lineIntersection(p1, p2, p3, p4); // Offset(1, 1)
  /// ```
  static Offset? lineIntersection(Offset p1, Offset p2, Offset p3, Offset p4) {
    // Direction vectors
    final d1 = p2 - p1; // Direction of line 1
    final d2 = p4 - p3; // Direction of line 2

    // Calculate the cross product to check if lines are parallel
    final cross = crossProduct(d1, d2);

    // If cross product is near zero, lines are parallel or collinear
    if (cross.abs() < epsilon) {
      return null;
    }

    // Vector from line 1 start to line 2 start
    final diff = p3 - p1;

    // Calculate parameters t and u using parametric equations
    // t = (diff × d2) / (d1 × d2)
    // u = (diff × d1) / (d1 × d2)
    final t = crossProduct(diff, d2) / cross;
    final u = crossProduct(diff, d1) / cross;

    // Check if intersection is within both line segments [0, 1]
    if (t >= 0.0 && t <= 1.0 && u >= 0.0 && u <= 1.0) {
      // Calculate intersection point using parameter t
      return p1 + Offset(d1.dx * t, d1.dy * t);
    }

    // Segments don't intersect within their bounds
    return null;
  }

  /// Calculates the shortest distance from a point to a line segment.
  ///
  /// Returns the perpendicular distance from point p to the line segment
  /// defined by points lineStart and lineEnd.
  ///
  /// Example:
  /// ```dart
  /// final p = Offset(1, 1);
  /// final lineStart = Offset(0, 0);
  /// final lineEnd = Offset(2, 0);
  /// final distance = VectorUtils.distanceToLineSegment(p, lineStart, lineEnd); // 1.0
  /// ```
  static double distanceToLineSegment(
      Offset p, Offset lineStart, Offset lineEnd) {
    final lineVec = lineEnd - lineStart;
    final lineLength = lineVec.distance;

    // If the line segment has zero length, return distance to the point
    if (lineLength < epsilon) {
      return (p - lineStart).distance;
    }

    // Calculate projection parameter t
    // t represents where the perpendicular from p intersects the line
    final t = dotProduct(p - lineStart, lineVec) / (lineLength * lineLength);

    // Clamp t to [0, 1] to stay within the line segment
    final tClamped = t.clamp(0.0, 1.0);

    // Calculate the closest point on the line segment
    final closestPoint = lineStart +
        Offset(
          lineVec.dx * tClamped,
          lineVec.dy * tClamped,
        );

    // Return distance from p to the closest point
    return (p - closestPoint).distance;
  }

  /// Checks if two line segments are parallel (within epsilon tolerance).
  ///
  /// Two line segments are considered parallel if the cross product of their
  /// direction vectors is near zero.
  ///
  /// Example:
  /// ```dart
  /// final p1 = Offset(0, 0);
  /// final p2 = Offset(1, 0);
  /// final p3 = Offset(0, 1);
  /// final p4 = Offset(1, 1);
  /// final parallel = VectorUtils.areParallel(p1, p2, p3, p4); // true
  /// ```
  static bool areParallel(Offset p1, Offset p2, Offset p3, Offset p4) {
    final d1 = p2 - p1;
    final d2 = p4 - p3;
    return crossProduct(d1, d2).abs() < epsilon;
  }

  /// Calculates the angle (in radians) of a vector relative to the positive x-axis.
  ///
  /// Returns a value in the range [-π, π].
  ///
  /// Example:
  /// ```dart
  /// final vec = Offset(1, 1);
  /// final angle = VectorUtils.angle(vec); // π/4 (45 degrees)
  /// ```
  static double angle(Offset offset) {
    return atan2(offset.dy, offset.dx);
  }

  /// Rotates a vector by the given angle (in radians).
  ///
  /// Positive angles rotate counter-clockwise.
  ///
  /// Example:
  /// ```dart
  /// final vec = Offset(1, 0);
  /// final rotated = VectorUtils.rotate(vec, pi / 2); // Offset(0, 1)
  /// ```
  static Offset rotate(Offset offset, double angleRadians) {
    final cosTheta = cos(angleRadians);
    final sinTheta = sin(angleRadians);
    return Offset(
      offset.dx * cosTheta - offset.dy * sinTheta,
      offset.dx * sinTheta + offset.dy * cosTheta,
    );
  }

  /// Linearly interpolates between two points.
  ///
  /// Returns a point that is t fraction of the way from start to end.
  /// t = 0.0 returns start, t = 1.0 returns end.
  ///
  /// Example:
  /// ```dart
  /// final start = Offset(0, 0);
  /// final end = Offset(10, 10);
  /// final mid = VectorUtils.lerp(start, end, 0.5); // Offset(5, 5)
  /// ```
  static Offset lerp(Offset start, Offset end, double t) {
    return start + (end - start) * t;
  }
}

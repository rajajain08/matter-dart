import 'dart:math' as math;

import 'vector.dart';
// import 'vertices.dart';

/// [Axes] contains methods to create and manipulate the sets of axes.
abstract class Axes {
  /// Creates a new set of axes from the given vertices.
  static List<Vector> fromVertices(List<Vector> vertices) {
    Map<String, Vector> gradientMap = {};

    // Find the unique axes, using edge normal gradients
    for (var i = 0; i < vertices.length; i++) {
      final j = (i + 1) % vertices.length;

      // Normalise the vector created from the two vertices.
      final normalised = Vector(vertices[j].y - vertices[i].y, vertices[i].x - vertices[j].x).normalise();
      final gradient = (normalised.y == 0) ? double.infinity : (normalised.x / normalised.y);
      gradientMap[gradient.toStringAsFixed(3)] = normalised;
    }

    return gradientMap.values.toList();
  }

  /// Rotates the given list of axes by the given angle.
  ///
  /// Note: Mutates the argument list directly.
  static void rotate(List<Vector> axes, double angle) {
    if (angle == 0) return;

    final cos = math.cos(angle);
    final sin = math.sin(angle);

    for (var i = 0; i < axes.length; i++) {
      axes[i].x = cos * axes[i].x - sin * axes[i].y;
      axes[i].y = sin * axes[i].x + cos * axes[i].y;
    }
  }
}

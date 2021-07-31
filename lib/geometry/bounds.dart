import 'dart:ui';

import 'vector.dart';
import 'vertices.dart';

/// [Bound] contains methods for creating and manipulating Axis-Aligned Bouding Boxes (AABB).
class Bounds {
  Bounds({this.min = Offset.zero, this.max = Offset.zero});

  /// Create bounds from vertices.
  factory Bounds.fromVertices(List<Vertex> vertices) {
    final bounds = Bounds();
    bounds.update(vertices);
    return bounds;
  }

  Offset min;
  Offset max;

  /// Updates bounds using the given vertices, and extend the bounds if given a velocity.
  void update(List<Vertex> vertices, [Vector? velocity]) {
    this.min = Offset.infinite;
    this.max = Offset.infinite;

    vertices.forEach((vertex) {
      if (vertex.x > max.dx) max = Offset(vertex.x, max.dy);
      if (vertex.x < min.dx) min = Offset(vertex.x, min.dy);
      if (vertex.y > max.dy) max = Offset(max.dx, vertex.y);
      if (vertex.y < min.dy) min = Offset(min.dx, vertex.y);
    });

    if (velocity != null) {
      if (velocity.x > 0) {
        max = max.translate(velocity.x, 0);
      } else {
        min = min.translate(velocity.x, 0);
      }

      if (velocity.y > 0) {
        max = max.translate(0, velocity.y);
      } else {
        min = min.translate(0, velocity.y);
      }
    }
  }

  /// Returns true if the given point is inside the bounds.
  bool contains(Vector point) {
    return point.x >= this.min.dx && point.x <= this.max.dx && point.y >= this.min.dy && point.y <= this.max.dy;
  }

  /// Returns true if this bound overlaps with other bound.
  bool overlaps(Bounds other) {
    return this.min.dx <= other.max.dx &&
        this.max.dx >= other.min.dx &&
        this.min.dy <= other.max.dy &&
        this.max.dy >= other.min.dy;
  }

  /// Translate the bounds by the given vector.
  void translate(Vector vector) {
    this.min = this.min.translate(vector.x, vector.y);
    this.max = this.max.translate(vector.x, vector.y);
  }

  /// Shifts the bounds to given position.
  void shift(Vector position) {
    final deltaX = this.max.dx - this.min.dx;
    final deltaY = this.max.dy - this.min.dy;

    this.min = Offset(position.x, position.y);
    this.max = Offset(position.x + deltaX, position.y + deltaY);
  }
}

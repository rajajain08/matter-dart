import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/body/support/models.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

/// Factory methods for common rigid body shapes.
///
/// Each public method delegates vertex generation to a dedicated helper and
/// shares finalization (label, position, chamfer, build) via [_finalize] —
/// keeping shape construction and body assembly cleanly separated.
class Bodies {
  static Body rectangle(
    double x,
    double y,
    double width,
    double height,
    BodyOptions? options,
  ) {
    final vertices = _rectangleVertices(width, height);
    return _finalize(x, y, vertices, 'Rectangle Body', options);
  }

  static Body trapezoid(
    double x,
    double y,
    double width,
    double height,
    double slope,
    BodyOptions? options,
  ) {
    final vertices = _trapezoidVertices(width, height, slope);
    return _finalize(x, y, vertices, 'Trapezoid Body', options);
  }

  /// Regular n-sided polygon inscribed in a circle of [radius].
  ///
  /// [sides] < 3 falls back to [circle] for a smooth approximation.
  static Body polygon(
    double x,
    double y,
    int sides,
    double radius,
    BodyOptions? options,
  ) {
    if (sides < 3) {
      return circle(x, y, radius, options);
    }
    final vertices = _polygonVertices(sides, radius);
    return _finalize(x, y, vertices, 'Polygon Body', options);
  }

  /// Circle approximated as a polygon with side count scaled to [radius].
  ///
  /// [maxSides] caps the polygon's resolution; the chosen count never exceeds
  /// `min(radius / 2.5, maxSides)` and is at least 3.
  static Body circle(
    double x,
    double y,
    double radius,
    BodyOptions? options, {
    int maxSides = 25,
  }) {
    options = options ?? BodyOptions();
    int sides = math.max(3, math.min(maxSides, (radius / 2.5).ceil()));
    if (sides.isOdd) sides += 1;

    options.circleRadius = radius;
    final vertices = _polygonVertices(sides, radius);
    return _finalize(x, y, vertices, 'Circle Body', options);
  }

  // --- vertex generators ---------------------------------------------------

  static List<Vertex> _rectangleVertices(double width, double height) {
    return [
      Vertex(x: 0, y: 0, index: 0),
      Vertex(x: width, y: 0, index: 1),
      Vertex(x: width, y: height, index: 2),
      Vertex(x: 0, y: height, index: 3),
    ];
  }

  static List<Vertex> _trapezoidVertices(double width, double height, double slope) {
    slope = slope * 0.5;
    final double roof = (1 - (slope * 2)) * width;
    final double x1 = width * slope;
    final double x2 = x1 + roof;
    final double x3 = x2 + x1;

    if (slope < 0.5) {
      return [
        Vertex(index: 0, x: 0, y: 0),
        Vertex(index: 1, x: x1, y: -height),
        Vertex(index: 2, x: x2, y: -height),
        Vertex(index: 3, x: x3, y: 0),
      ];
    }
    return [
      Vertex(index: 0, x: 0, y: 0),
      Vertex(index: 1, x: x2, y: -height),
      Vertex(index: 2, x: x3, y: 0),
    ];
  }

  static List<Vertex> _polygonVertices(int sides, double radius) {
    final double theta = 2 * math.pi / sides;
    final double offset = theta * 0.5;
    final List<Vertex> vertices = List.generate(sides, (i) {
      final double angle = offset + i * theta;
      return Vertex(
        index: i,
        x: math.cos(angle) * radius,
        y: math.sin(angle) * radius,
      );
    });
    return vertices;
  }

  // --- shared finalization -------------------------------------------------

  static Body _finalize(
    double x,
    double y,
    List<Vertex> vertices,
    String label,
    BodyOptions? options,
  ) {
    options = options ?? BodyOptions();
    options.label = label;
    options.position = Vector(x, y);
    options.vertices = _applyChamfer(vertices, options.chamfer);
    return Body.create(options);
  }

  static List<Vertex> _applyChamfer(List<Vertex> vertices, ChamferOptions? chamfer) {
    if (chamfer == null) return vertices;
    return Vertices.chamfer(
      vertices,
      radius: chamfer.radius ?? [8],
      quality: chamfer.quality ?? -1,
      qualityMin: chamfer.qualityMin ?? 2,
      qualityMax: chamfer.qualityMax ?? 14,
    );
  }
}

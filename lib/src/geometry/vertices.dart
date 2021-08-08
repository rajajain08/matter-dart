import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/utils/common.dart';

import 'vector.dart';

class Vertices {
  final List<Vector> points;
  final Body body;
  List<Vertex>? vertices;

  Vertices(this.points, this.body);

  void create() {
    vertices = <Vertex>[];
    for (var i = 0; i < points.length; i++) {
      var point = points[i];
      var vertex = Vertex(x: point.x, y: point.y, i: i, body: body, isInternal: false);

      vertices!.add(vertex);
    }
  }

  static Vector centre(List<Vertex> vertices) {
    var area = Vertices.area(vertices, true);
    Vector centre = Vector(0, 0);
    double cross;
    Vector temp;
    int j;

    for (var i = 0; i < vertices.length; i++) {
      j = (i + 1) % vertices.length;
      cross = Vector.cross(vertices[i], vertices[j]);
      temp = Vector.mult(Vector.add(vertices[i], vertices[j]), cross);
      centre = Vector.add(centre, temp);
    }

    return Vector.div(centre, 6 * area);
  }

  Vector mean(List<Vertex> vertices) {
    double x = 0;
    double y = 0;

    for (var i = 0; i < vertices.length; i++) {
      x += vertices[i].x;
      y += vertices[i].y;
    }

    return Vector.div(Vector(x, y), vertices.length.toDouble());
  }

  static double area(List<Vertex> vertices, bool signed) {
    double area = 0;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i++) {
      area += (vertices[j].x - vertices[i].x) * (vertices[j].y + vertices[i].y);
      j = i;
    }
    if (signed) return area / 2;

    return ((area) / 2).abs();
  }

  static double inertia(List<Vertex> vertices, double mass) {
    double numerator = 0;
    double denominator = 0;
    double cross;
    int j;
    for (var n = 0; n < vertices.length; n++) {
      j = (n + 1) % vertices.length;
      Vector vectorJ = Vector(vertices[j].x, vertices[j].y);
      Vector vectorN = Vector(vertices[n].x, vertices[n].y);
      cross = (Vector.cross(vectorJ, vectorN)).abs();
      numerator += cross * (Vector.dot(vectorJ, vectorJ) + Vector.dot(vectorJ, vectorN) + Vector.dot(vectorN, vectorN));
      denominator += cross;
    }

    return (mass / 6) * (numerator / denominator);
  }

  static List<Vertex> translate(List<Vertex> vertices, Vector vector, double? scalar) {
    int i;
    if (scalar != null) {
      for (i = 0; i < vertices.length; i++) {
        vertices[i].x += vector.x * scalar;
        vertices[i].y += vector.y * scalar;
      }
    } else {
      for (i = 0; i < vertices.length; i++) {
        vertices[i].x += vector.x;
        vertices[i].y += vector.y;
      }
    }

    return vertices;
  }

  static List<Vertex> rotate(List<Vertex> vertices, double angle, Vector point) {
    if (angle == 0) return vertices;
    double cos = math.cos(angle), sin = math.sin(angle);

    for (int i = 0; i < vertices.length; i++) {
      Vertex vertice = vertices[i];
      double dx = vertice.x - point.x, dy = vertice.y - point.y;

      vertice.x = point.x + (dx * cos - dy * sin);
      vertice.y = point.y + (dx * sin + dy * cos);
      vertices[i] = vertice;
    }

    return vertices;
  }

  static bool contains(List<Vertex> vertices, Vector point) {
    for (var i = 0; i < vertices.length; i++) {
      Vertex vertice = vertices[i], nextVertice = vertices[(i + 1) % vertices.length];
      if ((point.x - vertice.x) * (nextVertice.y - vertice.y) + (point.y - vertice.y) * (vertice.x - nextVertice.x) >
          0) {
        return false;
      }
    }

    return true;
  }

  static List<Vertex> scale(List<Vertex> vertices, double scaleX, double scaleY, Vector? point) {
    if (scaleX == 1 && scaleY == 1) return vertices;
    if (point == null) {
      point = Vertices.centre(vertices);
    }

    var vertex, delta;

    for (var i = 0; i < vertices.length; i++) {
      vertex = vertices[i];
      delta = Vector.sub(vertex, point);
      vertices[i].x = point.x + delta.x * scaleX;
      vertices[i].y = point.y + delta.y * scaleY;
    }

    return vertices;
  }

  List<Vertex> chamfer(
    List<Vertex> vertices, {
    List<double> radius = const [8],
    double quality = -1,
    double qualityMin = 2,
    double qualityMax = 14,
  }) {
    List<Vertex> newVertices = [];

    for (var i = 0; i < vertices.length; i++) {
      var prevVertex = vertices[i - 1 >= 0 ? i - 1 : vertices.length - 1],
          vertex = vertices[i],
          nextVertex = vertices[(i + 1) % vertices.length],
          currentRadius = radius[i < radius.length ? i : radius.length - 1];

      if (currentRadius == 0) {
        newVertices.add(vertex);
        continue;
      }

      var prevNormal = Vector(vertex.y - prevVertex.y, prevVertex.x - vertex.x).normalise();
      // x: nextVertex.y - vertex.y,
      // y: vertex.x - nextVertex.x,
      var nextNormal = Vector(nextVertex.y - vertex.y, vertex.x - nextVertex.x);

      var diagonalRadius = math.sqrt(2 * math.pow(currentRadius, 2)),
          radiusVector = Vector.mult(prevNormal, currentRadius),
          midNormal = Vector.mult(Vector.add(prevNormal, nextNormal), 0.5).normalise(),
          scaledVertex = Vector.sub(vertex, Vector.mult(midNormal, diagonalRadius));

      var precision = quality;

      if (quality == -1) {
        // automatically decide precision
        precision = math.pow(currentRadius, 0.32) * 1.75;
      }

      precision = Common.clamp(precision, qualityMin, qualityMax);

      // use an even value for precision, more likely to reduce axes by using symmetry
      if (precision % 2 == 1) precision += 1;

      var alpha = math.acos(Vector.dot(prevNormal, nextNormal)), theta = alpha / precision;

      for (var j = 0; j < precision; j++) {
        Vector newVector = Vector.add(radiusVector.rotateVactor(theta * j), scaledVertex);

        Vertex newVerticesFromVector = Vertex(x: newVector.x, y: newVector.y, body: body, i: j);

        newVertices.add(newVerticesFromVector);
      }
    }

    return newVertices;
  }

  List<Vertex> clockwiseSort(List<Vertex> vertices) {
    var centre = mean(vertices);

    vertices.sort((vertexA, vertexB) {
      return (Vector.angle(centre, vertexA) - Vector.angle(centre, vertexB)).toInt();
    });

    return vertices;
  }

  bool? isConvex(List<Vertex> vertices) {
    // http://paulbourke.net/geometry/polygonmesh/
    // Copyright (c) Paul Bourke (use permitted)

    var flag = 0, n = vertices.length, i, j, k, z;

    if (n < 3) return null;

    for (i = 0; i < n; i++) {
      j = (i + 1) % n;
      k = (i + 2) % n;
      z = (vertices[j].x - vertices[i].x) * (vertices[k].y - vertices[j].y);
      z -= (vertices[j].y - vertices[i].y) * (vertices[k].x - vertices[j].x);

      if (z < 0) {
        flag |= 1;
      } else if (z > 0) {
        flag |= 2;
      }

      if (flag == 3) {
        return false;
      }
    }

    if (flag != 0) {
      return true;
    } else {
      return null;
    }
  }

  List<Vertex> hull(List<Vertex> vertices) {
    // http://geomalgorithms.com/a10-_hull-1.html

    var upper = <Vertex>[], lower = <Vertex>[];
    Vertex? vertex;

    // sort vertices on x-axis (y-axis for ties)
    vertices = vertices.sublist(0);
    vertices.sort((vertexA, vertexB) {
      var dx = vertexA.x - vertexB.x;
      return (dx != 0 ? dx : vertexA.y - vertexB.y).toInt();
    });

    // build lower hull
    for (var i = 0; i < vertices.length; i += 1) {
      vertex = vertices[i];

      while (lower.length >= 2 && Vector.cross3(lower[lower.length - 2], lower[lower.length - 1], vertex) <= 0) {
        lower.removeLast();
      }

      lower.add(vertex);
    }

    // build upper hull
    for (var i = vertices.length - 1; i >= 0; i -= 1) {
      vertex = vertices[i];

      while (upper.length >= 2 && Vector.cross3(upper[upper.length - 2], upper[upper.length - 1], vertex) <= 0) {
        upper.removeLast();
      }

      upper.add(vertex);
    }

    // concatenation of the lower and upper hulls gives the convex hull
    // omit last points because they are repeated at the beginning of the other list
    upper.removeLast();
    lower.removeLast();
    upper.addAll(lower);
    return upper;
  }
}

class Vertex extends Vector {
  final int i;
  final Body body;
  final bool isInternal;

  Vertex({
    required double x,
    required double y,
    required this.i,
    required this.body,
    this.isInternal = false,
  }) : super(x, y);

  // Vector toVector() {
  //   return Vector(x, y);
  // }
}

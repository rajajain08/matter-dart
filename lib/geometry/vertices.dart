import 'dart:math' as math;

import 'vector.dart';

class Vertices {
  final List<Vertex> vertices;

  Vertices(this.vertices);

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
      numerator += cross *
          (Vector.dot(vectorJ, vectorJ) +
              Vector.dot(vectorJ, vectorN) +
              Vector.dot(vectorN, vectorN));
      denominator += cross;
    }

    return (mass / 6) * (numerator / denominator);
  }

  static Vertices translate(Vertices vertices, Vector vector, double scalar) {
    int i;
    if (scalar != null) {
      for (i = 0; i < vertices.vertices.length; i++) {
        vertices.vertices[i].x += vector.x * scalar;
        vertices.vertices[i].y += vector.y * scalar;
      }
    } else {
      for (i = 0; i < vertices.vertices.length; i++) {
        vertices.vertices[i].x += vector.x;
        vertices.vertices[i].y += vector.y;
      }
    }

    return Vertices(vertices.vertices);
  }

  static Vertices rotate(Vertices vertices, double angle, Vector point) {
    if (angle == 0) return vertices;
    double cos = math.cos(angle), sin = math.sin(angle);

    for (int i = 0; i < vertices.vertices.length; i++) {
      Vertex vertice = vertices.vertices[i];
      double dx = vertice.x - point.x, dy = vertice.y - point.y;

      vertice.x = point.x + (dx * cos - dy * sin);
      vertice.y = point.y + (dx * sin + dy * cos);
      vertices.vertices[i] = vertice;
    }

    return vertices;
  }

  static bool contains(Vertices vertices, Vector point) {
    for (var i = 0; i < vertices.vertices.length; i++) {
      Vertex vertice = vertices.vertices[i],
          nextVertice = vertices.vertices[(i + 1) % vertices.vertices.length];
      if ((point.x - vertice.x) * (nextVertice.y - vertice.y) +
              (point.y - vertice.y) * (vertice.x - nextVertice.x) >
          0) {
        return false;
      }
    }

    return true;
  }

  static Vertices scale(
      Vertices vertices, double scaleX, double scaleY, Vector point) {
    if (scaleX == 1 && scaleY == 1) return vertices;
    // TODO
    // point = point || Vertices.centre(vertices);

    var vertex, delta;

    for (var i = 0; i < vertices.vertices.length; i++) {
      vertex = vertices.vertices[i];
      delta = Vector.sub(vertex, point);
      vertices.vertices[i].x = point.x + delta.x * scaleX;
      vertices.vertices[i].y = point.y + delta.y * scaleY;
    }

    return vertices;
  }
}

class Vertex {
  double x;
  double y;
  final int i;
  final dynamic body;
  final bool isInternal;

  Vertex({this.x, this.y, this.i, this.body, this.isInternal = false});
}

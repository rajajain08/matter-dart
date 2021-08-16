import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/collision/collision.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

/// SAT contains methods for detecting collisions using the Separating Axis Theorem.
/// TODO: true circles and curves
class SAT {
  /// Detect collision between two bodies using the Separating Axis Theorem.
  static Collision collides(Body bodyA, Body bodyB, [Collision? previousCollision]) {
    _OverlapResult? overlapAB, overlapBA, minOverlap;
    Collision collision;
    bool canReusePrevCollision = false;

    if (previousCollision != null) {
      // Estimate total motion.
      Body parentA = bodyA.parent!, parentB = bodyB.parent!;
      double motion = parentA.speed * parentA.speed +
          parentA.angularSpeed * parentA.angularSpeed +
          parentB.speed * parentB.speed +
          parentB.angularSpeed * parentB.angularSpeed;

      // We may be able to (partially) reuse collision result but only safe if collision was resting.
      canReusePrevCollision = previousCollision.collided && motion < 0.2;
      collision = previousCollision;
    } else {
      collision = Collision(collided: false, bodyA: bodyA, bodyB: bodyB);
    }

    if (previousCollision != null && canReusePrevCollision) {
      // We only need to test the previously found axis.
      Body axisBodyA = collision.axisBody!;
      // TODO (manuinder): Need to figure out the equality check here.
      Body axisBodyB = axisBodyA == bodyA ? bodyB : bodyA;
      List<Vector> axes = [axisBodyA.axes[previousCollision.axisNumber!]];

      minOverlap = SAT._overlapAxes(axisBodyA.vertices, axisBodyB.vertices, axes);
      collision.reused = true;

      if (minOverlap.overlap <= 0) {
        collision.collided = false;
        return collision;
      }
    }
    // If we can't reuse a result, perform a full SAT test
    else {
      overlapAB = SAT._overlapAxes(bodyA.vertices, bodyB.vertices, bodyA.axes);
      if (overlapAB.overlap <= 0) {
        collision.collided = false;
        return collision;
      }

      overlapBA = SAT._overlapAxes(bodyB.vertices, bodyA.vertices, bodyB.axes);
      if (overlapBA.overlap <= 0) {
        collision.collided = false;
        return collision;
      }

      if (overlapAB.overlap < overlapBA.overlap) {
        minOverlap = overlapAB;
        collision.axisBody = bodyA;
      } else {
        minOverlap = overlapBA;
        collision.axisBody = bodyB;
      }

      collision.axisNumber = minOverlap.axisNumber;
    }

    collision
      ..bodyA = bodyA.id < bodyB.id ? bodyA : bodyB
      ..bodyB = bodyA.id < bodyB.id ? bodyB : bodyA
      ..collided = true
      ..depth = minOverlap.overlap
      ..parentA = collision.bodyA.parent
      ..parentB = collision.bodyB.parent;

    bodyA = collision.bodyA;
    bodyB = collision.bodyB;

    // ensure normal is facing away from bodyA
    if (Vector.dot(minOverlap.axis!, Vector.sub(bodyB.position, bodyA.position)) < 0) {
      collision.normal = Vector(minOverlap.axis!.x, minOverlap.axis!.y);
    } else {
      collision.normal = Vector(-minOverlap.axis!.x, -minOverlap.axis!.y);
    }

    collision.tangent = Vector.perp(collision.normal!);

    collision.penetration = collision.penetration ?? Vector(0, 0);
    collision.penetration!.x = collision.normal!.x * collision.depth!;
    collision.penetration!.y = collision.normal!.y * collision.depth!;

    // find support points, there is always either exactly one or two
    List<Vertex> verticesB = SAT._findSupports(bodyA, bodyB, collision.normal!);
    List<Vector> supports = <Vector>[];

    // find the supports from bodyB that are inside bodyA
    if (Vertices.contains(bodyA.vertices, verticesB[0])) {
      supports.add(verticesB[0]);
    }
    if (Vertices.contains(bodyA.vertices, verticesB[1])) {
      supports.add(verticesB[1]);
    }

    // find the supports from bodyA that are inside bodyB
    if (supports.length < 2) {
      var verticesA = SAT._findSupports(bodyB, bodyA, Vector.neg(collision.normal!));

      if (Vertices.contains(bodyB.vertices, verticesA[0])) {
        supports.add(verticesA[0]);
      }
      if (supports.length < 2 && Vertices.contains(bodyB.vertices, verticesA[1])) {
        supports.add(verticesA[1]);
      }
    }

    // account for the edge case of overlapping but no vertex containment
    if (supports.length < 1) {
      supports = [verticesB[0]];
    }
    collision.supports = supports;
    return collision;
  }

  /// Find the overlap between two sets of vertices.
  static _OverlapResult _overlapAxes(List<Vertex> verticesA, List<Vertex> verticesB, List<Vector> axes) {
    _OverlapResult result = _OverlapResult();

    for (int index = 0; index < axes.length; index++) {
      Vector axis = axes[index];

      final projectionA = SAT._projectToAxis(verticesA, axis);
      final projectionB = SAT._projectToAxis(verticesB, axis);
      final double overlap = math.min(projectionA.max - projectionB.min, projectionB.max - projectionA.min);

      if (overlap <= 0) {
        result.overlap = overlap;
        return result;
      }

      if (overlap < result.overlap) {
        result
          ..overlap = overlap
          ..axis = axis
          ..axisNumber = index;
      }
    }

    return result;
  }

  /// Projects vertices on an axis and returns an interval.
  static _ProjectionResult _projectToAxis(List<Vertex> vertices, Vector axis) {
    double min = Vector.dot(vertices.first, axis);
    double max = min;

    for (int index = 0; index < vertices.length; index++) {
      double dot = Vector.dot(vertices[index], axis);
      if (dot > max) {
        max = dot;
      } else if (dot < min) {
        min = dot;
      }
    }

    return _ProjectionResult(min, max);
  }

  /// Finds supporting vertices given two bodies along a given direction using hill-climbing.
  static List<Vertex> _findSupports(Body bodyA, Body bodyB, Vector normal) {
    double nearestDistance = double.maxFinite;
    Vector vertexToBody = Vector(0, 0);
    final List<Vertex> vertices = bodyB.vertices;
    final Vector bodyAPosition = bodyA.position;
    Vertex? vertexA, vertexB, vertex;

    // find closest vertex on bodyB
    for (var i = 0; i < vertices.length; i++) {
      Vertex vertex = vertices[i];
      vertexToBody
        ..x = vertex.x - bodyAPosition.x
        ..y = vertex.y - bodyAPosition.y;
      double distance = -Vector.dot(normal, vertexToBody);

      if (distance < nearestDistance) {
        nearestDistance = distance;
        vertexA = vertex;
      }
    }

    // Find next closest vertex using the two connected to it.
    var prevIndex = vertexA!.index - 1 >= 0 ? vertexA.index - 1 : vertices.length - 1;
    vertex = vertices[prevIndex];
    vertexToBody
      ..x = vertex.x - bodyAPosition.x
      ..y = vertex.y - bodyAPosition.y;
    nearestDistance = -Vector.dot(normal, vertexToBody);
    vertexB = vertex;

    var nextIndex = (vertexA.index + 1) % vertices.length;
    vertex = vertices[nextIndex];
    vertexToBody
      ..x = vertex.x - bodyAPosition.x
      ..y = vertex.y - bodyAPosition.y;
    final distance = -Vector.dot(normal, vertexToBody);
    if (distance < nearestDistance) {
      vertexB = vertex;
    }

    return [vertexA, vertexB];
  }
}

class _OverlapResult {
  double overlap = double.maxFinite;
  Vector? axis;
  int? axisNumber;
}

class _ProjectionResult {
  _ProjectionResult(this.min, this.max);
  double min = 0;
  double max = 0;
}

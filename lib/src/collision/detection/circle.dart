import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/collision/models/collision.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

/// Exact collision detection for bodies that carry a [Body.circleRadius].
///
/// Two dispatch paths:
///   - [circleCircle]   — both bodies are circles (pure distance math, no SAT)
///   - [circlePolygon]  — one circle, one polygon (closest-point + SAT axes)
class CircleCollision {
  /// Circle vs circle collision.
  ///
  /// Normal always points from bodyA → bodyB.
  /// Contact point is on the surface of bodyA along that normal.
  static Collision circleCircle(Body bodyA, Body bodyB, [Collision? previousCollision]) {
    final collision = previousCollision ?? Collision(collided: false, bodyA: bodyA, bodyB: bodyB);
    collision
      ..bodyA = bodyA.id < bodyB.id ? bodyA : bodyB
      ..bodyB = bodyA.id < bodyB.id ? bodyB : bodyA
      ..reused = false;

    final Body a = collision.bodyA;
    final Body b = collision.bodyB;
    final double rA = a.circleRadius!;
    final double rB = b.circleRadius!;

    final double dx = b.position.x - a.position.x;
    final double dy = b.position.y - a.position.y;
    final double distSq = dx * dx + dy * dy;
    final double radiiSum = rA + rB;

    if (distSq >= radiiSum * radiiSum) {
      collision.collided = false;
      return collision;
    }

    final double dist = math.sqrt(distSq);

    // SAT convention used by this engine: normal points from bodyB AWAY from bodyA
    // (i.e. axis flipped so dot(normal, B − A) < 0). Solver in resolver.dart relies
    // on this sign — see sat.dart:84.
    Vector normal = dist < 1e-9 ? Vector(0, -1) : Vector(dx / dist, dy / dist);
    final double dotCheck = Vector.dot(normal, Vector.sub(b.position, a.position));
    if (dotCheck > 0) normal = Vector(-normal.x, -normal.y);

    // Contact point: surface of bodyA toward bodyB. Normal points B→A, so we
    // step from A in the −normal direction.
    final Vector contactPoint = Vector(
      a.position.x - normal.x * rA,
      a.position.y - normal.y * rA,
    );

    collision
      ..collided = true
      ..depth = radiiSum - dist
      ..normal = normal
      ..tangent = Vector.perp(normal)
      ..penetration = Vector(normal.x * (radiiSum - dist), normal.y * (radiiSum - dist))
      ..supports = [_syntheticVertex(contactPoint, a, b.id)]
      ..parentA = a.parent
      ..parentB = b.parent;

    return collision;
  }

  /// Circle vs polygon collision.
  ///
  /// The circle body may be either [bodyA] or [bodyB]; this method normalises
  /// internally so [circle] and [poly] always refer to the right body.
  static Collision circlePolygon(Body bodyA, Body bodyB, [Collision? previousCollision]) {
    final collision = previousCollision ?? Collision(collided: false, bodyA: bodyA, bodyB: bodyB);
    collision
      ..bodyA = bodyA.id < bodyB.id ? bodyA : bodyB
      ..bodyB = bodyA.id < bodyB.id ? bodyB : bodyA
      ..reused = false;

    // Identify which body is the circle.
    final bool aIsCircle = collision.bodyA.circleRadius != null;
    final Body circle = aIsCircle ? collision.bodyA : collision.bodyB;
    final Body poly = aIsCircle ? collision.bodyB : collision.bodyA;
    final double r = circle.circleRadius!;
    final double cx = circle.position.x;
    final double cy = circle.position.y;

    final List<Vertex> verts = poly.vertices;
    double minDist = double.maxFinite;
    Vector closestPoint = Vector(0, 0);

    for (int i = 0; i < verts.length; i++) {
      final Vertex v1 = verts[i];
      final Vertex v2 = verts[(i + 1) % verts.length];

      final double edgeX = v2.x - v1.x;
      final double edgeY = v2.y - v1.y;
      final double edgeLenSq = edgeX * edgeX + edgeY * edgeY;
      if (edgeLenSq < 1e-9) continue;

      // Closest point on edge segment to circle center.
      final double t = ((cx - v1.x) * edgeX + (cy - v1.y) * edgeY) / edgeLenSq;
      final double tClamped = t.clamp(0.0, 1.0);
      final double cpX = v1.x + tClamped * edgeX;
      final double cpY = v1.y + tClamped * edgeY;

      final double dxC = cx - cpX;
      final double dyC = cy - cpY;
      final double dist = math.sqrt(dxC * dxC + dyC * dyC);

      if (dist < minDist) {
        minDist = dist;
        closestPoint = Vector(cpX, cpY);
      }
    }

    // Is the circle's centre inside the polygon? If so we have deep penetration:
    // depth = r + minDist, and the contact normal must point OUTWARD (closest → center
    // would point inward when inside, so we flip).
    final bool centerInside = Vertices.contains(verts, Vector(cx, cy));

    // No overlap: center outside AND nearest edge farther than r.
    if (!centerInside && minDist >= r) {
      collision.collided = false;
      return collision;
    }

    final double depth = centerInside ? r + minDist : r - minDist;

    // Raw normal points from polygon surface OUTWARD (away from poly interior).
    //   - center outside: outward = (center − closestPoint) / minDist
    //   - center inside:  outward = (closestPoint − center) / minDist
    Vector normal;
    if (minDist > 1e-9) {
      if (centerInside) {
        normal = Vector((closestPoint.x - cx) / minDist, (closestPoint.y - cy) / minDist);
      } else {
        normal = Vector((cx - closestPoint.x) / minDist, (cy - closestPoint.y) / minDist);
      }
    } else {
      // Center sits on an edge — use poly-center → circle-center as outward direction.
      final double ddx = cx - poly.position.x;
      final double ddy = cy - poly.position.y;
      final double d = math.sqrt(ddx * ddx + ddy * ddy);
      normal = d > 1e-9 ? Vector(ddx / d, ddy / d) : Vector(0, -1);
    }

    // SAT convention used by this engine: normal must point AWAY from bodyA
    // (so dot(normal, B − A) < 0). The solver in resolver.dart relies on this
    // sign — see sat.dart:84.
    final double dotCheck = Vector.dot(
      normal,
      Vector.sub(collision.bodyB.position, collision.bodyA.position),
    );
    if (dotCheck > 0) normal = Vector(-normal.x, -normal.y);

    collision
      ..collided = true
      ..depth = depth
      ..normal = normal
      ..tangent = Vector.perp(normal)
      ..penetration = Vector(normal.x * depth, normal.y * depth)
      ..supports = [_syntheticVertex(closestPoint, poly, circle.id)]
      ..parentA = collision.bodyA.parent
      ..parentB = collision.bodyB.parent;

    return collision;
  }

  /// Wraps a world-space point as a [Vertex] so it can slot into [Collision.supports].
  /// [index] should be unique per pair so [Contact.id] doesn't collide across pairs.
  static Vertex _syntheticVertex(Vector point, Body owner, [int index = 0]) {
    return Vertex(x: point.x, y: point.y, index: index, body: owner);
  }
}

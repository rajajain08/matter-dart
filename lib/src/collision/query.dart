import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/collision/collision.dart';
import 'package:matter_dart/src/factory/bodies.dart';
import 'package:matter_dart/src/geometry/bounds.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

import 'SAT.dart';

/// [Query] contains methods for performing collision queries.
class Query {
  /// Returns a list of collisions between `body` and `bodies`.
  static List<Collision> collides(Body body, List<Body> bodies) {
    List<Collision> collisions = [];

    for (int index = 0; index < bodies.length; index++) {
      Body bodyA = bodies[index];
      if (bodyA.bounds!.overlaps(body.bounds!)) {
        for (int j = bodyA.parts.length == 1 ? 0 : 1; j < bodyA.parts.length; j++) {
          Body part = bodyA.parts[j];
          if (part.bounds!.overlaps(body.bounds!)) {
            var collision = SAT.collides(part, body);
            if (collision.collided) {
              collisions.add(collision);
              break;
            }
          }
        }
      }
    }

    return collisions;
  }

  /// Casts a ray segment against a set of bodies and returns all collisions, ray width is optional.
  /// Intersection points are not provided.
  static List<Collision> ray(List<Body> bodies, Vector startPoint, Vector endPoint, [double? rayWidth]) {
    rayWidth = rayWidth ?? double.maxFinite;

    double rayAngle = Vector.angle(startPoint, endPoint);
    double rayLength = Vector.sub(startPoint, endPoint).magnitude();
    double rayX = (endPoint.x + startPoint.x) * 0.5;
    double rayY = (endPoint.y + startPoint.y) * 0.5;

    // TODO: Add Options.
    Body ray = Bodies.rectangle(rayX, rayY, rayLength, rayWidth, null);
    List<Collision> collisions = Query.collides(ray, bodies);

    for (int index = 0; index < collisions.length; index++) {
      Collision collision = collisions[index];
      collision.bodyB = collision.bodyA;
    }

    return collisions;
  }

  /// Returns all bodies whose bounds are inside (or outside if set) the given set of bounds, from the given set of bodies.
  static List<Body> region(List<Body> bodies, Bounds bounds, [bool outside = false]) {
    List<Body> result = [];

    for (int i = 0; i < bodies.length; i++) {
      Body body = bodies[i];
      bool overlaps = body.bounds!.overlaps(bounds);
      if ((overlaps && !outside) || (!overlaps && outside)) {
        result.add(body);
      }
    }

    return result;
  }

  /// Returns all bodies whose vertices contain the given point, from the given set of bodies.
  static List<Body> point(List<Body> bodies, Vector point) {
    List<Body> result = [];

    for (int i = 0; i < bodies.length; i++) {
      Body body = bodies[i];
      if (body.bounds!.contains(point)) {
        for (int j = body.parts.length == 1 ? 0 : 1; j < body.parts.length; j++) {
          Body part = body.parts[j];
          if (part.bounds!.contains(point) && Vertices.contains(part.vertices, point)) {
            result.add(body);
            break;
          }
        }
      }
    }

    return result;
  }
}

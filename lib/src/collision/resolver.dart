import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/collision/contact.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';
import 'package:matter_dart/src/utils/common.dart';

import 'pair.dart';

/// [Resolver] contains methods for resolving collision pairs.
class Resolver {
  static const int _restingThresh = 4;
  static const int _restingThreshTangent = 6;
  static const double _positionDampen = 0.9;
  static const double _positionWarming = 0.8;
  static const int _frictionNormalMultiplier = 5;

  /// Prepare pairs for position solving.
  static void preSolvePosition(List<Pair> pairs) {
    for (int index = 0; index < pairs.length; index++) {
      Pair pair = pairs[index];
      if (!pair.isActive) continue;

      final activeCount = pair.activeContacts.length;
      pair.collision.parentA?.totalContacts += activeCount;
      pair.collision.parentB?.totalContacts += activeCount;
    }
  }

  /// Find a solution for pair positions.
  static void solvePosition(List<Pair> pairs, double timescale) {
    // Find impulses required to resolve penetration
    for (int index = 0; index < pairs.length; index++) {
      Pair pair = pairs[index];
      if (!pair.isActive || pair.isSensor) continue;

      final collision = pair.collision;
      final bodyA = collision.parentA;
      final bodyB = collision.parentB;
      final normal = collision.normal;

      // Get current separation between body edges involved in collision.
      Vector bodyBtoA = Vector.sub(
        Vector.add(bodyB!.positionImpulse, bodyB.position),
        Vector.add(bodyA!.positionImpulse, Vector.sub(bodyB.position, collision.penetration!)),
      );

      pair.separation = Vector.dot(normal!, bodyBtoA);
    }

    for (int index = 0; index < pairs.length; index++) {
      Pair pair = pairs[index];
      if (!pair.isActive || pair.isSensor) continue;

      final collision = pair.collision;
      final bodyA = collision.parentA;
      final bodyB = collision.parentB;
      final normal = collision.normal;
      double positionImpulse = (pair.separation - pair.slop) * timescale;

      if (bodyA!.isStatic || bodyB!.isStatic) {
        positionImpulse *= 2;
      }

      if (!(bodyA.isStatic || bodyA.isSleeping)) {
        final contactShare = Resolver._positionDampen / bodyA.totalContacts;
        bodyA.positionImpulse.x += normal!.x * positionImpulse * contactShare;
        bodyA.positionImpulse.y += normal.y * positionImpulse * contactShare;
      }

      if (!(bodyB!.isStatic || bodyB.isSleeping)) {
        final contactShare = Resolver._positionDampen / bodyB.totalContacts;
        bodyB.positionImpulse.x -= normal!.x * positionImpulse * contactShare;
        bodyB.positionImpulse.y -= normal.y * positionImpulse * contactShare;
      }
    }
  }

  /// Apply position resolution.
  static void postSolvePosition(List<Body> bodies) {
    for (int index = 0; index < bodies.length; index++) {
      Body body = bodies[index];

      // Reset contact count
      body.totalContacts = 0;

      if (body.positionImpulse.x != 0 || body.positionImpulse.y != 0) {
        // Update body geometry
        for (int j = 0; j < body.parts.length; j++) {
          Body part = body.parts[j];
          part.vertices = Vertices.translate(part.vertices, body.positionImpulse);
          part.bounds?.update(part.vertices, body.velocity);
          part.position.x += body.positionImpulse.x;
          part.position.y += body.positionImpulse.y;
        }

        // Move the body without changing velocity
        body.positionPrev?.x += body.positionImpulse.x;
        body.positionPrev?.y += body.positionImpulse.y;

        // Reset cached impulse if the body has velocity along it
        if (Vector.dot(body.positionImpulse, body.velocity) < 0) {
          body.positionImpulse.x = 0;
          body.positionImpulse.y = 0;
        }
        // Warm the next iteration
        else {
          body.positionImpulse.x *= Resolver._positionWarming;
          body.positionImpulse.y *= Resolver._positionWarming;
        }
      }
    }
  }

  /// Prepare pairs for velocity solving.
  static void preSolveVelocity(List<Pair> pairs) {
    Vector impulse = Vector(0, 0);

    for (int index = 0; index < pairs.length; index++) {
      Pair pair = pairs[index];
      if (!pair.isActive || pair.isSensor) continue;

      final contacts = pair.activeContacts;
      final collision = pair.collision;
      final bodyA = collision.parentA;
      final bodyB = collision.parentB;
      final normal = collision.normal;
      final tangent = collision.tangent;

      // Resolve each contact.
      for (int j = 0; j < contacts.length; j++) {
        final Contact contact = contacts[j];
        final Vertex contactVertex = contact.vertex;
        final double normalImpulse = contact.normalImpulse;
        final double tangentImpluse = contact.tangentImpulse;

        if (normalImpulse != 0 || tangentImpluse != 0) {
          // Total impulse from contact.
          impulse.x = (normal!.x * normalImpulse) + (tangent!.x * tangentImpluse);
          impulse.y = (normal.y * normalImpulse) + (tangent.y * tangentImpluse);

          // Apply impulse from contact.
          if (!(bodyA!.isStatic || bodyA.isSleeping)) {
            final Vector offset = Vector.sub(contactVertex, bodyA.position);
            bodyA.positionPrev?.x += impulse.x * bodyA.inverseMass;
            bodyA.positionPrev?.y += impulse.y * bodyA.inverseMass;
            bodyA.anglePrev += Vector.cross(offset, impulse) * bodyA.inverseInertia;
          }

          if (!(bodyB!.isStatic || bodyB.isSleeping)) {
            final Vector offset = Vector.sub(contactVertex, bodyB.position);
            bodyB.positionPrev?.x -= impulse.x * bodyB.inverseMass;
            bodyB.positionPrev?.y -= impulse.y * bodyB.inverseMass;
            bodyB.anglePrev -= Vector.cross(offset, impulse) * bodyB.inverseInertia;
          }
        }
      }
    }
  }

  /// Find a solution for pair velocities.
  static void solveVelocity(List<Pair> pairs, double timescale) {
    final double timescaleSquared = math.pow(timescale, 2).toDouble();
    final Vector impulse = Vector(0, 0);

    for (int index = 0; index < pairs.length; index++) {
      Pair pair = pairs[index];

      if (!pair.isActive || pair.isSensor) continue;

      final collision = pair.collision;
      final bodyA = collision.parentA;
      final bodyB = collision.parentB;
      final normal = collision.normal;
      final tangent = collision.tangent;
      final contacts = pair.activeContacts;
      final contactShare = 1 / contacts.length;

      // Update body velocities.
      bodyA!.velocity.x = bodyA.position.x - (bodyA.positionPrev?.x ?? 0);
      bodyA.velocity.y = bodyA.position.y - (bodyA.positionPrev?.y ?? 0);
      bodyB!.velocity.x = bodyB.position.x - (bodyB.positionPrev?.x ?? 0);
      bodyB.velocity.y = bodyB.position.y - (bodyB.positionPrev?.y ?? 0);
      bodyA.angularVelocity = bodyA.angle - bodyA.anglePrev;
      bodyB.angularVelocity = bodyB.angle - bodyB.anglePrev;

      // Resolve each contact.
      for (int j = 0; j < contacts.length; j++) {
        final Contact contact = contacts[j];
        final Vertex contactVertex = contact.vertex;
        final offsetA = Vector.sub(contactVertex, bodyA.position);
        final offsetB = Vector.sub(contactVertex, bodyB.position);
        final velocityPointA = Vector.add(bodyA.velocity, Vector.mult(Vector.perp(offsetA), bodyA.angularVelocity));
        final velocityPointB = Vector.add(bodyB.velocity, Vector.mult(Vector.perp(offsetB), bodyB.angularVelocity));
        final relativeVelocity = Vector.sub(velocityPointA, velocityPointB);
        final double normalVelocity = Vector.dot(normal!, relativeVelocity);

        final double tangentVelocity = Vector.dot(tangent!, relativeVelocity);
        final double tangentSpeed = tangentVelocity.abs();
        final int tangentVelocityDirection = Common.sign(tangentVelocity);

        // Raw impulses
        double normalImpulse = (1 + pair.restitution) * normalVelocity;
        double normalForce = Common.clamp(pair.separation + normalVelocity, 0, 1) * Resolver._frictionNormalMultiplier;

        // Coulomb friction.
        double tangentImpulse = tangentVelocity;
        double maxFriction = double.infinity;

        if (tangentSpeed > pair.friction * pair.frictionStatic * normalForce * timescaleSquared) {
          maxFriction = tangentSpeed;
          tangentImpulse =
              Common.clamp(pair.friction * tangentVelocityDirection * timescaleSquared, -maxFriction, maxFriction);
        }

        // Modify impulses accounting for mass, inertia and offset
        final double oAcN = Vector.cross(offsetA, normal);
        final double oBcN = Vector.cross(offsetB, normal);
        final share = contactShare /
            (bodyA.inverseMass +
                bodyB.inverseMass +
                bodyA.inverseInertia * oAcN * oAcN +
                bodyB.inverseInertia * oBcN * oBcN);

        normalImpulse *= share;
        tangentImpulse *= share;

        // Handle high velocity and resting collisions separately
        if (normalVelocity < 0 && normalVelocity * normalVelocity > Resolver._restingThresh * timescaleSquared) {
          // high normal velocity so clear cached contact normal impulse
          contact.normalImpulse = 0;
        } else {
          // Solve resting collision constraints using Erin Catto's method (GDC08)
          // Impulse constraint tends to 0
          var contactNormalImpulse = contact.normalImpulse;
          contact.normalImpulse = math.min(contact.normalImpulse + normalImpulse, 0);
          normalImpulse = contact.normalImpulse - contactNormalImpulse;
        }

        // Handle high velocity and resting collisions separately.
        if (tangentVelocity * tangentVelocity > Resolver._restingThreshTangent * timescaleSquared) {
          // High tangent velocity so clear cached contact tangent impulse
          contact.tangentImpulse = 0;
        } else {
          // Solve resting collision constraints using Erin Catto's method (GDC08)
          // Tangent impulse tends to -tangentSpeed or +tangentSpeed
          var contactTangentImpulse = contact.tangentImpulse;
          contact.tangentImpulse = Common.clamp(contact.tangentImpulse + tangentImpulse, -maxFriction, maxFriction);
          tangentImpulse = contact.tangentImpulse - contactTangentImpulse;
        }

        // Total impulse from contact
        impulse.x = (normal.x * normalImpulse) + (tangent.x * tangentImpulse);
        impulse.y = (normal.y * normalImpulse) + (tangent.y * tangentImpulse);

        // Apply impulse from contact.
        if (!(bodyA.isStatic || bodyA.isSleeping)) {
          bodyA.positionPrev?.x += impulse.x * bodyA.inverseMass;
          bodyA.positionPrev?.y += impulse.y * bodyA.inverseMass;
          bodyA.anglePrev += Vector.cross(offsetA, impulse) * bodyA.inverseInertia;
        }
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/body/support/models.dart';
import 'package:matter_dart/src/core/sleeping.dart';
import 'package:matter_dart/src/geometry/axes.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';
import 'package:matter_dart/src/utils/enums.dart';

/// Constraints are used for specifying that a fixed distance must be maintained between two bodies (or a body and a fixed world-space position).
///
/// The stiffness of constraints can be modified to create springs or elastic.
class Constraint {
  static const double _warming = 0.4;
  static const double _torqueDampen = 1;
  static const double _minLength = 0.000001;

  Body? bodyA;
  Body? bodyB;
  String label;
  double stiffness;
  double damping;
  double angularStiffness;
  late double length;
  late Vector pointA;
  late Vector pointB;
  late ConstraintRenderOptions render;
  late double angleA;
  late double angleB;

  Constraint({
    this.bodyA,
    this.bodyB,
    this.label = 'Constraint',
    this.stiffness = 1.0,
    this.damping = 0,
    this.angularStiffness = 0,
    double? length,
    Vector? pointA,
    Vector? pointB,
    ConstraintRenderOptions? render,
    double angleA = 0,
    double angleB = 0,
  }) {
    // If bodies defined but no points, use body centre
    if (bodyA != null && pointA == null) {
      this.pointA = Vector(0, 0);
    }
    if (bodyB != null && pointB == null) {
      this.pointB = Vector(0, 0);
    }

    // Calculate static length using initial world space points
    Vector initialPointA = this.bodyA != null ? Vector.add(this.bodyA!.position, this.pointA) : this.pointA;
    Vector initialPointB = this.bodyB != null ? Vector.add(this.bodyB!.position, this.pointB) : this.pointB;
    this.length = length ?? Vector.sub(initialPointA, initialPointB).magnitude();

    this.angleA = this.bodyA != null ? this.bodyA!.angle : angleA;
    this.angleB = this.bodyB != null ? this.bodyB!.angle : angleB;

    this.render = render ?? ConstraintRenderOptions();

    if (this.length == 0 && this.stiffness > 0.1) {
      this.render
        ..type = ConstraintRenderType.pin
        ..anchors = false;
    } else if (this.stiffness < 0.9) {
      this.render.type = ConstraintRenderType.spring;
    }
  }

  /// Prepares for solving by constraint warming.
  void preSolveAll(List<Body> bodies) {
    for (int index = 0; index < bodies.length; index++) {
      Body body = bodies[index];
      BodyConstraintImpulse impulse = body.constraintImpulse;

      if (body.isStatic || (impulse.x == 0 && impulse.y == 0 && impulse.angle == 0)) {
        continue;
      }

      body.position.x += impulse.x;
      body.position.y += impulse.y;
      body.angle += impulse.angle;
    }
  }

  /// Solves all constraints in a list of collisions.
  void solveAll(List<Constraint> constraints, double timescale) {
    // Solve fixed constraints.
    for (int index = 0; index < constraints.length; index++) {
      Constraint constraint = constraints[index];
      bool fixedA = constraint.bodyA == null || (constraint.bodyA != null && constraint.bodyA!.isStatic);
      bool fixedB = constraint.bodyB == null || (constraint.bodyB != null && constraint.bodyB!.isStatic);

      if (fixedA || fixedB) {
        solve(constraints[index], timescale);
      }
    }

    // Solve free constraints last.
    for (int index = 0; index < constraints.length; index++) {
      Constraint constraint = constraints[index];
      bool fixedA = constraint.bodyA == null || (constraint.bodyA != null && constraint.bodyA!.isStatic);
      bool fixedB = constraint.bodyB == null || (constraint.bodyB != null && constraint.bodyB!.isStatic);

      if (!fixedA && !fixedB) {
        solve(constraints[index], timescale);
      }
    }
  }

  /// Solves a distance constraint with Gauss-Siedel method.
  void solve(Constraint constraint, double timescale) {
    Body? bodyA = constraint.bodyA, bodyB = constraint.bodyB;
    Vector pointA = constraint.pointA, pointB = constraint.pointB;

    if (bodyA == null && bodyB == null) return;

    // Update reference angle.
    if (bodyA != null && !bodyA.isStatic) {
      pointA = pointA.rotateVactor(bodyA.angle - constraint.angleA);
      constraint.angleA = bodyA.angle;
    }

    if (bodyB != null && !bodyB.isStatic) {
      pointB = pointB.rotateVactor(bodyB.angle - constraint.angleB);
      constraint.angleB = bodyB.angle;
    }

    Vector pointAWorld = pointA, pointBWorld = pointB;
    if (bodyA != null) pointAWorld = Vector.add(bodyA.position, pointA);
    if (bodyB != null) pointBWorld = Vector.add(bodyB.position, pointB);

    Vector delta = Vector.sub(pointAWorld, pointBWorld);
    double currentLength = delta.magnitude();

    // Prevent singularity.
    if (currentLength < Constraint._minLength) {
      currentLength = Constraint._minLength;
    }

    // Solve distance constraint with Gauss-Siedel method
    double difference = (currentLength - constraint.length) / currentLength;
    double stiffness = constraint.stiffness < 1 ? constraint.stiffness * timescale : constraint.stiffness;
    Vector force = Vector.mult(delta, difference * stiffness);
    double massTotal = (bodyA != null ? bodyA.inverseMass : 0) + (bodyB != null ? bodyB.inverseMass : 0);
    double inertiaTotal = (bodyA != null ? bodyA.inverseInertia : 0) + (bodyB != null ? bodyB.inverseInertia : 0);
    double resistanceTotal = massTotal + inertiaTotal;
    double? torque, share, normalVelocity;
    Vector? normal, relativeVelocity;

    if (constraint.damping != 0) {
      Vector zero = Vector(0, 0);
      normal = Vector.div(delta, currentLength);

      relativeVelocity = Vector.sub(
        bodyB != null ? Vector.sub(bodyB.position, bodyB.positionPrev!) : zero,
        bodyA != null ? Vector.sub(bodyA.position, bodyA.positionPrev!) : zero,
      );

      normalVelocity = Vector.dot(normal, relativeVelocity);
    }

    if (bodyA != null && !bodyA.isStatic) {
      share = bodyA.inverseMass / massTotal;

      // keep track of applied impulses for post solving
      bodyA.constraintImpulse.x -= force.x * share;
      bodyA.constraintImpulse.y -= force.y * share;

      // apply forces
      bodyA.position.x -= force.x * share;
      bodyA.position.y -= force.y * share;

      // apply damping
      if (constraint.damping != 0) {
        bodyA.positionPrev!.x -= constraint.damping * normal!.x * normalVelocity! * share;
        bodyA.positionPrev!.y -= constraint.damping * normal.y * normalVelocity * share;
      }

      // apply torque
      torque = (Vector.cross(pointA, force) / resistanceTotal) *
          Constraint._torqueDampen *
          bodyA.inverseInertia *
          (1 - constraint.angularStiffness);
      bodyA.constraintImpulse.angle -= torque;
      bodyA.angle -= torque;
    }

    if (bodyB != null && !bodyB.isStatic) {
      share = bodyB.inverseMass / massTotal;

      // keep track of applied impulses for post solving
      bodyB.constraintImpulse.x += force.x * share;
      bodyB.constraintImpulse.y += force.y * share;

      // apply forces
      bodyB.position.x += force.x * share;
      bodyB.position.y += force.y * share;

      // apply damping
      if (constraint.damping != 0) {
        bodyB.positionPrev!.x += constraint.damping * normal!.x * normalVelocity! * share;
        bodyB.positionPrev!.y += constraint.damping * normal.y * normalVelocity * share;
      }

      // apply torque
      torque = (Vector.cross(pointB, force) / resistanceTotal) *
          Constraint._torqueDampen *
          bodyB.inverseInertia *
          (1 - constraint.angularStiffness);
      bodyB.constraintImpulse.angle += torque;
      bodyB.angle += torque;
    }
  }

  /// Performs body updates required after solving constraints.
  void postSolveAll(List<Body> bodies) {
    for (int index = 0; index < bodies.length; index++) {
      Body body = bodies[index];
      BodyConstraintImpulse impulse = body.constraintImpulse;

      if (body.isStatic || (impulse.x == 0 && impulse.y == 0 && impulse.angle == 0)) {
        continue;
      }

      Sleeping.set(body, false);

      // Update geometry and reset.
      for (int j = 0; j < body.parts.length; j++) {
        Body part = body.parts[j];
        part.vertices = Vertices.translate(part.vertices, impulse);

        if (j > 0) {
          part.position.x += impulse.x;
          part.position.y += impulse.y;
        }

        if (impulse.angle != 0) {
          part.vertices = Vertices.rotate(part.vertices, impulse.angle, body.position);
          Axes.rotate(part.axes, impulse.angle);

          if (j > 0) {
            part.position = part.position.rotateAbout(impulse.angle, body.position);
          }
        }

        part.bounds?.update(part.vertices, body.velocity);
      }

      // dampen the cached impulse for warming next step
      impulse.angle *= Constraint._warming;
      impulse.x *= Constraint._warming;
      impulse.y *= Constraint._warming;
    }
  }

  /// Returns the world-space position of `constraint.pointA`, accounting for `constraint.bodyA`.
  Vector pointAWorld(Constraint constraint) {
    return Vector(
      (constraint.bodyA != null ? constraint.bodyA!.position.x : 0) + constraint.pointA.x,
      (constraint.bodyA != null ? constraint.bodyA!.position.y : 0) + constraint.pointA.y,
    );
  }

  /// Returns the world-space position of `constraint.pointB`, accounting for `constraint.bodyB`.
  Vector pointBWorld(Constraint constraint) {
    return Vector(
      (constraint.bodyB != null ? constraint.bodyB!.position.x : 0) + constraint.pointB.x,
      (constraint.bodyB != null ? constraint.bodyB!.position.y : 0) + constraint.pointB.y,
    );
  }
}

class ConstraintRenderOptions {
  double lineWidth = 2;
  Color strokeStyle = Colors.white;
  bool visible = true;
  bool anchors = true;
  ConstraintRenderType type = ConstraintRenderType.line;
}

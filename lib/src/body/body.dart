import 'dart:math' as math;

import 'package:matter_dart/matter_dart.dart';
import 'package:matter_dart/src/geometry/bounds.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';
import 'package:matter_dart/src/utils/common.dart';

import 'support/models.dart';

/// [Body] contains methods for creating and manipulating body models.
/// All properties have default values, and many are pre-calculated automatically based on other properties.
/// Vertices must be specified in clockwise order.
class Body {
  static const int _inertiaScale = 4;
  int _nextCollidingGroupId = 1;
  int _nextNonCollidingGroupId = -1;
  int _nextCategory = 0x0001;
  Body? original;

  int id = ID.instance.nextID;
  String type = 'body';
  String label = 'Body';

  List<Body> parts = <Body>[];
  double angle = 0;
  List<Vertex> vertices = <Vertex>[]; // TODO: Create vertices from path.
  Vector position = Vector(0, 0);
  Vector force = Vector(0, 0);
  double torque = 0;
  Vector positionImpulse = Vector(0, 0);
  BodyConstraintImpulse constraintImpulse = BodyConstraintImpulse();
  int totalContacts = 0;
  double speed = 0;
  double angularSpeed = 0;
  Vector velocity = Vector(0, 0);
  double angularVelocity = 0;
  bool isSensor = false;
  bool isStatic = false;
  bool isSleeping = false;
  double motion = 0;
  int sleepThreshold = 60;
  double density = 0.001;
  double restitution = 0;
  double friction = 0.1;
  double frictionStatic = 0.5;
  double frictionAir = 0.01;
  CollisionFilter collisionFilter = CollisionFilter(category: 0x0001, mask: 0xFFFFFFFF, group: 0);
  double slop = 0.05;
  double timescale = 1;
  BodyRenderOptions render = BodyRenderOptions();
  Bounds? bounds;
  ChamferOptions? chamfer;
  double? circleRadius;
  Vector? positionPrev;
  double anglePrev = 0;
  Body? parent;
  List<Vector> axes = <Vector>[];
  double area = 0;
  double mass = 0;
  double inverseMass = 0;
  double inertia = 0;
  double inverseInertia = 0;
  int sleepCounter = 0;
  Region? region;

  /// Returns the next unique group index for which bodies will collide.
  int nextGroup([bool isNonColliding = false]) {
    if (isNonColliding) {
      return _nextNonCollidingGroupId--;
    }
    return _nextCollidingGroupId++;
  }

  /// Returns the next unique category bitfield (starting after the initial default category `0x0001`).
  int nextCategory() {
    _nextCategory = _nextCategory << 1;
    return _nextCategory;
  }

  /// Sets the body as static, including isStatic flag and setting mass and inertia to Infinity.
  void setStatic(bool isStatic) {
    for (int index = 0; index < parts.length; index++) {
      Body part = parts[index];
      part.isStatic = isStatic;

      if (isStatic) {
        part.original = Body()
          ..restitution = part.restitution
          ..friction = part.friction
          ..mass = part.mass
          ..inertia = part.inertia
          ..density = part.density
          ..inverseMass = part.inverseMass
          ..inverseInertia = part.inverseInertia;

        part
          ..restitution = 0
          ..friction = 1;
        part.mass = part.inertia = part.density = double.infinity;
        part.inverseMass = part.inverseInertia = 0;
        part
          ..positionPrev?.x = part.position.x
          ..positionPrev?.y = part.position.y
          ..anglePrev = part.angle
          ..angularVelocity = 0
          ..speed = 0
          ..angularSpeed = 0
          ..motion = 0;
      } else if (part.original != null) {
        part
          ..restitution = part.original!.restitution
          ..friction = part.original!.friction
          ..mass = part.original!.mass
          ..inertia = part.original!.inertia
          ..density = part.original!.density
          ..inverseMass = part.original!.inverseMass
          ..inverseInertia = part.original!.inverseInertia;

        part.original = null;
      }
    }
  }

  /// Sets the mass of the body. Inverse mass, density and inertia are automatically updated to reflect the change.
  void setMass(double newMass) {
    double moment = inertia / (newMass / 6);
    inertia = moment * (newMass / 6);
    inverseInertia = 1 / inertia;

    mass = newMass;
    inverseMass = 1 / mass;
    density = mass / area;
  }

  /// Sets the density of the body. Mass and inertia are automatically updated to reflect the change.
  void setDensity(double newDensity) {
    setMass(newDensity * area);
    density = newDensity;
  }

  /// Sets the moment of inertia (i.e. second moment of area) of the body
  void setInertia(double newInertia) {
    inertia = newInertia;
    inverseInertia = 1 / inertia;
  }

  /// Sets the body's vertices and updates body properties accordingly, including inertia, area and mass (with respect to `body.density`).
  void setVertices(List<Vertex> newVertices) {
    // Change vertices.
    if (newVertices[0].body == this) {
      vertices = newVertices;
    } else {
      vertices = Vertices.create(newVertices, this);
    }

    // Update properties.
    axes = Axes.fromVertices(vertices);
    area = Vertices.area(vertices);
    setMass(density * area);

    // Orient vertices around the centre of mass at origin (0, 0)
    Vector centre = Vertices.centre(vertices);
    vertices = Vertices.translate(vertices, centre, -1);

    // Update inertia while vertices are at origin (0, 0)
    setInertia(Body._inertiaScale * Vertices.inertia(vertices, mass));

    // Update geometry
    vertices = Vertices.translate(vertices, position);
    bounds?.update(vertices, velocity);
  }

  /// Sets the parts of the `body` and updates mass, inertia and centroid.
  void setParts(List<Body> newParts, [bool autoHull = true]) {
    // TODO:
  }

  /// Set the centre of mass of the body. The `centre` is a vector in world-space
  /// unless `relative` is set, in which case it is a translation.
  void setCentre(Vector centre, [bool relative = false]) {
    if (!relative) {
      this.positionPrev!.x = centre.x - (position.x - positionPrev!.x);
      this.positionPrev!.y = centre.y - (position.y - positionPrev!.y);
      this.position.x = centre.x;
      this.position.y = centre.y;
    } else {
      positionPrev!.x += centre.x;
      positionPrev!.y += centre.y;
      position.x = centre.x;
      position.y = centre.y;
    }
  }

  /// Sets the position of the body instantly. Velocity, angle, force etc. are unchanged.
  void setPosition(Vector newPosition) {
    final delta = Vector.sub(newPosition, position);
    positionPrev!.x += delta.x;
    positionPrev!.y += delta.y;

    for (int index = 0; index < parts.length; index++) {
      Body part = parts[index];
      part.position.x += delta.x;
      part.position.y += delta.y;
      part.vertices = Vertices.translate(part.vertices, delta);
      part.bounds!.update(part.vertices, velocity);
    }
  }

  /// Sets the angle of the body instantly. Angular velocity, position, force etc. are unchanged.
  void setAngle(double newAngle) {
    final delta = newAngle - angle;
    anglePrev += delta;

    for (int index = 0; index < parts.length; index++) {
      Body part = parts[index];
      part.angle += delta;
      part.vertices = Vertices.rotate(part.vertices, delta, position);
      Axes.rotate(part.axes, delta);
      part.bounds!.update(part.vertices, velocity);

      if (index > 0) {
        part.position.rotateAbout(delta, position);
      }
    }
  }

  /// Sets the linear velocity of the body instantly. Position, angle, force etc. are unchanged.
  void setVelocity(Vector newVelocity) {
    positionPrev!.x = position.x - newVelocity.x;
    positionPrev!.y = position.y - newVelocity.y;
    velocity.x = newVelocity.x;
    velocity.y = newVelocity.y;
    speed = velocity.magnitude();
  }

  /// Sets the angular velocity of the body instantly. Position, angle, force etc. are unchanged.
  void setAngularVelocity(double newAngularVelocity) {
    anglePrev = angle - newAngularVelocity;
    angularVelocity = newAngularVelocity;
    angularSpeed = angularVelocity.abs();
  }

  /// Moves a body by a given vector relative to its current position, without imparting any velocity.
  void translate(Vector translation) {
    setPosition(Vector.add(position, translation));
  }

  /// Rotates a body by a given angle relative to its current angle, without imparting any angular velocity.
  void rotate(double rotation, [Vector? point]) {
    if (point == null) {
      setAngle(angle + rotation);
    } else {
      final cos = math.cos(rotation);
      final sin = math.sin(rotation);
      final dx = position.x - point.x;
      final dy = position.y - point.y;

      setPosition(Vector(point.x + (dx * cos - dy * sin), point.y + (dx * sin + dy * cos)));
      setAngle(angle + rotation);
    }
  }

  /// Scales the body, including updating physical properties (mass, area, axes, inertia), from a world-space point (default is body centre).
  void scale(double scaleX, double scaleY, [Vector? point]) {
    double totalArea = 0, totalInertia = 0;
    point = point ?? position;

    for (int index = 0; index < parts.length; index++) {
      Body part = parts[index];

      // Scale vertices.
      part.vertices = Vertices.scale(part.vertices, scaleX, scaleY, point);

      // Update properties.
      part.axes = Axes.fromVertices(part.vertices);
      part.area = Vertices.area(part.vertices);
      part.setMass(density * part.area);

      // Update inertia (required vertices to be at origin)
      Vertices.translate(part.vertices, Vector(-part.position.x, -part.position.y));
      part.setInertia(Body._inertiaScale * Vertices.inertia(part.vertices, part.mass));
      part.vertices = Vertices.translate(part.vertices, part.position);

      if (index > 0) {
        totalArea += part.area;
        totalInertia += part.inertia;
      }

      // Scale position.
      part.position
        ..x = point.x + (part.position.x - point.x) * scaleX
        ..y = point.y + (part.position.y - point.y) * scaleY;

      // Update bounds.
      part.bounds!.update(part.vertices, velocity);
    }

    // Handle parent body.
    if (parts.length > 1) {
      area = totalArea;
      if (!isStatic) {
        setMass(density * totalArea);
        setInertia(totalInertia);
      }
    }

    // Handle circles.
    if (circleRadius != null) {
      if (scaleX == scaleY) {
        circleRadius = circleRadius! * scaleX;
      } else {
        // Body is no longer a circle.
        circleRadius = null;
      }
    }
  }

  /// Performs a simulation step for the given `body`, including updating position and angle using Verlet integration.
  void update(double deltaTime, double timescale, double correction) {
    double deltaTimeSquared = math.pow(deltaTime * timescale * this.timescale, 2).toDouble();

    double frictionAir = this.frictionAir * timescale * this.timescale;
    double velocityPrevX = position.x - positionPrev!.x;
    double velocityPrevY = position.y - positionPrev!.y;

    // Update velocity with Verlet integration.
    velocity.x = (velocityPrevX * frictionAir * correction) + (force.x / mass) * deltaTimeSquared;
    velocity.y = (velocityPrevY * frictionAir * correction) + (force.y / mass) * deltaTimeSquared;

    positionPrev!.x = position.x;
    positionPrev!.y = position.y;
    position.x += velocity.x;
    position.y += velocity.y;

    // Update angular velocity with Verlet integration.
    angularVelocity = ((angle - anglePrev) * frictionAir * correction) + (torque / inertia) * deltaTimeSquared;
    anglePrev = angle;
    angle += angularVelocity;

    // Track speed and acceleration.
    speed = velocity.magnitude();
    angularSpeed = angularVelocity.abs();

    // Transform the body's geometry.
    for (int index = 0; index < parts.length; index++) {
      Body part = parts[index];
      part.vertices = Vertices.translate(part.vertices, velocity);

      if (index > 0) {
        position.x += velocity.x;
        position.y += velocity.y;
      }

      if (angularVelocity != 0) {
        part.vertices = Vertices.rotate(part.vertices, angularVelocity, position);
        Axes.rotate(part.axes, angularVelocity);

        if (index > 0) {
          part.position.rotateAbout(angularVelocity, position);
        }
      }

      // Update bounds.
      part.bounds!.update(part.vertices, velocity);
    }
  }

  /// Applies a force to a body from a given world-space position, including resulting torque.
  void applyForce(Vector position, Vector force) {
    this.force.x = force.x;
    this.force.y = force.y;
    Vector offset = Vector(position.x - this.position.x, position.y - this.position.y);
    this.torque += offset.x * force.y - offset.y * force.x;
  }

  /// Returns the sums of the properties of all compound parts of the parent body.
  void _totalProperties() {
    // TODO:
  }
}

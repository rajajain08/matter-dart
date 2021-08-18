import 'package:matter_dart/matter_dart.dart';
import 'package:matter_dart/src/geometry/bounds.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

class Body {
  int id = 0;
  bool isSensor = false;
  double inverseMass = 0;
  double friction = 1;
  double frictionStatic = 1;
  double restitution = 1;
  double slop = 0.05;
  bool isSleeping = false;
  int totalContacts = 0;
  Vector position = Vector(0, 0);
  Vector? positionPrev;
  Vector positionImpulse = Vector(0, 0);
  double angle = 0;
  double anglePrev = 0;
  double inertia = 0;
  double inverseInertia = 0;
  double angularVelocity = 0;
  Body? parent;
  double speed = 0;
  double angularSpeed = 0;
  List<Vector> axes = <Vector>[];
  Vector force = Vector(0, 0);
  double motion = 0;

  // Number of updates in which this body must have near-zero velocity before it is set as sleeping
  int sleepCounter = 0;
  int sleepThreshold = 60;

  // Indicates whether a body is considered static. A static body can never change position or angle and is completely fixed.
  bool isStatic = false;

  // An array of bodies that make up this body.
  List<Body> parts = <Body>[];

  // TODO: Default value should be resolved from path.
  List<Vertex> vertices = <Vertex>[];

  // Defines the AABB region for the body.
  Bounds? bounds;

  // The current velocity of the body after the last `Body.update`.
  Vector velocity = Vector(0, 0);

  CollisionFilter collisionFilter = CollisionFilter(category: 0x0001, mask: 0xFFFFFFFF, group: 0);
  Region? region;
  BodyConstraintImpulse constraintImpulse = BodyConstraintImpulse();
}

/// Creates a region for the body.
class Region {
  late final String id;
  final int startCol;
  final int endCol;
  final int startRow;
  final int endRow;

  Region({
    required this.startCol,
    required this.endCol,
    required this.startRow,
    required this.endRow,
  }) {
    id = '$startCol,$endCol,$startRow,$endRow';
  }
}

/// Defines constraint impulse for body.
class BodyConstraintImpulse extends Vector {
  double angle;
  BodyConstraintImpulse({double x = 0, double y = 0, this.angle = 0}) : super(x, y);
}
